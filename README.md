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
Client and subfolder names are converted to title case when new folders are
created.

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
- `footage`
- `audio`
- `graphics`
- `exports`
- `assets` (now includes archives like .zip, .rar)
- `captions`
- `project-files` (created by sortproject for .prproj, .aep, .drp, etc.)

*Bonus:* It automatically handles casing if the folder already exists, and instantly pins the newly created folder to your macOS Finder sidebar! (Requires Terminal Accessibility permissions).

### `sortproject`
Sorts loose files in your current directory into the standard subfolders based on their file extensions. Folders are only created if files match their category.

```bash
sortproject
sortproject --dry  # Preview changes without moving files
```
