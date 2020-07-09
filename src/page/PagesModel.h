/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 * 
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#pragma once

#include <memory>
#include <QAbstractListModel>
#include <QQmlParserStatus>

class PageDataObject;

class PagesModel : public QAbstractListModel, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

public:
    enum Roles {
        TitleRole = Qt::UserRole + 1,
        DataRole,
        IconRole,
        FileNameRole
    };
    Q_ENUM(Roles)

    explicit PagesModel(QObject *parent = nullptr);

    Q_PROPERTY(QStringList pageOrder READ pageOrder WRITE setPageOrder NOTIFY pageOrderChanged)

    QHash<int, QByteArray> roleNames() const override;

    int rowCount(const QModelIndex &parent) const override;
    QVariant data(const QModelIndex &index, int role) const override;

    void sort(int column = 0, Qt::SortOrder order = Qt::AscendingOrder) override;

    void classBegin() override;
    void componentComplete() override;

    Q_INVOKABLE PageDataObject *addPage(const QString &fileName, const QVariantMap &properties = QVariantMap{});

    QStringList pageOrder() const;
    void setPageOrder(const QStringList &pageOrder);

Q_SIGNALS:
    void pageOrderChanged();

private:
    void savePage(PageDataObject *page);

    QVector<PageDataObject*> m_pages;
    QStringList m_pageOrder;
};
