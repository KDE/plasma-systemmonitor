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

#include "ColumnDisplayModel.h"

#include <QDebug>

ColumnDisplayModel::ColumnDisplayModel(QObject* parent)
    : QIdentityProxyModel(parent)
{
}

void ColumnDisplayModel::setSourceModel(QAbstractItemModel* newSourceModel)
{
    m_idRoleNumber = -1;
    QIdentityProxyModel::setSourceModel(newSourceModel);
}

QHash<int, QByteArray> ColumnDisplayModel::roleNames() const
{
    auto roles = QIdentityProxyModel::roleNames();
    roles.insert(DisplayStyleRole, "displayStyle");
    return roles;
}

QVariant ColumnDisplayModel::data(const QModelIndex& index, int role) const
{
    if (role == DisplayStyleRole && sourceModel()) {
        auto id = sourceModel()->data(mapToSource(index), idRoleNumber()).toString();
        return m_columnDisplay.value(id, QStringLiteral("hidden"));
    }

    return QIdentityProxyModel::data(index, role);
}

void ColumnDisplayModel::setDisplay(int row, const QString &display)
{
    auto id = sourceModel()->data(sourceModel()->index(row, 0), idRoleNumber()).toString();
    if (id.isEmpty()) {
        return;
    }

    auto changed = false;
    if (!m_columnDisplay.contains(id)) {
        m_columnDisplay.insert(id, display);
        changed = true;
    } else if (m_columnDisplay.value(id) != display) {
        m_columnDisplay[id] = display;
        changed = true;
    }

    if (changed) {
        auto i = index(row, 0);
        Q_EMIT dataChanged(i, i, {DisplayStyleRole});
        Q_EMIT columnDisplayChanged();
    }
}

QVariantMap ColumnDisplayModel::columnDisplay() const
{
    QVariantMap result;
    for (auto itr = m_columnDisplay.cbegin(); itr != m_columnDisplay.cend(); ++itr) {
        result.insert(itr.key(), itr.value());
    }
    return result;
}

void ColumnDisplayModel::setColumnDisplay(const QVariantMap &newColumnDisplay)
{
    QHash<QString, QString> display;
    for (auto itr = newColumnDisplay.begin(); itr != newColumnDisplay.end(); ++itr) {
        display.insert(itr.key(), itr.value().toString());
    }

    m_columnDisplay = display;
    Q_EMIT columnDisplayChanged();
    Q_EMIT dataChanged(index(0, 0), index(rowCount() - 1, columnCount() - 1));
}

QStringList ColumnDisplayModel::visibleColumnIds() const
{
    QHash<QString, int> sourceRowMapping;
    for (int i = 0; i < rowCount(); ++i) {
        auto id = sourceModel()->data(sourceModel()->index(i, 0), idRoleNumber()).toString();
        sourceRowMapping.insert(id, i);
    }

    QStringList result;
    std::copy_if(m_columnDisplay.keyBegin(), m_columnDisplay.keyEnd(), std::back_inserter(result), [this](const auto &key) {
        return m_columnDisplay.value(key) != QStringLiteral("hidden");
    });

    std::stable_sort(result.begin(), result.end(), [sourceRowMapping](const QString &first, const QString &second) {
        return sourceRowMapping.value(first) < sourceRowMapping.value(second);
    });

    return result;
}

QString ColumnDisplayModel::idRole() const
{
    return m_idRole;
}

void ColumnDisplayModel::setIdRole(const QString & newIdRole)
{
    if (newIdRole == m_idRole) {
        return;
    }

    beginResetModel();
    m_idRole = newIdRole;
    m_idRoleNumber = -1;
    endResetModel();
    Q_EMIT idRoleChanged();
}

int ColumnDisplayModel::idRoleNumber() const
{
    if (m_idRoleNumber == -1 && !m_idRole.isEmpty() && sourceModel()) {
        m_idRoleNumber = sourceModel()->roleNames().key(m_idRole.toUtf8());
    }
    return m_idRoleNumber;
}
