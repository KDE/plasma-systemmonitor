
set(page_SRCS
    PageDataModel.cpp
    PageDataObject.cpp
    PagePlugin.cpp
    PagesModel.cpp
    FaceLoader.cpp
    PageSortModel.cpp
    FacesModel.cpp
    WidgetExporter.cpp
)

set(page_QML
    ColumnControl.qml
    Container.qml
    EditablePage.qml
    PageContents.qml
    PageEditor.qml
    PlaceholderRectangle.qml
    RowControl.qml
    SectionControl.qml
    PageDialog.qml
    EditablePageAction.qml
    FaceControl.qml
    FaceConfigurationPage.qml
    LoadPresetDialog.qml
    EditorToolBar.qml
    MoveButton.qml
    PageSortDialog.qml
    DialogLoader.qml
)

add_library(PagePlugin SHARED ${page_SRCS})
target_link_libraries(PagePlugin Qt::DBus Qt::Quick KF5::ConfigCore KF5::I18n KF5::NewStuff KSysGuard::Sensors KSysGuard::SensorFaces)

install(TARGETS PagePlugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/ksysguard/page)
install(FILES qmldir ${page_QML} DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/ksysguard/page)
