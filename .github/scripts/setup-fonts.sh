#!/usr/bin/env bash
# Makes fonts fontspec can load by name actually findable:
#
# - TeX Live ships Inconsolata, Fira Sans, EB Garamond etc. as files under
#   its own tree, not as system fonts, so fontconfig (which XeTeX and
#   LuaTeX ask to resolve a font name) does not know about them until that
#   tree is registered.
# - Arial and the other Microsoft core fonts are not part of TeX Live at
#   all; they come from the ttf-mscorefonts-installer package instead.
#
# Run after TeX Live is installed and on PATH. Needs apt; works both on the
# runner (via sudo) and as root inside a container (e.g. the full TeX Live
# image used to regenerate texlive-packages.txt).
set -uo pipefail

sudo=""
[ "$(id -u)" -eq 0 ] || sudo=sudo

# sudo drops the environment by default, so pass DEBIAN_FRONTEND through
# env rather than exporting it
$sudo debconf-set-selections <<< \
  "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true"
$sudo env DEBIAN_FRONTEND=noninteractive apt-get update
$sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  --no-install-recommends fontconfig ttf-mscorefonts-installer

root=$(kpsewhich -var-value TEXMFROOT)
conf=/etc/fonts/conf.d/09-texlive.conf
$sudo tee "$conf" > /dev/null <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <dir>$root/texmf-dist/fonts/opentype</dir>
  <dir>$root/texmf-dist/fonts/truetype</dir>
  <dir>$root/texmf-dist/fonts/type1</dir>
</fontconfig>
EOF
$sudo fc-cache -f
