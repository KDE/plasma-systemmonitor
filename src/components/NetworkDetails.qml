import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.4 as Kirigami

import org.kde.plasma.networkmanagement 0.2 as PlasmaNM

// This component displays network details.
// Currently it uses a (private?) import from PlasmaNM, because there seems to
// be no easier way, other than a lot of code to get info from NM directly.
Item {
    id: root

    property real itemHeight: Kirigami.Units.gridUnit * 3

    ColumnLayout {
        anchors.centerIn: parent
        height: Math.floor(parent.height / root.itemHeight) * root.itemHeight

        Repeater {
            id: repeater
            model: PlasmaNM.NetworkModel {}

            ColumnLayout {
                spacing: 0

                Layout.fillHeight: false

                visible: {
                    if (model.ConnectionState != PlasmaNM.Enums.Activated) {
                        return false;
                    }

                    switch(model.Type) {
                        case PlasmaNM.Enums.UnknownConnectionType:
                        case PlasmaNM.Enums.Bond:
                        case PlasmaNM.Enums.Bridge:
                        case PlasmaNM.Enums.Vlan:
                        case PlasmaNM.Enums.Vpn:
                            return false;
                        default:
                            break;
                    }

                    root.itemHeight = Math.max(height, itemHeight)

                    return true;
                }

                opacity: y + height > parent.height ? 0 : 1

                RowLayout {
                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: width
                        source: model.ConnectionIcon
                    }
                    Label { text: model.Name }
                }
                TextField {
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    Layout.preferredWidth: contentWidth

                    text: model.ConnectionDetails.length >= 2 ? model.ConnectionDetails[1] : ""
                    opacity: 0.8
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.7
                    visible: text != ""
                    readOnly: true
                    background: Item { }
                    padding: 0
                }
                TextField {
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    Layout.preferredWidth: contentWidth

                    text: model.ConnectionDetails.length >= 8 ? model.ConnectionDetails[7] : ""
                    opacity: 0.8
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.7
                    visible: text != ""
                    readOnly: true
                    background: Item { }
                    padding: 0
                }
            }
        }
    }
}
