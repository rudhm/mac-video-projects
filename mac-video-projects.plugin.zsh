# Usage: newproject ClientName        → creates $MAC_VIDEO_PROJECTS_DIR/ClientName/Month Day/...
#        newproject ClientName Phase2  → creates $MAC_VIDEO_PROJECTS_DIR/ClientName/Phase2/...
newproject() {
  if [ -z "$1" ]; then
    echo "Usage: newproject <project-name> [sub-project]"
    echo "Example: newproject Carvaidya Lot-69"
    return 1
  fi

  # Support custom directory, fallback to ~/Projects
  local projects_dir="${MAC_VIDEO_PROJECTS_DIR:-$HOME/Projects}"
  mkdir -p "$projects_dir"

  # Enable case-insensitive globbing for this function for fast lookups
  setopt local_options nocaseglob

  local client_name="${(C)1}"
  local base="$projects_dir/$client_name"
  # Look for existing case-insensitive match
  local existing_bases=("$projects_dir"/$client_name(N/))
  if (( ${#existing_bases[@]} > 0 )); then
    base="${existing_bases[1]}"
    if [ "$(basename "$base")" != "$client_name" ]; then
      echo "ℹ️  Using existing project: $(basename "$base")"
    fi
  fi

  local target="$base"

  if [ -n "$2" ]; then
    # Preserve sub-project identifiers exactly as entered (for example, MPCVL70L1).
    local subproject_name="$2"
    local existing_subs=("$base"/$subproject_name(N/))
    if (( ${#existing_subs[@]} > 0 )); then
      target="${existing_subs[1]}"
      if [ "$(basename "$target")" != "$subproject_name" ]; then
        echo "ℹ️  Using existing sub-project: $(basename "$target")"
      fi
    else
      target="$base/$subproject_name"
    fi
  else
    target="$base/$(date "+%B %-d")"
  fi

  mkdir -p "$target"/{footage,audio,graphics,exports,assets,captions}

  echo "✅ Created/Updated project structure:"
  find "$target" -type d | sed "s|^$projects_dir/||" | sort | head -20

  # Seamlessly pin the folder to the sidebar, handling permission errors gracefully
  osascript <<EOF &>/dev/null
try
  tell application "System Events"
    if not UI elements enabled then return
  end tell
  
  tell application "System Events" to set activeApp to name of first application process whose frontmost is true
  tell application "Finder" to activate
  tell application "Finder" to open (POSIX file "$target" as alias)
  delay 0.5
  tell application "System Events" to keystroke "t" using {command down, control down}
  delay 0.3
  tell application "Finder" to close front window
  tell application activeApp to activate
on error
  -- Silently fail if accessibility permissions are denied or other errors occur
end try
EOF
}

# Shorter alias for newproject
alias np="newproject"

# Sort files in current folder into project subfolders by extension
# Usage: sortproject         → sorts files in current directory
#        sortproject --dry   → preview what would happen (no files moved)
sortproject() {
  local dry=false
  if [ "$1" = "--dry" ]; then
    dry=true
    echo "🔍 DRY RUN — nothing will be moved\n"
  fi

  local moved=0

  for file in *; do
    # skip directories and dotfiles
    [ -d "$file" ] && continue
    [[ "$file" == .* ]] && continue

    local ext="${file##*.}"
    ext="${ext:l}"  # lowercase the extension
    local dest=""

    case "$ext" in
      # Video → footage
      mp4|avi|mkv|wmv|flv|webm|m4v|mov)
        dest="footage" ;;
      # Audio → audio
      mp3|wav|flac|aac|ogg|m4a|wma)
        dest="audio" ;;
      # Images → graphics
      png|jpg|jpeg|gif|bmp|svg|webp|avif|tiff|heic|psd|ai)
        dest="graphics" ;;
      # Subtitles → captions
      srt|vtt|ass|sub|sbv|lrc)
        dest="captions" ;;
      # Documents & Archives → assets
      pdf|doc|docx|xls|xlsx|ppt|pptx|txt|csv|rtf|zip|rar|7z|tar|gz)
        dest="assets" ;;
      # Project Files → project-files
      prproj|aep|drp|fcpx|cpr|veg)
        dest="project-files" ;;
      *)
        # unknown extension — skip
        ;;
    esac

    if [ -n "$dest" ]; then
      if $dry; then
        echo "  $file → $dest/"
      else
        # Only create the folder if a file is actually going into it
        [ ! -d "$dest" ] && mkdir -p "$dest"
        mv "$file" "$dest/" 2>/dev/null
      fi
      moved=$((moved + 1))
    fi
  done

  echo "\n✅ $moved file(s) sorted"
}
