import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
  id: root
  width: 640
  height: 480
  color: "#1a1b26"

  property string currentUser: userModel.lastUser
  property bool loginFailed: false

  // The keypad owns the bottom of the screen; the logo and password field stay
  // centred in whatever is left above it, so nothing hides behind the keys.
  readonly property real touchKeyboardHeight: Math.max(220, Math.min(Math.round(root.height * 0.42), 440))
  readonly property real headerHeight: Math.max(120, root.height - touchKeyboardHeight)

  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }

  function submit() {
    if (password.text.length === 0)
      return
    sddm.login(root.currentUser, password.text, root.sessionIndex)
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.loginFailed = true
      password.text = ""
      password.focus = true
    }
    function onLoginSucceeded() {
      root.loginFailed = false
    }
  }

  Column {
    id: form
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.top
    anchors.verticalCenterOffset: Math.round(root.headerHeight / 2)
    spacing: Math.max(24, Math.round(root.headerHeight * 0.12))

    Image {
      id: logo
      source: "logo.png"
      width: Math.min(sourceSize.width, root.width * 0.8)
      height: sourceSize.width > 0 ? Math.round(width * sourceSize.height / sourceSize.width) : 0
      fillMode: Image.PreserveAspectFit
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 15

      Image {
        source: root.loginFailed ? "lock-failed.png" : "lock.png"
        width: 34
        height: 38
        fillMode: Image.PreserveAspectFit
        anchors.verticalCenter: parent.verticalCenter
      }

      Item {
        width: entry.width
        height: entry.height

        Image {
          id: entry
          source: root.loginFailed ? "entry-failed.png" : "entry.png"
          anchors.centerIn: parent
        }

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 20
          anchors.verticalCenter: parent.verticalCenter
          spacing: 5

          Repeater {
            model: Math.min(password.text.length, 21)

            Image {
              source: "bullet.png"
              width: 7
              height: 7
            }
          }
        }

        TextInput {
          id: password
          anchors.fill: parent
          anchors.leftMargin: 20
          anchors.rightMargin: 20
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 24
          font.letterSpacing: 5
          passwordCharacter: "\u2022"
          color: "transparent"
          selectionColor: "transparent"
          selectedTextColor: "transparent"
          cursorDelegate: Item {}
          focus: true

          onTextChanged: root.loginFailed = false

          Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.submit()
              event.accepted = true
            }
          }
        }
      }
    }
  }

  // On-screen keyboard for machines without a physical one (tablets). It is a
  // plain QML keypad that appends to the password field directly, so it does
  // not depend on Qt VirtualKeyboard, QT_IM_MODULE or input-method plugins.
  Keypad {
    id: keypad
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: root.touchKeyboardHeight
    z: 99

    onCharacterTyped: {
      if (password.text.length < 128)
        password.text += text
      password.focus = true
    }
    onBackspacePressed: password.text = password.text.slice(0, -1)
    onSubmitPressed: root.submit()
  }

  Component.onCompleted: password.forceActiveFocus()
}
