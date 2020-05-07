import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import org.kde.kirigami 2.12 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as Addons

Dialog {
    id: dialog

    modal: true

    property string acceptText: i18n("Add")
    property string acceptIcon: "list-add"

    property string name: "New Page"
    property string iconName: "ksysguardd"
    property real margin: 2


    x: (parent.width / 2) - contentItem.implicitWidth / 2
    y: (parent.height / 2) - contentItem.implicitHeight / 2

    leftPadding: 1 // Allow dialog background border to show
    rightPadding: 1 // Allow dialog background border to show
    bottomPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomInset: -Kirigami.Units.smallSpacing
    topInset: Kirigami.Units.smallSpacing

    contentItem: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: Kirigami.Units.gridUnit * 15

        Kirigami.Separator { anchors { left: parent.left; right: parent.right; top: parent.top } }

        Kirigami.FormLayout {
            anchors.fill: parent

            TextField {
                Kirigami.FormData.label: i18n("Name")
                text: dialog.name
                onTextEdited: dialog.name = text
            }
            Button {
                Kirigami.FormData.label: i18n("Icon")
                icon.name: dialog.iconName
                onClicked: iconDialog.open()
            }
            ComboBox {
                Kirigami.FormData.label: i18n("Page Margins")

                textRole: "key"

                currentIndex: {
                    for (var i in model) {
                        if (model[i].value == dialog.margin) {
                            return i
                        }
                    }
                }

                model: [
                    { value: 0, key: i18n("None") },
                    { value: 1, key: i18n("Small") },
                    { value: 2, key: i18n("Large") }
                ]

                onActivated: dialog.margin = model[index].value
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
        }
        Button {
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            text: "Cancel"
            icon.name: "dialog-cancel"
        }
    }
}
