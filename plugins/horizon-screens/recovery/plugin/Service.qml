import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property var manifest: null
  readonly property string pluginDir: manifest && manifest.__sourceDir
    ? manifest.__sourceDir
    : Quickshell.env("HOME") + "/.config/omarchy/plugins/io.github.tbogard.horizon-display-layout"
  property bool ready: false
  property bool busy: false
  property bool verified: false
  property string message: "Preparing Horizon display compatibility…"
  property string layoutStatus: "Reading monitor layouts…"
  property string verificationResult: "Not verified in this login session."

  function setup() {
    if (busy) return
    busy = true
    setupCommand.command = [pluginDir + "/scripts/horizon-display-layout", "setup"]
    setupCommand.running = true
  }

  function launch() {
    if (!ready || launchCommand.running) return
    launchCommand.command = [pluginDir + "/scripts/horizon-display-layout", "launch"]
    launchCommand.running = true
    message = "Launching Horizon with the Hyprland display layout…"
  }

  function refresh() {
    if (statusCommand.running) return
    statusCommand.command = [pluginDir + "/scripts/horizon-display-layout", "status"]
    statusCommand.running = true
  }

  function verify() {
    if (!ready || busy) return
    busy = true
    verified = false
    verificationResult = "Asking Horizon to enumerate the corrected layout…"
    verifyCommand.command = [pluginDir + "/scripts/horizon-display-layout", "verify"]
    verifyCommand.running = true
  }

  Process {
    id: setupCommand
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
      root.busy = false
      root.ready = exitCode === 0
      if (root.ready) root.refresh()
      if (exitCode !== 0 && root.message === "")
        root.message = "Could not build Horizon display compatibility."
    }
  }

  Process {
    id: statusCommand
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.layoutStatus = String(text || "").trim()
    }
  }

  Process {
    id: verifyCommand
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text).trim() !== "") root.verificationResult = String(text).trim()
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text).trim() !== "") root.verificationResult = String(text).trim()
    }
    onExited: function(exitCode) {
      root.busy = false
      root.verified = exitCode === 0
      root.message = root.verified
        ? "Verified: Horizon matches the Hyprland display layout."
        : "Horizon layout verification failed."
    }
  }

  Process {
    id: launchCommand
    command: []
    onExited: function(exitCode) {
      root.message = exitCode === 0
        ? "Horizon closed. Display compatibility is ready."
        : "Horizon exited with an error."
    }
  }

  Component.onCompleted: root.setup()
}
