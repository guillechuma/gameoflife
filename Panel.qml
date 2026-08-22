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

  // Bounds keep this popout responsive and small enough for typical displays.
  function boundedInt(value, fallback, minimum, maximum) {
    var parsed = Number(value)
    if (!isFinite(parsed)) return fallback
    return Math.max(minimum, Math.min(maximum, Math.floor(parsed)))
  }

  function boundedReal(value, fallback, minimum, maximum) {
    var parsed = Number(value)
    if (!isFinite(parsed)) return fallback
    return Math.max(minimum, Math.min(maximum, parsed))
  }

  readonly property int cols: root.boundedInt(setting("cols", "48"), 48, 8, 64)
  readonly property int rows: root.boundedInt(setting("rows", "32"), 32, 8, 40)
  readonly property real speed: root.boundedReal(setting("speed", "8"), 8, 1, 60)
  readonly property bool wrap: setting("wrap", true) === true || setting("wrap", true) === "true"
  readonly property real trail: root.boundedReal(setting("trail", "0.35"), 0.35, 0, 1)

  property var grid: []
  property bool playing: true
  property int generation: 0
  property bool fullRepaint: true
  property string statusText: ""
  // Session-only speed control; the configured value remains the default.
  property int sessionSpeed: Math.round(root.speed)

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
    root.statusText = ""
    root.fullRepaint = true
    canvas.requestPaint()
  }

  function doClear() {
    Engine.clear(root.grid, root.cols, root.rows)
    root.generation = 0
    root.statusText = ""
    root.fullRepaint = true
    canvas.requestPaint()
  }

  function doSeed(type) {
    var size = Engine.seedSize(type)
    if (!size || root.cols < size.width || root.rows < size.height) {
      root.statusText = type + " needs " + size.width + "×" + size.height
      return false
    }
    Engine.clear(root.grid, root.cols, root.rows)
    Engine.seed(root.grid, root.cols, root.rows, type)
    root.generation = 0
    root.statusText = ""
    root.fullRepaint = true
    canvas.requestPaint()
    return true
  }

  function selectSeed(type) {
    if (root.doSeed(type)) root.playing = false
  }

  function setSpeed(value) {
    root.sessionSpeed = root.boundedInt(value, root.sessionSpeed, 1, 60)
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
    interval: Math.max(16, Math.round(1000 / root.sessionSpeed))
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
        else if (e.modifiers === Qt.NoModifier && e.key === Qt.Key_N) { root.playing = false; root.tick(); e.accepted = true }
        else if (e.modifiers === Qt.NoModifier && e.key === Qt.Key_R) { root.doRandom(); e.accepted = true }
        else if (e.modifiers === Qt.NoModifier && e.key === Qt.Key_C) { root.doClear(); e.accepted = true }
        else if (e.modifiers === Qt.NoModifier && e.key === Qt.Key_G) { root.selectSeed("glider"); e.accepted = true }
        else if (e.modifiers === Qt.NoModifier && e.key === Qt.Key_P) { root.selectSeed("pulsar"); e.accepted = true }
        else if (e.modifiers === Qt.NoModifier && e.key === Qt.Key_U) { root.selectSeed("gun"); e.accepted = true }
        else if (e.modifiers === Qt.NoModifier && e.key === Qt.Key_A) { root.selectSeed("acorn"); e.accepted = true }
        else if (e.modifiers === Qt.NoModifier && e.key === Qt.Key_O) { root.selectSeed("omarchy"); e.accepted = true }
        else if (e.modifiers === Qt.NoModifier && e.key === Qt.Key_Minus) { root.setSpeed(root.sessionSpeed - 1); e.accepted = true }
        else if (e.modifiers === Qt.NoModifier && e.key === Qt.Key_Plus) { root.setSpeed(root.sessionSpeed + 1); e.accepted = true }
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
          font.pixelSize: 11
        }
        opacity: enabled ? 1 : 0.35
        MouseArea {
          id: ma
          anchors.fill: parent
          enabled: parent.enabled
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

        Column {
          spacing: Style.space(6)

          Row {
            spacing: Style.space(6)
            Text {
              width: Style.space(54)
              anchors.verticalCenter: parent.verticalCenter
              text: "Controls:"
              horizontalAlignment: Text.AlignRight
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: 11
              opacity: 0.7
            }
            GLButton { label: root.playing ? "Pause" : "Play"; onClicked: root.playing = !root.playing }
            GLButton { label: "Step"; onClicked: { root.playing = false; root.tick() } }
            GLButton { label: "Random"; onClicked: root.doRandom() }
            GLButton { label: "Clear"; onClicked: root.doClear() }
          }

          Row {
            spacing: Style.space(6)
            Text {
              width: Style.space(54)
              anchors.verticalCenter: parent.verticalCenter
              text: "Presets:"
              horizontalAlignment: Text.AlignRight
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: 11
              opacity: 0.7
            }
            GLButton { label: "Glider"; onClicked: root.selectSeed("glider") }
            GLButton { label: "Pulsar"; enabled: root.cols >= 13 && root.rows >= 13; onClicked: root.selectSeed("pulsar") }
            GLButton { label: "Gun"; enabled: root.cols >= 36 && root.rows >= 9; onClicked: root.selectSeed("gun") }
            GLButton { label: "Acorn"; onClicked: root.selectSeed("acorn") }
            GLButton { label: "Omarchy"; enabled: root.cols >= 9 && root.rows >= 15; onClicked: root.selectSeed("omarchy") }
          }

          Row {
            spacing: Style.space(6)
            Text {
              width: Style.space(54)
              anchors.verticalCenter: parent.verticalCenter
              text: "Speed:"
              horizontalAlignment: Text.AlignRight
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: 11
              opacity: 0.7
            }
            GLButton { label: "−"; onClicked: root.setSpeed(root.sessionSpeed - 1) }
            Rectangle {
              id: speedTrack
              width: Style.space(180)
              height: Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              radius: height / 2
              color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.16)

              Rectangle {
                width: parent.width * (root.sessionSpeed - 1) / 59
                height: parent.height
                radius: parent.radius
                color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.55)
              }
              Rectangle {
                width: Style.space(12)
                height: width
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: (parent.width - width) * (root.sessionSpeed - 1) / 59
                color: root.barForeground
              }
              MouseArea {
                anchors.fill: parent
                onPressed: function(e) { root.setSpeed(1 + Math.round(e.x * 59 / speedTrack.width)) }
                onPositionChanged: function(e) { if (pressed) root.setSpeed(1 + Math.round(e.x * 59 / speedTrack.width)) }
              }
            }
            Text {
              width: Style.space(34)
              anchors.verticalCenter: parent.verticalCenter
              text: root.sessionSpeed + "/s"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: 11
              horizontalAlignment: Text.AlignRight
            }
            GLButton { label: "+"; onClicked: root.setSpeed(root.sessionSpeed + 1) }
          }
        }

        Text {
          width: parent.width
          text: root.statusText || ("gen " + root.generation + "  ·  Space play  −/+ speed  N step  R random  C clear  G glider  P pulsar  U gun  A acorn  O Omarchy")
          wrapMode: Text.WordWrap
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: 11
          opacity: 0.7
        }
      }
    }
  }
}
