import QtQuick
import qs.Commons
import qs.Ui as Ui

Ui.BarWidget {
  id: root
  moduleName: "io.github.tbogard.horizon-screens"
  property var layoutService: null
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
  function resolveService() {
    if (bar && bar.shell) layoutService = bar.shell.serviceFor(moduleName)
  }
  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.layoutService = root.layoutService
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: { resolveService(); injectPanel() }
  onLayoutServiceChanged: injectPanel()

  Timer {
    interval: 250
    running: !root.layoutService
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
      HorizonDisplayIcon {
        anchors.centerIn: parent
        iconSize: 20
        color: root.bar ? root.bar.foreground : "white"
        iconOpacity: root.layoutService && root.layoutService.aligned ? 1.0 : 0.55
      }
    }
    tooltipText: root.layoutService && root.layoutService.aligned
      ? "Horizon screens: aligned"
      : "Horizon screens: open recovery controls"
    onPressed: function(buttonCode) { if (buttonCode === Qt.LeftButton) root.toggle() }
  }
}
