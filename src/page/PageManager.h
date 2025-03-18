// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2025 Arjen Hiemstra <ahiemstra@quantumproductions.info>

#pragma once

#include <QObject>
#include <QQmlEngine>

#include <KNSCore/Entry>

#include "PageController.h"

class PageManagerPrivate;

class PageManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    PageManager(std::unique_ptr<PageManagerPrivate> &&d);
    ~PageManager();

    Q_PROPERTY(QList<PageController *> pages READ pages NOTIFY pagesChanged)
    QList<PageController *> pages() const;
    Q_INVOKABLE PageController *page(const QString &fileName);
    Q_SIGNAL void pagesChanged();
    Q_SIGNAL void pageAdded(PageController *page);
    Q_SIGNAL void pageRemoved(PageController *page);
    Q_SIGNAL void pageReset(PageController *page);

    void load();

    /*!
     * Add a new page.
     *
     * \p baseName indicates the initial file name of the page, without extension.
     * If a page already exists with that name, an increasing number will be
     * appended until a non-existing file name is found. \p properties is a
     * map containing initial properties that will be set on the root data object
     * of the page.
     */
    Q_INVOKABLE PageController *addPage(const QString &baseName, const QVariantMap &properties = QVariantMap{});
    /*!
     * Import a page from a URL.
     *
     * This will try to import the file pointed to by \p file . It should be a
     * URL pointing to a local file.
     */
    Q_INVOKABLE PageController *importPage(const QUrl &file);
    /*!
     * Remove or reset a page.
     *
     * If the page \p fileName is writable, this will remove the page and its
     * data file. If it instead has local changes, the local changes will be
     * removed and the page reset instead. If the page is not writable at all,
     * nothing will happen.
     */
    Q_INVOKABLE void removeLocalPageFiles(const QString &fileName);

    /*!
     * Install or remove a page based on the state of a GHNS entry.
     */
    Q_INVOKABLE PageController *ghnsEntryStatusChanged(const KNSCore::Entry &entry);

    /*!
     * Save all pages, ensuring any in-memory changes are written to disk.
     *
     * This is mainly intended to be called on application shutdown.
     */
    Q_INVOKABLE void saveAll();

    static std::shared_ptr<PageManager> instance();
    /*!
     * A helper function that returns QStandardPaths::AppDataLocation as a writable path.
     */
    static std::filesystem::path writeablePagePath();

    static PageManager *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    /*!
     * The current version of new pages.
     */
    static constexpr int CurrentPageVersion = 1;

private:
    const std::unique_ptr<PageManagerPrivate> d;
};
