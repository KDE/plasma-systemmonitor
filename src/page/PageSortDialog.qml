import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.12 as Kirigami

import org.kde.ksysguard.page 1.0 as Page

Dialog {
    property alias model : sortModel.sourceModel

    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel

    width: parent ? parent.width * 0.75 : 0
    height: parent ? parent.height * 0.75 : 0

    x: parent ? parent.width / 2 - width / 2 : 0
    y: ApplicationWindow.window ? ApplicationWindow.window.pageStack.globalToolBar.height - Kirigami.Units.smallSpacing : 0

    leftPadding: Kirigami.Units.devicePixelRatio
    rightPadding: Kirigami.Units.devicePixelRatio
    bottomPadding: Kirigami.Units.smallSpacing
    topPadding: Kirigami.Units.smallSpacing
    bottomInset: -Kirigami.Units.smallSpacing

    onAboutToShow: {
        sortModel.sourceModel = model
    }

    onAccepted: {
        sortModel.applyChangesToSourceModel()
    }

    Kirigami.Theme.colorSet: Kirigami.Theme.View

    Rectangle {
        anchors.fill: parent
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Kirigami.Separator { Layout.fillWidth: true; }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView {
                id: pageList
                model: Page.PageSortModel {
                    id: sortModel
                }
                delegate: Kirigami.DelegateRecycler {
                    width: pageList.width
                    sourceComponent: delegateComponent
                }
                Component {
                    id: delegateComponent
                    Kirigami.AbstractListItem {
                        id: listItem
                        //Using directly model.hidden below doesn't work for some reason
                        readonly property bool hidden: model.hidden
                        contentItem: RowLayout {
                            Kirigami.ListItemDragHandle {
                                id: handle
                                Layout.fillHeight: true
                                Layout.rowSpan: 2
                                listItem: listItem
                                listView: pageList
                                onMoveRequested: {
                                    sortModel.move(oldIndex, newIndex)
                                }
                            }
                            CheckBox {
                                checked: !hidden
                                onToggled: pageList.model.setData(pageList.model.index(index, 0), !hidden, Page.PagesModel.HiddenRole)
                                ToolTip.text: hidden ? i18n("Show Page") : i18n("Hide Page")
                                ToolTip.delay: Kirigami.Units.toolTipDelay
                                ToolTip.visible: hovered
                            }
                            Kirigami.Icon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                Layout.preferredHeight: Layout.preferredWidth
                                source: model.icon
                                opacity: hidden ? 0.3 : 1
                            }
                            Label {
                                Layout.fillWidth: true
                                text: model.title
                                opacity: hidden ? 0.3 : 1
                            }
                        }
                    }
                }
            }
        }
        Kirigami.Separator { Layout.fillWidth: true; }
    }
}
