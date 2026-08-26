import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.tbogard.yamaha-mg-xu"

  readonly property string pluginDir: Quickshell.env("HOME") + "/.config/omarchy/plugins/" + moduleName
  property bool detected: false
  property bool enabled: false
  property bool active: false
  property bool busy: false
  property string message: "Checking Yamaha MG-XU…"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  // Match Omarchy's symbolic tray icons so the badge follows every bar theme.
  readonly property color widgetForeground: bar ? bar.foreground : Color.foreground
  readonly property color badgeColor: active ? widgetForeground : Qt.darker(widgetForeground, 1.55)

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
  }

  function refresh() {
    if (statusProcess.running) return
    statusProcess.command = [pluginDir + "/scripts/status.sh", "--machine"]
    statusProcess.running = true
  }

  function applyStatus(text) {
    var lines = String(text || "").trim().split("\n")
    var values = {}
    for (var i = 0; i < lines.length; i++) {
      var separator = lines[i].indexOf("=")
      if (separator > 0) values[lines[i].substring(0, separator)] = lines[i].substring(separator + 1)
    }
    detected = values.detected === "yes"
    enabled = values.enabled === "yes"
    active = values.active === "yes"
    message = values.message || (active ? "Compatibility layer is active" : "Compatibility layer is off")
    busy = false
  }

  function setCompatibility(on) {
    if (busy || !detected) return
    busy = true
    actionProcess.command = [pluginDir + "/scripts/toggle.sh", on ? "on" : "off"]
    actionProcess.running = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()
  Component.onCompleted: refresh()

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProcess
    command: []
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyStatus(text) }
  }

  Process {
    id: actionProcess
    command: []
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.message = String(text).trim() }
    onExited: function(exitCode) {
      root.busy = false
      root.refresh()
    }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      YamahaIcon {
        anchors.centerIn: parent
        iconSize: Style.space(12)
        color: root.badgeColor
        opacity: root.active ? 1.0 : 0.6
      }
    }
    tooltipText: root.active
      ? "Yamaha MG-XU: compatibility on"
      : (root.detected ? "Turn on if your MG-XU loses sound after a few seconds" : "Yamaha MG-XU: not detected")
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.setCompatibility(!root.active)
      else root.toggle()
    }
  }
}
