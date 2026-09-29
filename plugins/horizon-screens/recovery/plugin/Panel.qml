import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.tbogard.horizon-display-layout"
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  property var layoutService: null

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
    contentWidth: panel.fittedContentWidth(Style.space(460))
    contentHeight: panel.fittedContentHeight(view.implicitHeight, Style.space(620))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: view.activate()
      onCloseRequested: view.dismissRequested()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) { view.handleTextKey(t) }

      LayoutView {
        id: view
        width: parent.width
        controller: root.layoutService
        foreground: root.bar ? root.bar.foreground : Color.foreground
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        onDismissRequested: root.close()
      }
    }
  }
}
