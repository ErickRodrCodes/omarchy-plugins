import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null
  property var service: null
  property bool opened: false

  function open(payloadJson) {
    opened = true
    view.showingActivity = false
    if (service) service.refresh()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function dismiss() {
    opened = false
    if (shell && typeof shell.hide === "function")
      shell.hide((manifest && manifest.id) || "io.github.tbogard.yamaha-mg-xu")
  }

  function close() { dismiss() }
  function toggle() { if (opened) dismiss(); else open("{}") }

  PanelWindow {
    id: window
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "yamaha-mg-xu-compat"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: Math.min(Style.space(640), window.width - Style.gapsOut * 2)
      height: Math.min(view.implicitHeight + Style.spacing.panelPadding * 2, window.height - Style.gapsOut * 2)
      anchors.centerIn: parent
      radius: Style.cornerRadius
      color: Color.menu.background
      borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(1)))

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            view.goBack()
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            view.activate()
            event.accepted = true
          } else if (event.text && event.text.length === 1) {
            view.handleTextKey(event.text)
            event.accepted = true
          }
        }

        CompatibilityView {
          id: view
          anchors.fill: parent
          anchors.margins: Style.spacing.panelPadding
          controller: root.service
          foreground: Color.foreground
          fontFamily: Style.font.family
          expanded: true
          onDismissRequested: root.dismiss()
        }
      }
    }
  }
}
