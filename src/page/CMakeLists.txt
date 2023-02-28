
set(page_SRCS
    FaceLoader.cpp
    FaceLoader.h
    FacesModel.cpp
    FacesModel.h
    PageDataModel.cpp
    PageDataModel.h
    PageDataObject.cpp
    PageDataObject.h
    PagePlugin.cpp
    PagePlugin.h
    PagesModel.cpp
    PagesModel.h
    PageSortModel.cpp
    PageSortModel.h
    WidgetExporter.cpp
    WidgetExporter.h
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
    MissingSensorsDialog.qml
)

add_library(PagePlugin SHARED ${page_SRCS})
target_link_libraries(PagePlugin Qt::DBus Qt::Quick KF6::ConfigCore KF6::I18n KF6::NewStuffCore KSysGuard::Sensors KSysGuard::SensorFaces)

install(TARGETS PagePlugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/ksysguard/page)
install(FILES qmldir ${page_QML} DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/ksysguard/page)
