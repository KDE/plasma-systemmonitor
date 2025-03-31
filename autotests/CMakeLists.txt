find_package(Qt6 REQUIRED CONFIG COMPONENTS Test)

include_directories(../src/page ${CMAKE_BINARY_DIR}/src/page)

file(GLOB _global_pages CONFIGURE_DEPENDS data/global/*.page)
foreach(_page ${_global_pages})
    get_filename_component(_file ${_page} NAME)
    configure_file("${_page}" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/TestPageManager_data/plasma-systemmonitor/${_file}" FILE_PERMISSIONS OWNER_READ GROUP_READ WORLD_READ COPYONLY)
endforeach()

ecm_add_test(TEST_NAME TestPageManager
    TestPageManager.cpp
    ../src/page/PageManager.cpp
    ../src/page/PageController.cpp
    ../src/page/PageDataObject.cpp
    ../src/page/FaceLoader.cpp
    LINK_LIBRARIES
    Qt6::Quick
    Qt6::Test
    KF6::ConfigCore
    KF6::NewStuffCore
    KSysGuard::Sensors
    KSysGuard::SensorFaces
)

kconfig_target_kcfg_file(TestPageManager FILE ${CMAKE_SOURCE_DIR}/src/page/systemmonitor.kcfg CLASS_NAME Configuration MUTATORS GENERATE_PROPERTIES GENERATE_MOC SINGLETON QML_REGISTRATION)
