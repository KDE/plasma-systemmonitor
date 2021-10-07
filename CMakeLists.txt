cmake_minimum_required(VERSION 3.16)

project(systemmonitor)

set(PROJECT_VERSION "5.23.0")
set(PROJECT_VERSION_MAJOR 5)

set(QT_MIN_VERSION "5.15.0")
set(KF5_MIN_VERSION "5.82")
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


find_package(Qt5 ${QT_MIN_VERSION} REQUIRED COMPONENTS Quick Widgets DBus)
find_package(KF5 ${KF5_MIN_VERSION} REQUIRED COMPONENTS I18n Config Declarative Service GlobalAccel KIO DBusAddons NewStuffQuick ItemModels)
find_package(KSysGuard ${PROJECT_VERSION} REQUIRED)
find_package(Qt5QuickControls2  ${QT_MIN_VERSION})
set_package_properties(Qt5QuickControls2 PROPERTIES
    TYPE RUNTIME
)
find_package(KF5Kirigami2  ${KF5_MIN_VERSION})
set_package_properties(KF5Kirigami2 PROPERTIES
    TYPE RUNTIME
)
ecm_find_qmlmodule(Qt.labs.qmlmodels 1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)

if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    add_definitions(-DQT_QML_DEBUG)
endif()

add_subdirectory(src)

install(PROGRAMS org.kde.plasma-systemmonitor.desktop  DESTINATION  ${KDE_INSTALL_APPDIR})

file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})
kde_configure_git_pre_commit_hook(CHECKS CLANG_FORMAT)


feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)
