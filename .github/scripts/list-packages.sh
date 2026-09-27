#!/usr/bin/env bash
# Run inside a full TeX Live install. Compiles ROOT_FILE, then rewrites
# texlive-packages.txt with the TeX Live packages providing every file TeX
# and its tools read, every format loaded, and every program latexmk ran.
set -uo pipefail

# Compile once untraced, so that building any missing format (which reads
# every installed language's hyphenation patterns) is not recorded
latexmk "$ENGINE" -interaction=nonstopmode "$ROOT_FILE" > /dev/null 2>&1
latexmk -C "$ROOT_FILE" > /dev/null 2>&1

# kpathsea logs every file it finds, including fonts XeTeX and xdvipdfmx
# load, which latexmk's .fls record of TeX's own reads omits
KPATHSEA_DEBUG=32 latexmk "$ENGINE" -recorder -file-line-error -interaction=nonstopmode "$ROOT_FILE" \
  > latexmk.out 2> kpathsea.log
status=$?
# Show the build output without the kpathsea debug lines
cat latexmk.out; grep -v '^kdebug:' kpathsea.log >&2 || true
[ $status -eq 0 ] || exit $status

root=$(kpsewhich -var-value TEXMFROOT)
arch=$(basename "$(kpsewhich -var-value SELFAUTOLOC)")
fls="${ROOT_FILE%.tex}.fls"

{
  # Files read from the TeX Live tree, relative to its root
  sed -n "s|^INPUT $root/||p" "$fls"
  grep -o "$root/[^ ]*" kpathsea.log | cut -c $((${#root} + 2))- || true
  # Formats, which TeX Live builds at install time rather than shipping
  { cat "$fls"; tr ' ' '\n' < kpathsea.log; } | sed -nE 's|^(INPUT )?/.*/([^/]+)\.fmt$|format \2|p'
  # Programs latexmk ran (rule names such as xelatex, "biber main"), and latexmk
  # (latexmk prints its own messages to stderr)
  cat latexmk.out kpathsea.log | sed -nE "s/^Latexmk: Run number [0-9]+ of rule '([^ ']+).*/bin\/$arch\/\1/p"
  echo "bin/$arch/latexmk"
} | sort -u > used.txt

# Owner of each file, binary (package.arch counts as package) and format
awk '
  /^name / { pkg = $2; sub(/\.[^.]*-(linux|darwin|freebsd|solaris|netbsd|cygwin)$/, "", pkg); next }
  /^(runfiles|binfiles)/ { files = 1; next }
  /^execute AddFormat/ { for (i = 3; i <= NF; i++) if ($i ~ /^name=/) print "format " substr($i, 6) "\t" pkg }
  /^[^ ]/ { files = 0 }
  files && /^ / { print $1 "\t" pkg }
' "$root/tlpkg/texlive.tlpdb" > owners.txt

packages=$(awk -F'\t' 'NR == FNR { used[$0] = 1; next } ($1 in used) { print $2 }' used.txt owners.txt | sort -u)

{
  sed -n '/^#/p' texlive-packages.txt
  echo "$packages"
} > texlive-packages.new
mv texlive-packages.new texlive-packages.txt
rm used.txt owners.txt latexmk.out kpathsea.log
cat texlive-packages.txt
