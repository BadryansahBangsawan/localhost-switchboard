# Localhost Switchboard

See what is listening on localhost, open it, copy the URL, or kill the process — from the menu bar.

Menu extra for macOS 14+. It lives in the menu bar and does not show a Dock icon.

## Features

- Lists TCP listeners via `lsof` (port, command, host, pid).
- Open in the browser, copy URL, send SIGTERM, or copy a `kill -9` command.
- Pin ports so they stay visible.
- Refresh every 1s, 2s, or 5s.
- Optional hide of Apple system processes.
- Optional confirm-before-kill.

## Requirements

- macOS 14 Sonoma or later
- Swift 5.9 or later
- `/usr/sbin/lsof` (present on macOS)

## Install

```bash
git clone https://github.com/BadryansahBangsawan/localhost-switchboard.git
cd localhost-switchboard
bash package-app.sh
open dist/LocalhostSwitchboard.app
```

`package-app.sh` builds a release binary, wraps `dist/LocalhostSwitchboard.app`, and ad-hoc codesigns it (`codesign -s -`). Unsigned is fine for local use.

Enable **Open at Login** from Settings if you want it after reboot.

## Usage

- Click the network extra. Listeners appear as port + command.
- **Open** uses the listener URL. **Kill** sends SIGTERM; **kill -9** copies the command instead of running it.
- If `lsof` fails, stderr is shown as a red label.

## Permissions

- No special TCC permission. Killing a process you do not own will fail and show the error.

Denied permissions must not crash the app. You should see a banner and a button to open System Settings.

## Privacy

No network of its own. It only reads `lsof` output and runs `kill` when you click Kill. Pinned ports are stored locally.

Bundle ID: `engineer.badry.localhostswitchboard`.

## Development

```bash
swift build
swift build -c release --product LocalhostSwitchboard
```

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`.

## License

[MIT](LICENSE)
