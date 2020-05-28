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

#ifndef COLUMNSORTMODEL_H
#define COLUMNSORTMODEL_H

#include <QIdentityProxyModel>
//#include <QVariantList>

class ColumnSortModel : public QIdentityProxyModel
{
    Q_OBJECT
//     Q_PROPERTY(QStringList excludedColumns READ excludedColumns WRITE setExcludedColumns NOTIFY excludedColumnsChanged)
//     Q_PROPERTY(QStringList visibleColumns READ visibleColumns WRITE setVisibleColumns NOTIFY visibleColumnsChanged)
//     Q_PROPERTY(QList<int> columnWeights READ columnWeights WRITE setColumnWeights NOTIFY columnWeightsChanged)
//     Q_PROPERTY(QString columnIdRole READ columnIdRole WRITE setColumnIdRole NOTIFY columnIdRoleChanged)
    Q_PROPERTY(QStringList sortedColumns READ sortedColumns WRITE setSortedColumns NOTIFY sortedColumnsChanged)
    Q_PROPERTY(QString idRole READ idRole WRITE setIdRole NOTIFY idRoleChanged)

public:
    enum Roles {
        VisibleRole = Qt::UserRole + 99
    };

    explicit ColumnSortModel(QObject* parent = nullptr);

    QVariant data(const QModelIndex &index, int role) const override;

    void setSourceModel(QAbstractItemModel* newSourceModel) override;

    QModelIndex mapFromSource(const QModelIndex & sourceIndex) const override;
    QModelIndex mapToSource(const QModelIndex & proxyIndex) const override;

    Q_INVOKABLE void move(int fromRow, int toRow);

    QStringList sortedColumns() const;
    void setSortedColumns(const QStringList &newSortedColumns);
    Q_SIGNAL void sortedColumnsChanged();

    QString idRole() const;
    void setIdRole(const QString &newIdRole);
    Q_SIGNAL void idRoleChanged();

private:
    int idRoleNumber() const;

    QVector<int> m_rowMapping;
    QString m_idRole = QStringLiteral("id");
    mutable int m_idRoleNumber = -1;
};

#endif // COLUMNSORTMODEL_H
