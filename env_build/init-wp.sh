#!/bin/sh
set -eu

WP_PATH="${WP_PATH:-/var/www/html}"
URL="${URL:-http://localhost:8080}"
TITLE="${TITLE:-wp-test}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-admin1234}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
CANTO_SLUG="${CANTO_SLUG:-${PLUGIN_SLUG:-canto}}"
CANTO_VERSION="${CANTO_VERSION:-${PLUGIN_VERSION:-3.0.4}}"
CANTO_ZIP="${CANTO_ZIP:-/plugins/canto.3.0.4.zip}"
MYCAL_SLUG="${MYCAL_SLUG:-my-calendar}"
MYCAL_VERSION="${MYCAL_VERSION:-3.4.0}"
MYCAL_ZIP="${MYCAL_ZIP:-/plugins/my-calendar.3.4.0.zip}"

log() {
  printf '%s\n' "$*"
}

wait_for_file() {
  file="$1"
  tries="${2:-60}"
  sleep_s="${3:-2}"

  i=0
  while [ "$i" -lt "$tries" ]; do
    if [ -f "$file" ]; then
      return 0
    fi
    i=$((i + 1))
    sleep "$sleep_s"
  done
  return 1
}

ensure_plugin() {
  slug="$1"
  desired_version="$2"
  zip_path="${3:-}"

  log "[*] Ensuring plugin $slug@$desired_version is installed..."

  if wp plugin is-installed "$slug" --allow-root >/dev/null 2>&1; then
    current_version="$(wp plugin get "$slug" --field=version --allow-root 2>/dev/null || true)"
    if [ "$current_version" != "$desired_version" ]; then
      log "[*] Updating $slug ($current_version -> $desired_version)..."
      wp plugin deactivate "$slug" --allow-root >/dev/null 2>&1 || true
      if [ -n "$zip_path" ] && [ -f "$zip_path" ]; then
        wp plugin install "$zip_path" --force --allow-root >/dev/null
      else
        wp plugin install "$slug" --version="$desired_version" --force --allow-root >/dev/null
      fi
    fi
  else
    if [ -n "$zip_path" ] && [ -f "$zip_path" ]; then
      wp plugin install "$zip_path" --allow-root >/dev/null
    else
      wp plugin install "$slug" --version="$desired_version" --allow-root >/dev/null
    fi
  fi
}

cd "$WP_PATH"

log "[*] Waiting for WordPress files/config..."
if ! wait_for_file "wp-config.php" 60 2; then
  log "[!] Timed out waiting for wp-config.php in $WP_PATH"
  exit 1
fi
if ! wait_for_file "wp-includes/version.php" 60 2; then
  log "[!] Timed out waiting for WordPress core files in $WP_PATH"
  exit 1
fi

if wp core is-installed --allow-root >/dev/null 2>&1; then
  log "[*] WordPress already installed."
else
  log "[*] Installing WordPress core..."
  i=0
  while [ "$i" -lt 30 ]; do
    if wp core install \
      --url="$URL" \
      --title="$TITLE" \
      --admin_user="$ADMIN_USER" \
      --admin_password="$ADMIN_PASS" \
      --admin_email="$ADMIN_EMAIL" \
      --skip-email \
      --allow-root; then
      break
    fi
    i=$((i + 1))
    log "[!] wp core install failed; retrying ($i/30)..."
    sleep 2
  done

  if ! wp core is-installed --allow-root >/dev/null 2>&1; then
    log "[!] WordPress core install did not complete successfully."
    exit 1
  fi
fi

log "[*] Disabling built-in plugin/theme file editor (DISALLOW_FILE_EDIT)..."
if ! wp config set DISALLOW_FILE_EDIT true --raw --type=constant --allow-root >/dev/null 2>&1; then
  log "[!] Failed to update wp-config.php (non-fatal); will rely on mu-plugin."
fi

log "[*] Ensuring admin user ($ADMIN_USER) exists with expected password..."
if wp user get "$ADMIN_USER" --field=ID --allow-root >/dev/null 2>&1; then
  wp user update "$ADMIN_USER" \
    --user_pass="$ADMIN_PASS" \
    --user_email="$ADMIN_EMAIL" \
    --role=administrator \
    --allow-root >/dev/null
else
  wp user create "$ADMIN_USER" "$ADMIN_EMAIL" \
    --role=administrator \
    --user_pass="$ADMIN_PASS" \
    --allow-root >/dev/null
fi

ensure_plugin "$CANTO_SLUG" "$CANTO_VERSION" "$CANTO_ZIP"
log "[*] Activating $CANTO_SLUG..."
wp plugin activate "$CANTO_SLUG" --allow-root >/dev/null 2>&1 || true

ensure_plugin "$MYCAL_SLUG" "$MYCAL_VERSION" "$MYCAL_ZIP"

log "[*] Done."
