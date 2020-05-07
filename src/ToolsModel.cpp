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

#include "ToolsModel.h"

#include <QDBusInterface>
#include <QDBusConnection>
#include <QDBusPendingCall>

#include <QDebug>

// #include <KRun>
#include <KLocalizedString>
#include <KGlobalAccel>
#include <KIO/ApplicationLauncherJob>
#include <KIO/CommandLauncherJob>

ToolsModel::ToolsModel(QObject* parent)
    : QAbstractListModel(parent)
{
    addFromService(QStringLiteral("org.kde.konsole"));
//     addFromService(QStringLiteral("org.kde.ksysguard"));
    addFromService(QStringLiteral("org.kde.ksystemlog"));
    addFromService(QStringLiteral("org.kde.kinfocenter"));
    addFromService(QStringLiteral("org.kde.filelight"));
    addFromService(QStringLiteral("org.kde.sweeper"));
    addFromService(QStringLiteral("org.kde.kmag"));
    addFromService(QStringLiteral("htop"));

    auto entry = Entry{};
    entry.id = QStringLiteral("krunner");
    entry.name = i18nc("@action:inmenu", "Run Command");
    entry.icon = QStringLiteral("system-run");
    entry.service = KService::serviceByDesktopName(QStringLiteral("krunner"));
    const auto runCommandShortcutList = KGlobalAccel::self()->globalShortcut(QStringLiteral("krunner.desktop"), QStringLiteral("_launch"));
    if (!runCommandShortcutList.isEmpty()) {
        entry.shortcut = runCommandShortcutList.first().toString();
    }
    m_entries << entry;

    m_kwinInterface = new QDBusInterface{QStringLiteral("org.kde.KWin"), QStringLiteral("/KWin"), QStringLiteral("org.kde.KWin"), QDBusConnection::sessionBus(), this};

    if (m_kwinInterface->isValid()) {
        entry = Entry{};
        entry.id = QStringLiteral("killWindow");
        entry.icon = "document-close";
        entry.name = i18nc("@action:inmenu", "Kill a Window");
        const auto killWindowShortcutList = KGlobalAccel::self()->globalShortcut(QStringLiteral("kwin"), QStringLiteral("Kill Window"));
        if (!killWindowShortcutList.isEmpty()) {
            entry.shortcut = killWindowShortcutList.first().toString();
        }
        m_entries << entry;
    }
}

QHash<int, QByteArray> ToolsModel::roleNames() const
{
    static QHash<int, QByteArray> names = {
        { IdRole, "id" },
        { NameRole, "name" },
        { IconRole, "icon" },
        { ShortcutRole, "shortcut" }
    };
    return names;
}

int ToolsModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_entries.count();
}

QVariant ToolsModel::data(const QModelIndex& index, int role) const
{
    if (!checkIndex(index, CheckIndexOption::IndexIsValid | CheckIndexOption::DoNotUseParent)) {
        return QVariant{};
    }

    auto entry = m_entries.at(index.row());
    switch (role) {
        case IdRole:
            return entry.id;
        case NameRole:
            return entry.name;
        case IconRole:
            return entry.icon;
        case ShortcutRole:
            return entry.shortcut;
    }

    return QVariant{};
}

void ToolsModel::trigger(const QString& id)
{
    auto itr = std::find_if(m_entries.cbegin(), m_entries.cend(), [id](const Entry &entry) { return entry.id == id; });
    if (itr == m_entries.cend()) {
        return;
    }

    if (itr->service) {
        auto job = new KIO::ApplicationLauncherJob(itr->service);
        job->start();
    }

    if (itr->id == QStringLiteral("killWindow") && m_kwinInterface->isValid()) {
        m_kwinInterface->asyncCall(QStringLiteral("killWindow"));
    }
}

void ToolsModel::addFromService(const QString& serviceName)
{
    auto service = KService::serviceByDesktopName(serviceName);
    if (service) {
        Entry entry;
        entry.id = serviceName;
        entry.name = i18n("Launch %1", service->name());
        entry.icon = service->icon();
        entry.service = service;
        m_entries << entry;
    }
}
