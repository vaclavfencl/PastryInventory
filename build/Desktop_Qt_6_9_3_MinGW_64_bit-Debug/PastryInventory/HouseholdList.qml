import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "." as Api

Popup {
    id: popup
    width: 180
    modal: true
    focus: true

    padding: 8
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: "#16a249"
        radius: 6
    }

    signal householdSelected(string id, string name)

    property var households: []
    property bool loading: false
    property string errorText: ""

    contentItem: ColumnLayout {
        width: popup.availableWidth
        spacing: 6

        BusyIndicator {
            visible: popup.loading
            running: popup.loading
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            visible: popup.errorText !== ""
            text: popup.errorText
            color: "red"
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        ListView {
            visible: !popup.loading && popup.errorText === ""
            model: popup.households
            clip: true

            interactive: false
            boundsBehavior: Flickable.StopAtBounds
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 280)

            delegate: ItemDelegate {
                width: ListView.view.width
                hoverEnabled: true

                background: Rectangle {
                    color: pressed ? "#0f7a37" : (hovered ? "#12853d" : "#16a249")
                }

                contentItem: Text {
                    text: modelData.name
                    color: "white"
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                onClicked: {
                    popup.householdSelected(modelData.id, modelData.name)
                    popup.close()
                }
            }
        }
    }

    function loadHouseholds() {
        popup.loading = true
        popup.errorText = ""
        popup.households = []

        Api.ApiClient.listHouseholds()
            .then(function (res) {
                popup.households = res || []
                popup.loading = false
            })
            .catch(function (err) {
                popup.loading = false
                popup.errorText = err.message || "Failed to load households"
                console.error("Household load error:", err)
            })
    }

    onOpened: loadHouseholds()
}
