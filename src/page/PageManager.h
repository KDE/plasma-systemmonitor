// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2025 Arjen Hiemstra <ahiemstra@quantumproductions.info>

#pragma once

#include <QObject>
#include <QQmlEngine>

#include <KNSCore/Entry>

#include "PageDataObject.h"

class PageManagerPrivate;

class PageManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum class FilesWriteableState {
        Unknown,
        NotWriteable,
        AllWriteable,
        LocalChanges,
    };
    Q_ENUM(FilesWriteableState)

    PageManager(std::unique_ptr<PageManagerPrivate> &&d);
    ~PageManager();

    Q_PROPERTY(QList<PageDataObject *> pages READ pages NOTIFY pagesChanged)
    QList<PageDataObject *> pages() const;
    Q_INVOKABLE PageDataObject *page(qsizetype index);
    Q_SIGNAL void pagesChanged();
    Q_SIGNAL void pageAdded(PageDataObject *page);
    Q_SIGNAL void pageRemoved(PageDataObject *page);
    Q_SIGNAL void pageReset(PageDataObject *page);

    Q_INVOKABLE FilesWriteableState writeableState(const QString &fileName);
    Q_INVOKABLE FilesWriteableState writeableState(PageDataObject *page);

    Q_PROPERTY(QStringList pageOrder READ pageOrder WRITE setPageOrder NOTIFY pageOrderChanged)
    QStringList pageOrder() const;
    void setPageOrder(const QStringList &newPageOrder);
    Q_SIGNAL void pageOrderChanged();

    Q_PROPERTY(QStringList hiddenPages READ hiddenPages WRITE setHiddenPages NOTIFY hiddenPagesChanged)
    QStringList hiddenPages() const;
    void setHiddenPages(const QStringList &newHiddenPages);
    Q_SIGNAL void hiddenPagesChanged();
    Q_INVOKABLE bool isHidden(const QString &fileName);
    Q_INVOKABLE bool isHidden(PageDataObject *page);

    void load();

    Q_INVOKABLE PageDataObject *addPage(const QString &baseName, const QVariantMap &properties = QVariantMap{});
    Q_INVOKABLE PageDataObject *importPage(const QUrl &file);
    Q_INVOKABLE void removeLocalPageFiles(const QString &fileName);
    Q_INVOKABLE void ghnsEntryStatusChanged(const KNSCore::Entry &entry);

    static std::shared_ptr<PageManager> instance();

    static PageManager *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

private:
    const std::unique_ptr<PageManagerPrivate> d;
};
