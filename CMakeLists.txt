cmake_minimum_required(VERSION 3.16)

project(PastryInventory VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appPastryInventory
    main.cpp
)

qt_add_qml_module(appPastryInventory
    URI PastryInventory
    VERSION 1.0
    QML_FILES
        Main.qml
        QML_FILES Footer.qml
        QML_FILES HomePage.qml
        QML_FILES InventoryPage.qml
        QML_FILES ShoppingPage.qml
        QML_FILES SettingsPage.qml
        QML_FILES AddItemPopup.qml
    RESOURCES
        icons/pie.ico
        icons/homeButton.png
        icons/homeIcon.png
        icons/inventoryButton.png
        icons/shoppingButton.png
        icons/settingsButton.png
        icons/searchIcon.png
        QML_FILES
        QML_FILES Config.js
        QML_FILES ApiClient.js
        QML_FILES HouseholdList.qml
        QML_FILES ItemListModel.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appPastryInventory PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appPastryInventory
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appPastryInventory
    PRIVATE Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS appPastryInventory
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
