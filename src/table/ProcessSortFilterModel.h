/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 * 
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#pragma once

#include <QSortFilterProxyModel>

#include <KCoreAddons/KUser>

class ProcessSortFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)
    Q_PROPERTY(int uidColumn READ uidColumn WRITE setUidColumn NOTIFY uidColumnChanged)
    Q_PROPERTY(int nameColumn READ nameColumn WRITE setNameColumn NOTIFY nameColumnChanged)
    Q_PROPERTY(QStringList hiddenAttributes READ hiddenAttributes WRITE setHiddenAttributes NOTIFY hiddenAttributesChanged)

public:
    enum ViewMode {
        ViewOwn,
        ViewUser,
        ViewSystem,
        ViewAll
    };
    Q_ENUM(ViewMode)

    ProcessSortFilterModel(QObject *parent = nullptr);

    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override;
    bool filterAcceptsColumn(int sourceColumn, const QModelIndex& sourceParent) const override;

    QString filterString() const;
    void setFilterString(const QString &newFilterString);
    Q_SIGNAL void filterStringChanged();

    int uidColumn() const;
    void setUidColumn(int newUidColumn);
    Q_SIGNAL void uidColumnChanged();

    int nameColumn() const;
    void setNameColumn(int newNameColumn);
    Q_SIGNAL void nameColumnChanged();

    QStringList hiddenAttributes() const;
    void setHiddenAttributes(const QStringList &newHiddenAttributes);
    Q_SIGNAL void hiddenAttributesChanged();

    Q_INVOKABLE void sort(int column, Qt::SortOrder order) override;

private:
    QString m_filterString;
    int m_uidColumn = -1;
    int m_nameColumn = -1;
    ViewMode m_viewMode = ViewOwn;
    KUser m_currentUser;
    QStringList m_hiddenAttributes;
};
