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

bool ProcessSortFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const
{
    auto result = true;

    auto source = sourceModel();

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
        case ViewAll:
            break;
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

int ProcessSortFilterModel::uidColumn() const
{
    return m_uidColumn;
}

void ProcessSortFilterModel::setUidColumn(int newUidColumn)
{
    if (newUidColumn == m_uidColumn) {
        return;
    }

    m_uidColumn = newUidColumn;
    invalidateFilter();
    Q_EMIT uidColumnChanged();
}

int ProcessSortFilterModel::nameColumn() const
{
    return filterKeyColumn();
}

void ProcessSortFilterModel::setNameColumn(int newNameColumn)
{
    if (newNameColumn == filterKeyColumn()) {
        return;
    }

    setFilterKeyColumn(newNameColumn);
    Q_EMIT nameColumnChanged();
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
