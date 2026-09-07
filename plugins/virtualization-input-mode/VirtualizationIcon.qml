import QtQuick

Item {
  id: root

  property color color: "white"
  property real iconSize: Math.min(width, height)
  property real iconOpacity: 1.0

  implicitWidth: iconSize
  implicitHeight: iconSize
  opacity: iconOpacity

  readonly property real keySize: Math.min(height * 0.92, width * 0.92)
  readonly property real keyX: (width - keySize) / 2
  readonly property real keyY: (height - keySize) / 2

  // Dark outer skirt and bright upper edges create the raised keycap profile.
  Rectangle {
    x: root.keyX
    y: root.keyY
    width: root.keySize
    height: root.keySize
    radius: root.keySize * 0.14
    color: Qt.darker(root.color, 1.9)
    border.color: Qt.darker(root.color, 1.35)
    border.width: Math.max(1, root.keySize * 0.055)
  }

  Rectangle {
    x: root.keyX + root.keySize * 0.105
    y: root.keyY + root.keySize * 0.075
    width: root.keySize * 0.79
    height: root.keySize * 0.76
    radius: root.keySize * 0.10
    border.color: Qt.lighter(root.color, 1.30)
    border.width: Math.max(1, root.keySize * 0.045)
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.lighter(root.color, 1.12) }
      GradientStop { position: 0.48; color: root.color }
      GradientStop { position: 1.0; color: Qt.darker(root.color, 1.35) }
    }
  }

  Text {
    x: root.keyX
    y: root.keyY
    width: root.keySize
    height: root.keySize * 0.86
    text: "V"
    color: Qt.darker(root.color, 2.7)
    font.pixelSize: root.keySize * 0.49
    font.bold: true
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }
}
