import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "GameOfLife.js" as Engine

Panel {
  id: root
  moduleName: "io.github.guillechuma.gameoflife"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property int cols: Math.max(8, parseInt(setting("cols", "48")))
  readonly property int rows: Math.max(8, parseInt(setting("rows", "32")))
  readonly property real speed: Math.max(1, parseFloat(setting("speed", "8")))
  readonly property bool wrap: setting("wrap", true) === true || setting("wrap", true) === "true"
  readonly property real trail: Math.min(1, Math.max(0, parseFloat(setting("trail", "0.35"))))

  property var grid: []
  property bool playing: true
  property int generation: 0
  property bool fullRepaint: true

  readonly property color bgColor: (root.bar && root.bar.barBackground)
    ? root.bar.barBackground
    : Color.background

  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { if (root.opened) root.close(); else root.open() }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function tick() {
    root.grid = Engine.step(root.grid, root.cols, root.rows, root.wrap)
    root.generation++
    canvas.requestPaint()
  }

  function doRandom() {
    Engine.randomize(root.grid, root.cols, root.rows, 0.28)
    root.generation = 0
    root.fullRepaint = true
    canvas.requestPaint()
  }

  function doClear() {
    Engine.clear(root.grid, root.cols, root.rows)
    root.generation = 0
    root.fullRepaint = true
    canvas.requestPaint()
  }

  function doSeed(type) {
    Engine.clear(root.grid, root.cols, root.rows)
    Engine.seed(root.grid, root.cols, root.rows, type)
    root.generation = 0
    root.fullRepaint = true
    canvas.requestPaint()
  }

  function paintCell(px, py, alive) {
    var cw = canvas.width / root.cols
    var ch = canvas.height / root.rows
    var x = Math.floor(px / cw)
    var y = Math.floor(py / ch)
    if (x >= 0 && y >= 0 && x < root.cols && y < root.rows) {
      root.grid[y * root.cols + x] = alive ? 1 : 0
      root.fullRepaint = true
      canvas.requestPaint()
    }
  }

  Component.onCompleted: {
    root.grid = Engine.makeGrid(root.cols, root.rows)
    Engine.randomize(root.grid, root.cols, root.rows, 0.28)
  }

  Timer {
    id: timer
    interval: Math.max(16, Math.round(1000 / root.speed))
    running: root.playing && root.opened
    repeat: true
    onTriggered: root.tick()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(canvasWrap.width + Style.space(24))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      Keys.onPressed: function(e) {
        if (e.key === Qt.Key_Space) { root.playing = !root.playing; e.accepted = true }
        else if (e.key === Qt.Key_R) { root.doRandom(); e.accepted = true }
        else if (e.key === Qt.Key_C) { root.doClear(); e.accepted = true }
      }

      component GLButton : Rectangle {
        property string label
        signal clicked()
        width: txt.implicitWidth + 16
        height: txt.implicitHeight + 10
        radius: 6
        color: ma.containsPress
          ? Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.28)
          : Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.12)
        border.color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.4)
        border.width: 1
        Text {
          id: txt
          anchors.centerIn: parent
          text: label
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.small
        }
        MouseArea {
          id: ma
          anchors.fill: parent
          onClicked: parent.clicked()
        }
      }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(8)

        Rectangle {
          id: canvasWrap
          width: root.cols * 14
          height: root.rows * 14
          radius: 8
          color: Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 1)
          border.color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.35)
          border.width: 1

          Canvas {
            id: canvas
            anchors.fill: parent
            onPaint: {
              var ctx = canvas.getContext("2d")
              if (root.fullRepaint) {
                ctx.fillStyle = root.bgColor
                ctx.fillRect(0, 0, canvas.width, canvas.height)
                root.fullRepaint = false
              } else {
                var fade = Math.max(0.05, 1 - root.trail)
                ctx.fillStyle = Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, fade)
                ctx.fillRect(0, 0, canvas.width, canvas.height)
              }
              ctx.fillStyle = root.barForeground
              var cw = canvas.width / root.cols
              var ch = canvas.height / root.rows
              for (var y = 0; y < root.rows; y++) {
                for (var x = 0; x < root.cols; x++) {
                  if (root.grid[y * root.cols + x]) {
                    ctx.fillRect(Math.floor(x * cw), Math.floor(y * ch), Math.ceil(cw) - 1, Math.ceil(ch) - 1)
                  }
                }
              }
            }
            MouseArea {
              anchors.fill: parent
              onPressed: function(e) {
                root.paintCell(e.x, e.y, e.button === Qt.RightButton ? 0 : 1)
              }
              onPositionChanged: function(e) {
                if (pressed) root.paintCell(e.x, e.y, pressedButtons & Qt.RightButton ? 0 : 1)
              }
            }
          }
        }

        Row {
          spacing: Style.space(6)
          GLButton { label: root.playing ? "Pause" : "Play"; onClicked: root.playing = !root.playing }
          GLButton { label: "Step"; onClicked: { root.playing = false; root.tick() } }
          GLButton { label: "Random"; onClicked: root.doRandom }
          GLButton { label: "Clear"; onClicked: root.doClear }
          GLButton { label: "Glider"; onClicked: function() { root.playing = false; root.doSeed("glider") } }
          GLButton { label: "Pulsar"; onClicked: function() { root.playing = false; root.doSeed("pulsar") } }
          GLButton { label: "Gun"; onClicked: function() { root.playing = false; root.doSeed("gun") } }
        }

        Text {
          width: parent.width
          text: "gen " + root.generation + "  ·  " + root.cols + "×" + root.rows + "  ·  space/R/C"
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.small
          opacity: 0.7
        }
      }
    }
  }
}
