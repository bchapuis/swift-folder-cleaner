# Keyboard Shortcuts - FolderCleaner

## Global Shortcuts

| Shortcut | Action | Context |
|----------|--------|---------|
| **Cmd+O** | Open folder picker / Scan new folder | Available when not scanning |
| **Cmd+W** | Close window | System default |
| **Cmd+Q** | Quit application | System default |

## Results View Shortcuts

### Navigation

| Shortcut | Action | Description |
|----------|--------|-------------|
| **Return** / **Enter** | Drill down | Opens selected directory in treemap |
| **Space** | Drill down | Opens selected directory in treemap |
| **Escape** | Navigate up | Goes to parent directory |
| **Cmd+↑** | Navigate up | Alternative to Escape |

### File Actions

| Shortcut | Action | Description |
|----------|--------|-------------|
| **Cmd+I** | Show in Finder | Reveals selected item in Finder |
| **Cmd+Delete** | Delete | Moves selected item to Trash (with confirmation) |
| **Cmd+Backspace** | Delete | Alternative to Cmd+Delete |

### Selection

| Shortcut | Action | Description |
|----------|--------|-------------|
| **Tab** | Next control | Cycles through interactive elements |
| **Shift+Tab** | Previous control | Cycles backward through interactive elements |
| **↑** / **↓** | Navigate list | Moves selection up/down in file list |
| **Click** | Select item | Selects file or folder |

## Filter Controls

All filter buttons are keyboard accessible via **Tab** navigation:

- **File Type Filters**: Tab to filter, Space/Enter to toggle
- **Size Filters**: Tab to filter, Space/Enter to select
- **Filename Search**: Tab to search field, type to filter

## VoiceOver Shortcuts (Accessibility)

| Shortcut | Action |
|----------|--------|
| **Cmd+F5** | Toggle VoiceOver |
| **VO+→** | Next element |
| **VO+←** | Previous element |
| **VO+Space** | Activate element |

*VO = VoiceOver modifier (Control+Option by default)*

## Tips

1. **Quick Scan**: Press **Cmd+O** from anywhere to start a new scan
2. **Fast Navigation**: Use **Return** to drill down, **Escape** to go back up
3. **Visual Focus**: Watch for the blue focus ring around active elements
4. **Full Keyboard Control**: Enable "Keyboard navigation" in System Preferences → Keyboard → Shortcuts → "Use keyboard navigation to move focus between controls"

## Implementation Notes

- All shortcuts follow macOS Human Interface Guidelines
- Keyboard shortcuts are properly localized
- Disabled actions are grayed out but still keyboard accessible
- VoiceOver provides spoken feedback for all actions
