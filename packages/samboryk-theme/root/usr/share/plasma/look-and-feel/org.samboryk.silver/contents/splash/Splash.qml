import QtQuick

// Заставка під час входу в систему.
Rectangle {
    id: root
    property int stage
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#16171b" }
        GradientStop { position: 1.0; color: "#050506" }
    }

    Column {
        anchors.centerIn: parent
        spacing: 22

        Image {
            id: logo
            anchors.horizontalCenter: parent.horizontalCenter
            source: "images/logo.png"
            width: 128
            height: 128
            smooth: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Samboryk OS"
            color: "#f2f4f7"
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 180
            height: 4
            radius: 2
            color: "#33ffffff"

            Rectangle {
                height: parent.height
                radius: 2
                color: "#f2f4f7"
                width: parent.width * Math.min(1, root.stage / 6)
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
    }
}
