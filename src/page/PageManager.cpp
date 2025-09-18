// SPDX-FileCopyrightText: 2025 Arjen Hiemstra <ahiemstra@quantumproductions.info>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#include "PageManager.h"

#include <filesystem>
#include <ranges>

#include <QDir>
#include <QHash>
#include <QStandardPaths>

#include <KConfigGroup>
#include <KSharedConfig>

#include "PageManager_p.h"

#include "systemmonitor.h"

using namespace Qt::StringLiterals;

namespace fs = std::filesystem;

constexpr auto PageExtension = ".page";

std::optional<fs::path> PageManagerPrivate::renamePage(PageController *controller, const QString &newName)
{
    if (controller->m_writeableState != PageController::WriteableState::Writeable) {
        return std::nullopt;
    }

    auto newPath = controller->m_path.parent_path() / newName.toStdString();
    if (!QFile::rename(controller->m_path, newPath)) {
        qWarning() << "Could not rename old page" << controller->m_path << "to" << newName;
        return std::nullopt;
    }

    return newPath;
}

QString PageManagerPrivate::determineFileName(const QString &initialFileName)
{
    auto baseName = initialFileName;
    if (baseName.endsWith(PageExtension)) {
        baseName.chop(qstrlen(PageExtension));
    }

    int counter = 0;
    QString fileName = baseName + PageExtension;
    auto itr = pages.begin();
    while ((itr = std::ranges::find(itr, pages.end(), fileName, &PageController::fileName)) != pages.end()) {
        fileName = baseName + QString::number(++counter) + PageExtension;
    }

    return fileName;
}

PageManager::PageManager(std::unique_ptr<PageManagerPrivate> &&_d)
    : QObject(nullptr)
    , d(std::move(_d))
{
    // KConfigSkeleton does not save automatically, to avoid having to add save()
    // calls everywhere, ensure that we automatically save the config.
    // Unfortunately, configChanged() is also not emitted until after save, so
    // we need to connect all the notify signals instead.
    for (auto signal : {
             &Configuration::hiddenPagesChanged,
             &Configuration::lastVisitedPageChanged,
             &Configuration::pageOrderChanged,
             &Configuration::sidebarCollapsedChanged,
             &Configuration::sidebarWidthChanged,
             &Configuration::startPageChanged,
         }) {
        connect(Configuration::self(), signal, Configuration::self(), &Configuration::save, Qt::QueuedConnection);
    }
}

PageManager::~PageManager()
{
}

QList<PageController *> PageManager::pages() const
{
    return d->pages;
}

PageController *PageManager::page(const QString &fileName)
{
    auto itr = std::ranges::find_if(d->pages, [fileName](PageController *page) {
        return page->fileName() == fileName;
    });
    if (itr != d->pages.end()) {
        return *itr;
    }

    return nullptr;
}

void PageManager::load()
{
    if (!d->pages.isEmpty()) {
        return;
    }

    QMultiHash<QString, PageController *> pages;
    QHash<QString, int> pageVersions;

    // First, collect information on all pages that we can find.
    const auto directories = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation);
    // Ensure we iterate in reverse order so the most "local" file is checked last.
    for (const auto &directory : directories | std::views::reverse) {
        auto dirPath = fs::path(directory.toStdString());

        if (!std::filesystem::exists(dirPath)) {
            continue;
        }

        for (const auto &entry : fs::directory_iterator(dirPath)) {
            if (entry.path().extension() != PageExtension) {
                continue;
            }

            PageController *controller = new PageController{this};
            controller->m_path = entry.path();

            auto config = KConfig(QString::fromStdString(entry.path()), KConfig::SimpleConfig);
            controller->m_version = config.group("page").readEntry("version", 0);
            controller->m_writeableState =
                config.isConfigWritable(false) ? PageController::WriteableState::Writeable : PageController::WriteableState::NotWriteable;

            // Store maximum version of page separately so we can mark pages as outdated.
            pageVersions[controller->fileName()] = std::max(pageVersions[controller->fileName()], controller->m_version);

            pages.insert(controller->fileName(), controller);
        }
    }

    // Before doing anything else, rename any pages that need renaming.
    for (const auto &info : d->s_replacePages) {
        if (!pages.contains(info.fromName)) {
            continue;
        }

        auto controller = pages.value(info.fromName);
        if (controller->m_version != info.version) {
            continue;
        }

        if (auto newPath = d->renamePage(controller, info.toName); newPath.has_value()) {
            pages.remove(info.fromName, controller);
            pages.insert(info.toName, controller);
            controller->m_path = newPath.value();

            pages.value(info.fromName)->m_replacedOutdated = true;
        }
    }

    auto keys = pages.keys();
    auto removed = std::ranges::unique(keys);
    for (const auto &key : std::ranges::subrange(keys.begin(), removed.begin())) {
        auto controller = pages.value(key);

        // Filter any replacement pages that are not writable, as those presumably
        // do not have local changes so we should not display them.
        if (std::ranges::any_of(PageManagerPrivate::s_replacePages, [controller](const auto &entry) {
                return entry.toName == controller->fileName() && controller->m_writeableState == PageController::WriteableState::NotWriteable;
            })) {
            continue;
        }

        // If the file is writable, in the local app data directory and we have multiple files
        // for the same page, mark the page as having local changes.
        if (controller->writeableState() != PageController::WriteableState::NotWriteable) {
            auto fileCount = pages.count(key);
            if (fileCount > 1 && controller->path().parent_path() == writeablePagePath()) {
                controller->setWriteableState(PageController::WriteableState::LocalChanges);
            }
        }

        // If we have multiple versions of a page and the current page is not
        // the highest, mark the page as outdated. Note that if we do not have
        // multiple versions, we do not mark it as outdated since there is no
        // other data to use for the page.
        auto highestVersion = pageVersions.value(controller->fileName());
        if (controller->m_version < highestVersion) {
            controller->m_outdated = true;
        }

        if (!controller->load()) {
            qWarning() << "Failed to load data from" << controller->m_path.string();
            continue;
        }

        d->pages.append(controller);
    }
}

PageController *PageManager::addPage(const QString &initialFileName, const QVariantMap &properties)
{
    auto fileName = d->determineFileName(initialFileName);

    PageController *controller = new PageController{this};
    controller->m_path = writeablePagePath() / fileName.toStdString();
    controller->m_version = CurrentPageVersion;
    controller->m_writeableState = PageController::WriteableState::Writeable;
    controller->load();

    for (auto itr = properties.begin(); itr != properties.end(); ++itr) {
        controller->data()->insert(itr.key(), itr.value());
    }

    d->pages.append(controller);

    Q_EMIT pagesChanged();
    Q_EMIT pageAdded(controller);

    auto pageOrder = Configuration::self()->pageOrder();
    pageOrder.append(fileName);
    Configuration::self()->setPageOrder(pageOrder);

    return controller;
}

PageController *PageManager::importPage(const QUrl &file)
{
    const QString initialFileName = file.fileName();
    if (!initialFileName.endsWith(PageExtension)) {
        return nullptr;
    }

    auto fileName = d->determineFileName(initialFileName);

    auto sourcePath = fs::path(file.toLocalFile().toStdString());
    auto destinationPath = writeablePagePath() / fileName.toStdString();

    QFile::copy(sourcePath, destinationPath);

    PageController *controller = new PageController{this};
    controller->m_path = destinationPath;
    controller->m_writeableState = PageController::WriteableState::Writeable;

    controller->load();

    d->pages.append(controller);

    Q_EMIT pagesChanged();
    Q_EMIT pageAdded(controller);

    auto pageOrder = Configuration::self()->pageOrder();
    pageOrder.append(fileName);
    Configuration::self()->setPageOrder(pageOrder);

    return controller;
}

void PageManager::removeLocalPageFiles(const QString &fileName)
{
    auto it = std::ranges::find(d->pages, fileName, &PageController::fileName);
    if (it == d->pages.end()) {
        return;
    }

    auto controller = *it;

    if (controller->writeableState() == PageController::WriteableState::NotWriteable) {
        return;
    }

    auto path = controller->path();
    if (QFileInfo(path).isWritable()) {
        QFile::remove(path);
    }

    bool isOldPage = std::ranges::any_of(PageManagerPrivate::s_replacePages, [controller](const auto &entry) {
        return entry.toName == controller->fileName();
    });

    if (controller->writeableState() == PageController::WriteableState::Writeable || isOldPage) {
        d->pages.erase(it);

        auto pageOrder = Configuration::self()->pageOrder();
        pageOrder.removeAll(fileName);
        Configuration::self()->setPageOrder(pageOrder);

        auto hiddenPages = Configuration::self()->hiddenPages();
        hiddenPages.removeAll(fileName);
        Configuration::self()->setHiddenPages(hiddenPages);

        controller->deleteLater();
        Q_EMIT pageRemoved(controller);
        Q_EMIT pagesChanged();
    } else {
        controller->m_path = fs::path(QStandardPaths::locate(QStandardPaths::AppDataLocation, fileName).toStdString());
        controller->reset();
        controller->setWriteableState(PageController::WriteableState::NotWriteable);
        Q_EMIT pageReset(controller);
    }
}

PageController *PageManager::ghnsEntryStatusChanged(const KNSCore::Entry &entry)
{
    if (!entry.isValid()) {
        return nullptr;
    }

    if (entry.status() == KNSCore::Entry::Installed) {
        const auto files = entry.installedFiles();
        for (const auto &file : files) {
            const auto url = QUrl::fromLocalFile(file);
            const QString fileName = url.fileName();
            if (fileName.endsWith(PageExtension)) {
                auto it = std::find_if(d->pages.begin(), d->pages.end(), [&](PageController *page) {
                    return page->fileName() == fileName;
                });
                if (it != d->pages.end()) {
                    // User selected to overwrite the existing file in the kns dialog
                    (*it)->reset();
                    if ((*it)->writeableState() == PageController::WriteableState::NotWriteable) {
                        (*it)->setWriteableState(PageController::WriteableState::LocalChanges);
                    }
                } else {
                    return importPage(url);
                }
            }
        }
    } else if (entry.status() == KNSCore::Entry::Deleted) {
        const auto files = entry.uninstalledFiles();
        for (const auto &file : files) {
            const QString fileName = QUrl::fromLocalFile(file).fileName();
            if (fileName.endsWith(PageExtension)) {
                removeLocalPageFiles(fileName);
            }
        }
    }

    return nullptr;
}

void PageManager::saveAll()
{
    for (auto page : std::as_const(d->pages)) {
        if (page->isModified() || page->forceSaveOnDestroy()) {
            page->save();
        }
    }
}

std::shared_ptr<PageManager> PageManager::instance()
{
    if (!PageManagerPrivate::s_instance) {
        PageManagerPrivate::s_instance = std::make_shared<PageManager>(std::make_unique<PageManagerPrivate>());
    }
    return PageManagerPrivate::s_instance;
}

std::filesystem::path PageManager::writeablePagePath()
{
    static auto writablePath = fs::path(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation).toStdString());
    return writablePath;
}

PageManager *PageManager::create(QQmlEngine *qmlEngine, [[maybe_unused]] QJSEngine *jsEngine)
{
    // The instance has to exist before it is used. We cannot replace it.
    Q_ASSERT(PageManagerPrivate::s_instance);

    // The engine has to have the same thread affinity as the singleton.
    Q_ASSERT(qmlEngine->thread() == PageManagerPrivate::s_instance->thread());

    // There can only be one engine accessing the singleton.
    if (PageManagerPrivate::s_engine) {
        Q_ASSERT(qmlEngine == PageManagerPrivate::s_engine);
    } else {
        PageManagerPrivate::s_engine = qmlEngine;
    }

    // Explicitly specify C++ ownership so that the engine doesn't delete
    // the instance.
    QJSEngine::setObjectOwnership(PageManagerPrivate::s_instance.get(), QJSEngine::CppOwnership);
    return PageManagerPrivate::s_instance.get();
}
