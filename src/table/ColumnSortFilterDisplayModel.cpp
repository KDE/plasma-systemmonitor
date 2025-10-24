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
        return m_columnDisplay.value(id, u"hidden"_s);
    case EnabledRole:
        return columnEnabled(id) ? u"enabled"_s : u"disabled"_s;
    }

    return QSortFilterProxyModel::data(index, role);
}

void ColumnSortFilterDisplayModel::setSourceModel(QAbstractItemModel *newSourceModel)
{
    // m_rowMapping.clear();
    // if (newSourceModel) {
    //     for (int i = 0; i < newSourceModel->rowCount(); ++i) {
    //         m_rowMapping.append(i);
    //     }
    // }

    QSortFilterProxyModel::setSourceModel(newSourceModel);

    sort(0);
}

void ColumnSortFilterDisplayModel::move(int fromRow, int toRow)
{
    beginMoveRows(QModelIndex(), fromRow, fromRow, QModelIndex(), fromRow < toRow ? toRow + 1 : toRow);
    // m_rowMapping.move(fromRow, toRow);
    endMoveRows();
    Q_EMIT sortedColumnsChanged();
}

QStringList ColumnSortFilterDisplayModel::sortedColumns() const
{
    QStringList result;
    auto source = sourceModel();
    // for (auto sourceRow : std::as_const(m_rowMapping)) {
    //     result.append(source->data(source->index(sourceRow, 0), idRoleNumber()).toString());
    // }
    return result;
}

void ColumnSortFilterDisplayModel::setSortedColumns(const QStringList &newSortedColumns)
{
    auto source = sourceModel();
    QHash<QString, int> sourceRowMapping;
    for (int i = 0; i < rowCount(); ++i) {
        auto id = source->data(source->index(i, 0), m_idRoleNumber).toString();
        sourceRowMapping.insert(id, i);
    }

    beginResetModel();
    // m_rowMapping.clear();
    // for (const auto &id : newSortedColumns) {
    //     auto row = sourceRowMapping.value(id, -1);
    //     if (row != -1) {
    //         m_rowMapping.append(row);
    //     }
    // }
    //
    // for (int i = 0; i < rowCount(); ++i) {
    //     if (!m_rowMapping.contains(i)) {
    //         m_rowMapping.append(i);
    //     }
    // }
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

    m_columnDisplay = display;
    Q_EMIT columnDisplayChanged();
    if (sourceModel()) {
        Q_EMIT dataChanged(index(0, 0), index(rowCount() - 1, columnCount() - 1));
    }
    invalidate();
}

void ColumnSortFilterDisplayModel::setDisplay(int row, const QString &display)
{
    resolveRoleNumbers();

    auto id = data(index(row, 0), m_idRoleNumber).toString();
    if (id.isEmpty()) {
        return;
    }

    qDebug() << id;

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

        Q_EMIT dataChanged(i, i, {DisplayStyleRole});
        Q_EMIT columnDisplayChanged();
        invalidate();
    }
}

QStringList ColumnSortFilterDisplayModel::visibleColumnIds() const
{
    resolveRoleNumbers();

    QHash<QString, int> sourceRowMapping;
    for (int i = 0; i < rowCount(); ++i) {
        auto id = sourceModel()->data(sourceModel()->index(i, 0), m_idRoleNumber).toString();
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
        if (leftId == u"name") {
            return true;
        }
        if (rightId == u"name") {
            return false;
        }

        return leftId < rightId;
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
    if (id == u"name") {
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

#include "moc_ColumnSortFilterDisplayModel.cpp"
