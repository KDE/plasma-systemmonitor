/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#include "PagesModel.h"

#include <QDebug>
#include <QDir>
#include <QStandardPaths>

#include <KConfig>
#include <KConfigGroup>
#include <KNSCore/Entry>

#include "PageController.h"
#include "PageManager.h"

#include "systemmonitor.h"

PagesModel::PagesModel(QObject *parent)
    : QAbstractListModel(parent)
{
    auto pm = PageManager::instance().get();
    connect(pm, &PageManager::pageAdded, this, &PagesModel::onPageAdded);
    connect(pm, &PageManager::pageRemoved, this, [this](auto page) {
        auto i = m_pages.indexOf(page);
        beginRemoveRows(QModelIndex{}, i, i);
        m_pages.remove(i);
        page->data()->disconnect(this);
        page->disconnect(this);
        endRemoveRows();
    });
    connect(pm, &PageManager::pageReset, this, [this](auto page) {
        auto i = m_pages.indexOf(page);
        Q_EMIT dataChanged(index(i), index(i), {TitleRole, IconRole, DataRole, FilesWriteableRole});
    });
    connect(Configuration::self(), &Configuration::pageOrderChanged, this, [this]() {
        sort();
    });
    connect(Configuration::self(), &Configuration::hiddenPagesChanged, this, [this]() {
        Q_EMIT dataChanged(index(0, 0), index(m_pages.count() - 1, 0), {HiddenRole});
    });
}

QHash<int, QByteArray> PagesModel::roleNames() const
{
    static QHash<int, QByteArray> roles{{TitleRole, "title"},
                                        {DataRole, "data"},
                                        {IconRole, "icon"},
                                        {FileNameRole, "fileName"},
                                        {HiddenRole, "hidden"},
                                        {FilesWriteableRole, "filesWriteable"}};
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

    auto page = m_pages.at(index.row());
    switch (role) {
    case TitleRole:
        return page->data()->value(QStringLiteral("title"));
    case DataRole:
        return QVariant::fromValue(page);
    case IconRole:
        return page->data()->value(QStringLiteral("icon"));
    case FileNameRole:
        return page->fileName();
    case HiddenRole:
        return page->isHidden();
    case FilesWriteableRole:
        return QVariant::fromValue(page->writeableState());
    default:
        return QVariant{};
    }
}

void PagesModel::classBegin()
{
}

void PagesModel::componentComplete()
{
    PageManager::instance()->load();

    const auto pages = PageManager::instance()->pages();
    for (auto page : pages) {
        onPageAdded(page);
    }

    sort();
}

void PagesModel::sort(int column, Qt::SortOrder order)
{
    Q_UNUSED(column)
    Q_UNUSED(order)

    auto pageOrder = Configuration::self()->pageOrder();
    if (pageOrder.isEmpty()) {
        return;
    }

    Q_EMIT layoutAboutToBeChanged({QPersistentModelIndex()}, QAbstractItemModel::VerticalSortHint);
    auto last = std::stable_partition(m_pages.begin(), m_pages.end(), [&pageOrder](PageController *page) {
        return pageOrder.contains(page->fileName());
    });
    std::sort(m_pages.begin(), last, [&pageOrder](PageController *left, PageController *right) {
        return pageOrder.indexOf(left->fileName()) < pageOrder.indexOf(right->fileName());
    });
    changePersistentIndex(QModelIndex(), QModelIndex());
    Q_EMIT layoutChanged();
}

void PagesModel::onPageAdded(PageController *page)
{
    connect(page, &PageController::loaded, this, [this, page] {
        auto i = m_pages.indexOf(page);
        Q_EMIT dataChanged(index(i), index(i), {TitleRole, IconRole});
    });
    connect(page, &PageController::saved, this, [this, page]() {
        auto i = m_pages.indexOf(page);
        Q_EMIT dataChanged(index(i), index(i), {FilesWriteableRole});
    });
    connect(page->data(), &PageDataObject::valueChanged, this, [this, page]() {
        auto i = m_pages.indexOf(page);
        Q_EMIT dataChanged(index(i), index(i), {TitleRole, IconRole});
    });

    beginInsertRows(QModelIndex{}, m_pages.size(), m_pages.size());
    m_pages.append(page);
    endInsertRows();
}

#include "moc_PagesModel.cpp"
