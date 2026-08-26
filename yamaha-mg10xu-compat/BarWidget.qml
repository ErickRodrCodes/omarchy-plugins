import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.tbogard.yamaha-mg-xu"

  readonly property var compatibilityService: bar && bar.shell
    ? bar.shell.serviceFor(moduleName)
    : null
  readonly property bool detected: compatibilityService ? compatibilityService.detected : false
  readonly property bool active: compatibilityService ? compatibilityService.active : false

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  readonly property color widgetForeground: bar ? bar.foreground : Color.foreground
  readonly property color badgeColor: active ? widgetForeground : Qt.darker(widgetForeground, 1.55)

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.compatibilityService = root.compatibilityService
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()
  onCompatibilityServiceChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      YamahaIcon {
        anchors.centerIn: parent
        iconSize: Style.space(12)
        color: root.badgeColor
        opacity: root.active ? 1.0 : 0.6
      }
    }
    tooltipText: root.active
      ? "Yamaha MG-XU: compatibility on"
      : (root.detected ? "Turn on if your MG-XU loses sound after a few seconds" : "Yamaha MG-XU: no device found")
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }
}
