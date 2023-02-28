add_subdirectory(page)
add_subdirectory(table)
add_subdirectory(faces)

set(plasma-systemmonitor_SRCS
    main.cpp
    ToolsModel.cpp
    ToolsModel.h
    Configuration.cpp
    Configuration.h
)

qt_add_resources(plasma-systemmonitor_QRC systemmonitor.qrc)

kconfig_add_kcfg_files(plasma-systemmonitor_SRCS GENERATE_MOC systemmonitor.kcfgc)

add_definitions(-DQT_NO_KEYWORDS)

add_executable(plasma-systemmonitor ${plasma-systemmonitor_SRCS} ${plasma-systemmonitor_QRC})
target_compile_definitions(plasma-systemmonitor PRIVATE PROJECT_VERSION="${PROJECT_VERSION}")
target_link_libraries(plasma-systemmonitor
    Qt::Quick
    Qt::Widgets
    Qt::DBus
    KF6::I18n
    KF6::ConfigGui
    KF6::Declarative
    KF6::Service
    KF6::KIOGui
    KF6::GlobalAccel
    KF6::DBusAddons
    KF6::WindowSystem
)

install(TARGETS plasma-systemmonitor DESTINATION ${KDE_INSTALL_BINDIR})
install(FILES systemmonitor.kcfg DESTINATION ${KDE_INSTALL_KCFGDIR})
install(FILES plasma-systemmonitor.knsrc DESTINATION ${KDE_INSTALL_KNSRCDIR})

install(FILES
    pages/applications.page
    pages/history.page
    pages/overview.page
    pages/processes.page
    DESTINATION ${KDE_INSTALL_DATADIR}/plasma-systemmonitor
)
