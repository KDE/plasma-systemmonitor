/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami
import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.kquickcontrolsaddons 2.0 as Addons

import org.kde.ksysguard.page 1.0

Dialog {
    id: dialog

    property string acceptText: i18nc("@action:button", "Add")
    property string acceptIcon: "list-add"

    property string name: i18nc("@info:placeholder", "New Page")
    property string iconName: "ksysguardd"
    property real margin: 2
    property string actionsFace: "dummy" //Can't leave it empty, otherwise it doesn't update when it's initially set to an empty string
    property alias pageData: facesModel.pageData

    modal: true
    parent: Overlay.overlay

    x: parent ? parent.width / 2 - width / 2 : 0
    y: ApplicationWindow.window ? ApplicationWindow.window.pageStack.globalToolBar.height - Kirigami.Units.smallSpacing : 0

    leftPadding: 1 // Allow dialog background border to show
    rightPadding: 1 // Allow dialog background border to show
    bottomPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomInset: -Kirigami.Units.smallSpacing

    onAccepted: {
        actionsFace = actionsCombobox.currentValue
    }

    onClosed: {
        actionsFace = "dummy" //see above
    }

    contentItem: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: Kirigami.Units.gridUnit * 15

        Kirigami.Separator { anchors { left: parent.left; right: parent.right; top: parent.top } }

        Kirigami.FormLayout {
            anchors.fill: parent

            TextField {
                id: nameField

                Kirigami.FormData.label: i18nc("@label:textbox", "Name")
                text: dialog.name
                onTextEdited: dialog.name = text

                validator: RegularExpressionValidator { regularExpression: /^[\pL\pN][^\pC/]*/ }
            }
            Kirigami.InlineMessage {
                Layout.fillWidth: true
                type: Kirigami.MessageType.Error
                text: i18nc("@info:status", "Name cannot be empty.")
                visible: !nameField.acceptableInput
            }
            Button {
                Kirigami.FormData.label: i18nc("@label:textbox", "Icon")
                icon.name: dialog.iconName
                onClicked: iconDialog.open()
            }
            ComboBox {
                Kirigami.FormData.label: i18nc("@label:listbox", "Page Margins")

                textRole: "key"

                currentIndex: {
                    for (var i in model) {
                        if (model[i].value == dialog.margin) {
                            return i
                        }
                    }
                }

                model: [
                    { value: 0, key: i18nc("@item:inlistbox", "None") },
                    { value: 1, key: i18nc("@item:inlistbox", "Small") },
                    { value: 2, key: i18nc("@item:inlistbox", "Large") }
                ]

                onActivated: dialog.margin = model[index].value
            }
            ComboBox {
                id: actionsCombobox
                Kirigami.FormData.label: i18nc("@label:listbox", "Use Actions From")
                visible: count > 1
                textRole: "display"
                valueRole: "id"
                currentIndex:indexOfValue(dialog.actionsFace)
                model:  KItemModels.KSortFilterProxyModel {
                    sourceModel: FacesModel {id: facesModel}
                    filterRowCallback: function(row, parent) {
                        // No face option
                        if (row == facesModel.rowCount() - 1) {
                            return true
                        }
                        const face = facesModel.faceAtIndex(row)
                        return face.primaryActions.length != 0 && face.secondaryActions.length != 0
                    }
                }
            }
        }

        Kirigami.Separator { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } }

        Addons.IconDialog {
            id: iconDialog;
            iconSize: Kirigami.Units.iconSizes.smallMedium
            onIconNameChanged: dialog.iconName = iconName
        }
    }

    footer: DialogButtonBox {
        Button {
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            text: dialog.acceptText
            icon.name: dialog.acceptIcon
            enabled: nameField.acceptableInput
        }
        Button {
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            text: i18nc("@action:button", "Cancel")
            icon.name: "dialog-cancel"
        }
    }
}
