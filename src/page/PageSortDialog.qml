/*
 * SPDX-FileCopyrightText: 2020 David Redondo <kde@david-redondo.de>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.12 as Kirigami
import org.kde.kitemmodels 1.0 as KItemModels


import org.kde.ksysguard.page 1.0 as Page

Dialog {
    property alias model : sortModel.sourceModel
    property string startPage

    modal: true
    focus: true
    standardButtons: Dialog.Ok | Dialog.Cancel

    width: parent ? parent.width * 0.75 : 0
    height: parent ? parent.height * 0.75 : 0

    x: parent ? Math.round(parent.width / 2 - width / 2) : 0
    y: ApplicationWindow.window ? ApplicationWindow.window.pageStack.globalToolBar.height - Kirigami.Units.smallSpacing : 0

    leftPadding: Kirigami.Units.devicePixelRatio
    rightPadding: Kirigami.Units.devicePixelRatio
    bottomPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomInset: -Kirigami.Units.smallSpacing

    onAboutToShow: {
        sortModel.sourceModel = model
        startPageBox.currentIndex = startPageBox.indexOfValue(startPage)
    }

    onAccepted: {
        sortModel.applyChangesToSourceModel()
        startPage = startPageBox.currentValue
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.View

    Rectangle {
        anchors.fill: parent
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Kirigami.Separator { Layout.fillWidth: true; }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView {
                id: pageList
                model: Page.PageSortModel {
                    id: sortModel
                }
                delegate: Kirigami.DelegateRecycler {
                    sourceComponent: delegateComponent
                }
                Component {
                    id: delegateComponent
                    Kirigami.AbstractListItem {
                        id: listItem
                        readonly property string title: model ? model.title : ""
                        readonly property string icon: model ? model.icon : ""
                        //Using directly model.hidden below doesn't work for some reason
                        readonly property bool hidden: model ? model.hidden : false
                        readonly property var filesWritable: model ? model.filesWriteable : false
                        readonly property bool shouldRemoveFiles: model ? model.shouldRemoveFiles : false

                        width: pageList.width

                        activeFocusOnTab: false

                        contentItem: RowLayout {
                            Kirigami.ListItemDragHandle {
                                id: handle
                                Layout.fillHeight: true
                                Layout.rowSpan: 2
                                listItem: listItem
                                listView: pageList
                                onMoveRequested: {
                                    sortModel.move(oldIndex, newIndex)
                                }
                            }
                            CheckBox {
                                checked: !listItem.hidden
                                onToggled: pageList.model.setData(pageList.model.index(index, 0), !listItem.hidden, Page.PagesModel.HiddenRole)
                                ToolTip.text: listItem.hidden ? i18nc("@info:tooltip", "Show Page")
                                                              : i18nc("@info:tooltip", "Hide Page")
                                ToolTip.delay: Kirigami.Units.toolTipDelay
                                ToolTip.visible: hovered
                            }
                            Kirigami.Icon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                Layout.preferredHeight: Layout.preferredWidth
                                source: listItem.icon
                                opacity: listItem.hidden ? 0.3 : 1
                            }
                            ColumnLayout {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0
                                Label {
                                    Layout.fillWidth: true
                                    text: listItem.title
                                    opacity: listItem.hidden ? 0.3 : 1
                                }
                                Label {
                                    id: subtitle
                                    Layout.fillWidth: true
                                    font: Kirigami.Theme.smallFont
                                    opacity: 0.7
                                    visible: text.length > 0
                                }
                            }
                            Button {
                                id: removeButton
                                onClicked: pageList.model.setData(pageList.model.index(index, 0), !listItem.shouldRemoveFiles, Page.PageSortModel.ShouldRemoveFilesRole)
                                ToolTip.delay: Kirigami.Units.toolTipDelay
                                ToolTip.visible: hovered
                                states: [
                                    State {
                                        name: "noChanges"
                                        extend: "localChanges"
                                        when: listItem.filesWritable == Page.PagesModel.NotWriteable
                                        PropertyChanges {
                                            target: removeButton;
                                            enabled: false;
                                        }
                                    },
                                    State {
                                        name: "removeLocalChanges"
                                        when:  listItem.filesWritable == Page.PagesModel.LocalChanges && listItem.shouldRemoveFiles
                                        PropertyChanges {
                                            target: removeButton
                                            icon.name: "edit-redo"
                                            ToolTip.text: i18nc("@info:tooltip", "Do not reset the page")
                                        }
                                        PropertyChanges {
                                            target: subtitle
                                            text: i18nc("@item:intable", "The page will be reset to its default state")
                                        }
                                    },
                                    State {
                                        name: "localChanges"
                                        when: listItem.filesWritable == Page.PagesModel.LocalChanges
                                        PropertyChanges {
                                            target: removeButton
                                            icon.name: "edit-reset"
                                            ToolTip.text: i18nc("@info:tooltip", "Reset the page to its default state")
                                        }
                                    },
                                    State {
                                        name: "remove"
                                        when: listItem.filesWritable == Page.PagesModel.AllWriteable && listItem.shouldRemoveFiles
                                        PropertyChanges {
                                            target: removeButton
                                            icon.name: "edit-undo"
                                            ToolTip.text: i18nc("@info:tooltip", "Do not remove this page")
                                        }
                                        PropertyChanges {
                                            target: subtitle
                                            text: i18nc("@item:intable", "The page will be removed")
                                        }
                                        PropertyChanges {
                                            target: listItem
                                            backgroundColor: Kirigami.Theme.negativeBackgroundColor
                                        }
                                    },
                                    State {
                                        name: "removeable"
                                        when: listItem.filesWritable == Page.PagesModel.AllWriteable
                                        PropertyChanges {
                                            target: removeButton
                                            icon.name: "edit-delete"
                                            ToolTip.text: i18nc("@info:tooltip", "Remove this page")
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            }
        }
        Kirigami.Separator { Layout.fillWidth: true; }
    }
    footer: DialogButtonBox {
        // Use an AbstractButton so the button box includes it
        AbstractButton {
            implicitWidth: childrenRect.width
            DialogButtonBox.buttonRole: DialogButtonBox.ActionRole
            RowLayout {
                Label {
                    text: i18nc("@label:listbox", "Start with:")
                }
                ComboBox {
                    id: startPageBox
                    textRole: "title"
                    valueRole: "fileName"
                    model: createModel()

                    function createModel() {
                        var result = [{fileName: "", title: i18n("Last Visited Page"), icon: "clock"}];
                        for (var i = 0; i < sortModel.rowCount(); ++i) {
                            const index = sortModel.index(i, 0)
                            if (sortModel.data(index, Page.PagesModel.HiddenRole)) {
                                continue
                            }
                            if (sortModel.data(index, Page.PageSortModel.ShouldRemoveFilesRole)
                                && sortModel.data(index, Page.PagesModel.FilesWriteableRole) == Page.PagesModel.AllWriteable) {
                                continue
                            }
                            result.push({fileName: sortModel.data(index, Page.PagesModel.FileNameRole),
                                         title: sortModel.data(index, Page.PagesModel.TitleRole),
                                         icon: sortModel.data(index, Page.PagesModel.IconRole)})
                        }
                        return result
                    }

                    Connections {
                        target: sortModel
                        function onDataChanged() { refreshModel() }
                        function onRowsMoved() { refreshModel() }
                        function refreshModel() {
                            const value = startPageBox.currentValue
                            startPageBox.model = startPageBox.createModel()
                            startPageBox.currentIndex = startPageBox.indexOfValue(value)
                        }
                    }

                    delegate: ItemDelegate {
                        width: parent.width
                        highlighted: startPageBox.highlightedIndex == index
                        contentItem: RowLayout {
                            Kirigami.Icon {
                                color: highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                source: modelData.icon
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            }
                            Label {
                                text: modelData.title
                                color: highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
