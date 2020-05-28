
add_subdirectory(page)
add_subdirectory(table)

set(ksysguardqml_SRCS
    main.cpp
    ToolsModel.cpp
    Configuration.cpp
    ColumnSortModel.cpp
    ColumnDisplayModel.cpp
    ComponentCacheProxyModel.cpp
)

qt5_add_resources(ksysguardqml_QRC ksysguardqml.qrc)

kconfig_add_kcfg_files(ksysguardqml_SRCS GENERATE_MOC Config.kcfgc)

add_definitions(-DQT_NO_KEYWORDS)

add_executable(ksysguardqml ${ksysguardqml_SRCS} ${ksysguardqml_QRC})
target_link_libraries(ksysguardqml
    Qt5::Quick
    Qt5::Widgets
    Qt5::DBus
    KF5::I18n
    KF5::ConfigGui
    KF5::Declarative
    KF5::Service
    KF5::KIOGui
    KF5::GlobalAccel
)

install(TARGETS ksysguardqml DESTINATION ${KDE_INSTALL_BINDIR})
install(PROGRAMS org.kde.ksysguardqml.desktop  DESTINATION  ${KDE_INSTALL_APPDIR})
install(FILES ksysguardqml.kcfg DESTINATION ${KDE_INSTALL_KCFGDIR})

install(FILES
    pages/applications.page
    pages/history.page
    pages/overview.page
    pages/processes.page
    DESTINATION ${KDE_INSTALL_DATADIR}/ksysguardqml
)
