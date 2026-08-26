import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property var controller: null
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property bool expanded: false
  property bool showingActivity: false
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property bool detected: controller ? controller.detected : false
  readonly property bool active: controller ? controller.active : false
  readonly property bool busy: controller ? controller.busy : false

  signal dismissRequested()

  implicitHeight: showingActivity ? activityContent.implicitHeight : mainContent.implicitHeight

  function openActivity() {
    showingActivity = true
    if (controller) controller.refreshActivity()
  }

  function goBack() {
    if (showingActivity) showingActivity = false
    else dismissRequested()
  }

  function activate() {
    if (showingActivity && controller) controller.refreshActivity()
    else if (detected && controller) controller.setCompatibility(!active)
  }

  function handleTextKey(t) {
    if ((t === "l" || t === "L") && controller) openActivity()
    else if ((t === "c" || t === "C") && showingActivity && controller) controller.clearActivity()
    else if ((t === "t" || t === "T") && detected && controller) controller.setCompatibility(!active)
    else if ((t === "r" || t === "R") && controller) {
      if (showingActivity) controller.refreshActivity()
      else controller.refresh()
    }
  }

  Column {
    id: mainContent
    width: parent.width
    spacing: Style.space(12)
    visible: !root.showingActivity

    PanelHero {
      width: parent.width
      title: "Yamaha MG-XU"
      meta: root.active ? "Compatibility layer active" : (root.detected ? "Compatibility layer off" : "No device found")
      foreground: root.foreground
      iconOpacity: root.active ? 1.0 : 0.5
      iconComponent: Component {
        YamahaIcon {
          iconSize: Style.font.display
          color: root.active ? root.foreground : root.dim
        }
      }
      trailingControl: Component {
        ToggleSwitch {
          checked: root.active
          busy: root.busy
          enabled: root.detected
          foreground: root.foreground
          onToggled: if (root.controller) root.controller.setCompatibility(!root.active)
        }
      }
    }

    Text {
      width: parent.width
      text: root.controller ? root.controller.message : "Checking status…"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width
      text: "Turn this on if your MG-XU mixer loses playback sound after a few seconds. The user service keeps its capture side active and discards samples to /dev/null. No audio is saved or transmitted."
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    CursorSurface {
      width: parent.width
      implicitHeight: activityLabel.implicitHeight + Style.space(20)
      foreground: root.foreground
      bordered: true

      Text {
        id: activityLabel
        anchors.left: parent.left
        anchors.right: activityArrow.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Style.space(12)
        text: "Activity log"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }

      Text {
        id: activityArrow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Style.space(12)
        text: "›"
        color: root.dim
        font.pixelSize: Style.font.subtitle
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openActivity()
      }
    }

    Text {
      width: parent.width
      text: "Click Activity log or press L to open it · T toggles · R refreshes · Esc closes"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
  }

  Column {
    id: activityContent
    width: parent.width
    spacing: Style.space(12)
    visible: root.showingActivity

    CursorSurface {
      width: parent.width
      implicitHeight: backLabel.implicitHeight + Style.space(16)
      foreground: root.foreground

      Text {
        id: backLabel
        anchors.verticalCenter: parent.verticalCenter
        text: "‹  Compatibility layer"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.goBack()
      }
    }

    Text {
      text: "Activity log"
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.subtitle
      font.bold: true
    }

    Flickable {
      width: parent.width
      height: root.expanded ? Style.space(420) : Style.space(320)
      contentWidth: width
      contentHeight: logText.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Text {
        id: logText
        width: parent.width
        text: root.controller ? root.controller.activityLog : "No activity available."
        color: root.dim
        font.family: "monospace"
        font.pixelSize: Style.font.caption
        wrapMode: Text.WrapAnywhere
      }
    }

    Text {
      width: parent.width
      text: root.controller && root.controller.activityBusy ? "Working…" : "Enter or R refreshes · C clears · Esc returns"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }
}
