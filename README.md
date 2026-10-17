# Mac Video Projects

Zsh commands to automate directory creation, sorting, and organization for video editing projects on macOS.

## Installation

Add the following to your `~/.zshrc`:

```zsh
# Optional: Set a custom base directory (defaults to ~/Projects if not set)
export MAC_VIDEO_PROJECTS_DIR="/Volumes/MyDrive/Active_Projects"

source /path/to/mac-video-projects/mac-video-projects.plugin.zsh
```

## Usage

### `newproject` (or `np`)
Creates a new standard video project structure in your base directory.
Client names are converted to title case when new folders are created.
Subfolder names are preserved exactly as entered, including capitalization.

```bash
np "client name"
np "client name" "phase two"
```

When only the client name is provided, the project is created under a
readable `Month Day` folder for the current date:

```text
~/Projects/Client Name/October 2/
```

Providing a second argument continues to use that value as the subfolder
name.

It creates the following folders:
- `01_footage`
- `02_audio`
- `03_graphics`
- `04_captions`
- `05_drafts`
- `06_final`

#### Options:
- `-u, --url`: Open the video tracking spreadsheet in your browser.
- `-p, --premiere`: Initialize `<project-name>.prproj` at the exact path and open it in Adobe Premiere Pro.
- `-c, --capcut`: Directly open in CapCut.
- `-s, --skip`: Skip opening an editor (bypass prompt).
- `--no-pin`: Skip pinning folder to Finder sidebar.

#### Environment Variables:
- `MAC_VIDEO_PROJECTS_DIR`: Base projects directory (defaults to `~/Projects`).
- `MAC_VIDEO_PROJECTS_EDITOR`: Default editor action (`p`, `c`, or `none`).
- `MAC_VIDEO_PROJECTS_PIN_SIDEBAR`: Set to `false` to disable sidebar pinning.

*Bonus:* Automatically handles casing if the folder already exists, and asynchronously pins the folder to your macOS Finder sidebar without stealing focus or slowing down the terminal.

### `sortproject`
Sorts loose files in your current directory into the standard subfolders based on their file extensions. Folders are only created if files match their category.

```bash
sortproject
sortproject --dry  # Preview changes without moving files
```
