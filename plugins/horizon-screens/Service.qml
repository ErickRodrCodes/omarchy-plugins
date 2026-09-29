import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property var shell: null
    property var manifest: null
    readonly property string pluginDir: manifest && manifest.__sourceDir
        ? manifest.__sourceDir
        : Quickshell.env("HOME") + "/.config/omarchy/plugins/io.github.tbogard.horizon-screens"
    property bool busy: false
    property bool known: false
    property bool running: true
    property bool canAlign: false
    property bool aligned: false
    property string summary: "Check the current screens"
    property string details: ""
    property string message: "Use Align screens when the remote desktop is shifted."
    property bool lastSuccess: true
    property string pendingAction: ""
    property string output: ""
    property string launcherText: ""
    property string launcherCommand: ""

    function execute(action, payload) {
        if (busy) return
        if (action === "fix" && (!known || !canAlign)) return
        if ((action === "restore" || action === "verify" || action === "repair-input" || action === "undo-input") && (!known || running)) return
        busy = true
        pendingAction = action
        output = ""
        command.command = payload === undefined ? [pluginDir + "/backend", action] : [pluginDir + "/backend", action, payload]
        command.running = true
    }
    function refresh() { execute("status") }

    Process {
        id: command
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.output = text
        }
        onExited: function(exitCode) {
            root.busy = false
            try {
                const result = JSON.parse(root.output)
                if (root.pendingAction === "status") {
                    root.known = result.ok === true && exitCode === 0
                    root.running = !root.known || result.running === true
                    root.canAlign = root.known && result.canAlign === true
                    root.aligned = root.known && result.aligned === true
                    root.summary = result.summary || "Check failed"
                    root.details = result.details || result.message || ""
                    root.launcherText = (result.launchers || []).join("\n")
                    root.launcherCommand = result.launcherCommand || ""
                } else {
                    root.lastSuccess = result.ok === true && exitCode === 0
                    root.message = result.message || "No result returned"
                    Qt.callLater(root.refresh)
                }
            } catch (error) {
                root.known = false
                root.running = true
                root.canAlign = false
                root.aligned = false
                root.summary = "Unable to check screens"
                root.message = "The recovery command failed. Check the plugin installation."
                root.lastSuccess = false
            }
        }
    }
    // Deliberately no setup, compilation, Horizon diagnostics, or moves on load.
    Component.onCompleted: root.refresh()
}
