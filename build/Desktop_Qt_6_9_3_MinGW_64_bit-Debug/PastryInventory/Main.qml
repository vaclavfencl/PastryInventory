import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

ApplicationWindow {
    width: 600
    height: 800
    minimumWidth: 480
    minimumHeight: 600
    visible: true
    title: qsTr("Smart Pantry")

    StackView {
        id: stackView
        anchors.fill: parent

        pushEnter: null
        pushExit: null
        popEnter: null
        popExit: null
        replaceEnter: null
        replaceExit: null

        Component {
            id: home
            HomePage {
                footerBar: footer
            }
        }
        Component {
            id: inventory
            InventoryPage {}
        }
        Component {
            id: shopping
            ShoppingPage {}
        }
        Component {
            id: settings
            SettingsPage {}
        }

        initialItem: home //HomePage{}
    }

    footer: Footer {
        id: footer
        stackView: stackView
        currentIndex: 0
    }
}
