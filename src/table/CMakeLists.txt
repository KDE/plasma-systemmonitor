set(table_SRCS
    TablePlugin.cpp
    ColumnDisplayModel.cpp
    ColumnSortModel.cpp
    ComponentCacheProxyModel.cpp
    ProcessSortFilterModel.cpp
)

set(table_QML
    BaseTableView.qml
    BasicCellDelegate.qml
    CellBackground.qml
    ColumnConfigurationDialog.qml
    FirstCellDelegate.qml
    LineChartCellDelegate.qml
    TableViewHeader.qml
    UserCellDelegate.qml
    KillDialog.qml
    TreeDecoration.qml
)

add_library(TablePlugin SHARED ${table_SRCS})
target_link_libraries(TablePlugin Qt5::Quick KSysGuard::Sensors KSysGuard::ProcessCore KF5::CoreAddons)

install(TARGETS TablePlugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/ksysguard/table)
install(FILES qmldir ${table_QML} DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/ksysguard/table)
