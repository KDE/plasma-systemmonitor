/*
 * SPDX-FileCopyrightText: 2025 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#include "PageController.h"

#include "FaceLoader.h"
#include "PageManager.h"

#include "systemmonitor.h"

using namespace Qt::StringLiterals;

namespace fs = std::filesystem;

QList<FaceLoader *> findFaceLoaders(PageDataObject *data)
{
    QList<FaceLoader *> result;
    if (data->faceLoader()) {
        result.append(data->faceLoader());
    }

    const auto children = data->children();
    for (auto child : children) {
        result.append(findFaceLoaders(child));
    }

    return result;
}

PageController::PageController(QObject *parent)
    : QObject(parent)
{
    connect(Configuration::self(), &Configuration::hiddenPagesChanged, this, &PageController::hiddenChanged);
}

std::filesystem::path PageController::path() const
{
    return m_path;
}

QString PageController::fileName() const
{
    return QString::fromStdString(m_path.filename());
}

PageDataObject *PageController::data() const
{
    return m_data;
}

bool PageController::isHidden() const
{
    return Configuration::self()->hiddenPages().contains(fileName());
}

bool PageController::isOutdated() const
{
    return m_outdated;
}

bool PageController::hasReplacedOutdated() const
{
    return m_replacedOutdated;
}

PageController::WriteableState PageController::writeableState() const
{
    return m_writeableState;
}

KSharedConfig::Ptr PageController::config() const
{
    return m_config;
}

bool PageController::isModified()
{
    if (m_writeableState == WriteableState::NotWriteable) {
        return false;
    }

    if (m_data->dirty()) {
        return true;
    }

    return false;
}

bool PageController::forceSaveOnDestroy()
{
    const auto faceLoaders = findFaceLoaders(m_data);
    return std::ranges::any_of(faceLoaders, [](auto faceLoader) {
        return faceLoader->forceSaveOnDestroy();
    });
}

bool PageController::load()
{
    KSharedConfig::Ptr config;
    if (m_version > 0) {
        // For newer pages, don't use cascade as that leads to corrupted pages when the page structure
        // changes too much.
        config = KSharedConfig::openConfig(QString::fromStdString(m_path), KConfig::SimpleConfig);
    } else {
        config = KSharedConfig::openConfig(fileName(), KConfig::CascadeConfig, QStandardPaths::AppDataLocation);
    }

    // Store data in an in-memory only version of the page, so things don't try
    // to write to non-writeable files.
    m_config = KSharedConfig::openConfig(QString{}, KConfig::SimpleConfig);
    const auto groups = config->groupList();
    for (auto groupName : groups) {
        auto group = m_config->group(groupName);
        copyGroupContents(config->group(groupName), group);
    }

    m_version = m_config->group(u"page"_s).readEntry("version", 0);

    m_data = new PageDataObject(this, fileName(), this);
    auto result = m_data->load(*m_config, u"page"_s);
    return result;
}

bool PageController::save(const fs::path &path)
{
    auto p = path;
    if (p.empty()) {
        if (m_path.parent_path() != PageManager::writeablePagePath()) {
            m_path = PageManager::writeablePagePath() / m_path.filename();
            setWriteableState(WriteableState::LocalChanges);
        }

        p = m_path;
    }

    KSharedConfig::Ptr config = KSharedConfig::openConfig(QString::fromStdString(p), KConfig::SimpleConfig);
    auto group = config->group(u"page"_s);
    if (!m_data->save(*config, group)) {
        qWarning() << "Could not save page" << fileName();
        return false;
    }
    config->group("page").writeEntry("version", PageManager::CurrentPageVersion);
    config->sync();

    Q_EMIT saved();

    return true;
}

bool PageController::save(const QUrl &path)
{
    return save(fs::path(path.toLocalFile().toStdString()));
}

bool PageController::upgrade(PageChanges changes)
{
    if (m_writeableState != WriteableState::LocalChanges) {
        qWarning() << "Tried upgrading a page that does not have local changes";
        return false;
    }

    if (changes == PageChanges::KeepChanges) {
        if (!save()) {
            return false;
        }
    } else {
        std::error_code error;
        fs::remove(PageManager::writeablePagePath() / m_path.filename(), error);
        if (error) {
            qWarning() << "Could not remove local data for page" << fileName() << error.message();
            return false;
        }

        m_path = fs::path(QStandardPaths::locate(QStandardPaths::AppDataLocation, fileName()).toStdString());
    }

    auto config = KSharedConfig::openConfig(QString::fromStdString(m_path), KConfig::SimpleConfig);
    if (!config->isConfigWritable(false)) {
        setWriteableState(WriteableState::NotWriteable);
    }

    m_outdated = false;
    Q_EMIT outdatedChanged();

    m_data->reset();
    return m_data->load(*config, u"page"_s);
}

void PageController::reset()
{
    m_data->reset();
    load();
}

void PageController::copyGroupContents(const KConfigGroup &from, KConfigGroup &to)
{
    // Note that this is different from KConfigGroup::copyTo as that doesn't do
    // recursive copy.

    const auto entries = from.entryMap();
    for (auto [key, value] : entries.asKeyValueRange()) {
        to.writeEntry(key, value);
    }

    const auto groups = from.groupList();
    for (auto groupName : groups) {
        auto fromGroup = from.group(groupName);
        auto toGroup = to.group(groupName);
        copyGroupContents(fromGroup, toGroup);
    }
}

void PageController::setWriteableState(WriteableState newState)
{
    if (newState == m_writeableState) {
        return;
    }

    m_writeableState = newState;
    Q_EMIT writeableStateChanged();
}

#include "moc_PageController.cpp"
