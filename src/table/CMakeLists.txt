set(table_SRCS
    TablePlugin.cpp
    ColumnDisplayModel.cpp
    ColumnSortModel.cpp
    ComponentCacheProxyModel.cpp
    ProcessSortFilterModel.cpp
    ReverseColumnsProxyModel.cpp
)

set(table_QML
    BaseCellDelegate.qml
    BaseTableView.qml
    BasicCellDelegate.qml
    ColumnConfigurationDialog.qml
    FirstCellDelegate.qml
    LineChartCellDelegate.qml
    TableViewHeader.qml
    UserCellDelegate.qml
    KillDialog.qml
    TreeDecoration.qml
)

add_library(TablePlugin SHARED ${table_SRCS})
target_link_libraries(TablePlugin Qt::Quick KSysGuard::Sensors KSysGuard::ProcessCore KF5::CoreAddons KF5::ItemModels)

install(TARGETS TablePlugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/ksysguard/table)
install(FILES qmldir ${table_QML} DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/ksysguard/table)
