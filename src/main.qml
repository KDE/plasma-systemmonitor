import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

import org.kde.kirigami 2.11 as Kirigami

import org.kde.ksysguardqml 1.0
import org.kde.ksysguard.page 1.0 as Page

Kirigami.ApplicationWindow {
    id: app

    minimumWidth: 700
    minimumHeight: 550

    title: (pageStack.currentItem ? pageStack.currentItem.title + " - " : "") + i18n("System Monitor")

    Kirigami.PagePool {
        id: pagePoolObject
    }

    Component.onCompleted: {
        var page = "Overview"
        if (__context__initialPage != "") {
            page = __context__initialPage
        }

        for (var i in globalDrawer.actions) {
            var action = globalDrawer.actions[i]
            if (action.pageData && action.pageData.title == page) {
                action.trigger()
                return
            }
        }
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
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Window

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
                        text: "Tools"
                        icon.name: "tools-symbolic"
                    },
                    Kirigami.Action {
                        icon.name: app.globalDrawer.collapsed ? "view-split-left-right" : "view-left-close"
                        text: app.globalDrawer.collapsed ? i18n("Expand Sidebar") : i18n("Collapse Sidebar")
                        onTriggered: app.globalDrawer.collapsed = !app.globalDrawer.collapsed
                    },
                    Kirigami.PagePoolAction {
                        icon.name: "settings-configure"
                        text: i18n("Configure System Monitor...");
                        checked: false
                        pagePool: pagePoolObject
                        page: "pages/SettingsPage.qml"
                    },
                    Kirigami.PagePoolAction {
                        icon.name: "help-about-symbolic";
                        text: i18n("About System Monitor");
                        checked: false
                        pagePool: pagePoolObject
                        page: "pages/AboutPage.qml"
                    },
                    Kirigami.Action {
                        icon.name: "application-exit-symbolic";
                        text: i18n("Quit")
                        shortcut: "Ctrl+Q"
                        onTriggered: Qt.quit()
                    }
                ]
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
                text: "Add new page"
                icon.name: "list-add"
                onTriggered: pageDialog.open()
            }
        ]

        Instantiator {
            model: Page.PagesModel { id: pagesModel }

            Page.EditablePageAction {
                text: model.title
                icon.name: model.icon
                pagePool: pagePoolObject
                pageData: model.data
            }

            onObjectAdded: {
                var actions = Array.prototype.map.call(globalDrawer.actions, i => i)
                actions.splice(index, 0, object)
                globalDrawer.actions = actions
            }
            onObjectRemoved: {
                var actions = Array.prototype.map.call(globalDrawer.actions, i => i)
                actions.splice(index, 1)
                globalDrawer.actions = actions
            }
        }
    }

    Page.PageDialog {
        id: pageDialog
        title: i18n("Add New Page")

        onAccepted: {
            var fileName = name.toLowerCase().replace(" ", "_") + ".page";
            var newPage = pagesModel.addPage(fileName, {title: name, icon: iconName, margin: margin})
            var row = newPage.insertChild(0, {name: "row-0", isTitle: false, title: ""})
            var column = row.insertChild(0, {name: "column-0", showBackground: false})
            column.insertChild(0, {name: "section-0", isSeparator: false})
        }
    }

    Configuration {
        id: config
        property alias width: app.width
        property alias height: app.height
        property alias sidebarCollapsed: globalDrawer.collapsed
    }

    pageStack.columnView.columnWidth: Kirigami.Units.gridUnit * 17
}
