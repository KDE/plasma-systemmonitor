/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#pragma once

#include <QSortFilterProxyModel>
#include <qqmlregistration.h>

class ColumnSortFilterDisplayModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT
    //     Q_PROPERTY(QStringList excludedColumns READ excludedColumns WRITE setExcludedColumns NOTIFY excludedColumnsChanged)
    //     Q_PROPERTY(QStringList visibleColumns READ visibleColumns WRITE setVisibleColumns NOTIFY visibleColumnsChanged)
    //     Q_PROPERTY(QList<int> columnWeights READ columnWeights WRITE setColumnWeights NOTIFY columnWeightsChanged)
    //     Q_PROPERTY(QString columnIdRole READ columnIdRole WRITE setColumnIdRole NOTIFY columnIdRoleChanged)

public:
    enum Roles {
        DisplayStyleRole = Qt::UserRole + 99,
        EnabledRole,
    };

    explicit ColumnSortFilterDisplayModel(QObject *parent = nullptr);

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;

    void setSourceModel(QAbstractItemModel *newSourceModel) override;

    // QModelIndex mapFromSource(const QModelIndex &sourceIndex) const override;
    // QModelIndex mapToSource(const QModelIndex &proxyIndex) const override;

    Q_INVOKABLE void move(int fromRow, int toRow);

    // Q_PROPERTY(QString idRole READ idRole WRITE setIdRole NOTIFY idRoleChanged)
    // QString idRole() const;
    // void setIdRole(const QString &newIdRole);
    // Q_SIGNAL void idRoleChanged();

    Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)
    QString filterString() const;
    void setFilterString(const QString &newFilterString);
    Q_SIGNAL void filterStringChanged();

    Q_PROPERTY(QStringList sortedColumns READ sortedColumns WRITE setSortedColumns NOTIFY sortedColumnsChanged)
    QStringList sortedColumns() const;
    void setSortedColumns(const QStringList &newSortedColumns);
    Q_SIGNAL void sortedColumnsChanged();

    Q_PROPERTY(QVariantMap columnDisplay READ columnDisplay WRITE setColumnDisplay NOTIFY columnDisplayChanged)
    QVariantMap columnDisplay() const;
    void setColumnDisplay(const QVariantMap &newColumnDisplay);
    Q_SIGNAL void columnDisplayChanged();

    Q_INVOKABLE void setDisplay(int column, const QString &display);
    Q_INVOKABLE void setDisplayById(const QString &id, const QString &display);

    Q_PROPERTY(QStringList visibleColumnIds READ visibleColumnIds NOTIFY columnDisplayChanged)
    QStringList visibleColumnIds() const;

protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    bool lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const override;

private:
    bool columnEnabled(const QString &id) const;
    void resolveRoleNumbers() const;
    QModelIndex indexForId(const QString &id);

    QString m_filterString;

    // QList<int> m_rowMapping;
    // QString m_idRole = QStringLiteral("id");
    mutable int m_idRoleNumber = -1;
    mutable int m_nameRoleNumber = -1;
    mutable int m_descriptionRoleNumber = -1;

    QHash<QString, QString> m_columnDisplay;

    // mutable int m_displayStyleRole = -1;
};
