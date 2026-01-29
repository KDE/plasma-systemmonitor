/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#include "ColumnSortFilterDisplayModel.h"

#include <QDebug>

using namespace Qt::StringLiterals;

ColumnSortFilterDisplayModel::ColumnSortFilterDisplayModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setFilterCaseSensitivity(Qt::CaseSensitivity::CaseInsensitive);
}

QHash<int, QByteArray> ColumnSortFilterDisplayModel::roleNames() const
{
    auto roles = QSortFilterProxyModel::roleNames();
    roles.insert(DisplayStyleRole, "displayStyle");
    roles.insert(EnabledRole, "enabled");
    return roles;
}

QVariant ColumnSortFilterDisplayModel::data(const QModelIndex &index, int role) const
{
    const auto source = sourceModel();
    if (!source) {
        return QVariant{};
    }

    resolveRoleNumbers();
    const auto id = source->data(mapToSource(index), m_idRoleNumber).toString();

    switch (role) {
    case DisplayStyleRole:
        if (id == m_nameAttribute) {
            return u"text"_s;
        } else {
            return m_columnDisplay.value(id, u"hidden"_s);
        }
    case EnabledRole:
        return columnEnabled(id) ? u"enabled"_s : u"disabled"_s;
    }

    return QSortFilterProxyModel::data(index, role);
}

void ColumnSortFilterDisplayModel::setSourceModel(QAbstractItemModel *newSourceModel)
{
    QSortFilterProxyModel::setSourceModel(newSourceModel);

    sort(0);
}

void ColumnSortFilterDisplayModel::move(int fromRow, int toRow)
{
    beginMoveRows(QModelIndex(), fromRow, fromRow, QModelIndex(), fromRow < toRow ? toRow + 1 : toRow);
    m_sortedColumns.move(fromRow, toRow);
    endMoveRows();
    Q_EMIT sortedColumnsChanged();
}

QString ColumnSortFilterDisplayModel::nameAttribute() const
{
    return m_nameAttribute;
}

void ColumnSortFilterDisplayModel::setNameAttribute(const QString &newNameAttribute)
{
    if (newNameAttribute == m_nameAttribute) {
        return;
    }

    beginResetModel();
    m_nameAttribute = newNameAttribute;
    endResetModel();
    Q_EMIT nameAttributeChanged();
}

QStringList ColumnSortFilterDisplayModel::sortedColumns() const
{
    return m_sortedColumns;
}

void ColumnSortFilterDisplayModel::setSortedColumns(const QStringList &newSortedColumns)
{
    if (newSortedColumns == m_sortedColumns) {
        return;
    }

    beginResetModel();
    m_sortedColumns = newSortedColumns;

    auto nameIndex = m_sortedColumns.indexOf(m_nameAttribute);
    if (nameIndex != 0) {
        if (nameIndex > 0) {
            m_sortedColumns.move(nameIndex, 0);
        } else {
            m_sortedColumns.prepend(m_nameAttribute);
        }
    }

    cleanupSortedColumns();

    endResetModel();

    Q_EMIT sortedColumnsChanged();
}

QString ColumnSortFilterDisplayModel::filterString() const
{
    return m_filterString;
}

void ColumnSortFilterDisplayModel::setFilterString(const QString &newFilterString)
{
    if (newFilterString == m_filterString) {
        return;
    }

    m_filterString = newFilterString;
    setFilterFixedString(m_filterString);
    Q_EMIT filterStringChanged();
}

QVariantMap ColumnSortFilterDisplayModel::columnDisplay() const
{
    QVariantMap result;
    for (auto itr = m_columnDisplay.cbegin(); itr != m_columnDisplay.cend(); ++itr) {
        result.insert(itr.key(), itr.value());
    }
    return result;
}

void ColumnSortFilterDisplayModel::setColumnDisplay(const QVariantMap &newColumnDisplay)
{
    QHash<QString, QString> display;
    for (auto itr = newColumnDisplay.begin(); itr != newColumnDisplay.end(); ++itr) {
        display.insert(itr.key(), itr.value().toString());
    }

    beginResetModel();

    m_columnDisplay = display;

    cleanupSortedColumns();

    endResetModel();

    Q_EMIT columnDisplayChanged();
}

void ColumnSortFilterDisplayModel::setDisplay(int row, const QString &display)
{
    resolveRoleNumbers();

    auto id = data(index(row, 0), m_idRoleNumber).toString();
    if (id.isEmpty()) {
        return;
    }

    setDisplayById(id, display);
}

void ColumnSortFilterDisplayModel::setDisplayById(const QString &id, const QString &display)
{
    auto changed = false;
    if (!m_columnDisplay.contains(id)) {
        m_columnDisplay.insert(id, display);
        changed = true;
    } else if (m_columnDisplay.value(id) != display) {
        m_columnDisplay[id] = display;
        changed = true;
    }

    if (changed) {
        auto i = indexForId(id);
        if (!i.isValid()) {
            return;
        }

        if (m_columnDisplay.value(id) == u"hidden"_s) {
            m_sortedColumns.removeOne(id);
        } else {
            m_sortedColumns.append(id);
        }

        Q_EMIT dataChanged(i, i, {DisplayStyleRole});
        Q_EMIT columnDisplayChanged();
        invalidate();
    }
}

bool ColumnSortFilterDisplayModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    resolveRoleNumbers();

    const auto source = sourceModel();
    const auto index = source->index(source_row, 0, source_parent);

    auto name = source->data(index, m_nameRoleNumber).toString();
    auto description = source->data(index, m_descriptionRoleNumber).toString();

    return name.contains(filterRegularExpression()) || description.contains(filterRegularExpression());
}

bool ColumnSortFilterDisplayModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    resolveRoleNumbers();

    const auto source = sourceModel();
    const auto leftId = source->data(source_left, m_idRoleNumber).toString();
    const auto rightId = source->data(source_right, m_idRoleNumber).toString();

    const bool leftEnabled = columnEnabled(leftId);
    const bool rightEnabled = columnEnabled(rightId);

    // Enabled columns go before disabled columns.
    if (leftEnabled && !rightEnabled) {
        return true;
    } else if (!leftEnabled && rightEnabled) {
        return false;
    } else if (leftEnabled && rightEnabled) {
        // For enabled columns, we always have the name column as first entry.
        if (leftId == m_nameAttribute) {
            return true;
        }
        if (rightId == m_nameAttribute) {
            return false;
        }

        return m_sortedColumns.indexOf(leftId) < m_sortedColumns.indexOf(rightId);
    } else {
        // Disabled columns are sorted by name, since changing their sort order
        // doesn't make much sense.
        auto leftName = source->data(source_left, m_nameRoleNumber).toString();
        auto rightName = source->data(source_right, m_nameRoleNumber).toString();
        return QString::localeAwareCompare(leftName, rightName) < 0;
    }
}

bool ColumnSortFilterDisplayModel::columnEnabled(const QString &id) const
{
    if (id == m_nameAttribute) {
        return true;
    }

    return m_columnDisplay.value(id, u"hidden"_s) != u"hidden";
}

void ColumnSortFilterDisplayModel::resolveRoleNumbers() const
{
    if (!sourceModel()) {
        return;
    }

    const auto sourceRoles = sourceModel()->roleNames();
    if (m_idRoleNumber == -1) {
        m_idRoleNumber = sourceRoles.key("id", -1);
    }

    if (m_nameRoleNumber == -1) {
        m_nameRoleNumber = sourceRoles.key("name", -1);
    }

    if (m_descriptionRoleNumber == -1) {
        m_descriptionRoleNumber = sourceRoles.key("description", -1);
    }
}

QModelIndex ColumnSortFilterDisplayModel::indexForId(const QString &id)
{
    resolveRoleNumbers();

    for (int i = 0; i < sourceModel()->rowCount(); i++) {
        const auto index = sourceModel()->index(i, 0);
        if (index.data(m_idRoleNumber).toString() == id) {
            return mapFromSource(index);
        }
    }

    return {};
}

void ColumnSortFilterDisplayModel::cleanupSortedColumns()
{
    if (m_sortedColumns.isEmpty() || m_columnDisplay.isEmpty()) {
        return;
    }

    auto range = std::ranges::remove_if(m_sortedColumns, [this](const QString &entry) {
        if (entry == m_nameAttribute) {
            return false;
        }

        return m_columnDisplay.value(entry, u"hidden"_s) == u"hidden"_s;
    });
    m_sortedColumns.erase(range.begin(), range.end());

    for (auto [key, value] : m_columnDisplay.asKeyValueRange()) {
        if (value != u"hidden"_s && !m_sortedColumns.contains(key)) {
            m_sortedColumns.append(key);
        }
    }
}

#include "moc_ColumnSortFilterDisplayModel.cpp"
