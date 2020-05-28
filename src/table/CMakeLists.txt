
set(table_SRCS
    TablePlugin.cpp
)

set(table_QML
)

add_library(TablePlugin SHARED ${table_SRCS})
target_link_libraries(TablePlugin Qt5::Quick KSysGuard::Sensors)

install(TARGETS TablePlugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/ksysguard/table)
install(FILES qmldir ${table_QML} DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/ksysguard/table)
