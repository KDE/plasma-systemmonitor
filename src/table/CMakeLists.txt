set(table_SRCS
    ColumnDisplayModel.cpp
    ColumnDisplayModel.h
    ColumnSortModel.cpp
    ColumnSortModel.h
    ComponentCacheProxyModel.cpp
    ComponentCacheProxyModel.h
    ProcessSortFilterModel.cpp
    ProcessSortFilterModel.h
    ReverseColumnsProxyModel.cpp
    ReverseColumnsProxyModel.h
    TablePlugin.cpp
    TablePlugin.h
)

set(table_QML
    BaseCellDelegate.qml
    BaseTableView.qml
    TextCellDelegate.qml
    ColumnConfigurationDialog.qml
    FirstCellDelegate.qml
    LineChartCellDelegate.qml
    TableViewHeader.qml
    UserCellDelegate.qml
    KillDialog.qml
    TreeDecoration.qml
)

add_library(TablePlugin SHARED ${table_SRCS})
target_link_libraries(TablePlugin Qt::Quick KSysGuard::Sensors KSysGuard::ProcessCore KF6::CoreAddons KF6::ItemModels)

install(TARGETS TablePlugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/ksysguard/table)
install(FILES qmldir ${table_QML} DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/ksysguard/table)
