#!/usr/bin/env bash
# Run inside a full TeX Live install. Compiles ROOT_FILE, then rewrites
# texlive-packages.txt with the TeX Live packages providing every file TeX
# read (from latexmk's .fls record), every format it loaded, and every
# program latexmk ran.
set -euo pipefail

latexmk "$ENGINE" -recorder -file-line-error -interaction=nonstopmode "$ROOT_FILE" | tee latexmk.out

root=$(kpsewhich -var-value TEXMFROOT)
arch=$(basename "$(kpsewhich -var-value SELFAUTOLOC)")
fls="${ROOT_FILE%.tex}.fls"

{
  # Files read from the TeX Live tree, relative to its root
  sed -n "s|^INPUT $root/||p" "$fls"
  # Formats, which TeX Live builds at install time rather than shipping
  sed -nE 's|^INPUT .*/([^/]+)\.fmt$|format \1|p' "$fls"
  # Programs latexmk ran (rule names such as xelatex, "biber main"), and latexmk
  sed -nE "s/^Latexmk: Run number [0-9]+ of rule '([^ ']+).*/bin\/$arch\/\1/p" latexmk.out
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
rm used.txt owners.txt latexmk.out
cat texlive-packages.txt
