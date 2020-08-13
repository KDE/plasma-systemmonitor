/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 * 
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#include "PageDataObject.h"

#include <QDebug>
#include <QRegularExpression>

#include <KConfig>
#include <KConfigGroup>

#include "FaceLoader.h"

QVariant converted(const QVariant &variant, QMetaType::Type type)
{
    auto result = variant;

    if (variant.toString().isEmpty()) {
        // Empty strings should be treated as just that, empty strings.
        // However, QVariant is a bit over eager to convert empty strings
        // to bool false. So explicitly ignore them here.
        return QVariant{};
    }

    if (!result.convert(type)) {
        return QVariant{};
    }

    if (type == QMetaType::Bool) {
        if (result.toBool()) {
            // Unfortunately, QVariant regards any string that is not "no" or "false" as true.
            // So we have to do our own parsing to check if the string matches "yes" or "true".
            static const QRegularExpression boolTrueExpression(QStringLiteral("^[yY][eE][sS]|[tT][rR][uU][eE]$"));
            auto match = boolTrueExpression.match(variant.toString());
            if (!match.hasMatch()) {
                return QVariant{};
            }
        }
    }

    return result;
}

int objectCount(QQmlListProperty<PageDataObject> *list)
{
    return static_cast<PageDataObject*>(list->object)->children().count();
}

PageDataObject *objectAt(QQmlListProperty<PageDataObject> *list, int index)
{
    return static_cast<PageDataObject*>(list->object)->children().at(index);
}

PageDataObject::PageDataObject(const KSharedConfig::Ptr& config, QObject* parent)
    : QQmlPropertyMap(this, parent), m_config(config)
{
    m_childrenProperty = QQmlListProperty<PageDataObject>(this, nullptr, &objectCount, &objectAt);
    connect(this, &PageDataObject::valueChanged, this, &PageDataObject::markDirty);
}

QQmlListProperty<PageDataObject> PageDataObject::childrenProperty() const
{
    return m_childrenProperty;
}

QVector<PageDataObject *> PageDataObject::children() const
{
    return m_children;
}

PageDataObject *PageDataObject::insertChild(int index, const QVariantMap &properties)
{
    if (index < 0) {
        return nullptr;
    }

    if (index >= m_children.size()) {
        index = m_children.size();
    }

    auto child = new PageDataObject(m_config, this);
    for (auto itr = properties.begin(); itr != properties.end(); ++itr) {
        child->insert(itr.key(), itr.value());
    }
    m_children.insert(index, child);
    child->markDirty();

    updateNames();

    connect(child, &PageDataObject::dirtyChanged, this, [this, child]() {
        if (child->dirty()) {
            markDirty();
        }
    });

    markDirty();

    Q_EMIT childInserted(index);
    Q_EMIT childrenChanged();

    return child;
}

void PageDataObject::removeChild(int index)
{
    if (index < 0 || index >= m_children.size()) {
        return;
    }

    auto child = m_children.at(index);
    m_children.remove(index);

    child->disconnect(this);
    child->deleteLater();

    updateNames();

    markDirty();

    Q_EMIT childRemoved(index);
    Q_EMIT childrenChanged();
}

void PageDataObject::moveChild(int from, int to)
{
    if (from < 0 || to < 0 || from >= m_children.size() || to >= m_children.size()) {
        return;
    }

    auto movingChild = m_children.at(from);
    m_children.remove(from);
    m_children.insert(to, movingChild);

    updateNames();

    markDirty();

    Q_EMIT childMoved(from, to);
    Q_EMIT childrenChanged();
}

PageDataObject *PageDataObject::childAt(int index) const
{
    if (index < 0 || index >= m_children.size()) {
        return nullptr;
    }

    return m_children.at(index);
}

int PageDataObject::childCount() const
{
    return m_children.size();
}

KSharedConfig::Ptr PageDataObject::config() const
{
    return m_config;
}

bool PageDataObject::resetPage()
{
    reset();

    m_config->markAsClean();
    m_config->reparseConfiguration();
    return load(*m_config, QStringLiteral("page"));
}

bool PageDataObject::savePage()
{
    auto result = save(*m_config, QStringLiteral("page"));
    if (result) {
        return m_config->sync();
    }
    return false;
}

bool PageDataObject::load(const KConfigBase &config, const QString &groupName)
{
    auto group = config.group(groupName);

    if (!m_children.isEmpty()) {
        qDeleteAll(m_children);
        m_children.clear();
    }

    if (isGroupEmpty(group)) {
        return false;
    }

    const auto entries = group.entryMap();
    for (auto itr = entries.begin(); itr != entries.end(); ++itr) {
        auto variant = QVariant::fromValue(itr.value());
        static const std::array<QMetaType::Type, 5> types{
            QMetaType::Double,
            QMetaType::Int,
            QMetaType::QDateTime,
            QMetaType::Bool,
            QMetaType::QString,
        };
        for (auto type : types) {
            auto value = converted(variant, type);
            if (value.isValid()) {
                insert(itr.key(), value);
                break;
            }
        }
    }

    auto groups = group.groupList();
    groups.sort();
    for (auto groupName : qAsConst(groups)) {
        auto object = new PageDataObject{m_config, this};
        if (object->load(group, groupName)) {
            m_children.append(object);
            connect(object, &PageDataObject::dirtyChanged, this, [this, object]() {
                if (object->dirty()) {
                    markDirty();
                }
            });
        } else {
            delete object;
        }

    }

    markClean();
    Q_EMIT childrenChanged();
    Q_EMIT loaded();
    return true;
}

bool PageDataObject::save(KConfigBase &config, const QString &groupName, const QStringList &ignoreProperties)
{
    if (!m_dirty && config.hasGroup(groupName)) {
        return false;
    }

    auto group = config.group(groupName);

    const auto names = keys();
    for (auto name : names) {
        if (ignoreProperties.contains(name)) {
            continue;
        } else {
            group.writeEntry(name, value(name));
        }
    }

    auto groupNames = group.groupList();
    for (auto child : qAsConst(m_children)) {
        auto name = child->value(QStringLiteral("name")).toString();
        groupNames.removeOne(name);
        child->save(group, name);
    }

    for (auto name : qAsConst(groupNames)) {
        group.deleteGroup(name);
    }

    markClean();
    Q_EMIT saved();
    return true;
}

void PageDataObject::reset()
{
    markClean();

    if (m_faceLoader) {
        m_faceLoader->reset();
    }

    for (auto child : qAsConst(m_children)) {
        child->reset();
    }
}

bool PageDataObject::dirty() const
{
    return m_dirty;
}

void PageDataObject::markDirty()
{
    if (m_dirty) {
        return;
    }

    m_dirty = true;
    Q_EMIT dirtyChanged();
}

void PageDataObject::markClean()
{
    if (!m_dirty) {
        return;
    }

    m_dirty = false;
    Q_EMIT dirtyChanged();
}

void PageDataObject::updateNames()
{
    for (auto i = 0; i < m_children.size(); ++i) {
        auto name = m_children.at(i)->value("name").toString();
        name = QStringLiteral("%1-%2").arg(name.left(name.lastIndexOf('-'))).arg(i);
        m_children.at(i)->insert(QStringLiteral("name"), name);
    }
}

FaceLoader* PageDataObject::faceLoader()
{
    return m_faceLoader;
}

void PageDataObject::setFaceLoader(FaceLoader* faceLoader)
{
    m_faceLoader = faceLoader;
}

bool PageDataObject::isGroupEmpty(const KConfigGroup &group)
{
    if (group.entryMap().size() != 0) {
        return false;
    }

    if (group.groupList().size() == 0) {
        return true;
    }

    const auto groups = group.groupList();
    for (auto subGroup : groups) {
        if (!isGroupEmpty(group.group(subGroup))) {
            return false;
        }
    }

    return true;
}
