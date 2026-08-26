import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property var manifest: null
  readonly property string pluginDir: manifest && manifest.__sourceDir
    ? manifest.__sourceDir
    : Quickshell.env("HOME") + "/.config/omarchy/plugins/io.github.tbogard.yamaha-mg-xu"

  property bool detected: false
  property bool enabled: false
  property bool active: false
  property bool busy: false
  property string message: "Checking Yamaha MG-XU…"
  property string activityLog: "Loading activity…"
  property bool activityBusy: false

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

  function refreshActivity() {
    if (activityProcess.running) return
    activityBusy = true
    activityProcess.command = [pluginDir + "/scripts/activity-log.sh", "60"]
    activityProcess.running = true
  }

  function clearActivity() {
    if (activityProcess.running) return
    activityBusy = true
    activityProcess.command = [pluginDir + "/scripts/activity-log.sh", "--clear"]
    activityProcess.running = true
  }

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
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text).trim() !== "") root.message = String(text).trim()
    }
    onExited: function(exitCode) {
      root.busy = false
      root.refresh()
      root.refreshActivity()
    }
  }

  Process {
    id: activityProcess
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.activityLog = String(text).trim()
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text).trim() !== "") root.activityLog = String(text).trim()
    }
    onExited: root.activityBusy = false
  }

  Component.onCompleted: refresh()
}
