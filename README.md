# Zoldshell

Shell de desktop em [Quickshell](https://quickshell.outfoxxed.me) para **Sway**, feito para rodar leve em hardware modesto.
Testado em **Void Linux (runit)** com Celeron 1017U, 4 GB de RAM e o shell inteiro em cerca de 200 MB.

<!-- Coloque aqui um print: docs/preview.png -->

## O que tem

- Barra com workspaces do Sway, título da janela, mídia (MPRIS), volume, rede e temperatura
- Control Center (Wi-Fi, Bluetooth, DND, Night, volume, brilho, energia)
- Seletor de temas e de wallpaper, com paleta gerada a partir da imagem
- Tema integrado a Quickshell, Kitty, Cava e cores do sistema (claro/escuro)
- OSD, notificações, app launcher, lockscreen e tela de Settings
- Widgets de desktop (fastfetch, cava, relógio)

## Dependências

Obrigatórias (`deps/void.txt`):

| Pacote | Para quê |
|---|---|
| `sway` | compositor (`swaymsg` para workspaces e título da janela) |
| `quickshell` | o shell em si |
| `kitty` | terminal, recebe as cores do tema |
| `cava` | visualizador de áudio |
| `fastfetch` | widget de sistema |
| `awww` | backend de wallpaper (o antigo `swww`, renomeado) |
| `matugen` | paleta de cores gerada a partir do wallpaper |
| `ImageMagick` | comando `convert` |
| `lm_sensors` | temperatura da CPU |
| `brightnessctl` | brilho (só telas com backlight) |
| `NetworkManager` | Wi-Fi e Ethernet (`nmcli`) |
| `pipewire`, `wireplumber`, `pulseaudio-utils` | áudio (`wpctl` e `pactl`) |
| `bluez`, `rfkill` | Bluetooth |
| `elogind`, `dbus` | logout, reboot e desligar (`loginctl`) |
| `glib` | `gsettings` (claro/escuro) |
| `wl-clipboard` | `wl-copy` |
| `jq` | utilitário para scripts |

Fonte: **JetBrainsMono Nerd Font** (os ícones da barra dependem dela).

Opcionais (`deps/optional.txt`): `ddcutil` (brilho de monitor externo) e `firefox`.

## Instalação

```sh
git clone https://github.com/hecthormra/zoldshell.git ~/zoldshell
cd ~/zoldshell
./install.sh              # dependências + links
./install.sh --optional   # também instala os opcionais
./install.sh --no-deps    # só os links
```

O script faz backup do que já existir em `~/.config/quickshell/` antes de criar os links.

### Ajustes manuais

**Sway** (`~/.config/sway/config`):

```
include ~/.config/sway/theme.conf
exec awww-daemon
exec qs -c minimal
```

Apague os `client.*` antigos do config, senão eles sobrescrevem o tema.

**Kitty** (`~/.config/kitty/kitty.conf`):

```
allow_remote_control yes
listen_on unix:/tmp/kitty
include theme-colors.conf
```

**Serviços (runit):**

```sh
sudo ln -s /etc/sv/dbus           /var/service/
sudo ln -s /etc/sv/NetworkManager /var/service/
sudo ln -s /etc/sv/bluetoothd     /var/service/
```

## Estrutura

```
quickshell/
  minimal/           # o shell (bar, control_center, osd, settings, ...)
  theme-switcher/    # themes.json e geração de paleta do wallpaper
deps/
  void.txt
  optional.txt
install.sh
```

O estado de cada máquina (`theme.conf`, `wallpaper.conf`, `wallpaper-theme.json`) fica fora do Git.

## Problemas comuns

| Sintoma | Causa |
|---|---|
| Temperatura `N/A` | falta `lm_sensors` ou o módulo `coretemp` |
| Brilho em 0% ou pill sumido | monitor externo não tem `/sys/class/backlight` (use `ddcutil`) |
| Kitty não muda de cor | falta `allow_remote_control` ou `listen_on` |
| Ícones quebrados | falta a Nerd Font |

## Créditos

Baseado em dotfiles de Quickshell originalmente feitos para Hyprland, adaptados para Sway.
Preencha aqui o autor e o link da base, e confira a licença dela antes de publicar.

- Base do shell: _autor / link_
- Painel de desempenho: [tomgonz/quickshell-simpleperfmeters](https://github.com/tomgonz/quickshell-simpleperfmeters) (GPL-3.0)

## Licença

Defina conforme a licença da base usada.
