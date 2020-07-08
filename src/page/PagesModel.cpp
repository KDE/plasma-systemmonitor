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
    sort();
    endResetModel();
}

void PagesModel::sort(int column, Qt::SortOrder order)
{
    Q_UNUSED(column)
    Q_UNUSED(order)

    if (m_pageOrder.isEmpty()) {
        return;
    }

    Q_EMIT layoutAboutToBeChanged({QPersistentModelIndex()}, QAbstractItemModel::VerticalSortHint);
    auto last = std::stable_partition(m_pages.begin(), m_pages.end(), [this] (PageDataObject *page) {
        return m_pageOrder.contains(page->config()->name());
    });
    std::sort(m_pages.begin(), last, [this] (PageDataObject *left, PageDataObject *right) {
        return m_pageOrder.indexOf(left->config()->name()) < m_pageOrder.indexOf(right->config()->name());
    });
    std::transform(last, m_pages.end(), std::back_inserter(m_pageOrder), [] (PageDataObject *page) {
        return page->config()->name();
    });
    if (last != m_pages.end()) {
        Q_EMIT pageOrderChanged();
    }
    changePersistentIndex(QModelIndex(), QModelIndex());
    layoutChanged();
}

PageDataObject *PagesModel::addPage(const QString& fileName, const QVariantMap &properties)
{
    KSharedConfig::Ptr config = KSharedConfig::openConfig(fileName, KConfig::CascadeConfig, QStandardPaths::AppDataLocation);

    auto page = new PageDataObject(config, this);

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
    m_pageOrder.append(fileName);
    Q_EMIT pageOrderChanged();
    endInsertRows();

    return page;
}

void PagesModel::savePage(PageDataObject* page)
{
    page->save(*page->config(), QStringLiteral("page"), {QStringLiteral("fileName")});
}

QStringList PagesModel::pageOrder() const
{
    return m_pageOrder;
}

void PagesModel::setPageOrder(const QStringList &pageOrder)
{
    if (pageOrder != m_pageOrder) {
        m_pageOrder = pageOrder;
        Q_EMIT pageOrderChanged();
        sort();
    }
}


