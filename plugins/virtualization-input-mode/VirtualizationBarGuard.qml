import QtQuick
import Quickshell.Io

Item {
  id: root
  required property string pluginDir

  // One-time compatibility cleanup; never hide the control used to exit mode.
  Component.onCompleted: restoreCommand.running = true

  Process {
    id: restoreCommand
    command: [root.pluginDir + "/scripts/virtualization-bar", "restore"]
    onExited: function(exitCode) {
      if (exitCode !== 0)
        console.warn("Virtualization Input Mode: could not restore the previously hidden bar")
    }
  }
}
