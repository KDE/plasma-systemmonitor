cmake_minimum_required(VERSION 3.16)

project(systemmonitor)

set(PROJECT_VERSION "6.3.90")
set(PROJECT_VERSION_MAJOR 6)

set(PROJECT_DEP_VERSION "6.3.5")
set(QT_MIN_VERSION "6.7.0")
set(KF6_MIN_VERSION "6.10.0")
set(KDE_COMPILERSETTINGS_LEVEL "5.82")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDEClangFormat)
include(ECMInstallIcons)
include(ECMFindQmlModule)
include(ECMQmlModule)
include(FeatureSummary)
include(KDEGitCommitHooks)
include(ECMDeprecationSettings)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Quick Widgets DBus)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS I18n Config Crash Service GlobalAccel KIO DBusAddons NewStuff ItemModels WindowSystem Package)
find_package(KSysGuard ${PROJECT_DEP_VERSION})
set_package_properties(KSysGuard PROPERTIES
    TYPE REQUIRED
    DESCRIPTION "The libksysguard collection of libraries"
    URL https://invent.kde.org/plasma/libksysguard
)
find_package(KSystemStats)
set_package_properties(KSystemStats PROPERTIES
    TYPE RUNTIME
    PURPOSE "Daemon providing system statistics"
    URL https://invent.kde.org/plasma/ksystemstats
)
find_package(Qt6QuickControls2  ${QT_MIN_VERSION})
set_package_properties(Qt6QuickControls2 PROPERTIES
    TYPE RUNTIME
)
find_package(KF6Kirigami  ${KF6_MIN_VERSION})
set_package_properties(KF6Kirigami PROPERTIES
    TYPE RUNTIME
)
find_package(KF${QT_MAJOR_VERSION}KirigamiAddons 1.1.0 REQUIRED)
set_package_properties(KF${QT_MAJOR_VERSION}KirigamiAddons PROPERTIES
    TYPE REQUIRED
    PURPOSE "Provides additional visual components"
)
ecm_find_qmlmodule(Qt.labs.qmlmodels 1.0)
ecm_find_qmlmodule(org.kde.iconthemes 1.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)
ecm_set_disabled_deprecation_versions(QT 6.8.1
    KF 6.9.0
)

if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    add_definitions(-DQT_QML_DEBUG)
endif()

add_subdirectory(src)

install(PROGRAMS org.kde.plasma-systemmonitor.desktop  DESTINATION  ${KDE_INSTALL_APPDIR})
install(PROGRAMS org.kde.plasma-systemmonitor.desktop  DESTINATION  ${KDE_INSTALL_DATADIR}/kglobalaccel)
install(FILES org.kde.plasma-systemmonitor.metainfo.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
install(FILES kcm_external_plasma-systemmonitor.desktop DESTINATION ${KDE_INSTALL_DATADIR}/plasma/kinfocenter/externalmodules)

install(FILES kconf_update/plasma-systemmonitor.upd DESTINATION ${KDE_INSTALL_KCONFUPDATEDIR})
install(PROGRAMS kconf_update/plasma-systemmonitor-replace-vmpss.py DESTINATION ${KDE_INSTALL_KCONFUPDATEDIR})

file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})
kde_configure_git_pre_commit_hook(CHECKS CLANG_FORMAT)

ki18n_install(po)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
