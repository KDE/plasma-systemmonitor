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

            AbstractButton {
                id: label

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
    }

    Popup {
        id: popup

        y: control.height
        width: control.width + 2
        implicitHeight: contentItem.implicitHeight
        topMargin: 6
        bottomMargin: 6
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

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

                model: Sensors.SensorTreeModel { }
                delegate: Kirigami.BasicListItem {
                    width: listView.width - listView.ScrollBar.vertical.width
                    text: model.display
                    reserveSpaceForIcon: false

                    onClicked: {
                        if (model.SensorId.length == 0) {
                            delegateModel.rootIndex = delegateModel.modelIndex(index);
                        } else {
                            control.selected.push(model.display)
                            control.selectedChanged()
                            popup.close()
                        }
                    }
                }
            }


//             KItemModels.KSortFilterProxyModel {
//                 id: sensorsSearchableModel
//                 filterCaseSensitivity: Qt.CaseInsensitive
//                 filterString: listView.searchString
//         //         filterString: ""
//                 sourceModel: KItemModels.KSortFilterProxyModel {
//         //             filterRole: "SensorId"
//         //             filterRowCallback: function(row, value) {
//         //                 return (value && value.length)
//         //             }
//                     sourceModel: KItemModels.KDescendantsProxyModel {
//                         model: Sensors.SensorTreeModel { }
//                     }
//                 }
//             }

// //             delegate: ItemDelegate {
// //                 width: popup.width - Kirigami.Units.largeSpacing * 2
// //                 text: model.display
// // //                 highlighted: mouseArea.pressed ? listView.currentIndex == index : controlRoot.highlightedIndex == index
// //                 property bool separatorVisible: false
// //                 Kirigami.Theme.colorSet: Kirigami.Theme.View
// //                 Kirigami.Theme.inherit: false
// //             }
//             currentIndex: controlRoot.highlightedIndex
            highlightRangeMode: ListView.ApplyRange
            highlightMoveDuration: 0
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { }

            header: TextField {
                width: ListView.view.width - Kirigami.Units.largeSpacing * 2
                placeholderText: i18n("Search...")
                onTextEdited: listView.searchString = text
            }
        }

        background: Item {
            anchors {
                fill: parent
                margins: -1
            }

            Kirigami.ShadowedRectangle {
                anchors.fill: parent

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
