import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var shell: null
  property var manifest: null
  readonly property string pluginDir: manifest && manifest.__sourceDir
    ? manifest.__sourceDir
    : Quickshell.env("HOME") + "/.config/omarchy/plugins/io.github.tbogard.virtualization-input-mode"
  property bool ready: false
  property bool active: false
  property bool busy: false
  property string diagnosticLog: "Loading diagnostic log…"
  readonly property bool vdiActive: vdiDetector.active
  readonly property int vdiCount: vdiDetector.count
  readonly property var vdiNames: vdiDetector.names
  property string message: ready ? (active
    ? "Omarchy shortcuts are paused. Guest applications receive Alt+Tab and Super shortcuts."
    : "Omarchy shortcuts are active.") : "Preparing virtualization input mode…"

  readonly property string submapName: "virtualization-input"

  VdiDetector {
    id: vdiDetector
  }

  // Recover a bar hidden by older plugin versions. Input mode itself
  // leaves bar visibility and fullscreen stacking to the compositor.
  VirtualizationBarGuard {
    pluginDir: root.pluginDir
  }
  function setActive(enabled) {
    if (!ready || busy) return
    busy = true
    modeCommand.command = [pluginDir + "/scripts/input-mode", enabled ? "on" : "off"]
    modeCommand.running = true
  }

  function refresh() {
    if (!statusQuery.running) {
      statusQuery.command = ["hyprctl", "submap"]
      statusQuery.running = true
    }
    if (!logQuery.running) {
      logQuery.command = [pluginDir + "/scripts/input-mode", "log"]
      logQuery.running = true
    }
  }

  Timer {
    interval: 1000
    running: root.ready
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: setupCommand
    command: [root.pluginDir + "/scripts/input-mode", "setup"]
    onExited: function(exitCode) {
      root.ready = exitCode === 0
      if (root.ready) root.refresh()
      else root.message = "Could not register virtualization input mode."
    }
  }

  Process {
    id: modeCommand
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text).trim() !== "") root.message = String(text).trim()
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text).trim() !== "") root.message = String(text).trim()
    }
    onExited: function(exitCode) {
      if (exitCode !== 0 && root.message === "") root.message = "Hyprland rejected the input-mode change."
      statusQuery.command = ["hyprctl", "submap"]
      statusQuery.running = true
    }
  }

  Process {
    id: statusQuery
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.active = String(text || "").trim() === root.submapName
        root.busy = false
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.busy = false
        root.message = "Could not read the active Hyprland keymap."
      }
    }
  }

  Process {
    id: logQuery
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.diagnosticLog = String(text || "").trim()
    }
  }

  Component.onCompleted: setupCommand.running = true
}
