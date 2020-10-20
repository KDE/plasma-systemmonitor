/*
 * SPDX-FileCopyrightText: 2020 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import org.kde.kirigami 2.8 as Kirigami

Dialog {
    id: dialog

    required property string killButtonText
    required property string killButtonIcon
    required property string questionText

    property var items: []
    property bool doNotAskAgain: false
    property alias delegate: list.delegate

    modal: true
    parent: Overlay.overlay
    focus: true

    x: parent ? parent.width / 2 - width / 2 : 0
    y: ApplicationWindow.window ? ApplicationWindow.window.pageStack.globalToolBar.height - Kirigami.Units.smallSpacing : 0

    leftPadding: 1 // Allow dialog background border to show
    rightPadding: 1 // Allow dialog background border to show
    bottomPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomInset: -Kirigami.Units.smallSpacing

    contentItem: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
        implicitWidth: Kirigami.Units.gridUnit * 25
        implicitHeight: Kirigami.Units.gridUnit * 20

        Kirigami.Separator { anchors { left: parent.left; right: parent.right; top: parent.top } }

        ScrollView {
            anchors.fill: parent
            anchors.topMargin: 1
            anchors.bottomMargin: 1

            ListView {
                id: list

                header: Label {
                    id: questionLabel
                    padding: Kirigami.Units.gridUnit
                    text: dialog.questionText
                }

                model: dialog.items
                currentIndex: -1

                delegate: Kirigami.AbstractListItem {
                    leftPadding: Kirigami.Units.gridUnit
                    contentItem: Label { text: modelData; width: parent.width; elide: Text.ElideRight }
                    highlighted: false
                    hoverEnabled: false
                }
            }
        }

        Kirigami.Separator { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } }
    }

    footer: DialogButtonBox {
        CheckBox {
            implicitWidth: contentItem.implicitWidth + Kirigami.Units.smallSpacing * 2
            contentItem: Label { leftPadding: Kirigami.Units.gridUnit; text: i18ndc("plasma-systemmonitor", "@option:check", "Do not ask again") }
            DialogButtonBox.buttonRole: DialogButtonBox.ActionRole

            onToggled: dialog.doNotAskAgain = checked
        }
        Button {
            implicitWidth: contentItem.implicitWidth + Kirigami.Units.largeSpacing * 2
            contentItem: RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.rightMargin: Kirigami.Units.largeSpacing
                //Workaround for QTBUG-81796
                Kirigami.Icon { source: dialog.killButtonIcon; width: Kirigami.Units.iconSizes.smallMedium; height: width }
                Label { text: dialog.killButtonText }
            }
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }
        Button {
            implicitWidth: contentItem.implicitWidth + Kirigami.Units.largeSpacing * 2
            contentItem: RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.rightMargin: Kirigami.Units.largeSpacing
                //Workaround for QTBUG-81796
                Kirigami.Icon { source: "dialog-cancel"; width: Kirigami.Units.iconSizes.smallMedium; height: width }
                Label { text: i18ndc("plasma-systemmonitor", "@action:button", "Cancel") }
            }
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
    }
}
