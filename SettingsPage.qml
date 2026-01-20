import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import "ApiClient.js" as Api

Page {
    id: settingsPage

    // model for household list
    property var households: []
    property bool busy: false

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

    //HouseholdList - add, delete, edit
    //Settings
    //Darkmode?
    //Language
    //Notifikace?
    //export/clear data?
    //About Application

    // load households once
    Component.onCompleted: {
        busy = true
        Api.ApiClient.listHouseholds()
            .then(function (list) {
                households = (list || []).slice().sort(function(a,b){
                    var an = String(a.name || "").toLowerCase()
                    var bn = String(b.name || "").toLowerCase()
                    if (an < bn) return -1
                    if (an > bn) return 1
                    return String(a.id||"").localeCompare(String(b.id||""))
                })
            })
            .catch(function (err) {
                console.error("Load households failed:", err.message)
                households = []
            })
            .then(function () { busy = false })
    }

    // ---------- Add/Edit popup ----------
    Popup {
        id: householdEditor
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        x: (parent ? parent.width : 400) / 2 - width / 2
        y: 90
        width: 340
        padding: 16

        property bool editMode: false
        property string editId: ""
        property string originalName: ""
        property string errorText: ""
        property bool saving: false

        background: Rectangle {
            color: "white"
            radius: 12
            border.width: 1
            border.color: "#E5E5E5"
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: householdEditor.editMode ? "Edit Household" : "Add Household"
                    font.bold: true
                    font.pointSize: 14
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: "#F8F8F8"
                    border.width: 1
                    border.color: "#E5E5E5"

                    ToolButton {
                        anchors.fill: parent
                        background: null
                        text: "X"
                        enabled: !householdEditor.saving
                        onClicked: householdEditor.close()
                    }
                }
            }

            Label {
                text: householdEditor.editMode
                      ? "Change the household name."
                      : "Create a new household."
                font.pointSize: 9
                color: "#6B6B6B"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Label {
                    text: "Name"
                    font.bold: true
                    font.pointSize: 11
                }

                TextField {
                    id: householdNameInput
                    Layout.fillWidth: true
                    maximumLength: 16
                    placeholderText: qsTr("e.g., Home, Dorm...")
                    enabled: !householdEditor.saving

                    background: Rectangle {
                        radius: height / 2
                        color: "white"
                        border.color: "#E0E0E0"
                        border.width: 1
                    }

                    onTextChanged: {
                        if (householdEditor.errorText.length) householdEditor.errorText = ""
                    }
                }

                Label {
                    visible: householdEditor.errorText.length > 0
                    text: householdEditor.errorText
                    color: "#EF4444"
                    font.pointSize: 9
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item { Layout.fillWidth: true }

                BusyIndicator {
                    running: householdEditor.saving
                    visible: householdEditor.saving
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                }

                Rectangle {
                    height: 36
                    radius: 18
                    color: "#16A249"
                    Layout.preferredWidth: (householdEditor.editMode ? 90 : 110)

                    opacity: householdEditor.saving ? 0.7 : 1.0

                    Label {
                        anchors.centerIn: parent
                        text: householdEditor.editMode ? "Save" : "Add"
                        color: "white"
                        font.bold: true
                        font.pointSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !householdEditor.saving
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            var name = String(householdNameInput.text || "").trim()

                            if (name.length === 0) {
                                householdEditor.errorText = "Name is required."
                                return
                            }
                            if (name.length > 16) {
                                householdEditor.errorText = "Max 16 characters."
                                return
                            }

                            householdEditor.saving = true
                            householdEditor.errorText = ""

                            if (!householdEditor.editMode) {
                                // CREATE
                                Api.ApiClient.createHousehold({ name: name })
                                    .then(function (created) {
                                        var arr = (households || []).slice()
                                        arr.push(created)
                                        arr.sort(function(a,b){
                                            var an = String(a.name || "").toLowerCase()
                                            var bn = String(b.name || "").toLowerCase()
                                            if (an < bn) return -1
                                            if (an > bn) return 1
                                            return String(a.id||"").localeCompare(String(b.id||""))
                                        })
                                        households = arr
                                        householdEditor.close()
                                    })
                                    .catch(function (err) {
                                        householdEditor.errorText = err.message || "Create failed."
                                    })
                                    .then(function () {
                                        householdEditor.saving = false
                                    })
                            } else {
                                // UPDATE
                                Api.ApiClient.updateHousehold(householdEditor.editId, { name: name })
                                    .then(function () {
                                        var arr2 = (households || []).slice()
                                        for (var i = 0; i < arr2.length; i++) {
                                            if (String(arr2[i].id) === String(householdEditor.editId)) {
                                                arr2[i].name = name
                                                break
                                            }
                                        }
                                        arr2.sort(function(a,b){
                                            var an2 = String(a.name || "").toLowerCase()
                                            var bn2 = String(b.name || "").toLowerCase()
                                            if (an2 < bn2) return -1
                                            if (an2 > bn2) return 1
                                            return String(a.id||"").localeCompare(String(b.id||""))
                                        })
                                        households = arr2
                                        householdEditor.close()
                                    })
                                    .catch(function (err) {
                                        householdEditor.errorText = err.message || "Save failed."
                                    })
                                    .then(function () {
                                        householdEditor.saving = false
                                    })
                            }
                        }
                    }
                }
            }
        }

        onOpened: {
            householdEditor.errorText = ""
            householdEditor.saving = false
            householdNameInput.forceActiveFocus()
            householdNameInput.selectAll()
        }
    }

    // ---------- Delete confirm popup ----------
    Popup {
        id: deleteConfirm
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        x: (parent ? parent.width : 400) / 2 - width / 2
        y: 110
        width: 340
        padding: 16

        property string deleteId: ""
        property string deleteName: ""
        property string errorText: ""
        property bool deleting: false

        background: Rectangle {
            color: "white"
            radius: 12
            border.width: 1
            border.color: "#E5E5E5"
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "Delete Household"
                    font.bold: true
                    font.pointSize: 14
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: "#F8F8F8"
                    border.width: 1
                    border.color: "#E5E5E5"

                    ToolButton {
                        anchors.fill: parent
                        background: null
                        text: "X"
                        enabled: !deleteConfirm.deleting
                        onClicked: deleteConfirm.close()
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.pointSize: 9
                color: "#6B6B6B"
                text: "Are you sure you want to delete \"" + (deleteConfirm.deleteName || "") + "\"?\nThis also deletes its items and categories."
            }

            Label {
                visible: deleteConfirm.errorText.length > 0
                text: deleteConfirm.errorText
                color: "#EF4444"
                font.pointSize: 9
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 18
                    color: "#F2F2F2"
                    border.width: 1
                    border.color: "#D9D9D9"
                    opacity: deleteConfirm.deleting ? 0.7 : 1.0

                    Label {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: "black"
                        font.bold: true
                        font.pointSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !deleteConfirm.deleting
                        cursorShape: Qt.PointingHandCursor
                        onClicked: deleteConfirm.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 18
                    color: "white"
                    border.width: 1
                    border.color: "#E5E5E5"
                    opacity: deleteConfirm.deleting ? 0.7 : 1.0

                    Label {
                        anchors.centerIn: parent
                        text: deleteConfirm.deleting ? "Deleting..." : "Delete"
                        color: "#EF4444"
                        font.bold: true
                        font.pointSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !deleteConfirm.deleting
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            deleteConfirm.deleting = true
                            deleteConfirm.errorText = ""

                            Api.ApiClient.deleteHousehold(deleteConfirm.deleteId)
                                .then(function () {
                                    var arr = (households || []).slice().filter(function (h) {
                                        return String(h.id) !== String(deleteConfirm.deleteId)
                                    })
                                    households = arr
                                    deleteConfirm.close()
                                })
                                .catch(function (err) {
                                    deleteConfirm.errorText = err.message || "Delete failed."
                                })
                                .then(function () {
                                    deleteConfirm.deleting = false
                                })
                        }
                    }
                }
            }
        }

        onOpened: {
            deleteConfirm.errorText = ""
            deleteConfirm.deleting = false
        }
    }

    ColumnLayout {
        anchors {
            top: headerToolBar.bottom
            left: parent.left
            right: parent.right
            margins: 16
        }
        spacing: 16

        // Household card
        Rectangle {
            id: householdCard
            Layout.fillWidth: true
            radius: 20
            color: "white"
            border.width: 1
            border.color: "#E5E5E5"
            implicitHeight: householdContent.implicitHeight + 36

            Column {
                id: householdContent
                width: parent.width
                anchors.margins: 18
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 14

                Row {
                    spacing: 10

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: "#F5F5F5"
                        border.width: 1
                        border.color: "#E5E5E5"

                        Image {
                            anchors.centerIn: parent
                            source: "icons/homeIcon.png"
                            width: 16
                            height: 16
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    Label {
                        text: "Household"
                        font.pointSize: 14
                        font.bold: true
                        color: "black"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // List of households
                Column {
                    width: parent.width
                    spacing: 0

                    Item {
                        width: parent.width
                        height: (households.length === 0) ? 44 : 0
                        visible: households.length === 0

                        Label {
                            anchors.centerIn: parent
                            text: busy ? "Loading..." : "No households yet"
                            color: "#6B6B6B"
                            font.pointSize: 10
                        }
                    }

                    Repeater {
                        model: households

                        delegate: Column {
                            width: parent.width
                            spacing: 0

                            RowLayout {
                                width: parent.width
                                height: 44
                                spacing: 12

                                Label {
                                    text: modelData.name || ""
                                    font.pointSize: 12
                                    font.bold: true
                                    color: "black"
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                    Layout.fillWidth: true
                                }

                                // Edit
                                Rectangle {
                                    height: 34
                                    radius: 17
                                    color: "#F8F8F8"
                                    border.width: 1
                                    border.color: "#E5E5E5"
                                    Layout.preferredWidth: editLbl.paintedWidth + 26
                                    opacity: (busy || householdEditor.saving || deleteConfirm.deleting) ? 0.6 : 1.0

                                    Label {
                                        id: editLbl
                                        anchors.centerIn: parent
                                        text: "Edit"
                                        color: "black"
                                        font.pointSize: 10
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !(busy || householdEditor.saving || deleteConfirm.deleting)
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            householdEditor.editMode = true
                                            householdEditor.editId = String(modelData.id || "")
                                            householdEditor.originalName = String(modelData.name || "")
                                            householdNameInput.text = householdEditor.originalName
                                            householdEditor.open()
                                        }
                                    }
                                }

                                // Delete
                                Rectangle {
                                    height: 34
                                    radius: 17
                                    color: "#F8F8F8"
                                    border.width: 1
                                    border.color: "#E5E5E5"
                                    Layout.preferredWidth: delLbl.paintedWidth + 26
                                    opacity: (busy || householdEditor.saving || deleteConfirm.deleting) ? 0.6 : 1.0

                                    Label {
                                        id: delLbl
                                        anchors.centerIn: parent
                                        text: "Delete"
                                        color: "#EF4444"
                                        font.pointSize: 10
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !(busy || householdEditor.saving || deleteConfirm.deleting)
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            deleteConfirm.deleteId = String(modelData.id || "")
                                            deleteConfirm.deleteName = String(modelData.name || "")
                                            deleteConfirm.open()
                                        }
                                    }
                                }
                            }

                            // divider line (except after last)
                            Rectangle {
                                width: parent.width
                                height: 1
                                color: "#E9E9E9"
                                visible: index !== (households.length - 1)
                            }
                        }
                    }

                    Item { width: 1; height: 10 }

                    // Add Household button
                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: 22
                        color: "white"
                        border.width: 1
                        border.color: "#E5E5E5"
                        opacity: (busy || householdEditor.saving || deleteConfirm.deleting) ? 0.6 : 1.0

                        Label {
                            anchors.centerIn: parent
                            text: "Add Household"
                            font.pointSize: 11
                            font.bold: true
                            color: "black"
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !(busy || householdEditor.saving || deleteConfirm.deleting)
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                householdEditor.editMode = false
                                householdEditor.editId = ""
                                householdEditor.originalName = ""
                                householdNameInput.text = ""
                                householdEditor.open()
                            }
                        }
                    }
                }
            }
        }

        // About card (visual only)
        Rectangle {
            id: aboutCard
            Layout.fillWidth: true
            radius: 20
            visible: true
            color: "#F7F7F7"
            border.width: 1
            border.color: "#E5E5E5"
            implicitHeight: aboutContent.implicitHeight + 36

            Column {
                id: aboutContent
                width: parent.width
                anchors.margins: 18
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 6

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "SmartPantry"
                    font.pointSize: 14
                    font.bold: true
                    color: "black"
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Version 1.0.0"
                    font.pointSize: 10
                    color: "#6B6B6B"
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "© 2025 SmartPantry"
                    font.pointSize: 10
                    color: "#6B6B6B"
                }
            }
        }
    }
}
