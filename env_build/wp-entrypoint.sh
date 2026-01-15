#!/bin/sh
set -eu

sync_mu_plugin_file() {
  file="$1"

  src="/usr/src/wordpress/wp-content/mu-plugins/$file"
  dst="/var/www/html/wp-content/mu-plugins/$file"

  if [ -f "$src" ]; then
    mkdir -p /var/www/html/wp-content/mu-plugins
    cp -a "$src" "$dst"
    chown www-data:www-data "$dst" 2>/dev/null || true
  fi
}

sync_plugin_dir() {
  slug="$1"

  src="/usr/src/wordpress/wp-content/plugins/$slug"
  dst="/var/www/html/wp-content/plugins/$slug"

  if [ -d "$src" ] && [ ! -d "$dst" ]; then
    mkdir -p /var/www/html/wp-content/plugins
    cp -a "$src" /var/www/html/wp-content/plugins/
    chown -R www-data:www-data "$dst" 2>/dev/null || true
  fi
}

# If /var/www/html is a persisted volume, upstream entrypoint won't re-copy new plugins.
sync_mu_plugin_file "disable-file-editor.php"
sync_plugin_dir "canto"
sync_plugin_dir "my-calendar"

exec /usr/local/bin/docker-entrypoint-original.sh "$@"
