import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import "ApiClient.js" as Api

Page {
    id: homePage
    property var footerBar
    property string activeHouseholdId: ""
    property int totalItemsCount: 0
    property int outOfStockCount: 0

    ListModel { id: recentActivityModel }

    header: ToolBar{
        id: headerToolBar
        height: parent.height*0.2
        Material.background: "#16a249"
        Material.foreground: "white"
        Material.elevation: 6

        Label {
            id: pageName
            text: qsTr("SmartPantry")
            font.bold: true
            font.pointSize: 24
            y: parent.height/4
            x: parent.width/5

            Rectangle {
                id: householdButton
                width: 75
                height: parent.height*0.8
                radius: height / 2
                color: "transparent"
                border.width: 2
                border.color: "white"
                antialiasing: true
                x:parent.width*1.2
                y:parent.height*0.2

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Image {
                        source: "icons/homeIcon.png"
                        width: 18
                        height: 18
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        text: "▼"
                        font.pointSize: 12
                        color: "white"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        householdListPopup.x = householdButton.x - householdListPopup.width*0.3
                        householdListPopup.y = householdButton.y + householdButton.height + 10
                        householdListPopup.open()
                    }

                    onPressed: householdButton.color = "#22FFFFFF"
                    onReleased: householdButton.color = "transparent"
                    onCanceled: householdButton.color = "transparent"
                }
            }

            HouseholdList {
                id: householdListPopup
                onHouseholdSelected: (id, name) => {
                    console.log("Selected household:", name, id)
                    activeHouseholdId = id
                }
            }
        }

        Label {
            id: pageDescription
            text: qsTr("Manage your home inventory with ease")
            font.pointSize: 12
            topPadding: 50
            y: pageName.y
            x: pageName.x
        }
    }
    AddItemPopup {
        id: addItemPopup
        householdId: activeHouseholdId

        onItemCreated: (_) => homePage.activeHouseholdIdChanged()
        onItemSaved: (_) => homePage.activeHouseholdIdChanged()
        onItemDeleted: (_) => homePage.activeHouseholdIdChanged()
    }

    Component.onCompleted: {
        Api.ApiClient.listHouseholds()
            .then(function (households) {
                if (!households || households.length === 0) return
                activeHouseholdId = households[0].id
            })
            .catch(function (err) {
                console.error("Load households failed:", err.message)
            })
    }

    onActiveHouseholdIdChanged: {
        if (!activeHouseholdId || activeHouseholdId.length === 0) return

        Api.ApiClient.listItems(activeHouseholdId, null)
            .then(function (items) {
                items = items || []

                totalItemsCount = items.length

                var out = 0
                for (var i = 0; i < items.length; i++) {
                    var it = items[i]
                    var minC = (it.minCount === undefined || it.minCount === null) ? null : Number(it.minCount)
                    var c = Math.max(0, Number(it.count || 0))
                    if (minC !== null && c < minC) out++
                }
                outOfStockCount = out

                var sorted = items.slice().sort(function (a, b) {
                    var ad = new Date(a.updatedAt || a.createdAt || 0).getTime()
                    var bd = new Date(b.updatedAt || b.createdAt || 0).getTime()
                    return bd - ad
                })

                recentActivityModel.clear()

                var nowMs = Date.now()
                var limit = Math.min(5, sorted.length)

                for (var j = 0; j < limit; j++) {
                    var x = sorted[j]
                    var t = new Date(x.updatedAt || x.createdAt || nowMs).getTime()
                    var diffMin = Math.floor((nowMs - t) / 60000)
                    if (diffMin < 0) diffMin = 0

                    var agoText = ""
                    if (diffMin < 60) {
                        agoText = diffMin + " min ago"
                    } else {
                        var diffH = Math.floor(diffMin / 60)
                        if (diffH < 24) {
                            agoText = diffH + " hours ago"
                        } else {
                            var diffD = Math.floor(diffH / 24)
                            agoText = diffD + " days ago"
                        }
                    }

                    recentActivityModel.append({
                        name: String(x.name || ""),
                        ago: agoText
                    })
                }
            })
            .catch(function (err) {
                console.error("Load items failed:", err.message)
            })
    }

    ColumnLayout {
        anchors{
            top: headerToolBar.bottom
            left: parent.left
            right: parent.right
            margins: 16
        }
        spacing: 16

        RowLayout{
            spacing: 15
            Layout.margins: 16
            Layout.leftMargin: parent.width*0.16
            Layout.rightMargin: parent.width*0.16

            Rectangle{
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 80
                radius:16
                color:"white"
                border.color: "#E5E5E5"
                visible:true

                Rectangle{
                    id:totalItemsIcon
                    radius:height/2
                    anchors.left:parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter:  parent.verticalCenter
                    height:parent.height/2
                    width:height
                    color:"#e7f6ec"
                    visible:true

                    ToolButton{
                        icon.source: "qrc:qt/qml/PastryInventory/icons/inventoryButton.png"
                        anchors.centerIn: parent
                        background:null
                        Material.foreground: "#16a249"
                        onClicked: {
                            if (footerBar) {
                                footerBar.currentIndex = 1
                                console.log("footer index from HomePage:", footerBar.currentIndex)
                            }
                        }
                    }
                }

                Label{
                    text: String(totalItemsCount)
                    font.bold: true
                    font.pointSize: 14
                    anchors.left: totalItemsIcon.left
                    anchors.leftMargin: totalItemsIcon.width+12
                    anchors.top: totalItemsIcon.top
                }

                Label{
                    text: "Total Items"
                    color:"gray"
                    anchors.left: totalItemsIcon.left
                    anchors.leftMargin: totalItemsIcon.width+12
                    anchors.bottom: totalItemsIcon.bottom
                }
            }

            Rectangle{
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 80
                radius:16
                color:"white"
                border.color: "#E5E5E5"
                visible:true

                Rectangle{
                    id:outOfStockItemsIcon
                    radius:height/2
                    anchors.left:parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter:  parent.verticalCenter
                    height:parent.height/2
                    width:height
                    color:"#e7f6ec"
                    visible:true

                    ToolButton{
                        icon.source: "qrc:qt/qml/PastryInventory/icons/shoppingButton.png"
                        anchors.centerIn: parent
                        background:null
                        Material.foreground: "red"
                        onClicked:{
                            if (footerBar) {
                                footerBar.currentIndex = 2
                                console.log("footer index from HomePage:", footerBar.currentIndex)
                            }
                        }
                    }
                }

                Label{
                    text: String(outOfStockCount)
                    font.bold: true
                    font.pointSize: 14
                    anchors.left: outOfStockItemsIcon.left
                    anchors.leftMargin: outOfStockItemsIcon.width+12
                    anchors.top: outOfStockItemsIcon.top
                }

                Label{
                    text: "Out of Stock"
                    color:"gray"
                    anchors.left: outOfStockItemsIcon.left
                    anchors.leftMargin: outOfStockItemsIcon.width+12
                    anchors.bottom: outOfStockItemsIcon.bottom
                }
            }
        }

        Label{
            id:quickActionsText
            Layout.leftMargin: parent.width*0.16
            Layout.rightMargin: parent.width*0.16
            text:"Quick Actions"
            font.pointSize: 16
        }

        Rectangle{
            id:quickActionsRect
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: parent.width*0.16
            anchors.rightMargin: parent.width*0.16
            anchors.top: quickActionsText.bottom
            anchors.topMargin: 16
            radius: 20
            height:40
            color:"#16A249"
            visible:true

            Label {
                anchors.centerIn: parent
                text: "+    Add Item"
                font.pointSize: 10
                font.bold: true
                color:"white"
            }

            ToolButton{
                anchors.fill: parent
                onClicked: addItemPopup.open()
            }
        }

        Label{
            id:recentActivityText
            Layout.leftMargin: parent.width*0.16
            Layout.rightMargin: parent.width*0.16
            anchors.top: quickActionsRect.bottom
            anchors.topMargin: 16
            text:"Recent Activity"
            font.pointSize: 16
        }

        Column {
            anchors.top:recentActivityText.bottom
            anchors.topMargin: 8
            anchors.left:recentActivityText.left
            spacing: 8

            Repeater {
                model: recentActivityModel

                delegate: Rectangle{
                    height: 35
                    width: quickActionsRect.width
                    radius: height/3
                    border.width: 1
                    border.color: "#E0E0E0"

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        text: (name || "") + " • " + (ago || "")
                        font.pixelSize: 12
                        color: "black"
                        elide: Text.ElideRight
                        width: parent.width - 40
                    }
                }
            }
        }
    }
}
