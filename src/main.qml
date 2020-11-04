/*
 * SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

import org.kde.kirigami 2.11 as Kirigami
import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.newstuff 1.62 as NewStuff


import org.kde.systemmonitor 1.0
import org.kde.ksysguard.page 1.0 as Page

Kirigami.ApplicationWindow {
    id: app

    minimumWidth: 700
    minimumHeight: 550

    title: (pageStack.currentItem ? pageStack.currentItem.title + " - " : "") + i18n("System Monitor")

    Kirigami.PagePool {
        id: pagePoolObject
    }


    globalDrawer: Kirigami.GlobalDrawer {
        id: globalDrawer

        handleVisible: false
        modal: false
        width: collapsed ? globalToolBar.Layout.minimumWidth + Kirigami.Units.smallSpacing : Kirigami.Units.gridUnit * 10
        Behavior on width { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.InOutQuad } }
        showHeaderWhenCollapsed: true

        Kirigami.Theme.colorSet: Kirigami.Theme.View

        header: ToolBar {
            Layout.fillWidth: true
            Layout.preferredHeight: app.pageStack.globalToolBar.preferredHeight

            leftPadding: globalDrawer.collapsed ? 0 : Kirigami.Units.smallSpacing
            rightPadding: globalDrawer.collapsed ? Kirigami.Units.smallSpacing / 2 : Kirigami.Units.smallSpacing
            topPadding: 0
            bottomPadding: 0

            Kirigami.ActionToolBar {
                id: globalToolBar

                anchors.fill: parent

                overflowIconName: "application-menu"

                actions: [
                    Kirigami.Action {
                        id: toolsAction
                        text: i18nc("@action", "Tools")
                        icon.name: "tools-symbolic"
                    },
                    Kirigami.Action {
                        icon.name: "handle-sort"
                        text: i18nc("@action", "Edit pages...")
                        onTriggered: pageSortDialog.open()
                    },
                    Kirigami.Action {
                        icon.name: app.globalDrawer.collapsed ? "view-split-left-right" : "view-left-close"
                        text: app.globalDrawer.collapsed ? i18nc("@action", "Expand Sidebar") : i18nc("@action", "Collapse Sidebar")
                        onTriggered: app.globalDrawer.collapsed = !app.globalDrawer.collapsed
                    },
                    Kirigami.Action {
                        icon.name: "get-hot-new-stuff"
                        text: i18nc("@action:inmenu", "Get New Pages...")
                        onTriggered: getNewPageDialog.open()
                    },
                    Kirigami.Action {
                        icon.name: "help-about-symbolic";
                        text: i18nc("@action", "About System Monitor");
                        onTriggered: app.pageStack.layers.push("AboutPage.qml")
                    }
                ]
                Component.onCompleted: actions.push(app.quitAction)
            }

            Instantiator {
                model: ToolsModel { id: toolsModel }

                Kirigami.Action {
                    text: model.name
                    icon.name: model.icon
                    shortcut: model.shortcut
                    onTriggered: toolsModel.trigger(model.id)
                }

                onObjectAdded: { toolsAction.children.push(object) }
                onObjectRemoved: { }
            }
        }

        actions: [
            Kirigami.Action {
                text: i18nc("@action", "Add new page")
                icon.name: "list-add"
                onTriggered: pageDialog.open()
            }
        ]

        Instantiator {
            model:  KItemModels.KSortFilterProxyModel {
                sourceModel: Page.PagesModel { id: pagesModel }
                filterRowCallback: function(row, parent) {
                    const index = pagesModel.index(row, parent)
                    return !pagesModel.data(index, Page.PagesModel.HiddenRole)
                 }
            }

            Page.EditablePageAction {
                text: model.title
                icon.name: model.icon
                fileName: model.fileName
                pagePool: pagePoolObject
                pageData: model.data

                Component.onCompleted: {
                    if (CommandLineArguments.pageId && model.fileName == CommandLineArguments.pageId) {
                        trigger()
                    } else if (CommandLineArguments.pageName && model.title == CommandLineArguments.pageName) {
                        trigger()
                    }
                }
            }

            onObjectAdded: {
                var actions = Array.prototype.map.call(globalDrawer.actions, i => i)
                actions.splice(index, 0, object)
                globalDrawer.actions = actions
            }

            onObjectRemoved: {
                var actions = Array.prototype.map.call(globalDrawer.actions, i => i)
                var actionIndex = actions.indexOf(object)
                actions.splice(actionIndex, 1)
                globalDrawer.actions = actions
            }
        }
    }

    Page.PageDialog {
        id: pageDialog
        title: i18nc("@window:title", "Add New Page")

        onAccepted: {
            var fileName = name.toLowerCase().replace(" ", "_");
            var newPage = pagesModel.addPage(fileName, {title: name, icon: iconName, margin: margin})
            var row = newPage.insertChild(0, {name: "row-0", isTitle: false, title: ""})
            var column = row.insertChild(0, {name: "column-0", showBackground: true})
            column.insertChild(0, {name: "section-0", isSeparator: false})

            const pageAction = Array.prototype.find.call(globalDrawer.actions, action => action.fileName == fileName)
            pageAction.trigger()
            app.pageStack.currentItem.edit = true
        }
    }

    Page.PageSortDialog {
        id: pageSortDialog
        title: i18nc("@window:title", "Edit Pages")
        model: pagesModel
    }


    NewStuff.Dialog {
        id: getNewPageDialog
        configFile: "plasma-systemmonitor.knsrc"
        // I have a weird bug on my machine where getNewPageDialog.changedEntries is not an alias
        // engine.changedEntries but for the engine itself, so I directly use the property of the engine
        Connections {
            target: getNewPageDialog.engine
            function onChangedEntriesChanged() {
                pagesModel.ghnsEntriesChanged(getNewPageDialog.engine.changedEntries)
            }
        }
    }

    Configuration {
        id: config
        property alias width: app.width
        property alias height: app.height
        property alias sidebarCollapsed: globalDrawer.collapsed
        property alias pageOrder: pagesModel.pageOrder
        property alias hiddenPages: pagesModel.hiddenPages
    }

    pageStack.columnView.columnWidth: Kirigami.Units.gridUnit * 17
}
