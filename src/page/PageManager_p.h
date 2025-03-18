// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
// SPDX-FileCopyrightText: 2025 Arjen Hiemstra <ahiemstra@quantumproductions.info>

#pragma once

#include <filesystem>

struct ReplaceInfo {
    QString fromName;
    QString toName;
    int version = 0;
};

class PageManagerPrivate
{
public:
    std::optional<std::filesystem::path> renamePage(PageController *controller, const QString &newName);
    QString determineFileName(const QString &initialFileName);

    QList<PageController *> pages;

    inline static std::shared_ptr<PageManager> s_instance = nullptr;
    inline static QQmlEngine *s_engine = nullptr;

    // A mapping of pages and page versions to new names. If there are local changes
    // that match one of these, the local changes will be copied to the new name to
    // preserve the local changes.
    inline static QList<ReplaceInfo> s_replacePages = {};
};
