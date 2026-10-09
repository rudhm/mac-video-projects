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

  mkdir -p "$target"/{01_footage,02_audio,03_graphics,04_captions,05_drafts,06_final}

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
      # Video → 01_footage
      mp4|avi|mkv|wmv|flv|webm|m4v|mov)
        dest="01_footage" ;;
      # Audio → 02_audio
      mp3|wav|flac|aac|ogg|m4a|wma)
        dest="02_audio" ;;
      # Images, Documents & Archives → 03_graphics
      png|jpg|jpeg|gif|bmp|svg|webp|avif|tiff|heic|psd|ai|pdf|doc|docx|xls|xlsx|ppt|pptx|txt|csv|rtf|zip|rar|7z|tar|gz)
        dest="03_graphics" ;;
      # Subtitles → 04_captions
      srt|vtt|ass|sub|sbv|lrc)
        dest="04_captions" ;;
      # Project Files → 00_project-files
      prproj|aep|drp|fcpx|cpr|veg)
        dest="00_project-files" ;;
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


# Automatically version a file by appending _vXX_YYYY-MM-DD
# Usage: versionfile <file>
# It checks existing files with the same base name to find the next version.
versionfile() {
  if [ -z "$1" ]; then
    echo "Usage: versionfile <file>"
    return 1
  fi
  
  local filepath="$1"
  if [ ! -f "$filepath" ]; then
    echo "❌ File not found: $filepath"
    return 1
  fi
  
  local dir=$(dirname "$filepath")
  local file=$(basename "$filepath")
  local base="${file%.*}"
  local ext="${file##*.}"
  local today=$(date "+%Y-%m-%d")
  
  # Strip any existing _vXX_YYYY-MM-DD from base to find the true base
  local true_base=$(echo "$base" | sed -E 's/_v[0-9]+_[0-9]{4}-[0-9]{2}-[0-9]{2}$//')
  
  # Find the highest version number for this true_base
  local max_v=0
  for f in "$dir"/"$true_base"_v*_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].*(N); do
    if [ -f "$f" ]; then
      local v=$(echo "$f" | grep -oE '_v[0-9]+_' | grep -oE '[0-9]+')
      if [[ -n "$v" ]] && (( v > max_v )); then
        max_v=$v
      fi
    fi
  done
  
  local next_v=$((max_v + 1))
  local next_v_pad=$(printf "%02d" $next_v)
  
  local new_name="${true_base}_v${next_v_pad}_${today}.${ext}"
  mv "$filepath" "$dir/$new_name"
  echo "✅ Renamed to: $new_name"
}

alias vf="versionfile"
