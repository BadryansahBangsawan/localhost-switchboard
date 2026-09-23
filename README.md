<div align="center">

# Localhost Switchboard

**List TCP listeners from `lsof`. Open the URL, copy it, SIGTERM the pid, or copy `kill -9`.**

Menu extra for macOS 14+. Lives on the **right** of the menu bar. No Dock icon.

<br/>

[![Build](https://github.com/BadryansahBangsawan/localhost-switchboard/actions/workflows/ci.yml/badge.svg)](https://github.com/BadryansahBangsawan/localhost-switchboard/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/localhost-switchboard?style=flat-square)](https://github.com/BadryansahBangsawan/localhost-switchboard/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/localhost-switchboard/releases/latest)

<br/>

| | |
|---|---|
| Product | `LocalhostSwitchboard` |
| Bundle ID | `engineer.badry.localhostswitchboard` |
| Cask | `localhost-switchboard` |
| Status item | SF Symbol `network` |
| Panel | opaque ~360×420 pt |

</div>

---

## What you get

| Piece | Behavior |
|---|---|
| **lsof** | `/usr/sbin/lsof -nP -iTCP -sTCP:LISTEN`. Port, command, host, pid. Not loopback-only — `0.0.0.0` listeners are listed. |
| **Open** | **Open** button (not click-row). URL is `http://127.0.0.1:<port>`, or `https://` when the port is 443 or 8443. |
| **Kill** | **Kill** sends SIGTERM. **kill -9** copies the command instead of running it. |
| **Pin** | Pinned ports stay visible. Filter by port or command. |
| **Refresh** | Every 1s, 2s, or 5s. Optional hide of Apple system processes. Optional confirm-before-kill. |
| **Login** | Open at Login from Settings (`SMAppService`). |

---

## Download

| File | Use |
|---|---|
| **`LocalhostSwitchboard.app.zip`** | Homebrew cask / unzip, drag **LocalhostSwitchboard** onto **Applications** |

**[Releases](https://github.com/BadryansahBangsawan/localhost-switchboard/releases/latest)**

---

## Install

### Homebrew

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew trust BadryansahBangsawan/mac-menu-apps
brew install --cask localhost-switchboard
```

`brew trust` is required on Homebrew 6 or `brew install --cask` refuses the tap.

First open (ad-hoc signed):

```bash
xattr -cr /Applications/LocalhostSwitchboard.app
open /Applications/LocalhostSwitchboard.app
```

Still blocked: System Settings → Privacy & Security → Open Anyway.

Do not run `dist/LocalhostSwitchboard.app` while `/Applications/LocalhostSwitchboard.app` is running (same bundle ID).

---

## How to open

This is an `LSUIElement` extra. Proof it is running is the **network** status item on the **right** of the menu bar, not a window from Finder or Launchpad.

1. Click that extra. The panel is opaque ~360×420 pt, not a 10px strip.
2. If the bar is full, look behind the Control Center overflow chevron **«**.
3. Double-clicking in Finder/Launchpad only changes the left-side app name. That is expected. There is no Dock icon.

---

## Usage

1. **Filter** matches port, command, host, or pid. Empty filter + no listeners: **No listeners**. Non-empty filter + no rows: **No matches**.
2. **Open** / **Copy URL** / pin. **Open** uses `http://127.0.0.1:<port>` (`https://` on 443 / 8443) even when `lsof` shows another bind address.
3. **Kill** sends SIGTERM, then SIGKILL after 3 seconds if that pid is still listening. **kill -9** copies `kill -9 <pid>` instead of running it. Confirm-before-kill defaults on.
4. If `lsof` fails, stderr is a red label.
5. **Settings** at the bottom: Refresh 1s / 2s / 5s, Confirm before kill, Hide Apple system processes, Open at Login, Quit.

---

## Permissions

No TCC prompts. Killing a process you do not own fails and shows `kill` stderr as a red label. The extra does not crash.

---

## Data

| What | Where |
|---|---|
| Refresh interval | UserDefaults `engineer.badry.localhostswitchboard.refreshMs` |
| Confirm before kill | UserDefaults `engineer.badry.localhostswitchboard.confirmKill` |
| Hide Apple system | UserDefaults `engineer.badry.localhostswitchboard.hideAppleSystem` |
| Pinned ports | UserDefaults `engineer.badry.localhostswitchboard.pinnedPorts` |
| Open at Login | `SMAppService.mainApp` (Settings toggle) |

Nothing under Application Support.

---

## Privacy

No network of its own. It reads `lsof` output and runs `kill` when you click Kill. Pinned ports stay on this Mac.

---

## Uninstall

```bash
brew uninstall --cask localhost-switchboard
```

Or delete `/Applications/LocalhostSwitchboard.app`.

This does not delete UserDefaults.

Turn off **Localhost Switchboard** in System Settings → General → Login Items if it remains.

---

## Troubleshooting

| What you see | What to do |
|---|---|
| Finder “opens” nothing / no Dock icon | Click the **network** extra on the right of the menu bar. |
| Extra missing | Overflow **«**, or `pgrep -x LocalhostSwitchboard` then `open /Applications/LocalhostSwitchboard.app`. |
| “Damaged” / cannot verify | `xattr -cr /Applications/LocalhostSwitchboard.app`. `spctl --assess` is `rejected` even when it runs. |
| `brew install --cask` refuses the tap | `brew trust BadryansahBangsawan/mac-menu-apps` |
| **No listeners** / **No matches** | Nothing listening, or filter is too narrow. |
| Kill failed | You do not own that pid; the red label is the `kill` stderr. |
| ~10px empty strip under the bar | Reinstall from this repo. |

---

## Build from source

```bash
git clone https://github.com/BadryansahBangsawan/localhost-switchboard.git
cd localhost-switchboard
swift build -c release --product LocalhostSwitchboard
bash package-app.sh
open dist/LocalhostSwitchboard.app
```

Tag `v*` runs CI: `LocalhostSwitchboard.app.zip`. Never commit `dist/`.

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`. `FunTheme.swift` is copied verbatim (no shared package).

---

## FAQ

**Why is there no Dock icon?**  
It is a menu extra. Click the network item on the **right** of the menu bar.

**Does Kill run `kill -9`?**  
No. **Kill** sends SIGTERM, then SIGKILL after 3 seconds if the pid is still listening. The **kill -9** button copies `kill -9 <pid>`.

**Where are pinned ports stored?**  
UserDefaults `engineer.badry.localhostswitchboard.pinnedPorts`.

**How do I stop it opening at login?**  
Settings in the panel, or System Settings → General → Login Items → **Localhost Switchboard**.

---

<div align="center">

[MIT](LICENSE)

</div>
