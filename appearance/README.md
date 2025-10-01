# Appearance (Light/Dark Mode)

Automatically match your system's appearance across all applications for better eye comfort.

## Operating Systems

### macOS
- **System Setting:** System Preferences → Appearance → Light/Dark/Auto
- **Check current:** `defaults read -g AppleInterfaceStyle` (returns "Dark" or error if light)
- **Auto mode:** Based on time of day or ambient light sensor

### Windows 11
- **System Setting:** Settings → Personalization → Colors → Choose your mode
- **Auto switching:** [Windows Auto Dark Mode](https://github.com/AutoDarkMode/Windows-Auto-Night-Mode)
- **Toggle script:** `appearance/bin/appearance-toggle.ps1`

#### WSL (Windows Subsystem for Linux)
- Inherits from Windows host theme
- Query Windows theme: `powershell.exe -Command "(Get-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize).AppsUseLightTheme"`
- Returns: 1 for light, 0 for dark

### Linux
- **GNOME/Ubuntu:** Settings → Appearance → Style (Light/Dark)
  - Check: `gsettings get org.gnome.desktop.interface color-scheme`
- **KDE Plasma:** System Settings → Appearance → Global Theme
- **XFCE:** Window Manager → Style

## Applications

### Development Tools
- **tmux:** [Theme switching guide](../tmux/docs/theme-switching.md) - Auto-follows OS with `Ctrl-b T` toggle
- **Neovim:** Configure with `vim.o.background` based on system detection
- **VS Code:** `"window.autoDetectColorScheme": true` in settings.json
- **Windows Terminal:** Settings → Profiles → Appearance → Color scheme

### Browsers
Install Dark Reader extension and set to "Use system color scheme":
- [Firefox](https://addons.mozilla.org/en-US/firefox/addon/darkreader/)
- [Chrome](https://chrome.google.com/webstore/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh)
- [Edge](https://microsoftedge.microsoft.com/addons/detail/dark-reader/ifoakfbpdcdoeenechcleahebpibofpc)

### Web Services
- **GitHub:** [Settings → Appearance](https://github.com/settings/appearance) → Sync with system
- **Google:** Search settings → Appearance → Device default
- **Obsidian:** Settings → Appearance → Base color scheme → Adapt to system

## Quick Reference

### Unified Appearance Command
```bash
# Check current appearance (works on all platforms)
appearance              # Shows: light, dark, or auto (currently light/dark)

# Set appearance
appearance light        # Set to light mode
appearance dark         # Set to dark mode
appearance auto         # Set to auto mode (macOS only)
```

### Platform-Specific Commands
```bash
# macOS
defaults read -g AppleInterfaceStyle 2>/dev/null || echo "light"

# Linux (GNOME)
gsettings get org.gnome.desktop.interface color-scheme

# WSL/Windows
powershell.exe -Command "if ((Get-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize).AppsUseLightTheme -eq 1) {'light'} else {'dark'}"
```

### Environment Variables
```bash
# Override detection
export TERMINAL_THEME="dark"  # or "light"

# WSL-specific
export WINDOWS_THEME="dark"   # or "light"
```

## See Also
- [Apps with Auto Dark Mode support](https://github.com/AutoDarkMode/Windows-Auto-Night-Mode/wiki/Apps-with-Auto-Dark-Mode-support)