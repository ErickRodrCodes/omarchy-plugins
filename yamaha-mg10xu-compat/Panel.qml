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
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: if (root.detected && root.hostWidget) root.hostWidget.setCompatibility(!root.active)
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if ((t === "t" || t === "T") && root.detected && root.hostWidget)
          root.hostWidget.setCompatibility(!root.active)
        else if ((t === "r" || t === "R") && root.hostWidget) root.hostWidget.refresh()
      }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)

        PanelHero {
          width: parent.width
          title: "Yamaha MG-XU"
          meta: root.active ? "Compatibility layer active" : (root.detected ? "Compatibility layer off" : "Mixer not detected")
          foreground: root.foreground
          iconComponent: Component {
            YamahaIcon {
              iconSize: Style.font.display
              color: root.active ? "#8fcf76" : root.dim
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
      }
    }
  }
}
