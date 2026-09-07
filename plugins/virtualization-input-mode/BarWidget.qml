import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui as Ui

Ui.BarWidget {
  id: root
  moduleName: "io.github.tbogard.virtualization-input-mode"
  property var inputService: null
  readonly property bool active: inputService ? inputService.active : false
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  // Each widget controls its own monitor's bar surface. Keep the surface
  // alive beneath guest windows, including borderless spanning VDIs.
  readonly property var barWindow: root.QsWindow.window
  Binding {
    target: root.barWindow ? root.barWindow.WlrLayershell : null
    property: "layer"
    value: WlrLayer.Bottom
    when: root.active && root.barWindow !== null
    restoreMode: Binding.RestoreBindingOrValue
  }

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
  function resolveService() {
    if (bar && bar.shell) inputService = bar.shell.serviceFor(moduleName)
  }
  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.inputService = root.inputService
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: { resolveService(); injectPanel() }
  onInputServiceChanged: injectPanel()

  Timer {
    interval: 250
    running: !root.inputService
    repeat: true
    triggeredOnStart: true
    onTriggered: root.resolveService()
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
  }

  Ui.BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      VirtualizationIcon {
        anchors.centerIn: parent
        iconSize: 20
        color: root.bar ? root.bar.foreground : "white"
        iconOpacity: root.active ? 1.0 : 0.55
      }
    }
    tooltipText: root.active ? "Virtualization input mode: on" : "Virtualization input mode: off"
    onPressed: function(buttonCode) { if (buttonCode === Qt.LeftButton) root.toggle() }
  }
}
