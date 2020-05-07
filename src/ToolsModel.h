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

#ifndef TOOLSMODEL_H
#define TOOLSMODEL_H

#include <QAbstractListModel>
#include <QQmlParserStatus>

#include <KService>

class QDBusInterface;

/**
 * @todo write docs
 */
class ToolsModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        IdRole = Qt::UserRole,
        NameRole,
        IconRole,
        ShortcutRole,
    };

    explicit ToolsModel(QObject *parent = nullptr);

    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex & parent) const override;
    QVariant data(const QModelIndex & index, int role) const override;

    Q_INVOKABLE void trigger(const QString &id);

private:
    void addFromService(const QString &serviceName);

    struct Entry {
        QString id;
        QString name;
        QString icon;
        QString shortcut;
        KService::Ptr service;
    };
    QVector<Entry> m_entries;
    QDBusInterface *m_kwinInterface;
};

#endif // TOOLSMODEL_H
