import QtQuick
import qs.Commons
import qs.Ui

Item {
    id: root
    property var controller: null
    property color foreground: Color.foreground
    property string fontFamily: Style.font.family
    readonly property bool busy: !controller || controller.busy
    property bool editLaunchers: false
    readonly property bool editingShortcuts: shortcuts.activeFocus
    signal dismissRequested()
    implicitHeight: content.implicitHeight
    function activate() { if (controller) controller.execute("fix") }
    function handleTextKey(t) {
        if (!controller) return
        if (t.toLowerCase() === "a") controller.execute("fix")
        else if (t.toLowerCase() === "r") controller.refresh()
    }

    Column {
        id: content
        width: parent.width
        spacing: Style.space(12)
        PanelHero {
            width: parent.width
            title: "Horizon Screens"
            meta: root.controller ? root.controller.summary : "Service unavailable"
            foreground: root.foreground
            iconComponent: Component { HorizonDisplayIcon { iconSize: Style.font.display } }
        }
        Text {
            width: parent.width
            text: root.controller ? root.controller.details : ""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
        }
        CursorSurface {
            width: parent.width
            implicitHeight: Style.space(38)
            foreground: root.foreground
            bordered: true
            Text { anchors.centerIn: parent; text: "Launcher shortcuts ▾"; color: root.foreground; font.family: root.fontFamily }
            MouseArea { anchors.fill: parent; onClicked: root.editLaunchers = !root.editLaunchers }
        }
        Column {
            visible: root.editLaunchers
            width: parent.width
            spacing: Style.space(8)
            Text {
                width: parent.width
                text: "Shortcuts to repair — one .desktop path per line. Review this list and save it before Restore. System shortcuts get a user override."
                wrapMode: Text.Wrap
                color: root.foreground
                font.pixelSize: Style.font.caption
            }
            Rectangle {
                width: parent.width
                height: Style.space(105)
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                border.color: root.foreground
                clip: true
                TextEdit {
                    id: shortcuts
                    anchors.fill: parent
                    anchors.margins: Style.space(8)
                    text: root.controller ? root.controller.launcherText : ""
                    color: root.foreground
                    font.pixelSize: Style.font.caption
                    wrapMode: TextEdit.WrapAnywhere
                    selectByMouse: true
                    Keys.onEscapePressed: { focus = false; root.dismissRequested() }
                }
            }
            CursorSurface {
                width: parent.width
                implicitHeight: Style.space(36)
                foreground: root.foreground
                bordered: true
                enabled: !root.busy
                Text { anchors.centerIn: parent; text: "Save shortcut selection"; color: root.foreground }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        const paths = shortcuts.text.split("\n").map(s => s.trim()).filter(s => s.length > 0)
                        root.controller.execute("save-launchers", JSON.stringify(paths))
                    }
                }
            }
            Text { text: "Command for a custom launcher (select to copy):"; color: root.foreground; font.pixelSize: Style.font.caption }
            TextEdit {
                width: parent.width
                text: root.controller ? root.controller.launcherCommand : ""
                color: root.foreground
                font.pixelSize: Style.font.caption
                wrapMode: TextEdit.WrapAnywhere
                readOnly: true
                selectByMouse: true
            }
        }
        Repeater {
            model: [
                {label: "Align screens", action: "fix", hint: "Align the running desktop after checking screen and mouse boundaries."},
                {label: "Repair screens and mouse", action: "repair-input", hint: "Quit Horizon first. Match screen positions and mouse boundaries to your current display arrangement."},
                {label: "Undo input layout", action: "undo-input", hint: "Quit Horizon first. Restore the normal XWayland arrangement."},
                {label: "Check screens", action: "status", hint: "Read the current monitor and window positions."},
                {label: "Verify launch fix", action: "verify", hint: "Check Horizon's monitor order while it is closed."},
                {label: "Restore launch fix", action: "restore", hint: "Rebuild compatibility and repair launchers with backups."}
            ]
            delegate: CursorSurface {
                required property var modelData
                width: content.width
                implicitHeight: labels.implicitHeight + Style.space(16)
                foreground: root.foreground
                bordered: true
                enabled: !root.busy && (modelData.action === "status"
                    || (modelData.action === "fix" ? root.controller.known && root.controller.canAlign
                        : root.controller.known && !root.controller.running))
                opacity: enabled ? 1 : 0.4
                Column {
                    id: labels
                    x: Style.space(10)
                    y: Style.space(8)
                    width: parent.width - Style.space(20)
                    spacing: Style.space(3)
                    Text {
                        width: parent.width
                        text: modelData.label
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.body
                        font.bold: true
                    }
                    Text {
                        width: parent.width
                        text: modelData.hint
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        wrapMode: Text.Wrap
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.controller.execute(modelData.action)
                }
            }
        }
        Text {
            width: parent.width
            text: root.controller && root.controller.running
                ? "Quit Horizon to repair input layout, Verify, or Restore. Align requires matching display coordinates."
                : "After restoring: open Horizon, select All Screens, then Align screens."
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
        }
        Text {
            width: parent.width
            text: root.busy ? "Working…" : (root.controller ? root.controller.message : "")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 8
            elide: Text.ElideRight
        }
    }
}
