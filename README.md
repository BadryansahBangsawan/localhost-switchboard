<div align="center">

# Localhost Switchboard

**See all localhost listeners and open them in the browser from the menu bar.**  
macOS menu extra — lives in the menu bar, no Dock icon.

<br/>

[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/localhost-switchboard?style=flat-square&color=76B900&label=latest)](https://github.com/BadryansahBangsawan/localhost-switchboard/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/localhost-switchboard/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)

<br/>

</div>

---

## Download

| Platform | File |
|---|---|
| **macOS** (Apple Silicon & Intel, macOS 14+) | `LocalhostSwitchboard-*-macos.zip` |

[Go to Releases](https://github.com/BadryansahBangsawan/localhost-switchboard/releases/latest)

---

## Installation

### Homebrew (recommended)

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew install --cask localhost-switchboard
```

A **Localhost Switchboard** icon appears in the menu bar. If Gatekeeper blocks it on first launch:

```bash
xattr -cr /Applications/LocalhostSwitchboard.app && open /Applications/LocalhostSwitchboard.app
```

Or: right-click the app, Open, then Open again. Still blocked? **System Settings → Privacy & Security → Open Anyway**.

### GitHub Releases

1. Download `LocalhostSwitchboard-*-macos.zip` from [Releases](https://github.com/BadryansahBangsawan/localhost-switchboard/releases/latest)
2. Unzip and drag **LocalhostSwitchboard** into Applications
3. On first launch, run the xattr command above if Gatekeeper blocks it

### Build from source

```bash
git clone https://github.com/BadryansahBangsawan/localhost-switchboard.git
cd localhost-switchboard
bash package-app.sh
open dist/LocalhostSwitchboard.app
```

Requires Xcode Command Line Tools and Swift 5.9+.

---

## Notes

– Polls lsof to detect listening TCP ports. The menu refreshes automatically each time you open it, so newly started servers appear without a manual restart.
– Click any port to open http://localhost:<port> in the default browser. Local HTTPS servers still appear in the list, but the click always uses `http://` — open the HTTPS URL manually if the service rejects plain HTTP.
– No Dock icon; lives entirely in the menu bar.
– Only ports bound to `127.0.0.1` or `::1` are listed — externally exposed listeners on `0.0.0.0` are excluded.

---

<div align="center">

Made with ♥ for developers who prefer staying in the flow.

</div>
