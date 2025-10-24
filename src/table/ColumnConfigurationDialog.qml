/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 * SPDX-FileCopyrightText: 2023 Nate Graham <nate@kde.org>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.ksysguard.formatter as Formatter
import org.kde.ksysguard.table as Table

Dialog {
    id: columnDialog

    property string nameAttribute: "name"

    property alias model: columnView.model
    property alias sourceModel: sortModel.sourceModel
    property var sortedColumns: []
    property var columnDisplay: {}

    title: i18ndc("plasma-systemmonitor", "@window:title", "Configure Columns")

    focus: true

    standardButtons: Dialog.Ok | Dialog.Cancel

    popupType: Popup.Window
    modal: false
    padding: 0

    function setColumnDisplay(display) {
        columnDisplay = display
        prepare()
        apply()
    }

    onAccepted: {
        apply()
    }

    onAboutToShow: {
        prepare()
    }

    function prepare() {
        sortModel.sortedColumns = sortedColumns
        sortModel.columnDisplay = columnDisplay
    }

    function apply() {
        sortedColumns = sortModel.sortedColumns
        columnDisplay = sortModel.columnDisplay
    }

    function hideColumn(columnId) {
        sortModel.setDisplayById(columnId, "hidden");
        accept()
    }

    header: ToolBar {
        Kirigami.SearchField {
            id: searchField
            width: parent.width
            onAccepted: sortModel.filterString = text
        }
    }

    footer: ToolBar {
        DialogButtonBox {
            width: parent.width
            standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel

            onAccepted: columnDialog.accept()
            onRejected: columnDialog.reject()
        }
    }

    contentItem: ScrollView {
        id: scrollView

        implicitWidth: Kirigami.Units.gridUnit * 40
        implicitHeight: Kirigami.Units.gridUnit * 40

        ListView {
            id: columnView

            model: visible ? sortModel : null

            Table.ColumnSortFilterDisplayModel {
                id: sortModel
                nameAttribute: columnDialog.nameAttribute
            }

            section.property: "enabled"
            section.delegate: Kirigami.ListSectionHeader {
                required property string section
                width: ListView.view.width
                text: section === "enabled" ? i18nc("@item:inlistbox", "Enabled Columns") : i18nc("@item:inlistbox", "Disabled Columns")
            }

            delegate: Loader {
                width: columnView.width
                height: Kirigami.Units.gridUnit * 3
                property var modelData: model
                sourceComponent: delegateComponent
            }

            Component {
                id: delegateComponent
                Kirigami.SubtitleDelegate {
                    id: delegate
                    rightPadding: Kirigami.Units.smallSpacing
                    property int index: modelData ? modelData.row : -1
                    activeFocusOnTab: false

                    highlighted: parent === columnView

                    // We don't want visual interactivity for the background except on drag.
                    hoverEnabled: false
                    down: false

                    text: modelData?.name ?? ""
                    subtitle: modelData?.description ?? ""

                    Kirigami.Theme.useAlternateBackgroundColor: true

                    ToolTip.visible: hoverHandler.hovered && contentItem.truncated

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        property bool truncated: titleSubtitle.truncated

                        Kirigami.ListItemDragHandle {
                            id: handle
                            listItem: delegate
                            listView: columnView
                            onMoveRequested: (oldIndex, newIndex) => {
                                if (newIndex > 0) {
                                    sortModel.move(oldIndex, newIndex);
                                }
                            }
                            visible: modelData?.enabled === "enabled" ?? false
                            enabled: modelData?.id !== columnDialog.nameAttribute
                        }

                        Kirigami.TitleSubtitle {
                            id: titleSubtitle
                            Layout.fillWidth: true
                            title: delegate.text
                            subtitle: delegate.subtitle
                        }

                        ComboBox {
                            id: showCombo
                            textRole: "text"
                            Layout.rowSpan: 2
                            Layout.rightMargin: Kirigami.Units.smallSpacing
                            enabled: modelData?.id !== columnDialog.nameAttribute ?? true
                            model: {
                                var result = [
                                    {text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Hidden"), value: "hidden"},
                                    {text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Text Only"), value: "text"},
                                ]

                                if (modelData && modelData.unit) {
                                    if (modelData.unit != Formatter.Units.UnitInvalid
                                        && modelData.unit != Formatter.Units.UnitNone) {
                                        result.push({text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Line Chart"), value: "line"})
                                    }
                                    if (modelData.unit == Formatter.Units.UnitPercent
                                        && modelData.maximum != 100) {
                                        result.push({text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Text Only (Scaled to 100%)"), value: "textScaled"})
                                        result.push({text: i18ndc("plasma-systemmonitor", "@item:inlistbox", "Line Chart (Scaled to 100%)"), value: "lineScaled"})
                                    }
                                }
                                return result
                            }

                            currentIndex: {
                                if (!modelData) {
                                    return -1;
                                }

                                if (modelData.id === columnDialog.nameAttribute) {
                                    return 1;
                                }

                                for (var i = 0; i < model.length; ++i) {
                                    if (model[i].value == modelData.displayStyle) {
                                        return i;
                                    }
                                }
                                return -1;
                            }

                            onActivated: index => {
                                sortModel.setDisplay(delegate.index, model[index].value);
                            }
                        }
                    }

                    HoverHandler {
                        id: hoverHandler
                    }
                }
            }

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width * 0.75

                visible: !columnView.count

                text: i18ndc("plasma-systemmonitor", "@info", "No columns matched the search")
            }
        }
    }
}
