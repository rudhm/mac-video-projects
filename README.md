# Mac Video Projects

Zsh commands to automate directory creation, sorting, and organization for video editing projects on macOS.

## Installation

Add the following to your `~/.zshrc`:

```zsh
source /path/to/mac-video-projects/mac-video-projects.plugin.zsh
```

## Usage

### `newproject` (or `np`)
Creates a new standard video project structure in `~/Projects/<ProjectName>`.

```bash
np "ClientName"
np "ClientName" "Phase2"
```

It creates the following folders:
- `footage`
- `audio`
- `graphics`
- `exports`
- `assets`
- `captions`

*Bonus:* It automatically handles casing if the folder already exists, and instantly pins the newly created folder to your macOS Finder sidebar!

### `sortproject`
Sorts loose files in your current directory into the standard subfolders (`footage`, `audio`, etc.) based on their file extensions.

```bash
sortproject
sortproject --dry  # Preview changes without moving files
```
