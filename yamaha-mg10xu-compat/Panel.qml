import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.tbogard.yamaha-mg-xu"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var compatibilityService: null

  function open() { controller.show() }
  function close() { controller.hide() }
  function switchPanel(direction) {
    if (bar && typeof bar.switchPanelFrom === "function")
      return bar.switchPanelFrom(hostWidget || root, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(view.implicitHeight, Style.space(520))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: view.activate()
      onCloseRequested: view.goBack()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) { view.handleTextKey(t) }

      CompatibilityView {
        id: view
        width: parent.width
        controller: root.compatibilityService
        foreground: root.bar ? root.bar.foreground : Color.foreground
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        onDismissRequested: root.close()
      }
    }
  }
}
