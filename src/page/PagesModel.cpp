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
        { IconRole, "icon" },
        { FileNameRole, "fileName"},
        { HiddenRole, "hidden"},
        { FilesWriteableRole, "filesWriteable"}
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
        case FileNameRole:
            return data->config()->name();
        case HiddenRole:
            return m_hiddenPages.contains(data->config()->name());
        case FilesWriteableRole:
            return m_writeableCache[data->config()->name()];
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
        const auto entries = dir.entryInfoList({QStringLiteral("*.page")}, QDir::NoDotAndDotDot | QDir::Files);
        for (auto entry : entries) {
            const FilesWriteableStates entryState = entry.isWritable() ? AllWriteable : NotWriteable;
            if (!files.contains(entry.fileName())) {
                files.insert(entry.fileName(), dir.relativeFilePath(entry.fileName()));
                m_writeableCache.insert(entry.fileName(), entryState);
            } else {
                FilesWriteableStates &state = m_writeableCache[entry.fileName()];
                if ((state == NotWriteable && entryState == AllWriteable) ||
                    (state == AllWriteable && entryState == NotWriteable)) {
                    state = LocalChanges;
                }
            }
        }
    }

    beginResetModel();
    for (auto itr = files.begin(); itr != files.end(); ++itr) {
        auto config = KSharedConfig::openConfig(itr.value(), KConfig::CascadeConfig, QStandardPaths::AppDataLocation);

        auto page = new PageDataObject{config, this};
        page->load(*config, QStringLiteral("page"));
        connect(page, &PageDataObject::dirtyChanged, this, [this, page]() {
            savePage(page);
            if (m_writeableCache[page->config()->name()] == NotWriteable) {
                m_writeableCache[page->config()->name()] = LocalChanges;
                auto i = m_pages.indexOf(page);
                Q_EMIT dataChanged(index(i), index(i), {FilesWriteableRole});
            }
        });
        connect(page, &PageDataObject::valueChanged, this, [this, page]() {
            auto i = m_pages.indexOf(page);
            if (m_writeableCache[page->config()->name()] == NotWriteable) {
                m_writeableCache[page->config()->name()] = LocalChanges;
            }
            Q_EMIT dataChanged(index(i), index(i), {TitleRole, IconRole, FilesWriteableRole});
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
    m_writeableCache[fileName] = AllWriteable;

    connect(page, &PageDataObject::dirtyChanged, this, [this, page]() { savePage(page); });
    connect(page, &PageDataObject::valueChanged, this, [this, page]() {
        auto i = m_pages.indexOf(page);
        Q_EMIT dataChanged(index(i), index(i), {TitleRole, IconRole, FilesWriteableRole});
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

QStringList PagesModel::hiddenPages() const
{
    return m_hiddenPages;
}

void PagesModel::setHiddenPages(const QStringList &hiddenPages)
{
    if (hiddenPages != m_hiddenPages) {
        m_hiddenPages = hiddenPages;
        Q_EMIT hiddenPagesChanged();
        Q_EMIT dataChanged(index(0, 0), index(m_pages.count()-1, 0), {HiddenRole});
    }
}

void PagesModel::removeLocalPageFiles(const QString &fileName)
{
     auto it = std::find_if(m_pages.begin(), m_pages.end(), [&] (PageDataObject *page) {
        return page->config()->name() == fileName;
    });
    if (it == m_pages.end()) {
        return;
    }
    if (m_writeableCache[fileName] == NotWriteable) {
        return;
    }
    PageDataObject * const page = *it;
    QStringList files = QStandardPaths::locateAll(QStandardPaths::AppDataLocation, page->config()->name(), QStandardPaths::LocateFile);
    for (const auto file : files) {
        if (QFileInfo(file).isWritable()) {
            QFile::remove(file);
        }
    }
    int row = it - m_pages.begin();
    if (m_writeableCache[fileName] == AllWriteable) {
        Q_EMIT beginRemoveRows(QModelIndex(), row, row);
        m_pages.erase(it);
        m_hiddenPages.removeAll(fileName);
        m_writeableCache.remove(fileName);
        Q_EMIT endRemoveRows();
    } else {
        page->config()->markAsClean();
        page->config()->reparseConfiguration();
        page->load(*page->config(), QStringLiteral("page"));
        m_writeableCache[fileName] = NotWriteable;
        Q_EMIT dataChanged(index(row, 0), index(row, 0), {TitleRole, IconRole, DataRole, FilesWriteableRole});
    }
}
