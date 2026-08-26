import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.tbogard.yamaha-mg-xu"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property bool detected: hostWidget ? hostWidget.detected : false
  readonly property bool active: hostWidget ? hostWidget.active : false
  readonly property bool busy: hostWidget ? hostWidget.busy : false
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  property bool showingActivity: false

  function open() { controller.show() }
  function close() { controller.hide() }
  function switchPanel(direction) {
    if (bar && typeof bar.switchPanelFrom === "function")
      return bar.switchPanelFrom(hostWidget || root, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(root.showingActivity ? activityContent.implicitHeight : content.implicitHeight, Style.space(520))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: {
        if (root.showingActivity && root.hostWidget) root.hostWidget.refreshActivity()
        else if (root.detected && root.hostWidget) root.hostWidget.setCompatibility(!root.active)
      }
      onCloseRequested: {
        if (root.showingActivity) root.showingActivity = false
        else root.close()
      }
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if ((t === "l" || t === "L") && root.hostWidget) {
          root.showingActivity = true
          root.hostWidget.refreshActivity()
        } else if ((t === "c" || t === "C") && root.showingActivity && root.hostWidget) {
          root.hostWidget.clearActivity()
        } else if ((t === "t" || t === "T") && root.detected && root.hostWidget)
          root.hostWidget.setCompatibility(!root.active)
        else if ((t === "r" || t === "R") && root.hostWidget) {
          if (root.showingActivity) root.hostWidget.refreshActivity()
          else root.hostWidget.refresh()
        }
      }

      Column {
        id: content
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
              onToggled: if (root.hostWidget) root.hostWidget.setCompatibility(!root.active)
            }
          }
        }

        Text {
          width: parent.width
          text: root.hostWidget ? root.hostWidget.message : "Checking status…"
          color: root.dim
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width
          text: "Turn this on if your MG-XU mixer loses playback sound after a few seconds. The user service keeps its capture side active and discards samples to /dev/null. No audio is saved or transmitted."
          color: root.dim
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
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
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
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
            onClicked: {
              root.showingActivity = true
              if (root.hostWidget) root.hostWidget.refreshActivity()
            }
          }
        }

        Text {
          width: parent.width
          text: "Click Activity log or press L to open it · T toggles · R refreshes · Esc closes"
          color: root.dim
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
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
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showingActivity = false
          }
        }

        Text {
          text: "Activity log"
          color: root.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
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
            text: root.hostWidget ? root.hostWidget.activityLog : "No activity available."
            color: root.dim
            font.family: "monospace"
            font.pixelSize: Style.font.caption
            wrapMode: Text.WrapAnywhere
          }
        }

        Text {
          width: parent.width
          text: root.hostWidget && root.hostWidget.activityBusy ? "Working…" : "Enter or R refreshes · C clears · Esc returns"
          color: root.dim
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
