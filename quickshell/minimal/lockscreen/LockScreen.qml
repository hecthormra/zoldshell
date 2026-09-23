import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Scope {
    id: root

    property var theme
    property string password: ""
    property string statusText: ""
    property bool authenticating: false

    function startLock() {
        if (lock.locked)
            return;

        password = "";
        statusText = "";
        authenticating = false;
        lock.locked = true;
    }

    function tryUnlock() {
        if (!lock.locked || authenticating || password.length === 0)
            return;

        statusText = "";
        authenticating = true;

        if (!pam.start()) {
            authenticating = false;
            statusText = "Não foi possível iniciar a autenticação";
        }
    }

    function unlock() {
        password = "";
        statusText = "";
        authenticating = false;
        lock.locked = false;
    }

    IpcHandler {
        target: "lock"

        function toggle(): void {
            if (lock.locked)
                root.unlock();
            else
                root.startLock();
        }
    }

    PamContext {
        id: pam

        configDirectory: "pam"
        config: "password.conf"

        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }

        onCompleted: result => {
            root.authenticating = false;

            if (result === PamResult.Success) {
                root.unlock();
            } else {
                root.password = "";
                root.statusText = "Senha incorreta";
            }
        }

        onError: error => {
            root.authenticating = false;
            root.password = "";
            root.statusText = "Erro de autenticação";
            console.warn("Quickshell PAM:", error);
        }
    }

    WlSessionLock {
        id: lock

        locked: false

        surface: Component {
            WlSessionLockSurface {
                Rectangle {
                    anchors.fill: parent
                    color: root.theme.bgBase

                    Rectangle {
                        anchors.fill: parent
                        color: root.theme.bgOverlay
                        opacity: 0.18
                    }

                    Column {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 80, 420)
                        spacing: 22

                        Rectangle {
                            width: 92
                            height: 92
                            radius: 46
                            anchors.horizontalCenter: parent.horizontalCenter

                            color: root.theme.bgSurface
                            border.width: 1
                            border.color: root.theme.bgBorder

                            Text {
                                anchors.centerIn: parent

                                text: "●"
                                color: root.theme.accentPrimary
                                font.pixelSize: 38
                                font.bold: true
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 5

                            Text {
                                width: parent.width

                                text: "Tela bloqueada"
                                color: root.theme.textPrimary

                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: 28
                                font.bold: true
                            }

                            Text {
                                width: parent.width

                                text: root.authenticating
                                      ? "Verificando..."
                                      : "Digite sua senha para continuar"

                                color: root.theme.textSecondary

                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: 14
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 56
                            radius: 28

                            color: root.theme.bgSurface
                            border.width: 1
                            border.color: rootPasswordInput.activeFocus
                                            ? root.theme.accentPrimary
                                            : root.theme.bgBorder

                            TextInput {
                                id: rootPasswordInput

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter

                                anchors.leftMargin: 22
                                anchors.rightMargin: 22

                                text: root.password
                                color: root.theme.textPrimary

                                font.pixelSize: 16
                                font.family: "Hack Nerd Font"

                                echoMode: TextInput.Password
                                passwordCharacter: "•"

                                enabled: !root.authenticating

                                selectByMouse: false

                                onTextChanged: {
                                    if (root.password !== text)
                                        root.password = text;
                                }

                                Keys.onReturnPressed: root.tryUnlock()
                                Keys.onEnterPressed: root.tryUnlock()
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 22
                                anchors.verticalCenter: parent.verticalCenter

                                text: "Senha"
                                color: root.theme.textMuted

                                font.pixelSize: 16

                                visible: rootPasswordInput.text.length === 0 &&
                                         !rootPasswordInput.activeFocus

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: rootPasswordInput.forceActiveFocus()
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !root.authenticating

                                onClicked: rootPasswordInput.forceActiveFocus()
                            }
                        }

                        Text {
                            width: parent.width

                            text: root.statusText
                            color: root.theme.accentRed

                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 13

                            visible: text.length > 0
                        }

                        Text {
                            width: parent.width

                            text: root.authenticating
                                  ? ""
                                  : "Enter para desbloquear"

                            color: root.theme.textMuted

                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 12
                        }
                    }

                    Component.onCompleted: {
                        rootPasswordInput.forceActiveFocus();
                    }
                }
            }
        }

        onLockedChanged: {
            if (locked) {
                root.password = "";
                root.statusText = "";
                root.authenticating = false;
            }
        }
    }
}

