import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root
  property var controller: null
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property bool showingLog: false
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property bool active: controller ? controller.active : false
  readonly property bool busy: controller ? controller.busy : false
  readonly property bool ready: controller ? controller.ready : false
  signal dismissRequested()

  implicitHeight: showingLog ? logContent.implicitHeight : mainContent.implicitHeight

  function openLog() {
    showingLog = true
    if (controller) controller.refresh()
  }
  function goBack() {
    if (showingLog) showingLog = false
    else dismissRequested()
  }
  function activate() {
    if (controller && ready && !busy) controller.setActive(!active)
  }
  function handleTextKey(t) {
    if ((t === "l" || t === "L") && controller) openLog()
    else if ((t === "t" || t === "T") && !showingLog) activate()
    else if ((t === "r" || t === "R") && controller) controller.refresh()
  }

  Column {
    id: mainContent
    width: parent.width
    spacing: Style.space(12)
    visible: !root.showingLog

    PanelHero {
      width: parent.width
      title: "Virtualization Input Mode"
      meta: root.active ? "Passing shortcuts to the guest" : "Omarchy shortcuts active"
      foreground: root.foreground
      iconOpacity: root.active ? 1.0 : 0.55
      iconComponent: Component {
        VirtualizationIcon {
          iconSize: Style.font.display
          color: root.foreground
          iconOpacity: root.active ? 1.0 : 0.55
        }
      }
      trailingControl: Component {
        ToggleSwitch {
          checked: root.active
          busy: root.busy
          enabled: root.ready
          foreground: root.foreground
          onToggled: root.activate()
        }
      }
    }

    Text {
      width: parent.width
      text: root.controller ? root.controller.message : "Service unavailable."
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width
      text: root.active
        ? "Alt+Tab and Super shortcuts now pass through to the guest application. Press Super+Ctrl+Escape at any time to restore Omarchy shortcuts."
        : "Turn this on for a VM, VDI, remote desktop, nested compositor, or other application that must receive shortcuts normally handled by Omarchy."
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    Text {
      width: parent.width
      text: {
        if (!root.controller || !root.controller.vdiActive)
          return "VDI status: No Horizon desktop detected"
        return "VDI status: Active (" + root.controller.vdiCount + ")\n"
          + root.controller.vdiNames.join("\n")
      }
      color: root.controller && root.controller.vdiActive ? root.foreground : root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
    }

    CursorSurface {
      width: parent.width
      implicitHeight: logLabel.implicitHeight + Style.space(20)
      foreground: root.foreground
      bordered: true
      Text {
        id: logLabel
        anchors.left: parent.left
        anchors.right: logArrow.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Style.space(12)
        text: "Diagnostic log"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }
      Text {
        id: logArrow
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
        onClicked: root.openLog()
      }
    }

    Text {
      width: parent.width
      text: "Click Diagnostic log or press L · T toggles · R refreshes · Esc closes"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
  }

  Column {
    id: logContent
    width: parent.width
    spacing: Style.space(12)
    visible: root.showingLog

    CursorSurface {
      width: parent.width
      implicitHeight: backLabel.implicitHeight + Style.space(16)
      foreground: root.foreground
      Text {
        id: backLabel
        anchors.verticalCenter: parent.verticalCenter
        text: "‹  Virtualization Input Mode"
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
      text: "Diagnostic log"
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.subtitle
      font.bold: true
    }

    Flickable {
      width: parent.width
      height: Style.space(320)
      contentWidth: width
      contentHeight: logText.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      Text {
        id: logText
        width: parent.width
        text: root.controller ? root.controller.diagnosticLog : "Service unavailable."
        color: root.dim
        font.family: "monospace"
        font.pixelSize: Style.font.caption
        wrapMode: Text.WrapAnywhere
      }
    }

    Text {
      width: parent.width
      text: "R refreshes · Esc returns"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }
}
