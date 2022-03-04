cmake_minimum_required(VERSION 3.16)

project(systemmonitor)

set(PROJECT_VERSION "5.24.80")
set(PROJECT_VERSION_MAJOR 5)

set(QT_MIN_VERSION "5.15.0")
set(KF5_MIN_VERSION "5.90")
set(KDE_COMPILERSETTINGS_LEVEL "5.82")

find_package(ECM ${KF5_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDEClangFormat)
include(ECMInstallIcons)
include(ECMQMLModules)
include(FeatureSummary)
include(KDEGitCommitHooks)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

find_package(Qt${QT_MAJOR_VERSION} ${QT_MIN_VERSION} REQUIRED COMPONENTS Quick Widgets DBus)
find_package(KF5 ${KF5_MIN_VERSION} REQUIRED COMPONENTS I18n Config Declarative Service GlobalAccel KIO DBusAddons NewStuffQuick ItemModels)
find_package(KSysGuard ${PROJECT_VERSION})
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
find_package(Qt${QT_MAJOR_VERSION}QuickControls2  ${QT_MIN_VERSION})
set_package_properties(Qt${QT_MAJOR_VERSION}QuickControls2 PROPERTIES
    TYPE RUNTIME
)
find_package(KF5Kirigami2  ${KF5_MIN_VERSION})
set_package_properties(KF5Kirigami2 PROPERTIES
    TYPE RUNTIME
)
ecm_find_qmlmodule(Qt.labs.qmlmodels 1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)
add_definitions(-DQT_DISABLE_DEPRECATED_BEFORE=0x050f02)
add_definitions(-DKF_DISABLE_DEPRECATED_BEFORE_AND_AT=0x055900)

if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    add_definitions(-DQT_QML_DEBUG)
endif()

add_subdirectory(src)

install(PROGRAMS org.kde.plasma-systemmonitor.desktop  DESTINATION  ${KDE_INSTALL_APPDIR})
install(FILES kcm_external_plasma-systemmonitor.desktop DESTINATION ${KDE_INSTALL_DATADIR}/plasma/kinfocenter/externalmodules)

file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})
kde_configure_git_pre_commit_hook(CHECKS CLANG_FORMAT)


feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)
