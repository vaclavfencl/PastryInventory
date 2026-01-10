import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import "ApiClient.js" as Api

Page {
    id: shoppingPage

    property int activeFilter: 0

    property string activeHouseholdId: ""

    property var allItems: []

    property int buyNowCount: 0
    property int buyOnSaleCount: 0

    ListModel { id: shoppingModel }

    function _isBuyNow(it) {
        if (!it) return false
        if (it.minCount === undefined || it.minCount === null) return false
        return Number(it.count || 0) < Number(it.minCount)
    }

    function _isBuyOnSale(it) {
        if (!it) return false
        if (it.saleCount === undefined || it.saleCount === null) return false

        if (it.minCount !== undefined && it.minCount !== null) {
            if (Number(it.count || 0) < Number(it.minCount)) return false
        }

        return Number(it.count || 0) < Number(it.saleCount)
    }


    function _recalcBadges() {
        var b0 = 0
        var b1 = 0
        for (var i = 0; i < (allItems ? allItems.length : 0); i++) {
            var it = allItems[i]
            if (_isBuyNow(it)) b0++
            if (_isBuyOnSale(it)) b1++
        }
        buyNowCount = b0
        buyOnSaleCount = b1
    }

    function applyFilter() {
        shoppingModel.clear()

        var items = allItems || []
        for (var i = 0; i < items.length; i++) {
            var it = items[i]

            var show = (activeFilter === 0) ? _isBuyNow(it) : _isBuyOnSale(it)
            if (!show) continue

            var threshold = (activeFilter === 0) ? Number(it.minCount) : Number(it.saleCount)
            var count = Number(it.count || 0)
            var need = Math.max(0, threshold - count)

            shoppingModel.append({
                id: String(it.id || ""),
                name: String(it.name || ""),
                categoryId: it.categoryId,
                unit: String(it.unit || "pcs"),
                need: need
            })
        }
    }

    function reloadItems() {
        if (!activeHouseholdId) return

        Api.ApiClient.listItems(activeHouseholdId, null)
            .then(function(items) {
                allItems = items || []
                _recalcBadges()
                applyFilter()
            })
            .catch(function(err) {
                console.error("Shopping load failed:", err.message)
                allItems = []
                _recalcBadges()
                applyFilter()
            })
    }

    onActiveFilterChanged: applyFilter()

    Component.onCompleted: {
        Api.ApiClient.listHouseholds()
            .then(function(households) {
                if (!households || households.length === 0) return
                activeHouseholdId = households[0].id
                reloadItems()
            })
            .catch(function(err) {
                console.error("Load households failed:", err.message)
            })
    }

    header: ToolBar{
        id: headerToolBar
        height: parent.height*0.2
        Material.background: "#16A249"
        Material.foreground: "white"
        Material.elevation: 6

        Label {
            id: pageName
            text: qsTr("Shopping")
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
                    reloadItems()
                }
            }
        }

        Label {
            id: pageDescription
            text: qsTr("See everything you need")
            font.pointSize: 12
            topPadding: 50
            y: pageName.y
            x: pageName.x
        }
    }

    ColumnLayout {
        anchors.fill: parent

        Rectangle {
            id:switchButtons
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height * 0.075
            anchors.topMargin: parent.height * 0.04
            anchors.bottomMargin: parent.height * 0.02
            anchors.leftMargin: parent.width*0.2
            anchors.rightMargin: parent.width*0.2
            radius: height/3
            color:"lightgray"
            visible:true

            RowLayout{
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.fill: parent
                anchors.margins: 4

                Rectangle {
                    color: shoppingPage.activeFilter === 0 ? "white" : "transparent"
                    radius: height / 3
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ToolButton {
                        anchors.fill: parent
                        background: null
                        onClicked: shoppingPage.activeFilter = 0
                    }

                    Item {
                        anchors.fill: parent
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Label { text: "Buy now" }
                            Rectangle {
                                width: 22
                                height: 20
                                radius: height / 2
                                color: "#ef4343"
                                Label {
                                    anchors.centerIn: parent
                                    text: String(buyNowCount)
                                    color: "white"
                                    font.bold: true
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    color: shoppingPage.activeFilter === 1 ? "white" : "transparent"
                    radius: height / 3
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ToolButton {
                        anchors.fill: parent
                        background: null
                        onClicked: shoppingPage.activeFilter = 1
                    }

                    Item {
                        anchors.fill: parent
                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Label { text: "Buy on Sale" }
                            Rectangle {
                                width: 22
                                height: 20
                                radius: height / 2
                                color: "#f59f0a"
                                Label {
                                    anchors.centerIn: parent
                                    text: String(buyOnSaleCount)
                                    color: "black"
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }
        }

        Column {
            anchors.top:switchButtons.bottom
            anchors.topMargin: 8
            anchors.left:switchButtons.left
            spacing: 8

            Repeater {
                model: shoppingModel

                delegate: Rectangle {
                    height: 75
                    width: switchButtons.width
                    radius: height/3
                    border.width: 1
                    border.color: "#E0E0E0"

                    Rectangle{
                        id:circle
                        radius:height/2
                        anchors.left:parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter:  parent.verticalCenter
                        height:parent.height/3
                        width:height
                        color:"transparent"
                        border.width: 1
                        border.color: "gray"
                        visible:true
                    }

                    Label{
                        text: model.name
                        font.bold: true
                        font.pointSize: 14
                        anchors.left: circle.left
                        anchors.leftMargin: circle.width+12
                        anchors.verticalCenter: circle.top
                    }

                    Label{
                        id: infoLine
                        property string categoryName: "Uncategorized"

                        text: categoryName + " • " + model.need + " " + model.unit
                        color:"black"
                        font.pointSize: 10
                        anchors.left: circle.left
                        anchors.leftMargin: circle.width+12
                        anchors.verticalCenter: circle.bottom

                        Component.onCompleted: {
                            Api.ApiClient.getCategoryName(model.categoryId)
                                .then(function(n) { infoLine.categoryName = n })
                                .catch(function() { infoLine.categoryName = "Uncategorized" })
                        }
                    }
                }
            }
        }
    }
}
