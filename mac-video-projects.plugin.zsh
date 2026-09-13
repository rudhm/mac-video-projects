# Usage: newproject ClientName        → creates ~/Projects/ClientName/...
#        newproject ClientName Phase2  → creates ~/Projects/ClientName/Phase2/...
newproject() {
  if [ -z "$1" ]; then
    echo "Usage: newproject <project-name> [sub-project]"
    echo "Example: newproject Carvaidya Lot-69"
    return 1
  fi

  local base
  local existing_base=$(find "$HOME/Projects" -maxdepth 1 -iname "$1" -type d 2>/dev/null | head -n 1)

  if [ -n "$existing_base" ]; then
    base="$existing_base"
    if [ "$(basename "$base")" != "$1" ]; then
      echo "ℹ️  Using existing project: $(basename "$base")"
    fi
  else
    base="$HOME/Projects/$1"
  fi

  local target="$base"

  if [ -n "$2" ]; then
    local existing_sub=$(find "$base" -maxdepth 1 -iname "$2" -type d 2>/dev/null | head -n 1)
    if [ -n "$existing_sub" ]; then
      target="$existing_sub"
      if [ "$(basename "$target")" != "$2" ]; then
        echo "ℹ️  Using existing sub-project: $(basename "$target")"
      fi
    else
      target="$base/$2"
    fi
  fi

  mkdir -p "$target"/{footage,audio,graphics,exports,assets,captions}

  echo "✅ Created/Updated project structure:"
  find "$target" -type d | sed "s|$HOME/||" | sort | head -20

  # Seamlessly pin the folder to the sidebar
  osascript <<EOF
tell application "System Events" to set activeApp to name of first application process whose frontmost is true
tell application "Finder" to activate
tell application "Finder" to open (POSIX file "$target" as alias)
delay 0.5
tell application "System Events" to keystroke "t" using {command down, control down}
delay 0.3
tell application "Finder" to close front window
tell application activeApp to activate
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

  mkdir -p footage audio graphics exports assets captions

  for file in *; do
    # skip directories and dotfiles
    [ -d "$file" ] && continue
    [[ "$file" == .* ]] && continue

    local ext="${file##*.}"
    ext="${ext:l}"  # lowercase the extension
    local dest=""

    case "$ext" in
      # Video → footage
      mov|mp4|avi|mkv|wmv|flv|webm|m4v|mov)
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
      # Documents → assets
      pdf|doc|docx|xls|xlsx|ppt|pptx|txt|csv|rtf)
        dest="assets" ;;
      *)
        # unknown extension — skip
        ;;
    esac

    if [ -n "$dest" ]; then
      if $dry; then
        echo "  $file → $dest/"
      else
        mv "$file" "$dest/" 2>/dev/null
      fi
      moved=$((moved + 1))
    fi
  done

  # remove empty folders if nothing was moved into them
  if ! $dry; then
    for d in footage audio graphics exports assets captions; do
      rmdir "$d" 2>/dev/null  # only removes if empty
    done
  fi

  echo "\n✅ $moved file(s) sorted"
}
