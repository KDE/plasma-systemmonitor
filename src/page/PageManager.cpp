// SPDX-FileCopyrightText: 2025 Arjen Hiemstra <ahiemstra@quantumproductions.info>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#include "PageManager.h"

#include <QDir>
#include <QHash>
#include <QStandardPaths>

#include <KConfigGroup>
#include <KSharedConfig>

using namespace Qt::StringLiterals;

static const auto PageExtension = u".page"_s;

class PageManagerPrivate
{
public:
    QList<PageDataObject *> pages;
    QStringList pageOrder;
    QStringList hiddenPages;
    QHash<QString, PageManager::FilesWriteableState> writeableCache;

    inline static std::shared_ptr<PageManager> s_instance = nullptr;
    inline static QQmlEngine *s_engine = nullptr;
};

PageManager::PageManager(std::unique_ptr<PageManagerPrivate> &&d)
    : QObject(nullptr)
    , d(std::move(d))
{
}

PageManager::~PageManager()
{
}

QList<PageDataObject *> PageManager::pages() const
{
    return d->pages;
}

PageDataObject *PageManager::page(qsizetype index)
{
    if (index >= 0 && index < d->pages.size()) {
        return d->pages.at(index);
    }
    return nullptr;
}

QStringList PageManager::pageOrder() const
{
    return d->pageOrder;
}

void PageManager::setPageOrder(const QStringList &newPageOrder)
{
    if (newPageOrder == d->pageOrder) {
        return;
    }

    d->pageOrder = newPageOrder;
    Q_EMIT pageOrderChanged();
}

QStringList PageManager::hiddenPages() const
{
    return d->hiddenPages;
}

void PageManager::setHiddenPages(const QStringList &newHiddenPages)
{
    if (newHiddenPages == hiddenPages()) {
        return;
    }

    d->hiddenPages = newHiddenPages;
    Q_EMIT hiddenPagesChanged();
}

bool PageManager::isHidden(const QString &fileName)
{
    return d->hiddenPages.contains(fileName);
}

bool PageManager::isHidden(PageDataObject *page)
{
    return isHidden(page->fileName());
}

PageManager::FilesWriteableState PageManager::writeableState(const QString &fileName)
{
    if (d->writeableCache.contains(fileName)) {
        return d->writeableCache.value(fileName);
    }
    return FilesWriteableState::Unknown;
}

PageManager::FilesWriteableState PageManager::writeableState(PageDataObject *page)
{
    return writeableState(page->fileName());
}

void PageManager::load()
{
    if (!d->pages.isEmpty()) {
        return;
    }

    QHash<QString, QString> files;

    const auto directories = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation);
    for (const auto &directory : directories) {
        QDir dir{directory};
        const auto entries = dir.entryInfoList({u"*"_s + PageExtension}, QDir::NoDotAndDotDot | QDir::Files);
        for (const auto &entry : entries) {
            const FilesWriteableState entryState = entry.isWritable() ? FilesWriteableState::AllWriteable : FilesWriteableState::NotWriteable;
            if (!files.contains(entry.fileName())) {
                files.insert(entry.fileName(), dir.relativeFilePath(entry.fileName()));
                d->writeableCache.insert(entry.fileName(), entryState);
            } else {
                FilesWriteableState &state = d->writeableCache[entry.fileName()];
                if ((state == FilesWriteableState::NotWriteable && entryState == FilesWriteableState::AllWriteable)
                    || (state == FilesWriteableState::AllWriteable && entryState == FilesWriteableState::NotWriteable)) {
                    state = FilesWriteableState::LocalChanges;
                }
            }
        }
    }

    for (auto itr = files.begin(); itr != files.end(); ++itr) {
        auto config = KSharedConfig::openConfig(itr.value(), KConfig::CascadeConfig, QStandardPaths::AppDataLocation);

        auto page = new PageDataObject{config, this};
        page->load(*config, QStringLiteral("page"));

        connect(page, &PageDataObject::saved, this, [this, page]() {
            if (d->writeableCache[page->fileName()] == FilesWriteableState::NotWriteable) {
                d->writeableCache[page->fileName()] = FilesWriteableState::LocalChanges;
            }
        });
        d->pages.append(page);
    }
}

PageDataObject *PageManager::addPage(const QString &baseName, const QVariantMap &properties)
{
    int counter = 0;
    QString fileName = baseName + PageExtension;
    while (d->writeableCache.contains(fileName)) {
        fileName = baseName + QString::number(++counter) + PageExtension;
    }

    KSharedConfig::Ptr config = KSharedConfig::openConfig(fileName, KConfig::CascadeConfig, QStandardPaths::AppDataLocation);
    auto page = new PageDataObject(config, this);
    page->load(*config, QStringLiteral("page"));

    for (auto itr = properties.begin(); itr != properties.end(); ++itr) {
        page->insert(itr.key(), itr.value());
    }
    d->writeableCache[fileName] = FilesWriteableState::AllWriteable;

    d->pages.append(page);
    d->pageOrder.append(fileName);
    Q_EMIT pagesChanged();
    Q_EMIT pageAdded(page);

    return page;
}

PageDataObject *PageManager::importPage(const QUrl &file)
{
    const QString fileName = file.fileName();
    if (!fileName.endsWith(PageExtension)) {
        return nullptr;
    }
    // Let addPage first figure out the file name to avoid duplicates and then reload the page after we placed the file
    auto page = addPage(fileName);
    const auto destination = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + u'/' + page->fileName();
    QFile::copy(file.toLocalFile(), destination);
    page->resetPage();
    return page;
}

void PageManager::removeLocalPageFiles(const QString &fileName)
{
    auto it = std::find_if(d->pages.begin(), d->pages.end(), [&](PageDataObject *page) {
        return page->fileName() == fileName;
    });
    if (it == d->pages.end()) {
        return;
    }

    if (d->writeableCache[fileName] == FilesWriteableState::NotWriteable) {
        return;
    }

    PageDataObject *const page = *it;
    const QStringList files = QStandardPaths::locateAll(QStandardPaths::AppDataLocation, page->fileName(), QStandardPaths::LocateFile);
    for (const auto &file : files) {
        if (QFileInfo(file).isWritable()) {
            QFile::remove(file);
        }
    }

    if (d->writeableCache[fileName] == FilesWriteableState::AllWriteable) {
        d->pages.erase(it);
        d->pageOrder.removeAll(fileName);
        d->hiddenPages.removeAll(fileName);
        d->writeableCache.remove(fileName);
        page->deleteLater();
        Q_EMIT pageRemoved(page);
        Q_EMIT pagesChanged();
        Q_EMIT pageOrderChanged();
        Q_EMIT hiddenPagesChanged();
    } else {
        page->resetPage();
        d->writeableCache[fileName] = FilesWriteableState::NotWriteable;
        Q_EMIT pageReset(page);
    }
}

void PageManager::ghnsEntryStatusChanged(const KNSCore::Entry &entry)
{
    if (!entry.isValid()) {
        return;
    }

    if (entry.status() == KNSCore::Entry::Installed) {
        const auto files = entry.installedFiles();
        for (const auto &file : files) {
            const QString fileName = QUrl::fromLocalFile(file).fileName();
            if (fileName.endsWith(QLatin1String(".page"))) {
                auto it = std::find_if(d->pages.begin(), d->pages.end(), [&](PageDataObject *page) {
                    return page->fileName() == fileName;
                });
                if (it != d->pages.end()) {
                    // User selected to overwrite the existing file in the kns dialog
                    (*it)->resetPage();
                    if (d->writeableCache[fileName] == FilesWriteableState::NotWriteable) {
                        d->writeableCache[fileName] = FilesWriteableState::LocalChanges;
                    }
                } else {
                    addPage(fileName.chopped(PageExtension.size()));
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
}

std::shared_ptr<PageManager> PageManager::instance()
{
    if (!PageManagerPrivate::s_instance) {
        PageManagerPrivate::s_instance = std::make_shared<PageManager>(std::make_unique<PageManagerPrivate>());
    }
    return PageManagerPrivate::s_instance;
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
