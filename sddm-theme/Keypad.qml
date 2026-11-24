import QtQuick 2.0

// Touch-only password keyboard for the SDDM greeter.
//
// It is a plain QML keypad rather than a Qt VirtualKeyboard InputPanel: the
// greeter only has to append characters to the password field itself, so it
// works regardless of QT_IM_MODULE, input-method plugins or Qt version
// mismatches. Letters, numbers and symbols are three pages of one grid; shift
// applies to the next character (double-tap locks capitals), backspace repeats
// while held, and Enter submits.
Item {
  id: root

  property bool inputEnabled: true

  signal characterTyped(string text)
  signal backspacePressed()
  signal submitPressed()

  property int page: 0          // 0 letters, 1 numbers, 2 symbols
  property bool shift: false
  property bool capsLock: false

  readonly property real keyGap: Math.max(4, Math.round(height * 0.018))
  readonly property real rowHeight: (height - keyGap * 4) / 4
  readonly property real keyFontSize: Math.max(11, Math.round(rowHeight * 0.34))
  readonly property int keyRadius: 8

  readonly property color keyFill: "#26273b"
  readonly property color keyBorder: "#3b3d5c"
  readonly property color keyPressedFill: "#7aa3f7"
  readonly property color activeFill: "#7aa3f7"
  readonly property color keyLabel: "#c0caf5"
  readonly property color pressedLabel: "#1a1b26"

  readonly property var letterRows: [
    ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
    ["a", "s", "d", "f", "g", "h", "j", "k", "l", { label: "DEL", action: "backspace", weight: 1.2 }],
    [{ label: "⇧", action: "shift", weight: 1.5 }, "z", "x", "c", "v", "b", "n", "m", { label: "DEL", action: "backspace", weight: 1.2 }]
  ]
  readonly property var numberRows: [
    ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
    ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
    [{ label: "#+=", action: "symbols", weight: 1.5 }, ".", ",", "?", "!", "'", "`", { label: "DEL", action: "backspace", weight: 1.2 }]
  ]
  readonly property var symbolRows: [
    ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
    ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"],
    [{ label: "123", action: "numbers", weight: 1.5 }, "…", "°", "§", "¬", "±", "×", { label: "DEL", action: "backspace", weight: 1.2 }]
  ]

  readonly property var bottomKeys: page === 0
    ? [
        { label: "123", action: "numbers", weight: 1.5 },
        { label: "space", action: "space", weight: 4.2 },
        { label: "@", value: "@", weight: 0.9 },
        { label: ".", value: ".", weight: 0.9 },
        { label: "Enter", action: "submit", weight: 1.5 }
      ]
    : [
        { label: "ABC", action: "letters", weight: 1.5 },
        { label: "space", action: "space", weight: 4.2 },
        { label: "-", value: "-", weight: 0.9 },
        { label: "_", value: "_", weight: 0.9 },
        { label: "Enter", action: "submit", weight: 1.5 }
      ]

  function activeRows() {
    if (page === 1) return numberRows
    if (page === 2) return symbolRows
    return letterRows
  }

  function keySpec(item) {
    return typeof item === "string" ? { label: item, value: item, weight: 1 } : item
  }

  function rowWeight(row) {
    var sum = 0
    for (var i = 0; i < row.length; i++) sum += keySpec(row[i]).weight
    return sum > 0 ? sum : 1
  }

  function letterFor(label) {
    if (!/^[a-z]$/.test(label)) return label
    return (shift || capsLock) ? label.toUpperCase() : label
  }

  function reset() {
    page = 0
    shift = false
    capsLock = false
    stopRepeat()
  }

  // ---- backspace auto-repeat ------------------------------------------------
  property bool repeating: false
  property double lastShiftTap: 0

  function beginRepeat() {
    backspacePressed()
    repeatDelay.restart()
  }

  function stopRepeat() {
    repeating = false
    repeatDelay.stop()
    repeatTimer.stop()
  }

  Timer {
    id: repeatDelay
    interval: 420
    repeat: false
    onTriggered: {
      root.repeating = true
      root.backspacePressed()
      repeatTimer.start()
    }
  }

  Timer {
    id: repeatTimer
    interval: 65
    repeat: true
    onTriggered: root.backspacePressed()
  }

  // ---- key handling ---------------------------------------------------------
  function press(item) {
    if (!inputEnabled) return
    var key = keySpec(item)

    switch (key.action) {
    case "shift":
      // Double-tap locks capitals, like a phone keyboard.
      if (shift && Date.now() - lastShiftTap < 350) {
        capsLock = !capsLock
        shift = false
      } else {
        shift = !shift
      }
      lastShiftTap = Date.now()
      return
    case "numbers":
      page = 1
      shift = false
      return
    case "symbols":
      page = 2
      shift = false
      return
    case "letters":
      page = 0
      return
    case "space":
      characterTyped(" ")
      return
    case "backspace":
      return
    case "submit":
      submitPressed()
      return
    }

    characterTyped(letterFor(key.value !== undefined ? key.value : key.label))

    if (shift && !capsLock) shift = false
  }

  Column {
    anchors.fill: parent
    spacing: root.keyGap

    // Letter / number / symbol rows
    Repeater {
      model: root.activeRows()

      delegate: Item {
        id: keyRow
        required property var modelData

        readonly property var rowKeys: modelData
        readonly property real totalWeight: root.rowWeight(rowKeys)

        width: parent.width
        height: root.rowHeight

        Repeater {
          model: keyRow.rowKeys

          delegate: Item {
            id: keyCell
            required property var modelData
            required property int index

            property var key: root.keySpec(modelData)
            property bool isShift: key.action === "shift"
            property bool isActive: isShift && (root.shift || root.capsLock)

            x: {
              var before = 0
              for (var i = 0; i < index; i++) before += root.keySpec(keyRow.rowKeys[i]).weight
              return before * (keyRow.width - root.keyGap * (keyRow.rowKeys.length - 1)) / keyRow.totalWeight + index * root.keyGap
            }
            width: (keyRow.width - root.keyGap * (keyRow.rowKeys.length - 1)) * key.weight / keyRow.totalWeight
            height: keyRow.height

            Rectangle {
              anchors.fill: parent
              radius: root.keyRadius
              color: keyCell.isActive ? root.activeFill : (tap.pressed ? root.keyPressedFill : root.keyFill)
              border.color: keyCell.isActive ? root.activeFill : root.keyBorder
              border.width: 1
              opacity: root.inputEnabled ? 1.0 : 0.4

              Text {
                anchors.centerIn: parent
                text: {
                  if (keyCell.isShift) return root.capsLock ? "⇪" : "⇧"
                  if (root.page === 0) return root.letterFor(keyCell.key.label)
                  return keyCell.key.label
                }
                color: (keyCell.isActive || tap.pressed) ? root.pressedLabel : root.keyLabel
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: root.keyFontSize
                font.bold: keyCell.isActive
              }

              MouseArea {
                id: tap
                anchors.fill: parent
                enabled: root.inputEnabled
                onPressed: {
                  if (keyCell.key.action === "backspace") root.beginRepeat()
                  else root.press(keyCell.key)
                }
                onReleased: root.stopRepeat()
                onCanceled: root.stopRepeat()
              }
            }
          }
        }
      }
    }

    // Bottom row: page switch, space, punctuation, submit.
    Item {
      id: bottomRow
      width: parent.width
      height: root.rowHeight

      readonly property var rowKeys: root.bottomKeys
      readonly property real totalWeight: root.rowWeight(rowKeys)

      Repeater {
        model: bottomRow.rowKeys

        delegate: Item {
          id: bottomCell
          required property var modelData
          required property int index

          property var key: root.keySpec(modelData)

          x: {
            var before = 0
            for (var i = 0; i < index; i++) before += root.keySpec(bottomRow.rowKeys[i]).weight
            return before * (bottomRow.width - root.keyGap * (bottomRow.rowKeys.length - 1)) / bottomRow.totalWeight + index * root.keyGap
          }
          width: (bottomRow.width - root.keyGap * (bottomRow.rowKeys.length - 1)) * key.weight / bottomRow.totalWeight
          height: bottomRow.height

          Rectangle {
            anchors.fill: parent
            radius: root.keyRadius
            color: submitTap.pressed ? root.keyPressedFill : root.keyFill
            border.color: root.keyBorder
            border.width: 1
            opacity: root.inputEnabled ? 1.0 : 0.4

            Text {
              anchors.centerIn: parent
              text: bottomCell.key.label
              color: submitTap.pressed ? root.pressedLabel : root.keyLabel
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: bottomCell.key.action === "space" ? Math.round(root.keyFontSize * 0.85) : root.keyFontSize
            }

            MouseArea {
              id: submitTap
              anchors.fill: parent
              enabled: root.inputEnabled
              onPressed: root.press(bottomCell.key)
            }
          }
        }
      }
    }
  }
}
