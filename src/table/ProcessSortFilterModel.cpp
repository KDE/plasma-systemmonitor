/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 * 
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#include "ProcessSortFilterModel.h"

#include <QDebug>

#include <processcore/process_data_model.h>

using namespace KSysGuard;

ProcessSortFilterModel::ProcessSortFilterModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setSortRole(ProcessDataModel::Value);
    setSortCaseSensitivity(Qt::CaseInsensitive);
    setSortLocaleAware(true);

    setFilterRole(ProcessDataModel::Value);
    setFilterCaseSensitivity(Qt::CaseInsensitive);
}

void ProcessSortFilterModel::setSourceModel(QAbstractItemModel* newSourceModel)
{
    auto oldSourceModel = sourceModel();

    if (newSourceModel == oldSourceModel) {
        return;
    }

    if (oldSourceModel) {
        oldSourceModel->disconnect(this);
    }

    QSortFilterProxyModel::setSourceModel(newSourceModel);
    if (newSourceModel) {
        connect(newSourceModel, &QAbstractItemModel::modelReset, this, &ProcessSortFilterModel::findColumns);
        connect(newSourceModel, &QAbstractItemModel::columnsInserted, this, &ProcessSortFilterModel::findColumns);
        connect(newSourceModel, &QAbstractItemModel::columnsRemoved, this, &ProcessSortFilterModel::findColumns);
        connect(newSourceModel, &QAbstractItemModel::columnsMoved, this, &ProcessSortFilterModel::findColumns);
    }
}

bool ProcessSortFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const
{
    auto result = true;

    auto source = sourceModel();

    if (m_viewMode != ViewAll) {
        auto uid = source->data(source->index(sourceRow, m_uidColumn, sourceParent), ProcessDataModel::Value).toUInt();

        switch (m_viewMode) {
            case ViewOwn:
                result = m_currentUser.userId().nativeId() == uid;
                break;
            case ViewUser:
                result = uid >= 1000 && uid < 65534;
                break;
            case ViewSystem:
                result = uid < 1000 || uid >= 65534;
                break;
            default:
                break;
        }
    }

    if (result) {
        result = QSortFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent);
    }

    return result;
}

bool ProcessSortFilterModel::filterAcceptsColumn(int sourceColumn, const QModelIndex& sourceParent) const
{
    Q_UNUSED(sourceParent)

    auto attribute = sourceModel()->headerData(sourceColumn, Qt::Horizontal, ProcessDataModel::Attribute).toString();
    if (m_hiddenAttributes.contains(attribute)) {
        return false;
    }

    return true;
}

QString ProcessSortFilterModel::filterString() const
{
    return m_filterString;
}

void ProcessSortFilterModel::setFilterString(const QString & newFilterString)
{
    if (newFilterString == m_filterString) {
        return;
    }

    m_filterString = newFilterString;
    setFilterWildcard(m_filterString);
    Q_EMIT filterStringChanged();
}

ProcessSortFilterModel::ViewMode ProcessSortFilterModel::viewMode() const
{
    return m_viewMode;
}

void ProcessSortFilterModel::setViewMode(ViewMode newViewMode)
{
    if (newViewMode == m_viewMode) {
        return;
    }

    m_viewMode = newViewMode;
    invalidateFilter();
    Q_EMIT viewModeChanged();
}

QStringList ProcessSortFilterModel::hiddenAttributes() const
{
    return m_hiddenAttributes;
}

void ProcessSortFilterModel::setHiddenAttributes(const QStringList &newHiddenAttributes)
{
    if (newHiddenAttributes == m_hiddenAttributes) {
        return;
    }

    m_hiddenAttributes = newHiddenAttributes;
    invalidateFilter();
    Q_EMIT hiddenAttributesChanged();
}

void ProcessSortFilterModel::sort(int column, Qt::SortOrder order)
{
    QSortFilterProxyModel::sort(column, order);
}

void ProcessSortFilterModel::findColumns()
{
    m_uidColumn = -1;
    setFilterKeyColumn(-1);

    auto source = sourceModel();

    for (auto column = 0; column < source->columnCount(); ++column) {
        auto attribute = source->headerData(column, Qt::Horizontal, ProcessDataModel::Attribute).toString();
        if (attribute == QStringLiteral("uid")) {
            m_uidColumn = column;
        } else if (attribute == QStringLiteral("name")) {
            setFilterKeyColumn(column);
        }
    }

    invalidate();
}
