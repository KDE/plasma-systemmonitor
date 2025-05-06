/*
 *    SPDX-FileCopyrightText: 2025 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 *    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

#include <QTest>

#include <KConfigGroup>

#include "PageManager.h"
#include "PageManager_p.h"

using namespace Qt::StringLiterals;
namespace fs = std::filesystem;

class PageManagerTest : public QObject
{
    Q_OBJECT

    std::filesystem::path m_appDataWriteLocation;
    std::filesystem::path m_appDataReadLocation;

    // Helper function to create and load a new page manager instance.
    // This avoids us needing to use the singleton instance, so we don't store
    // state between different tests.
    std::unique_ptr<PageManager> makePageManager()
    {
        auto pm = std::make_unique<PageManager>(std::make_unique<PageManagerPrivate>());
        pm->load();
        return pm;
    }

    // Copy a file from test data local to QStandardPaths local.
    void copyToLocal(const char *fileName)
    {
        auto path = QFINDTESTDATA("data/local/"_L1 + fileName);
        QVERIFY(QFile::copy(fs::path(path.toStdString()), m_appDataWriteLocation / fileName));
    }

private Q_SLOTS:

    void initTestCase()
    {
        // PageManager uses QStandardPaths::AppDataLocation to look for pages.
        // Ensure we have these available and in a known state, that includes
        // ensuring we do not read any actual System Monitor installed pages.
        QCoreApplication::setApplicationName(u"plasma-systemmonitor"_s);

        auto path = QFINDTESTDATA("TestPageManager_data/plasma-systemmonitor/newtestpage.page");
        auto systemDir = path.left(path.indexOf("plasma-systemmonitor/newtestpage.page"));
        QStringList dataDirs = {
            systemDir,
            // To test that we handle non-existent paths correctly.
            u"/some/nonexistent/path/"_s,
        };
        qputenv("XDG_DATA_DIRS", dataDirs.join(':').toUtf8());
        QStandardPaths::setTestModeEnabled(true);

        m_appDataReadLocation = fs::path(systemDir.toStdString()) / "plasma-systemmonitor";

        m_appDataWriteLocation = fs::path(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation).toStdString());
        fs::create_directories(m_appDataWriteLocation);

        // Clear replacePages so the state is the same between all tests.
        PageManagerPrivate::s_replacePages = {};
    }

    void cleanup()
    {
        // Cleanup any local data that was written by the test.
        fs::remove_all(m_appDataWriteLocation);
        fs::create_directories(m_appDataWriteLocation);

        // Ensure we have a clean set of replacePages, even if the test code
        // modified things.
        PageManagerPrivate::s_replacePages = {};
    }

    void testLoad()
    {
        copyToLocal("basepage.page");
        copyToLocal("localpage.page");
        copyToLocal("replacepage.page");

        auto pm = makePageManager();

        QCOMPARE(pm->pages().count(), 6);

        auto newTestPage = pm->page(u"newtestpage.page"_s);
        QVERIFY(newTestPage);
        QCOMPARE(newTestPage->data()->property("title"), u"New Test Page"_s);
        QCOMPARE(newTestPage->isOutdated(), false);
        QCOMPARE(newTestPage->hasReplacedOutdated(), false);
        QCOMPARE(newTestPage->writeableState(), PageController::WriteableState::NotWriteable);

        auto localPage = pm->page(u"localpage.page"_s);
        QVERIFY(localPage);
        QCOMPARE(localPage->writeableState(), PageController::WriteableState::Writeable);

        auto replacePage = pm->page(u"replacepage.page"_s);
        QVERIFY(replacePage);
        QCOMPARE(replacePage->data()->property("title"), u"Local Replaced Page"_s);
        QCOMPARE(replacePage->isOutdated(), false);
        QCOMPARE(replacePage->writeableState(), PageController::WriteableState::LocalChanges);

        auto oldTestPage = pm->page(u"oldtestpage.page"_s);
        QVERIFY(oldTestPage);
        QCOMPARE(oldTestPage->isOutdated(), false);
        QCOMPARE(oldTestPage->writeableState(), PageController::WriteableState::NotWriteable);

        auto basePage = pm->page(u"basepage.page"_s);
        QVERIFY(basePage);
        QCOMPARE(basePage->isOutdated(), true);
        QCOMPARE(basePage->writeableState(), PageController::WriteableState::LocalChanges);
    }

    void testReplaceOutdated()
    {
        copyToLocal("basepage.page");

        PageManagerPrivate::s_replacePages = {
            ReplaceInfo{u"basepage.page"_s, u"old-basepage.page"_s, 0},
        };

        auto pm = makePageManager();

        auto basePage = pm->page(u"basepage.page"_s);
        QVERIFY(basePage);
        QCOMPARE(basePage->hasReplacedOutdated(), true);

        auto oldBasePage = pm->page(u"old-basepage.page"_s);
        QVERIFY(oldBasePage);
        // Verify that it's actually using the data from our old page.
        QCOMPARE(oldBasePage->data()->property("title"), u"Base Page"_s);
    }

    void testIgnoreReplacePages()
    {
        PageManagerPrivate::s_replacePages = {
            ReplaceInfo{u"basepage.page"_s, u"old-basepage.page"_s, 0},
        };

        auto pm = makePageManager();

        auto basePage = pm->page(u"basepage.page"_s);
        QVERIFY(basePage);

        // When we do not have any local changes for a replaced page, the
        // replaced page should be ignored and never added to the set of pages.
        auto oldBasePage = pm->page(u"old-basepage.page"_s);
        QVERIFY(!oldBasePage);
    }

    void testAddPage()
    {
        auto pm = makePageManager();

        auto page = pm->addPage(u"addedtestpage"_s, {{u"title"_s, u"Added Test Page"_s}});
        QVERIFY(page);
        QCOMPARE(page->path(), m_appDataWriteLocation / "addedtestpage.page");
        QCOMPARE(page->data()->property("title"), u"Added Test Page"_s);

        auto page1 = pm->addPage(u"addedtestpage"_s, {{u"title"_s, u"Added Test Page"_s}});
        QVERIFY(page1);
        QCOMPARE(page1->path(), m_appDataWriteLocation / "addedtestpage1.page");
        QCOMPARE(page1->data()->property("title"), u"Added Test Page"_s);
    }

    void testSave()
    {
        copyToLocal("basepage.page");
        copyToLocal("localpage.page");
        copyToLocal("replacepage.page");

        auto pm = makePageManager();

        auto page = pm->addPage(u"addedtestpage"_s, {{u"title"_s, u"Added Test Page"_s}});
        QVERIFY(page);
        QVERIFY(page->save());
        QVERIFY(fs::exists(page->path()));

        auto localPage = pm->page(u"localpage.page"_s);
        QVERIFY(localPage);
        QVERIFY(localPage->save());

        auto replacePage = pm->page(u"replacepage.page"_s);
        QVERIFY(replacePage);
        QVERIFY(replacePage->save());

        auto basePage = pm->page(u"basepage.page"_s);
        QVERIFY(basePage);
        QVERIFY(basePage->save());

        // Saving an old config that used to use cascading should now write out
        // a full page.
        KConfig config(QString::fromStdString(basePage->path()), KConfig::SimpleConfig);
        QVERIFY(config.hasGroup(u"page"_s));
        QCOMPARE(config.group("page").readEntry("version", 0), PageManager::CurrentPageVersion);
        QVERIFY(config.group("page").hasGroup("row-0"));
    }

    void testUpgradeDiscard()
    {
        copyToLocal("basepage.page");

        auto pm = makePageManager();

        auto basePage = pm->page(u"basepage.page"_s);
        QVERIFY(basePage);
        QCOMPARE(basePage->writeableState(), PageController::WriteableState::LocalChanges);

        auto oldPath = basePage->path();

        QVERIFY(basePage->upgrade(PageController::PageChanges::DiscardChanges));
        QVERIFY(!fs::exists(oldPath));
        QCOMPARE(basePage->data()->property("title"), u"New Base Page"_s);
    }

    void testUpgradeKeep()
    {
        copyToLocal("basepage.page");

        auto pm = makePageManager();

        auto basePage = pm->page(u"basepage.page"_s);
        QVERIFY(basePage);
        QCOMPARE(basePage->writeableState(), PageController::WriteableState::LocalChanges);

        auto oldPath = basePage->path();

        QVERIFY(basePage->upgrade(PageController::PageChanges::KeepChanges));
        QVERIFY(fs::exists(oldPath));
        QCOMPARE(basePage->data()->property("title"), u"Base Page"_s);
    }

    void testEdit()
    {
        auto pm = makePageManager();

        auto newTestPage = pm->page(u"newtestpage.page"_s);
        QVERIFY(newTestPage);

        newTestPage->edit();
        newTestPage->data()->setProperty("title", "Edited Title");
        newTestPage->save();

        QCOMPARE(newTestPage->path(), m_appDataWriteLocation / "newtestpage.page");
        QCOMPARE(newTestPage->writeableState(), PageController::WriteableState::LocalChanges);

        KConfig config(QString::fromStdString(newTestPage->path()), KConfig::SimpleConfig);
        QVERIFY(config.hasGroup(u"page"_s));
        QCOMPARE(config.group("page").readEntry("Title", QString{}), u"Edited Title");
    }

    void testReset()
    {
        auto pm = makePageManager();

        auto newTestPage = pm->page(u"newtestpage.page"_s);
        QVERIFY(newTestPage);

        newTestPage->edit();
        newTestPage->data()->setProperty("title", u"Edited Title"_s);
        newTestPage->save();

        QCOMPARE(newTestPage->path(), m_appDataWriteLocation / "newtestpage.page");
        QCOMPARE(newTestPage->writeableState(), PageController::WriteableState::LocalChanges);

        pm->removeLocalPageFiles(newTestPage->fileName());

        QCOMPARE(newTestPage->path(), m_appDataReadLocation / "newtestpage.page");
        QCOMPARE(newTestPage->writeableState(), PageController::WriteableState::NotWriteable);

        QCOMPARE(newTestPage->data()->property("title").toString(), u"New Test Page"_s);
    }
};

QTEST_MAIN(PageManagerTest);

#include "TestPageManager.moc"
