import QtQuick 2.14
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
                implicitWidth: layout.implicitWidth + Kirigami.Units.smallSpacing * 2

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
                        text: sensor.name
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

        y: control.height
        width: control.width + 2
        implicitHeight: {
            var yInScene = mapToGlobal(y, 0)
            Math.min(contentItem.implicitHeight + 2, applicationWindow().height - yInScene.y - Kirigami.Units.gridUnit)
        }
        topMargin: 6
        bottomMargin: 6
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        padding: 1

        contentItem: ListView {
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
            ScrollBar.vertical: ScrollBar { }

            header: RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right

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
