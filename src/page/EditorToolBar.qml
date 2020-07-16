import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami

Control {
    id: control

    property list<Action> addActions
    property list<Action> extraActions

    property bool single: false

    property alias moveAxis: moveButton.axis
    property alias moveTarget: moveButton.target

    signal moved(int from, int to)
    signal removeClicked()

    implicitWidth: layout.implicitWidth
    implicitHeight: visible ? layout.implicitHeight : 0

    Layout.minimumWidth: overflowButton.width

    readonly property real layoutWidth: width - spacing - overflowButton.width

    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0
    topPadding: 0

    contentItem: Item {
        RowLayout {
            id: layout

            spacing: 0

            Button {
                id: addButton

                Layout.rightMargin: Kirigami.Units.smallSpacing

                text: i18nc("@action:button", "Add...")
                icon.name: "list-add"
                checkable: true
                checked: addMenu.opened

                onToggled: {
                    if (checked) {
                        addMenu.popup(0, height)
                    } else {
                        addMenu.close()
                    }
                }

                opacity: x + width < control.layoutWidth ? 1 : 0

                Menu {
                    id: addMenu

                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                    Repeater {
                        model: control.addActions

                        MenuItem {
                            action: modelData
                        }
                    }
                }
            }

            MoveButton {
                id: moveButton
                Layout.rightMargin: Kirigami.Units.smallSpacing
                enabled: !control.single
                opacity: x + width < control.layoutWidth ? 1 : 0
                axis: control.moveAxis
                target: control.moveTarget
                onMoved: control.moved(from, to)
            }


            Button {
                id: removeButton

                Layout.rightMargin: Kirigami.Units.smallSpacing
                opacity: x + width < control.layoutWidth ? 1 : 0

                action: Action {
                    enabled: !control.single
                    text: i18nc("@action:button", "Remove")
                    icon.name: "edit-delete"
                    onTriggered: control.removeClicked()
                }
            }

            Repeater {
                model: control.extraActions

                Button {
                    Layout.rightMargin: Kirigami.Units.smallSpacing
                    opacity: x + width < control.layoutWidth ? 1 : 0
                    onVisibleChanged: {
                        if (opacity > 0) {
                            let menuIndex = overflowButton.hiddenActions.indexOf(modelData)
                            if (menuIndex != -1) {
                                overflowButton.hiddenActions.splice(menuIndex, 1)
                                overflowButton.hiddenActionsChanged()
                            }
                        } else {
                            if (!overflowButton.hiddenActions.includes(modelData)) {
                                overflowButton.hiddenActions.push(modelData)
                                overflowButton.hiddenActionsChanged()
                            }
                        }
                    }
                    action: modelData
                }
            }
        }

        Button {
            id: overflowButton

            anchors.right: parent.right
            height: addButton.height
            width: height

            text: i18nc("@action:button", "More...")
            icon.name: "overflow-menu"
            display: Button.IconOnly

            property var hiddenActions: []

            visible: addButton.opacity == 0 || moveButton.opacity == 0 || removeButton.opacity == 0 || hiddenActions.length > 0

            checkable: true
            checked: overflowMenu.opened

            onToggled: {
                if (checked) {
                    overflowMenu.popup(0, height)
                } else {
                    overflowMenu.close()
                }
            }

            Menu {
                id: overflowMenu

                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                Menu {
                    id: overflowAddMenu
                    title: i18nc("@action:inmenu", "Add")

                    Instantiator {
                        model: control.addActions

                        MenuItem {
                            visible: !addButton.visible
                            action: modelData
                        }

                        onObjectAdded: overflowAddMenu.insertItem(index, object)
                        onObjectRemoved: overflowAddMenu.takeItem(index)
                    }

                    Component.onCompleted: {
                        var item = overflowMenu.itemAt(0)
                        // Workaround missing API in QQC2 Menu
                        item.icon.name = "list-add"
                        item.visible = Qt.binding(function () { return addButton.opacity == 0 })
                        item.height = Qt.binding(function () { return item.visible ? item.implicitHeight : 0 } )
                    }
                }

                MoveButton {
                    visible: moveButton.opacity == 0
                    height: visible ? implicitHeight : 0
//                     flat: true
                    axis: moveButton.axis
                    target: moveButton.target
                    onMoved: control.moved(from, to)
                }

                MenuItem {
                    visible: removeButton.opacity == 0
                    action: removeButton.action
                }

                Instantiator {
                    model: control.extraActions

                    MenuItem {
                        id: item
                        visible: overflowButton.hiddenActions.includes(modelData)
                        action: modelData
                    }

                    onObjectAdded: overflowMenu.insertItem(index + 3, object)
                    onObjectRemoved: overflowMenu.takeItem(index + 3)
                }
            }
        }
    }
}
