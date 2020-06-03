/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 * 
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#include "PagesModel.h"

#include <QStandardPaths>
#include <QDir>
#include <QDebug>

#include <KConfig>
#include <KConfigGroup>

#include "PageDataObject.h"

PagesModel::PagesModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

QHash<int, QByteArray> PagesModel::roleNames() const
{
    static QHash<int, QByteArray> roles {
        { TitleRole, "title" },
        { DataRole, "data" },
        { IconRole, "icon" }
    };
    return roles;
}

int PagesModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return m_pages.count();
}

QVariant PagesModel::data(const QModelIndex &index, int role) const
{
    if (!checkIndex(index, CheckIndexOption::IndexIsValid | CheckIndexOption::DoNotUseParent)) {
        return QVariant{};
    }

    auto data = m_pages.at(index.row());
    switch (role) {
        case TitleRole:
            return data->value("title");
        case DataRole:
            return QVariant::fromValue(data);
        case IconRole:
            return data->value("icon");
        default:
            return QVariant{};
    }
}

void PagesModel::classBegin()
{
}

void PagesModel::componentComplete()
{
    QHash<QString, QString> files;

    const auto directories = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation);
    for (auto directory : directories) {
        QDir dir{directory};
        const auto entries = dir.entryList({QStringLiteral("*.page")}, QDir::NoDotAndDotDot | QDir::Files);
        for (auto entry : entries) {
            if (!files.contains(entry)) {
                files.insert(entry, dir.relativeFilePath(entry));
            }
        }
    }

    beginResetModel();
    for (auto itr = files.begin(); itr != files.end(); ++itr) {
        auto config = KSharedConfig::openConfig(itr.value(), KConfig::CascadeConfig, QStandardPaths::AppDataLocation);

        auto page = new PageDataObject{config, this};
        page->load(*config, QStringLiteral("page"));

        connect(page, &PageDataObject::dirtyChanged, this, [this, page]() { savePage(page); });
        connect(page, &PageDataObject::valueChanged, this, [this, page]() {
            auto i = m_pages.indexOf(page);
            Q_EMIT dataChanged(index(i), index(i), {TitleRole, IconRole});
        });

        m_pages.append(page);
    }
    std::stable_sort(m_pages.begin(), m_pages.end(), [](PageDataObject *left, PageDataObject *right) {
        return left->value("index").toInt() < right->value("index").toInt();
    });
    endResetModel();
}

PageDataObject *PagesModel::addPage(const QString& fileName, const QVariantMap &properties)
{
    KSharedConfig::Ptr config = KSharedConfig::openConfig(fileName, KConfig::CascadeConfig, QStandardPaths::AppDataLocation);

    auto page = new PageDataObject(config, this);
    page->insert(QStringLiteral("index"), m_pages.size());

    for (auto itr = properties.begin(); itr != properties.end(); ++itr) {
        page->insert(itr.key(), itr.value());
    }

    connect(page, &PageDataObject::dirtyChanged, this, [this, page]() { savePage(page); });
    connect(page, &PageDataObject::valueChanged, this, [this, page]() {
        auto i = m_pages.indexOf(page);
        Q_EMIT dataChanged(index(i), index(i), {TitleRole, IconRole});
    });

    beginInsertRows(QModelIndex{}, m_pages.size(), m_pages.size());
    m_pages.append(page);
    endInsertRows();

    return page;
}

void PagesModel::savePage(PageDataObject* page)
{
//     KConfig config(QStringLiteral("pages/") % page->value(QStringLiteral("fileName")).toString(),
//                     KConfig::SimpleConfig, QStandardPaths::AppDataLocation);
    qDebug() << page->config()->name();
    page->save(*page->config(), QStringLiteral("page"), {QStringLiteral("fileName")});
}
