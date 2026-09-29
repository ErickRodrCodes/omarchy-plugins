import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root
  property var controller: null
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property bool ready: controller ? controller.ready : false
  readonly property bool busy: controller ? controller.busy : false
  readonly property bool verified: controller ? controller.verified : false
  signal dismissRequested()

  implicitHeight: content.implicitHeight

  function activate() { if (controller && ready && !busy) controller.verify() }
  function handleTextKey(t) {
    if ((t === "v" || t === "V") && controller) controller.verify()
    else if ((t === "l" || t === "L") && controller) controller.launch()
    else if ((t === "r" || t === "R") && controller) controller.refresh()
  }

  Column {
    id: content
    width: parent.width
    spacing: Style.space(12)

    PanelHero {
      width: parent.width
      title: "Horizon Display Layout"
      meta: root.verified ? "Fix verified by Horizon" : (root.ready ? "Ready to verify" : "Preparing compatibility")
      foreground: root.foreground
      iconOpacity: root.verified ? 1.0 : 0.55
      iconComponent: Component {
        HorizonDisplayIcon {
          iconSize: Style.font.display
          color: root.foreground
          iconOpacity: root.verified ? 1.0 : 0.55
        }
      }
    }

    Text {
      width: parent.width
      text: root.controller ? root.controller.layoutStatus : "Service unavailable."
      color: root.dim
      font.family: "monospace"
      font.pixelSize: Style.font.caption
      wrapMode: Text.WrapAnywhere
    }

    Rectangle {
      width: parent.width
      implicitHeight: resultText.implicitHeight + Style.space(20)
      radius: Style.cornerRadius
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, root.verified ? 0.12 : 0.05)
      border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, root.verified ? 0.45 : 0.14)
      border.width: 1

      Text {
        id: resultText
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Style.space(10)
        text: root.controller ? root.controller.verificationResult : "Not verified."
        color: root.verified ? root.foreground : root.dim
        font.family: "monospace"
        font.pixelSize: Style.font.caption
        font.bold: root.verified
        wrapMode: Text.WrapAnywhere
      }
    }

    Row {
      width: parent.width
      spacing: Style.space(10)

      CursorSurface {
        width: (parent.width - parent.spacing) / 2
        implicitHeight: verifyLabel.implicitHeight + Style.space(20)
        foreground: root.foreground
        bordered: true
        enabled: root.ready && !root.busy
        Text {
          id: verifyLabel
          anchors.centerIn: parent
          text: root.busy ? "Verifying…" : "Verify fix"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
        }
        MouseArea {
          anchors.fill: parent
          enabled: parent.enabled
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: if (root.controller) root.controller.verify()
        }
      }

      CursorSurface {
        width: (parent.width - parent.spacing) / 2
        implicitHeight: launchLabel.implicitHeight + Style.space(20)
        foreground: root.foreground
        bordered: true
        enabled: root.ready && !root.busy
        Text {
          id: launchLabel
          anchors.centerIn: parent
          text: "Launch Horizon"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
        }
        MouseArea {
          anchors.fill: parent
          enabled: parent.enabled
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: if (root.controller) root.controller.launch()
        }
      }
    }

    Text {
      width: parent.width
      text: "Verify asks Horizon itself to enumerate monitors through the fix. V verifies · L launches · R refreshes · Esc closes"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
  }
}
