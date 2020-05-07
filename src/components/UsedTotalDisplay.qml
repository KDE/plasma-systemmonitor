import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

import org.kde.kirigami 2.4 as Kirigami

ColumnLayout {
    spacing: 0

    property alias usedLabel: usedLabel.text
    property alias usedValue: usedValue.text
    property alias totalLabel: totalLabel.text
    property alias totalValue: totalValue.text

    Label {
        id: usedLabel
        Layout.alignment: Text.AlignHCenter;
        text: i18n("Used");
        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.75
        color: Kirigami.Theme.disabledTextColor
    }

    Label {
        id: usedValue
        Layout.alignment: Text.AlignHCenter;
    }

    Kirigami.Separator { Layout.fillWidth: true }

    Label {
        id: totalValue
        Layout.alignment: Text.AlignHCenter;
    }

    Label {
        id: totalLabel
        Layout.alignment: Text.AlignHCenter;
        text: i18n("Total");
        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.75
        color: Kirigami.Theme.disabledTextColor
    }
}
