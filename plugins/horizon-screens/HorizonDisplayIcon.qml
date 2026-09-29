import QtQuick

Item {
  id: root

  property color color: "white"
  property real iconSize: Math.min(width, height)
  property real iconOpacity: 1.0

  implicitWidth: iconSize
  implicitHeight: iconSize
  opacity: iconOpacity

  Image {
    anchors.fill: parent
    source: Qt.resolvedUrl("assets/horizon-icon.svg")
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    asynchronous: true
  }
}
