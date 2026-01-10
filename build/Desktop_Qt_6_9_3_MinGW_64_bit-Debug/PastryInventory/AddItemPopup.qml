import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import "ApiClient.js" as Api

Popup  {
    id: root
    modal: true
    focus: true
    x: (parent ? parent.width : 400) / 2 - width / 2
    y: 80
    width: 320
    padding: 16
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // Provided by page
    property string householdId: ""

    // Edit support
    property bool editMode: false
    property var itemToEdit: null

    // Notify page
    signal itemCreated(var createdItem)
    signal itemSaved(string householdId)
    signal itemDeleted(string householdId)

    property bool isSaving: false
    property string errorText: ""

    background: Rectangle {
        color: "white"
        radius: 12
    }

    // Fill/reset fields when popup opens
    onOpened: {
        errorText = ""
        isSaving = false

        if (editMode && itemToEdit) {
            itemNameInput.text = (itemToEdit.name || "")
            unitInput.text = (itemToEdit.unit || "pcs")
            quantityInput.text = String(Math.max(0, Number(itemToEdit.count || 0)))
            stepInput.text = String(Math.max(1, Number(itemToEdit.incrementStep || 1)))
            aMinInput.text = String(Math.max(0, Number(itemToEdit.minCount || 0)))
            saleInput.text = String(Math.max(0, Number(itemToEdit.saleCount || 0)))

            // Category shown as NAME
            if (itemToEdit.categoryId) {
                categoryInput.text = "..."
                Api.ApiClient.getCategoryName(itemToEdit.categoryId)
                    .then(function (n) {
                        // If category was deleted / missing, treat as empty
                        categoryInput.text = (n === "Uncategorized") ? "" : n
                    })
            } else {
                categoryInput.text = ""
            }
        } else {
            // Add mode defaults
            itemNameInput.text = ""
            categoryInput.text = ""
            unitInput.text = ""
            quantityInput.text = "0"
            stepInput.text = "1"
            aMinInput.text = "0"
            saleInput.text = "0"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        ColumnLayout{
            RowLayout{
                anchors.left: parent.left
                anchors.right: parent.right

                Label {
                    id:addNewItemText
                    text: root.editMode ? "Edit Item" : "Add New Item"
                    Layout.alignment: Qt.AlignLeft
                    font.bold: true
                    font.pointSize: 14
                }

                Rectangle{
                    anchors.right: parent.right
                    height: 2*addNewItemText.height/3
                    width: height
                    radius: height/2
                    border.width: 1
                    border.color: "#E0E0E0"

                    ToolButton {
                        anchors.fill: parent
                        background: null
                        text: "X"
                        onClicked: root.close()
                    }
                }
            }

            Label {
                text: root.editMode
                      ? "Update the item details and save."
                      : "Add a new item to your inventory. Fill in the details below."
                font.pointSize: 8
            }

            Label {
                visible: root.errorText.length > 0
                text: root.errorText
                color: "#B00020"
                font.pointSize: 9
                wrapMode: Text.Wrap
            }
        }

        ColumnLayout{
            Label {
                text: "Item Name"
                font.bold: true
                font.pointSize: 12
            }

            TextField{
                id:itemNameInput
                Layout.fillWidth: true
                maximumLength: 16
                background: Rectangle {
                    radius: height / 2
                    color: "white"
                    border.color: "#E0E0E0"
                    border.width: 1
                }
                placeholderText: qsTr("e.g., Milk, Bread, Eggs")
            }
        }

        RowLayout{
            spacing:16

            ColumnLayout{
                Label {
                    text: "Category"
                    font.bold: true
                    font.pointSize: 12
                }

                TextField{
                    id:categoryInput
                    Layout.fillWidth: true
                    maximumLength: 16
                    background: Rectangle {
                        radius: height / 2
                        color: "white"
                        border.color: "#E0E0E0"
                        border.width: 1
                    }
                    placeholderText: qsTr("e.g., Pantry, Fridge")
                }
            }

            ColumnLayout{
                Label {
                    text: "Unit"
                    font.bold: true
                    font.pointSize: 12
                }

                TextField{
                    id:unitInput
                    Layout.fillWidth: true
                    background: Rectangle {
                        radius: height / 2
                        color: "white"
                        border.color: "#E0E0E0"
                        border.width: 1
                    }
                    placeholderText: qsTr("e.g., pcs, kg, l")
                }
            }
        }

        RowLayout{
            spacing:16

            ColumnLayout{
                Label { text: "Quantity"; font.bold: true; font.pointSize: 12 }

                TextField{
                    id:quantityInput
                    Layout.fillWidth: true
                    background: Rectangle {
                        radius: height / 2
                        color: "white"
                        border.color: "#E0E0E0"
                        border.width: 1
                    }
                    text: "0"
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 0; top: 9999 }
                }
            }

            ColumnLayout{
                Label { text: "Step"; font.bold: true; font.pointSize: 12 }

                TextField{
                    id:stepInput
                    Layout.fillWidth: true
                    background: Rectangle {
                        radius: height / 2
                        color: "white"
                        border.color: "#E0E0E0"
                        border.width: 1
                    }
                    text: "1"
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 1; top: 9999 }
                }
            }

            ColumnLayout{
                Label { text: "Min"; font.bold: true; font.pointSize: 12 }

                TextField{
                    id: aMinInput
                    Layout.fillWidth: true
                    background: Rectangle {
                        radius: height / 2
                        color: "white"
                        border.color: "#E0E0E0"
                        border.width: 1
                    }
                    text: "0"
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 0; top: 9999 }
                }
            }

            ColumnLayout{
                Label { text: "Sale"; font.bold: true; font.pointSize: 12 }

                TextField{
                    id:saleInput
                    Layout.fillWidth: true
                    background: Rectangle {
                        radius: height / 2
                        color: "white"
                        border.color: "#E0E0E0"
                        border.width: 1
                    }
                    text: "0"
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 0; top: 9999 }
                }
            }
        }

        // Split actions: Cancel/Delete (left) + Save/Add (right)
        Rectangle {
            Layout.fillWidth: true
            height: 40
            radius: 20
            clip: true
            color: "transparent"

            Row {
                anchors.fill: parent
                spacing: 1  // divider line

                // LEFT HALF: Cancel (add) or Delete (edit)
                Rectangle {
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    color: root.editMode ? "#FFE9E9" : "#F2F2F2"   // delete = light red, cancel = light gray

                    Label {
                        anchors.centerIn: parent
                        text: root.editMode ? "Delete" : "Cancel"
                        font.pointSize: 10
                        font.bold: true
                        color: root.editMode ? "#B00020" : "black"
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.isSaving
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.errorText = ""

                            // ADD mode: Cancel -> close popup
                            if (!root.editMode) {
                                root.close()
                                return
                            }

                            // EDIT mode: Delete item
                            if (!root.itemToEdit || !root.itemToEdit.id) {
                                root.errorText = "Missing item to delete."
                                return
                            }

                            const hhId = String(root.itemToEdit.householdId || root.householdId || "").trim()
                            if (hhId.length === 0) {
                                root.errorText = "No household selected."
                                return
                            }

                            root.isSaving = true

                            Api.ApiClient.deleteItem(root.itemToEdit.id)
                                .then(function () {
                                    root.itemDeleted(hhId)
                                    root.close()
                                })
                                .catch(function (err) {
                                    root.errorText = err && err.message ? err.message : String(err)
                                })
                                .finally(function () {
                                    root.isSaving = false
                                })
                        }
                    }
                }

                // RIGHT HALF: Save/Add
                Rectangle {
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    color: root.isSaving ? "#7CCB98" : "#16A249"

                    Label {
                        anchors.centerIn: parent
                        text: root.isSaving
                              ? "Saving..."
                              : (root.editMode ? "Save Changes" : "Add to Inventory")
                        font.pointSize: 10
                        font.bold: true
                        color: "white"
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.isSaving
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.errorText = ""

                            const hhId = (root.editMode && root.itemToEdit && root.itemToEdit.householdId)
                                         ? String(root.itemToEdit.householdId)
                                         : String(root.householdId || "").trim()

                            if (hhId.length === 0) { root.errorText = "No household selected."; return; }

                            const name = (itemNameInput.text || "").trim()
                            if (name.length === 0) { root.errorText = "Item name is required."; return; }
                            if (name.length > 16)  { root.errorText = "Item name max 16 characters."; return; }

                            const unit = (unitInput.text || "").trim()
                            if (unit.length > 8) { root.errorText = "Unit max 8 characters."; return; }

                            const categoryName = (categoryInput.text || "").trim()
                            if (categoryName.length > 16) { root.errorText = "Category max 16 characters."; return; }

                            const count = Math.min(9999, Math.max(0, parseInt(quantityInput.text, 10) || 0))
                            const minCount = Math.min(9999, Math.max(0, parseInt(aMinInput.text, 10) || 0))
                            const saleCount = Math.min(9999, Math.max(0, parseInt(saleInput.text, 10) || 0))
                            const step = Math.min(9999, Math.max(1, parseInt(stepInput.text, 10) || 1))

                            root.isSaving = true

                            // Resolve categoryId by NAME (find or create). Empty => null.
                            var catPromise = Promise.resolve(null)
                            if (categoryName.length > 0) {
                                catPromise = Api.ApiClient.listCategories(hhId)
                                    .then(function (cats) {
                                        cats = cats || []
                                        const target = categoryName.toLowerCase()
                                        const existing = cats.find(c => (c.name || "").toLowerCase() === target)
                                        if (existing) return existing.id

                                        return Api.ApiClient.createCategory({ householdId: hhId, name: categoryName })
                                            .then(created => created.id)
                                    })
                            }

                            catPromise
                                .then(function (catId) {
                                    if (!root.editMode) {
                                        // CREATE
                                        return Api.ApiClient.createItem({
                                            householdId: hhId,
                                            categoryId: catId,
                                            name: name,
                                            count: count,
                                            unit: unit,
                                            minCount: minCount,
                                            saleCount: saleCount,
                                            incrementStep: step
                                        }).then(function (createdItem) {
                                            root.itemCreated(createdItem)
                                            root.close()
                                        })
                                    }

                                    // UPDATE
                                    if (!root.itemToEdit || !root.itemToEdit.id) {
                                        throw new Error("Missing item to edit.")
                                    }

                                    return Api.ApiClient.updateItem(root.itemToEdit.id, {
                                        householdId: hhId, // required by your ApiClient normalizer
                                        categoryId: catId,
                                        name: name,
                                        count: count,
                                        description: (root.itemToEdit.description === undefined ? null : root.itemToEdit.description),
                                        unit: unit,
                                        minCount: minCount,
                                        saleCount: saleCount,
                                        incrementStep: step
                                    }).then(function () {
                                        root.itemSaved(hhId)
                                        root.close()
                                    })
                                })
                                .catch(function (err) {
                                    root.errorText = err && err.message ? err.message : String(err)
                                })
                                .finally(function () {
                                    root.isSaving = false
                                })
                        }
                    }
                }
            }
        }
    }
}
