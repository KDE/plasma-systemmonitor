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
    Q_PROPERTY(ViewMode viewMode READ viewMode WRITE setViewMode NOTIFY viewModeChanged)
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

    void setSourceModel(QAbstractItemModel *newSourceModel) override;
    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override;
    bool filterAcceptsColumn(int sourceColumn, const QModelIndex& sourceParent) const override;

    QString filterString() const;
    void setFilterString(const QString &newFilterString);
    Q_SIGNAL void filterStringChanged();

    ViewMode viewMode() const;
    void setViewMode(ViewMode newViewMode);
    Q_SIGNAL void viewModeChanged();

    QStringList hiddenAttributes() const;
    void setHiddenAttributes(const QStringList &newHiddenAttributes);
    Q_SIGNAL void hiddenAttributesChanged();

    Q_INVOKABLE void sort(int column, Qt::SortOrder order) override;

private:
    void findColumns();

    QString m_filterString;
    ViewMode m_viewMode = ViewOwn;
    QStringList m_hiddenAttributes;
    int m_uidColumn = -1;
    KUser m_currentUser;
};
