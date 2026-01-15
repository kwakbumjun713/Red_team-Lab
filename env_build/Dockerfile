FROM wordpress:latest

ARG POLKIT_VERSION=0.120

# 필요한 툴 + polkit(최소 0.120 보장)
# NOTE: wordpress:latest는 Debian bookworm 기반이라 libmozjs-78-dev가 없어 polkit 0.120 소스 빌드는 깨집니다.
#       대신 distro 패키지(pkexec/polkitd 또는 policykit-1)를 설치하고 버전만 검증합니다.
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

# PHP 설정(의도적으로 취약하게): allow_url_include 활성화
RUN set -eux; \
  { \
    echo 'allow_url_fopen = On'; \
    echo 'allow_url_include = On'; \
  } > /usr/local/etc/php/conf.d/zz-allow-url-include.ini

# WP 관리자 파일 편집기 비활성화(mu-plugin)
RUN mkdir -p /usr/src/wordpress/wp-content/mu-plugins
COPY mu-plugins/disable-file-editor.php /usr/src/wordpress/wp-content/mu-plugins/disable-file-editor.php

# 플러그인 설치(zip을 빌드 컨텍스트에 포함해서 DNS/네트워크 이슈 회피)
# NOTE: docker-compose에서 /var/www/html이 volume으로 덮이므로, 기본 wp 소스(/usr/src/wordpress)에 넣어야
#       최초 실행 시 entrypoint가 볼륨으로 복사합니다.
COPY plugins/canto.3.0.4.zip /tmp/canto.zip
COPY plugins/my-calendar.3.4.0.zip /tmp/my-calendar.zip
RUN mkdir -p /usr/src/wordpress/wp-content/plugins \
  && unzip -q /tmp/canto.zip -d /usr/src/wordpress/wp-content/plugins \
  && unzip -q /tmp/my-calendar.zip -d /usr/src/wordpress/wp-content/plugins \
  && rm -f /tmp/canto.zip /tmp/my-calendar.zip \
  && chown -R www-data:www-data /usr/src/wordpress/wp-content/plugins

# 플러그인 동기화: 기존 wp 볼륨이 있어도(초기화가 끝난 상태여도) 누락된 플러그인을 복사
RUN set -eux; \
  if [ ! -f /usr/local/bin/docker-entrypoint.sh ]; then \
    echo >&2 "[!] Expected /usr/local/bin/docker-entrypoint.sh not found in base image."; \
    exit 1; \
  fi; \
  mv /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint-original.sh
COPY wp-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# uploads 디렉터리 인덱싱 허용(의도적으로 취약하게)
RUN cat > /etc/apache2/conf-available/uploads-index.conf <<'EOF'
<Directory "/var/www/html/wp-content/uploads">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
EOF

RUN a2enconf uploads-index

# flag 파일(루트만 읽기 가능)
RUN set -eux; \
  printf '%s\n' 'ASC{U_F1nD_@_F149_c0ngr4t3s!!}' > /flag.txt; \
  chown root:root /flag.txt; \
  chmod 400 /flag.txt
# LPE
RUN apt update && apt install -y sudo && \
    echo 'www-data ALL=(root) NOPASSWD: /usr/local/bin/php' \
    > /etc/sudoers.d/wp-lpe && \
    chmod 440 /etc/sudoers.d/wp-lpe
