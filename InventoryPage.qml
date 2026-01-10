import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import "ApiClient.js" as Api

Page {
    property var app
    property string activeHouseholdName: ""
    property string activeHouseholdId: ""
    property string selectedCategoryId: ""
    property var categoryButtonsModel: [{ id: "", name: "All Items" }]

    property var allItems: []
    property var categoryNameById: ({})

    function rebuildCategoryButtonsModel() {
        var used = {}
        for (var i = 0; i < allItems.length; i++) {
            var cid = allItems[i].categoryId
            if (cid) used[String(cid)] = true
        }

        var arr = [{ id: "", name: "All Items" }]
        var keys = Object.keys(categoryNameById)

        keys.sort(function (a, b) {
            var an = String(categoryNameById[a] || "").toLowerCase()
            var bn = String(categoryNameById[b] || "").toLowerCase()
            if (an < bn) return -1
            if (an > bn) return 1
            return String(a).localeCompare(String(b))
        })

        for (var k = 0; k < keys.length; k++) {
            var id = keys[k]
            if (used[id]) arr.push({ id: id, name: String(categoryNameById[id] || "") })
        }

        categoryButtonsModel = arr

        if (selectedCategoryId !== "" && !arr.some(function (x) { return String(x.id) === String(selectedCategoryId) })) {
            selectedCategoryId = ""
        }
    }

    function applyLocalFilter() {
        var q = (searchBar.text || "").trim().toLowerCase()
        var cat = String(selectedCategoryId || "")

        var out = []
        for (var i = 0; i < allItems.length; i++) {
            var it = allItems[i]

            if (cat !== "" && String(it.categoryId || "") !== cat) continue

            if (q.length > 0) {
                var name = String(it.name || "").toLowerCase()
                if (name.indexOf(q) === -1) continue
            }

            out.push(it)
        }

        out.sort(function (a, b) {
            var an = String(a.name || "").toLowerCase()
            var bn = String(b.name || "").toLowerCase()
            if (an < bn) return -1
            if (an > bn) return 1
            return String(a.id || "").localeCompare(String(b.id || ""))
        })

        itemListModel.items = out
    }

    function loadHouseholdData() {
        if (!activeHouseholdId || activeHouseholdId.length === 0) return

        Promise.all([
            Api.ApiClient.listCategories(activeHouseholdId),
            Api.ApiClient.listItems(activeHouseholdId, null)
        ]).then(function (res) {
            var cats = res[0] || []
            var items = res[1] || []

            var map = {}
            for (var i = 0; i < cats.length; i++) {
                map[String(cats[i].id)] = String(cats[i].name || "")
            }
            categoryNameById = map

            allItems = items

            rebuildCategoryButtonsModel()
            applyLocalFilter()
        }).catch(function (err) {
            console.error("Load household data failed:", err.message)
            categoryNameById = ({})
            allItems = []
            rebuildCategoryButtonsModel()
            applyLocalFilter()
        })
    }

    function bumpLocalCount(itemId, delta) {
        var did = false
        for (var i = 0; i < allItems.length; i++) {
            if (String(allItems[i].id) === String(itemId)) {
                var cur = Math.max(0, Number(allItems[i].count || 0))
                var next = Math.max(0, Math.min(9999, cur + Number(delta || 0)))
                allItems[i].count = next
                did = true
                break
            }
        }
        if (did) {
            allItems = allItems.slice()
            rebuildCategoryButtonsModel()
            applyLocalFilter()
        }
    }

    function setLocalCount(itemId, newCount) {
        var did = false
        for (var i = 0; i < allItems.length; i++) {
            if (String(allItems[i].id) === String(itemId)) {
                allItems[i].count = Math.max(0, Math.min(9999, Number(newCount || 0)))
                did = true
                break
            }
        }
        if (did) {
            allItems = allItems.slice()
            rebuildCategoryButtonsModel()
            applyLocalFilter()
        }
    }

    Timer {
        id: searchDebounce
        interval: 180
        repeat: false
        onTriggered: applyLocalFilter()
    }

    onActiveHouseholdIdChanged: {
        selectedCategoryId = ""
        loadHouseholdData()
    }

    header: ToolBar{
        id: headerToolBar
        height: parent.height*0.2
        Material.background: "#16A249"
        Material.foreground: "white"
        Material.elevation: 6

        Label {
            id: pageName
            text: qsTr("Inventory")
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
                x: parent.width*1.2
                y: parent.height*0.2

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
            text: qsTr("Visualize your home inventory with ease")
            font.pointSize: 12
            topPadding: 50
            y: pageName.y
            x: pageName.x
        }
    }

    AddItemPopup {
        id: addItemPopup
        householdId: activeHouseholdId

        onItemCreated: (_) => loadHouseholdData()

        onItemSaved: (hhId) => {
            if (hhId && String(hhId) !== String(activeHouseholdId)) activeHouseholdId = hhId
            else loadHouseholdData()
        }

        onItemDeleted: (hhId) => {
            if (hhId && String(hhId) !== String(activeHouseholdId)) activeHouseholdId = hhId
            else loadHouseholdData()
        }
    }

    ColumnLayout {
        anchors.fill: parent

        TextField{
            id: searchBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.025
            anchors.leftMargin: parent.width*0.2
            anchors.rightMargin: parent.width*0.2

            background: Rectangle {
                radius: height / 2
                color: "white"
                border.color: "#E0E0E0"
                border.width: 1
            }
            leftPadding: 32

            Image {
                source: "qrc:qt/qml/PastryInventory/icons/searchIcon.png"
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
            }

            placeholderText: qsTr("Search items...")
            onTextChanged: searchDebounce.restart()
        }

        Flickable {
            id: categoryBar
            anchors.top: searchBar.bottom
            anchors.topMargin: 8
            anchors.left: searchBar.left
            width: searchBar.width
            height: 32
            clip: true

            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            contentWidth: categoryRow.implicitWidth
            contentHeight: height

            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

            Row {
                id: categoryRow
                height: parent.height
                spacing: 8

                Repeater {
                    model: categoryButtonsModel

                    delegate: Rectangle {
                        height: 32
                        radius: height / 2
                        property bool selected: (String(modelData.id) === String(selectedCategoryId))

                        color: selected ? "#16A249" : "white"
                        border.width: selected ? 0 : 1
                        border.color: "#E0E0E0"

                        width: catLabel.paintedWidth + 24

                        Label {
                            id: catLabel
                            text: modelData.name
                            anchors.centerIn: parent
                            color: selected ? "white" : "black"
                            font.bold: selected
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                selectedCategoryId = String(modelData.id || "")
                                applyLocalFilter()
                            }
                        }
                    }
                }
            }
        }

        ItemListModel { id: itemListModel }

        Component.onCompleted: {
            Api.ApiClient.listHouseholds()
                .then(function (households) {
                    if (!households || households.length === 0) {
                        console.error("Load failed: No households returned.")
                        return
                    }
                    activeHouseholdId = households[0].id
                })
                .catch(function (err) {
                    console.error("Load failed:", err.message)
                })
        }

        Column {
            anchors.top: categoryBar.bottom
            anchors.topMargin: 8
            anchors.left: categoryBar.left
            spacing: 8

            Repeater {
                model: itemListModel.items

                delegate: Rectangle {
                    width: searchBar.width
                    height: 92
                    radius: 16
                    color: "white"
                    border.width: 1
                    border.color: "#E6E6E6"
                    clip: true

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Item {
                            width: parent.width * 0.60
                            height: parent.height

                            Column {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Item {
                                    width: parent.width
                                    height: 20

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name || ""
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "black"
                                        elide: Text.ElideRight
                                        clip: true
                                        width: parent.width - 8
                                    }
                                }

                                Row {
                                    spacing: 8

                                    Rectangle {
                                        id: categoryPill
                                        height: 20
                                        radius: 10
                                        color: "white"
                                        border.width: 1
                                        border.color: "#CFCFCF"

                                        Text {
                                            id: categoryText
                                            text: categoryNameById[String(modelData.categoryId)] || "Uncategorized"
                                            anchors.centerIn: parent
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: "black"
                                            leftPadding: 8
                                            rightPadding: 8
                                        }

                                        width: categoryText.paintedWidth + 16
                                    }

                                    Rectangle {
                                        id: editCircle
                                        height: 20
                                        radius: 10
                                        color: "#16A249"

                                        Text {
                                            id: editText
                                            anchors.centerIn: parent
                                            text: "EDIT"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: "white"
                                            leftPadding: 8
                                            rightPadding: 8
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                addItemPopup.editMode = true
                                                addItemPopup.itemToEdit = modelData
                                                addItemPopup.open()
                                            }
                                        }

                                        width: editText.paintedWidth + 16
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 1
                            height: parent.height * 0.62
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#EAEAEA"
                        }

                        Column {
                            width: 58
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Item {
                                width: 38
                                height: 38
                                anchors.horizontalCenter: parent.horizontalCenter

                                Rectangle {
                                    id: countCircle
                                    anchors.fill: parent
                                    radius: 19
                                    color: "transparent"
                                    border.width: 2
                                    border.color: "#D9D9D9"
                                    clip: true

                                    property bool editing: false
                                    property bool committing: false

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !countCircle.editing
                                        text: modelData.count
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "black"
                                    }

                                    TextField {
                                        id: countInput
                                        anchors.fill: parent
                                        visible: countCircle.editing
                                        text: String(modelData.count || 0)

                                        background: Rectangle {
                                            radius: 19
                                            color: "white"
                                            border.width: 0
                                        }

                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "black"
                                        horizontalAlignment: Text.AlignHCenter
                                        inputMethodHints: Qt.ImhDigitsOnly
                                        validator: IntValidator { bottom: 0; top: 9999 }

                                        leftPadding: 0
                                        rightPadding: 0
                                        topPadding: 6
                                        bottomPadding: 0

                                        onAccepted: focus = false

                                        onEditingFinished: {
                                            if (!countCircle.editing || countCircle.committing) return
                                            countCircle.committing = true

                                            var hh = modelData.householdId || activeHouseholdId
                                            var newCount = Math.min(9999, Math.max(0, parseInt(text, 10) || 0))
                                            var oldCount = Math.max(0, Number(modelData.count || 0))

                                            if (newCount === oldCount) {
                                                countCircle.editing = false
                                                countCircle.committing = false
                                                return
                                            }

                                            Api.ApiClient.updateItem(modelData.id, {
                                                householdId: hh,
                                                categoryId: modelData.categoryId,
                                                name: modelData.name,
                                                count: newCount,
                                                description: modelData.description,
                                                unit: modelData.unit,
                                                minCount: modelData.minCount,
                                                saleCount: modelData.saleCount,
                                                incrementStep: modelData.incrementStep
                                            }).then(function () {
                                                setLocalCount(modelData.id, newCount)
                                            }).catch(function (err) {
                                                console.error(err.message)
                                            }).then(function () {
                                                countCircle.editing = false
                                                countCircle.committing = false
                                            })
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !countCircle.editing
                                        cursorShape: Qt.IBeamCursor
                                        onClicked: {
                                            countCircle.editing = true
                                            countInput.text = String(modelData.count || 0)
                                            countInput.forceActiveFocus()
                                            countInput.selectAll()
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.unit || "pcs"
                                font.pixelSize: 10
                                color: "#6B6B6B"
                            }
                        }

                        Column {
                            width: 42
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: "#16A249"
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 16; color: "white" }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var step = Math.max(1, Number(modelData.incrementStep || 1))
                                        var current = Math.max(0, Number(modelData.count || 0))
                                        if (current >= 9999) return

                                        var delta = Math.min(step, 9999 - current)
                                        if (delta <= 0) return

                                        Api.ApiClient.patchItemCount(modelData.id, delta)
                                            .then(function () { bumpLocalCount(modelData.id, delta) })
                                            .catch(function (err) { console.error(err.message) })
                                    }
                                }
                            }

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: "#F2F2F2"
                                border.width: 1
                                border.color: "#D9D9D9"
                                anchors.horizontalCenter: parent.horizontalCenter

                                opacity: (Number(modelData.count || 0) <= 0) ? 0.4 : 1.0

                                Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 16; color: "#333" }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: Number(modelData.count || 0) > 0
                                    onClicked: {
                                        var step = Math.max(1, Number(modelData.incrementStep || 1))
                                        var current = Math.max(0, Number(modelData.count || 0))
                                        var delta = -Math.min(step, current)
                                        if (delta === 0) return

                                        Api.ApiClient.patchItemCount(modelData.id, delta)
                                            .then(function () { bumpLocalCount(modelData.id, delta) })
                                            .catch(function (err) { console.error(err.message) })
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle{
        id: addButton
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        radius: 50
        height: 50
        width: 150
        color: "#16A249"
        visible: true

        Label {
            anchors.centerIn: parent
            text: "+    Add Item"
            font.pointSize: 12
            font.bold: true
            color: "white"
        }

        ToolButton{
            anchors.fill: parent
            onClicked: {
                addItemPopup.editMode = false
                addItemPopup.itemToEdit = null
                addItemPopup.open()
            }
        }
    }
}
