/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#pragma once

#include <QAbstractListModel>
#include <QQmlParserStatus>
#include <qqmlregistration.h>

#include <KNSCore/Entry>

#include <memory>

class PageController;

class PagesModel : public QAbstractListModel, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    QML_ELEMENT

public:
    enum Roles {
        TitleRole = Qt::UserRole + 1,
        DataRole,
        IconRole,
        FileNameRole,
        HiddenRole,
        FilesWriteableRole,
    };
    Q_ENUM(Roles)

    explicit PagesModel(QObject *parent = nullptr);

    QHash<int, QByteArray> roleNames() const override;

    int rowCount(const QModelIndex &parent) const override;
    QVariant data(const QModelIndex &index, int role) const override;

    void sort(int column = 0, Qt::SortOrder order = Qt::AscendingOrder) override;

    void classBegin() override;
    void componentComplete() override;

private:
    void onPageAdded(PageController *page);

    QList<PageController *> m_pages;
};
