import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

import org.kde.kirigami 2.6 as Kirigami

import org.kde.ksysguardqml 1.0

Kirigami.Page {
    title: i18n("Configure")

    Kirigami.FormLayout {
        anchors.fill: parent
        CheckBox { id: applicationsConfirm; text: i18n("Ask for confirmation when quitting applications.") }
        CheckBox { id: processesConfirm; text: i18n("Ask for confirmation when ending processes.") }
    }

    Configuration {
        property alias askWhenKillingApplications: applicationsConfirm.checked
        property alias askWhenKillingProcesses: processesConfirm.checked
    }
}
