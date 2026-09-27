#!/usr/bin/env bash
# Compiles ROOT_FILE with latexmk. When TeX cannot find a file, looks up the
# TeX Live package that provides it and reports it in the job summary.
# With --resolve, also installs that package, adds it to texlive-packages.txt
# and compiles again, until the document compiles or no provider is found.
set -uo pipefail

resolve=false
[ "${1-}" = --resolve ] && resolve=true
log="${ROOT_FILE%.tex}.log"
summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
# Stop TeX wrapping log lines at 79 characters, so each error is on one line
export max_print_line=100000

# Files TeX reported as missing in the log (a font name without an extension
# comes from XeTeX/LuaTeX, which look fonts up by name)
missing_files() {
  sed -nE \
    -e "s/.*LaTeX Error: File \`([^']+)' not found.*/\\1/p" \
    -e "s/.*I can't find file \`([^']+)'.*/\\1/p" \
    -e 's/.*Font \\?[^= ]+=\[([^]]+)\].* not loadable.*/\1/p' \
    -e 's/.*Font \\?[^= ]+=([^ :"[]+) .* not loadable: Metric.*/\1.tfm/p' \
    "$log" 2>/dev/null | sort -u
}

# TeX Live package containing that file (matching with or without extension)
provider() {
  tlmgr search --global --file "/$1" 2>/dev/null | awk -v f="$1" '
    /^[^ \t].*:$/ { pkg = substr($0, 1, length($0) - 1); next }
    {
      n = split($1, path, "/")
      if (path[n] == f || index(path[n], f ".") == 1) { print pkg; exit }
    }'
}

added=()
while true; do
  latexmk "$ENGINE" -file-line-error -interaction=nonstopmode "$ROOT_FILE" && break

  mapfile -t files < <(missing_files)
  [ ${#files[@]} -eq 0 ] && exit 1
  packages=()
  for file in "${files[@]}"; do
    package=$(provider "$file")
    if [ -z "$package" ]; then
      echo "::error::No TeX Live package provides $file"
      echo "No TeX Live package provides \`$file\`." >> "$summary"
      exit 1
    fi
    if $resolve; then
      echo "::notice::$file is missing; installing the TeX Live package $package"
    else
      echo "::error::$file is missing; it is in the TeX Live package $package"
      echo "\`$file\` is missing; add \`$package\` to \`texlive-packages.txt\`." >> "$summary"
    fi
    packages+=("$package")
  done

  mapfile -t packages < <(printf '%s\n' "${packages[@]}" | sort -u)

  if ! $resolve; then
    echo "To find every missing package, run this workflow manually with \"Resolve missing packages\" ticked." >> "$summary"
    exit 1
  fi
  for package in "${packages[@]}"; do
    # Stop if installing a package did not make its file available
    if [[ " ${added[*]-} " == *" $package "* ]]; then exit 1; fi
  done
  tlmgr install "${packages[@]}" || exit 1
  printf '%s\n' "${packages[@]}" >> texlive-packages.txt
  added+=("${packages[@]}")
done

if [ ${#added[@]} -gt 0 ]; then
  echo "Added to \`texlive-packages.txt\`: ${added[*]}" >> "$summary"
fi
