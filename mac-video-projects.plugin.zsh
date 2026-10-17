# Usage: newproject ClientName        → creates $MAC_VIDEO_PROJECTS_DIR/ClientName/Month Day/...
#        newproject ClientName Phase2  → creates $MAC_VIDEO_PROJECTS_DIR/ClientName/Phase2/...
newproject() {
  local open_url=false
  local no_pin=false
  local editor_choice="${MAC_VIDEO_PROJECTS_EDITOR:-}"
  local args=()

  while (( $# > 0 )); do
    case "$1" in
      -u|--url)
        open_url=true ;;
      -p|--premiere)
        editor_choice="p" ;;
      -c|--capcut)
        editor_choice="c" ;;
      -s|--skip|-n|--no-editor)
        editor_choice="none" ;;
      --no-pin)
        no_pin=true ;;
      -h|--help)
        echo "Usage: newproject [-u] [-p|-c|-s] [--no-pin] <project-name> [sub-project]"
        echo "Aliases: np"
        echo ""
        echo "Options:"
        echo "  -u, --url       Open tracking spreadsheet in default browser"
        echo "  -p, --premiere  Directly open project path in Premiere Pro"
        echo "  -c, --capcut    Directly open CapCut"
        echo "  -s, --skip      Skip opening an editor (no prompt)"
        echo "  --no-pin        Skip pinning project to Finder sidebar"
        return 0 ;;
      *)
        args+=("$1") ;;
    esac
    shift
  done

  if (( ${#args[@]} == 0 )); then
    echo "Usage: newproject [-u] [-p|-c|-s] [--no-pin] <project-name> [sub-project]"
    echo "Example: newproject -u Carvaidya Lot-69"
    return 1
  fi

  # Support custom directory, fallback to ~/Projects
  local projects_dir="${MAC_VIDEO_PROJECTS_DIR:-$HOME/Projects}"
  mkdir -p "$projects_dir"

  # Enable case-insensitive globbing for this function for fast lookups
  setopt local_options nocaseglob

  local client_name="${(C)args[1]}"
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

  if (( ${#args[@]} > 1 )); then
    # Preserve sub-project identifiers exactly as entered (for example, MPCVL70L1).
    local subproject_name="${args[2]}"
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

  local rel_target="${target#$projects_dir/}"
  echo "✅ Created/Updated project structure:"
  echo "$rel_target"
  for sub in 01_footage 02_audio 03_graphics 04_captions 05_drafts 06_final; do
    echo "$rel_target/$sub"
  done

  # Always copy target directory path to macOS clipboard as a convenience
  print -n -r -- "$target" | pbcopy

  # Pin folder to Finder sidebar in background without stealing screen focus or delaying terminal
  if [[ "${MAC_VIDEO_PROJECTS_PIN_SIDEBAR:-true}" != "false" ]] && ! $no_pin; then
    (
      osascript 2>/dev/null <<EOF
try
  tell application "Finder" to reveal (POSIX file "$target" as alias)
  tell application "System Events" to tell process "Finder"
    click menu item "Add to Sidebar" of menu "File" of menu bar 1
  end tell
  tell application "Finder" to close front window
on error
end try
EOF
    ) &!
  fi

  # Open tracking spreadsheet if -u was provided
  if $open_url; then
    open "https://docs.google.com/spreadsheets/d/1laNvw3iefHJpQiySSKjZFQ1QBrIsxhQWSD8rq0NaXvE/edit?gid=78774952#gid=78774952"
  fi

  # Ask which editor to open (or use flag / environment setting)
  local choice="$editor_choice"
  if [[ -z "$choice" ]]; then
    if [[ -t 0 ]]; then
      read -k 1 "choice?Open in (p) Premiere, (c) CapCut, or any other key to skip: "
      echo
    fi
  fi

  case "${choice:l}" in
    p)
      local premiere=(/Applications/Adobe\ Premiere\ Pro*/Adobe\ Premiere\ Pro*.app(N))
      if (( ${#premiere[@]} > 0 )); then
        local plugin_dir="${${(%):-%x}:A:h}"
        [[ -z "$plugin_dir" || "$plugin_dir" == "." ]] && plugin_dir="$HOME/Code/mac-video-projects"
        local template="$plugin_dir/template.prproj"
        
        # Determine project file name from target folder name
        local project_name="$(basename "$target")"
        local project_file="$target/$project_name.prproj"

        # Check for existing project file or initialize from clean template
        local existing_projects=("$target"/*.prproj(N))
        if (( ${#existing_projects[@]} > 0 )); then
          project_file="${existing_projects[1]}"
        elif [[ -f "$template" ]]; then
          cp "$template" "$project_file"
        elif [[ -f "/Applications/Adobe Premiere Pro 2026/Adobe Premiere Pro 2026.app/Contents/Resources/TemplateProjects/en_US/Standard Template Project.prproj" ]]; then
          cp "/Applications/Adobe Premiere Pro 2026/Adobe Premiere Pro 2026.app/Contents/Resources/TemplateProjects/en_US/Standard Template Project.prproj" "$project_file"
        fi


        if [[ -f "$project_file" ]]; then
          open -a "${premiere[-1]}" "$project_file"
          echo "🎬 Premiere Pro opened project at exact path: $(basename "$project_file")"
        else
          open -a "${premiere[-1]}"
          echo "🎬 Premiere Pro opening."
        fi
      else
        echo "⚠️  Premiere Pro not found in /Applications"
      fi ;;
    c)
      open -a "CapCut" || echo "⚠️  CapCut not found" ;;
  esac
}

# Shorter function and alias for newproject
unalias np 2>/dev/null
np() {
  newproject "$@"
}
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

  for file in *(N); do
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

unalias vf 2>/dev/null
vf() {
  versionfile "$@"
}
alias vf="versionfile"
