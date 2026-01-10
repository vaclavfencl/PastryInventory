import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Page {

    header: ToolBar{
        id: headerToolBar
        height: parent.height*0.2
        Material.background: "#16A249"
        Material.foreground: "white"
        Material.elevation: 6

        Label {
            id: pageName
            text: qsTr("Settings")
            font.bold: true
            font.pointSize: 24
            y: parent.height/4
            x: parent.width/5
        }
        Label {
            id: pageDescription
            text: qsTr("Setup your experience")
            font.pointSize: 12
            topPadding: 50
            y: pageName.y
            x: pageName.x
        }
    }

    //Settings
    //Darkmode
    //Language
    //Notifikace?
    //export/clear data?
    //About Application
    Label{
        anchors.centerIn: parent
        text:"Settings page"
        font.pointSize: 20
        font.bold: true
    }

}
