/*
 * This file is part of KSysGuard.
 * Copyright 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License or (at your option) version 3 or any later version
 * accepted by the membership of KDE e.V. (or its successor approved
 * by the membership of KDE e.V.), which shall act as a proxy
 * defined in Section 14 of version 3 of the license.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "ColumnSortModel.h"

#include <QDebug>

ColumnSortModel::ColumnSortModel(QObject* parent)
    : QIdentityProxyModel(parent)
{
}

QVariant ColumnSortModel::data(const QModelIndex& index, int role) const
{
    return QIdentityProxyModel::data(mapToSource(index), role);
}

void ColumnSortModel::setSourceModel(QAbstractItemModel *newSourceModel)
{
    m_rowMapping.clear();
    if (newSourceModel) {
        for (int i = 0; i < newSourceModel->rowCount(); ++i) {
            m_rowMapping.append(i);
        }
    }

    QIdentityProxyModel::setSourceModel(newSourceModel);
}

QModelIndex ColumnSortModel::mapFromSource(const QModelIndex& sourceIndex) const
{
    if (!sourceIndex.isValid()) {
        return QModelIndex();
    }

    return createIndex(m_rowMapping.indexOf(sourceIndex.row()), sourceIndex.column());
}

QModelIndex ColumnSortModel::mapToSource(const QModelIndex& proxyIndex) const
{
    if (!proxyIndex.isValid()) {
        return QModelIndex();
    }

    return sourceModel()->index(m_rowMapping.at(proxyIndex.row()), proxyIndex.column());
}

void ColumnSortModel::move(int fromRow, int toRow)
{
    beginMoveRows(QModelIndex(), fromRow, fromRow, QModelIndex(), fromRow < toRow ? toRow + 1 : toRow);
    m_rowMapping.move(fromRow, toRow);
    endMoveRows();
    Q_EMIT sortedColumnsChanged();
}

QStringList ColumnSortModel::sortedColumns() const
{
    QStringList result;
    auto source = sourceModel();
    for (auto sourceRow : qAsConst(m_rowMapping)) {
        result.append(source->data(source->index(sourceRow, 0), idRoleNumber()).toString());
    }
    return result;
}

void ColumnSortModel::setSortedColumns(const QStringList & newSortedColumns)
{
    auto source = sourceModel();
    QHash<QString, int> sourceRowMapping;
    for (int i = 0; i < rowCount(); ++i) {
        auto id = source->data(source->index(i, 0), idRoleNumber()).toString();
        sourceRowMapping.insert(id, i);
    }

    beginResetModel();
    m_rowMapping.clear();
    for (auto id : newSortedColumns) {
        auto row = sourceRowMapping.value(id, -1);
        if (row != -1) {
            m_rowMapping.append(row);
        }
    }

    for (int i = 0; i < rowCount(); ++i) {
        if (!m_rowMapping.contains(i)) {
            m_rowMapping.append(i);
        }
    }
    endResetModel();
    Q_EMIT sortedColumnsChanged();
}

QString ColumnSortModel::idRole() const
{
    return m_idRole;
}

void ColumnSortModel::setIdRole(const QString & newIdRole)
{
    if (newIdRole == m_idRole) {
        return;
    }

    m_idRole = newIdRole;
    m_idRoleNumber = -1;
    Q_EMIT idRoleChanged();
}

int ColumnSortModel::idRoleNumber() const
{
    if (m_idRoleNumber == -1 && !m_idRole.isEmpty() && sourceModel()) {
        m_idRoleNumber = sourceModel()->roleNames().key(m_idRole.toUtf8());
    }

    return m_idRoleNumber;
}
