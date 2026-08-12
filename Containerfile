ARG FREEBSD_RELEASE

FROM ghcr.io/appjail-makejails/core:${FREEBSD_RELEASE}

ARG NO_PKGCLEAN

LABEL org.opencontainers.image.title="Grafana" \
    org.opencontainers.image.description="Dashboard and graph editor for multiple data stores" \
    org.opencontainers.image.source="https://github.com/AppJail-makejails/grafana" \
    org.opencontainers.image.url="https://github.com/AppJail-makejails/grafana" \
    org.opencontainers.image.vendor="DtxdF" \
    org.opencontainers.image.authors="Jesús Daniel Colmenares Oviedo <dtxdf@disroot.org>"

RUN set -xe; \
    \
    pkg update; \
    pkg install -U grafana bash gnugrep gsed; \
    \
    if [ -z "${NO_PKGCLEAN}" ]; then \
        pkg clean -a; \
        rm -rf /var/cache/pkg/*; \
    fi; \
    rm -rf /var/db/pkg/repos/*

ENV PATH="/usr/local/share/grafana/bin:$PATH" \
  GF_PATHS_CONFIG="/usr/local/etc/grafana/grafana.ini" \
  GF_PATHS_DATA="/var/db/grafana" \
  GF_PATHS_HOME="/usr/local/share/grafana" \
  GF_PATHS_LOGS="/var/log/grafana" \
  GF_PATHS_PLUGINS="/var/db/grafana/plugins" \
  GF_PATHS_PROVISIONING="/usr/local/etc/grafana/provisioning"

WORKDIR $GF_PATHS_HOME

RUN set -xe; \
    \
    umask 0022; \
    \
    mkdir -p "$GF_PATHS_HOME/.aws" \
    "$GF_PATHS_PROVISIONING/datasources" \
    "$GF_PATHS_PROVISIONING/dashboards" \
    "$GF_PATHS_PROVISIONING/notifiers" \
    "$GF_PATHS_PROVISIONING/plugins" \
    "$GF_PATHS_PROVISIONING/access-control" \
    "$GF_PATHS_PROVISIONING/alerting" \
    "$GF_PATHS_LOGS" \
    "$GF_PATHS_PLUGINS" \
    "$GF_PATHS_HOME/data/plugins-bundled" \
    "$GF_PATHS_DATA" \
    /usr/local/etc/grafana; \
    \
    grafana server --homepath="$GF_PATHS_HOME" -v | sed -e 's/Version //' > /.grafana-version

EXPOSE 3000

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
