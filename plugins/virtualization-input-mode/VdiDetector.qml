import QtQuick
import Quickshell.Io

Item {
  id: root

  property bool active: false
  property int count: 0
  property var names: []

  function refresh() {
    if (clientQuery.running) return
    clientQuery.command = ["hyprctl", "clients", "-j"]
    clientQuery.running = true
  }

  function applyClientList(output) {
    var clients
    try {
      clients = JSON.parse(String(output || "[]"))
    } catch (error) {
      active = false
      count = 0
      names = []
      return
    }

    var detectedNames = []
    clients.forEach(function(window) {
      if (window.class === "Horizon-client"
          && window.title !== "Omnissa Horizon Client")
        detectedNames.push(window.title || "Horizon desktop")
    })
    names = detectedNames
    count = detectedNames.length
    active = count > 0
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: clientQuery
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyClientList(text)
    }
  }
}
