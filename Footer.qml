import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

ToolBar {
    id: mainToolBar
    Material.background: "white"
    Material.foreground: "darkslategray"
    implicitHeight: 56
    property StackView stackView
    property int currentIndex: 0

    onCurrentIndexChanged: {
        switch (currentIndex) {
        case 0: stackView.replace("HomePage.qml"); break;
        case 1: stackView.replace("InventoryPage.qml"); break;
        case 2: stackView.replace("ShoppingPage.qml"); break;
        case 3: stackView.replace("SettingsPage.qml"); break;
        }
    }

    Rectangle {
        color: "#BDBDBD"
        height: 1
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
    }

    RowLayout {
        spacing: 48
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        ToolButton {
            id: homeButton
            property int index: 0
            background: null
            icon.source: "qrc:qt/qml/PastryInventory/icons/homeButton.png"
            text: "Home"
            spacing: 2
            display: AbstractButton.TextUnderIcon

            Material.foreground: index == mainToolBar.currentIndex? "#16A249"
                                                                  : (hovered? "black"
                                                                            : "darkslategray")

            onClicked: /*if (index !== mainToolBar.currentIndex)*/  {
                stackView.replace("HomePage.qml")
                mainToolBar.currentIndex = index
            }

        }
        ToolButton {
            id: inventoryButton
            property int index: 1
            background: null
            icon.source: "qrc:qt/qml/PastryInventory/icons/inventoryButton.png"
            text: "Inventory"
            spacing: 2
            display: AbstractButton.TextUnderIcon

            Material.foreground: index == mainToolBar.currentIndex? "#16A249"
                                                                  : (hovered? "black"
                                                                            : "darkslategray")

            onClicked: /*if (index !== mainToolBar.currentIndex)*/  {
                stackView.replace("InventoryPage.qml")
                mainToolBar.currentIndex = index
            }
        }

        ToolButton {
            id: shoppingButton
            property int index: 2
            background: null
            icon.source: "qrc:qt/qml/PastryInventory/icons/shoppingButton.png"
            text: "Shopping"
            spacing: 2
            display: AbstractButton.TextUnderIcon

            Material.foreground: index == mainToolBar.currentIndex? "#16A249"
                                                                  : (hovered? "black"
                                                                            : "darkslategray")

            onClicked: /*if (index !== mainToolBar.currentIndex)*/  {
                stackView.replace("ShoppingPage.qml")
                mainToolBar.currentIndex = index
            }
        }

        ToolButton {
            id: settingsButton
            property int index: 3
            background: null
            icon.source: "qrc:qt/qml/PastryInventory/icons/settingsButton.png"
            text: "Settings"
            spacing: 2
            display: AbstractButton.TextUnderIcon

            Material.foreground: index == mainToolBar.currentIndex? "#16A249"
                                                                  : (hovered? "black"
                                                                            : "darkslategray")

            onClicked: /*if (index !== mainToolBar.currentIndex)*/  {
                stackView.replace("SettingsPage.qml")
                mainToolBar.currentIndex = index
            }

        }
    }
}
