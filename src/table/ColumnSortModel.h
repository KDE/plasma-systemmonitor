/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
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
        VisibleRole = Qt::UserRole + 99,
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
