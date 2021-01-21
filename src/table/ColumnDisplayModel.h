/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#ifndef COLUMNDISPLAYMODEL_H
#define COLUMNDISPLAYMODEL_H

#include <QIdentityProxyModel>

class ColumnDisplayModel : public QIdentityProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap columnDisplay READ columnDisplay WRITE setColumnDisplay NOTIFY columnDisplayChanged)
    Q_PROPERTY(QStringList visibleColumnIds READ visibleColumnIds NOTIFY columnDisplayChanged)
    Q_PROPERTY(QString idRole READ idRole WRITE setIdRole NOTIFY idRoleChanged)

public:
    enum Roles {
        DisplayStyleRole = Qt::UserRole + 99,
    };

    explicit ColumnDisplayModel(QObject *parent = nullptr);

    void setSourceModel(QAbstractItemModel *newSourceModel) override;

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;

    Q_INVOKABLE void setDisplay(int column, const QString &display);

    QVariantMap columnDisplay() const;
    void setColumnDisplay(const QVariantMap &newColumnDisplay);
    Q_SIGNAL void columnDisplayChanged();

    QStringList visibleColumnIds() const;

    QString idRole() const;
    void setIdRole(const QString &newIdRole);
    Q_SIGNAL void idRoleChanged();

private:
    int idRoleNumber() const;

    QHash<QString, QString> m_columnDisplay;

    QString m_idRole = QStringLiteral("id");
    mutable int m_idRoleNumber = -1;
};

#endif // COLUMNDISPLAYMODEL_H
