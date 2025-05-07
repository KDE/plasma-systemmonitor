/*
 * SPDX-FileCopyrightText: 2025 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#pragma once

#include <filesystem>

#include <KSharedConfig>
#include <QTemporaryFile>

#include "PageDataObject.h"

/*!
 *
 */
class PageController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Used for data storage")

public:
    enum class WriteableState {
        Unknown,
        NotWriteable,
        Writeable,
        LocalChanges,
    };
    Q_ENUM(WriteableState)

    enum class PageChanges {
        KeepChanges,
        DiscardChanges,
    };
    Q_ENUM(PageChanges)

    PageController(QObject *parent = nullptr);

    /*!
     * The path to the file that stores the data of this page.
     */
    std::filesystem::path path() const;

    /*!
     * The filename of this page.
     */
    Q_PROPERTY(QString fileName READ fileName CONSTANT)
    QString fileName() const;

    /*!
     * The data object for this page.
     */
    Q_PROPERTY(PageDataObject *data READ data NOTIFY loaded)
    PageDataObject *data() const;

    /*!
     * Has this page been hidden by the user?
     */
    Q_PROPERTY(bool hidden READ isHidden NOTIFY hiddenChanged)
    bool isHidden() const;
    Q_SIGNAL void hiddenChanged();

    /*!
     * Is this page considered outdated?
     *
     * Pages are considered outdated when there are multiple files for a page
     * and the most local page has a version that is not the highest.
     */
    Q_PROPERTY(bool outdated READ isOutdated NOTIFY outdatedChanged)
    bool isOutdated() const;
    Q_SIGNAL void outdatedChanged();

    /*!
     * Has this page replaced an outdated version of the page?
     *
     * In some cases, the structure of a page changes too much and we need to
     * copy local changes to a different file instead of just marking things as
     * outdated. This property indicates that this page is a newer version of
     * such a page and the local changes have been moved to a different page.
     */
    Q_PROPERTY(bool replacedOutdated READ hasReplacedOutdated NOTIFY replacedOutdatedChanged)
    bool hasReplacedOutdated() const;
    Q_SIGNAL void replacedOutdatedChanged();

    /*!
     * The writable state of this page.
     */
    Q_PROPERTY(WriteableState writeableState READ writeableState NOTIFY writeableStateChanged)
    WriteableState writeableState() const;
    Q_SIGNAL void writeableStateChanged();

    /*!
     * The config object associated with this page.
     */
    KSharedConfig::Ptr config() const;

    /*!
     * Has the page data been modified in any way.
     */
    bool isModified();

    /*!
     * Are any of the faces of this page marked as forceSaveOnDestroy?
     */
    bool forceSaveOnDestroy();

    /*!
     * Load the page's data.
     */
    Q_INVOKABLE bool load();
    /*!
     * Save the page's data.
     *
     * This will store the full data to path if it is supplied. If path is empty,
     * it will save to the page's path instead.
     */
    Q_INVOKABLE bool save(const std::filesystem::path &path = std::filesystem::path{});
    Q_INVOKABLE bool save(const QUrl &path);
    /*!
     * Upgrade an outdated page to a newer version.
     *
     * \p changes indicates what to do with any local changes, either keeping
     * them or discarding them.
     */
    Q_INVOKABLE bool upgrade(PageChanges changes);
    /*!
     * Reset the page to the state stored in its data file.
     */
    Q_INVOKABLE void reset();
    /*!
     * Emitted whenever the page has loaded.
     */
    Q_SIGNAL void loaded();
    /*!
     * Emitted whenever the page was saved.
     */
    Q_SIGNAL void saved();

    /*!
     * A helper function to copy the contents of one KConfigGroup to another.
     *
     * This copies contents recursively from one group to another.
     */
    static void copyGroupContents(const KConfigGroup &from, KConfigGroup &to);

private:
    friend class PageManager;
    friend class PageManagerPrivate;

    void setWriteableState(WriteableState newState);

    std::filesystem::path m_path;
    PageDataObject *m_data = nullptr;
    int m_version = 0;
    bool m_outdated = false;
    bool m_replacedOutdated = false;
    WriteableState m_writeableState = WriteableState::Unknown;
    KSharedConfig::Ptr m_config;
    std::unique_ptr<QTemporaryFile> m_temporaryConfigFile;
};
