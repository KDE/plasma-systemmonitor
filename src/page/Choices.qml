import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQml.Models 2.12

import org.kde.kirigami 2.12 as Kirigami
import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.ksysguard.sensors 1.0 as Sensors

Control {
    id: control

    property var selected: []
    property var colors: {}

    signal selectColor(string sensorId)

    background: TextField {
        readOnly: true
        hoverEnabled: false

        onFocusChanged: {
            if (focus) {
                popup.open()
            } else {
                popup.close()
            }
        }
        onReleased: {
            if (focus) {
                popup.open()
            }
        }
    }

    contentItem: Flow {
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: control.selected


            delegate: Rectangle {
                color: Qt.rgba(
                            Kirigami.Theme.highlightColor.r,
                            Kirigami.Theme.highlightColor.g,
                            Kirigami.Theme.highlightColor.b,
                            0.25)
                radius: Kirigami.Units.smallSpacing
                border.color: Kirigami.Theme.highlightColor
                border.width: 1

                implicitHeight: layout.implicitHeight + Kirigami.Units.smallSpacing * 2
                implicitWidth: Math.min(layout.implicitWidth + Kirigami.Units.smallSpacing * 2,
                                        control.width - control.leftPadding - control.rightPadding)

                Sensors.Sensor { id: sensor; sensorId: modelData }

                RowLayout {
                    id: layout

                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing

                    ToolButton {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

                        padding: Kirigami.Units.smallSpacing

                        contentItem: Rectangle {
                            color: control.colors[sensor.sensorId]
                        }

                        onClicked: control.selectColor(sensor.sensorId)
                    }

                    Label {
                        id: label

                        Layout.fillWidth: true
                        Layout.maximumWidth: contentWidth

                        text: sensor.name
                        elide: Text.ElideRight

                        HoverHandler { id: handler }

                        ToolTip.text: sensor.name
                        ToolTip.visible: handler.hovered && label.truncated
                        ToolTip.delay: Kirigami.Units.toolTipDelay
                    }

                    ToolButton {
                        icon.name: "edit-delete-remove"
                        icon.width: Kirigami.Units.iconSizes.small
                        icon.height: Kirigami.Units.iconSizes.small
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

                        onClicked: {
                            if (control.selected === undefined || control.selected === null) {
                                control.selected = []
                            }
                            control.selected.splice(control.selected.indexOf(sensor.sensorId), 1)
                            control.selectedChanged()
                        }
                    }
                }
            }
        }

        Item { width: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing * 2; height: width }
    }

    Popup {
        id: popup

        // Those bindings will be immediately broken on show, but they're needed to not show the popup at a wrong position for an instant
        y: (control.Kirigami.ScenePosition.y + control.height + height > control.Window.height)
            ? - height
            : control.height
        implicitHeight: Math.min(contentItem.implicitHeight + 2, Kirigami.Units.gridUnit * 20)
        width: control.width + 2
        topMargin: 6
        bottomMargin: 6
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        padding: 1

        onOpened: {
            if (control.Kirigami.ScenePosition.y + control.height + height > control.Window.height) {
                y = - height;
            } else {
                y = control.height
            }
            implicitHeight = Math.min(contentItem.implicitHeight + 2, Kirigami.Units.gridUnit * 20)
        }
        onClosed: delegateModel.rootIndex = delegateModel.parentModelIndex()

        contentItem: ColumnLayout {
            spacing: 0
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: implicitHeight
                Layout.maximumHeight: implicitHeight
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing

                ToolButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    icon.name: "go-previous"
                    text: i18nc("@action:button", "Back")
                    display: Button.IconOnly
                    visible: delegateModel.rootIndex.valid
                    onClicked: delegateModel.rootIndex = delegateModel.parentModelIndex()
                }

                TextField {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: i18n("Search...")
                    onTextEdited: listView.searchString = text
                }
            }
            Kirigami.Separator {
                Layout.fillWidth: true
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ListView {
                    id: listView

                    // this causes us to load at least one delegate
                    // this is essential in guessing the contentHeight
                    // which is needed to initially resize the popup
                    cacheBuffer: 1

                    property string searchString

                    implicitHeight: contentHeight
                    model: DelegateModel {
                        id: delegateModel

                        model: listView.searchString ? sensorsSearchableModel : treeModel
                        delegate: Kirigami.BasicListItem {
                            width: listView.width
                            text: model.display
                            reserveSpaceForIcon: false

                            onClicked: {
                                if (model.SensorId.length == 0) {
                                    delegateModel.rootIndex = delegateModel.modelIndex(index);
                                } else {
                                    if (control.selected === undefined || control.selected === null) {
                                        control.selected = []
                                    }
                                    control.selected.push(model.SensorId)
                                    control.selectedChanged()
                                    popup.close()
                                }
                            }
                        }
                    }

                    Sensors.SensorTreeModel { id: treeModel }

                    KItemModels.KSortFilterProxyModel {
                        id: sensorsSearchableModel
                        filterCaseSensitivity: Qt.CaseInsensitive
                        filterString: listView.searchString
                        sourceModel: KItemModels.KSortFilterProxyModel {
                            filterRowCallback: function(row, parent) {
                                var sensorId = sourceModel.data(sourceModel.index(row, 0), Sensors.SensorTreeModel.SensorId)
                                return sensorId.length > 0
                            }
                            sourceModel: KItemModels.KDescendantsProxyModel {
                                model: listView.searchString ? treeModel : null
                            }
                        }
                    }

                    highlightRangeMode: ListView.ApplyRange
                    highlightMoveDuration: 0
                    boundsBehavior: Flickable.StopAtBounds
                }
            }
        }

        background: Item {
            anchors {
                fill: parent
                margins: -1
            }

            Kirigami.ShadowedRectangle {
                anchors.fill: parent
                anchors.margins: 1

                Kirigami.Theme.colorSet: Kirigami.Theme.View
                Kirigami.Theme.inherit: false

                radius: 2
                color: Kirigami.Theme.backgroundColor

                property color borderColor: Kirigami.Theme.textColor
                border.color: Qt.rgba(borderColor.r, borderColor.g, borderColor.b, 0.3)
                border.width: 1

                shadow.xOffset: 0
                shadow.yOffset: 2
                shadow.color: Qt.rgba(0, 0, 0, 0.3)
                shadow.size: 8
            }
        }
    }
}
