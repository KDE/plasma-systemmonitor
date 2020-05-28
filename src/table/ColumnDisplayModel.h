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
        DisplayStyleRole = Qt::UserRole + 99
    };

    explicit ColumnDisplayModel(QObject* parent = nullptr);

    void setSourceModel(QAbstractItemModel *newSourceModel) override;

    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex & index, int role) const override;

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
    void sortColumns();

    QHash<QString, QString> m_columnDisplay;

    QString m_idRole = QStringLiteral("id");
    mutable int m_idRoleNumber = -1;
};

#endif // COLUMNDISPLAYMODEL_H
