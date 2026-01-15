FROM wordpress:latest

ARG POLKIT_VERSION=0.120

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip; \
  if apt-cache policy pkexec | awk -F': ' '/Candidate:/ {print $2}' | grep -vq '(none)'; then \
    apt-get install -y --no-install-recommends pkexec polkitd; \
  elif apt-cache policy policykit-1 | awk -F': ' '/Candidate:/ {print $2}' | grep -vq '(none)'; then \
    apt-get install -y --no-install-recommends policykit-1; \
  elif apt-cache policy polkit | awk -F': ' '/Candidate:/ {print $2}' | grep -vq '(none)'; then \
    apt-get install -y --no-install-recommends polkit; \
  else \
    echo >&2 "[!] No polkit package candidate found (pkexec/polkitd/policykit-1/polkit)."; \
    exit 1; \
  fi; \
  pkver="$(pkexec --version 2>/dev/null | awk '{print $3}' || true)"; \
  if [ -z "$pkver" ]; then \
    echo >&2 "[!] pkexec not found after install."; \
    exit 1; \
  fi; \
  dpkg --compare-versions "$pkver" ge "$POLKIT_VERSION"; \
  rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  { \
    echo 'allow_url_fopen = On'; \
    echo 'allow_url_include = On'; \
  } > /usr/local/etc/php/conf.d/zz-allow-url-include.ini

RUN mkdir -p /usr/src/wordpress/wp-content/mu-plugins
COPY mu-plugins/disable-file-editor.php /usr/src/wordpress/wp-content/mu-plugins/disable-file-editor.php

COPY plugins/canto.3.0.4.zip /tmp/canto.zip
COPY plugins/my-calendar.3.4.0.zip /tmp/my-calendar.zip
RUN mkdir -p /usr/src/wordpress/wp-content/plugins \
  && unzip -q /tmp/canto.zip -d /usr/src/wordpress/wp-content/plugins \
  && unzip -q /tmp/my-calendar.zip -d /usr/src/wordpress/wp-content/plugins \
  && rm -f /tmp/canto.zip /tmp/my-calendar.zip \
  && chown -R www-data:www-data /usr/src/wordpress/wp-content/plugins

RUN set -eux; \
  if [ ! -f /usr/local/bin/docker-entrypoint.sh ]; then \
    echo >&2 "[!] Expected /usr/local/bin/docker-entrypoint.sh not found in base image."; \
    exit 1; \
  fi; \
  mv /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint-original.sh
COPY wp-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN cat > /etc/apache2/conf-available/uploads-index.conf <<'EOF'
<Directory "/var/www/html/wp-content/uploads">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
EOF

RUN a2enconf uploads-index

RUN set -eux; \
  printf '%s\n' 'ASC{U_F1nD_@_F149_c0ngr4t3s!!}' > /flag.txt; \
  chown root:root /flag.txt; \
  chmod 400 /flag.txt
# LPE
RUN apt update && apt install -y sudo && \
    echo 'www-data ALL=(root) NOPASSWD: /usr/local/bin/php' \
    > /etc/sudoers.d/wp-lpe && \
    chmod 440 /etc/sudoers.d/wp-lpe
