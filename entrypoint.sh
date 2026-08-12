#!/usr/local/bin/bash

. /lib.subr

set -e

if [ "$(id -u)" = 0 ]; then
    create_user

    change_owner "$GF_PATHS_DATA"
    change_owner "$GF_PATHS_HOME/.aws"
    change_owner "$GF_PATHS_LOGS"
    change_owner "$GF_PATHS_PLUGINS"
    change_owner "$GF_PATHS_PROVISIONING"
    change_owner "$GF_PATHS_HOME/data/plugins-bundled"
	change_owner "/usr/local/etc/grafana"

    exec su-exec noroot "$BASH_SOURCE" "$@"
fi

if [ ! -z ${GF_AWS_PROFILES+x} ]; then
    :> "$GF_PATHS_HOME/.aws/credentials"

    for profile in ${GF_AWS_PROFILES}; do
        access_key_varname="GF_AWS_${profile}_ACCESS_KEY_ID"
        secret_key_varname="GF_AWS_${profile}_SECRET_ACCESS_KEY"
        region_varname="GF_AWS_${profile}_REGION"

        if [ ! -z "${!access_key_varname}" ] && [ ! -z "${!secret_key_varname}" ]; then
            echo "[${profile}]" >> "$GF_PATHS_HOME/.aws/credentials"
            echo "aws_access_key_id = ${!access_key_varname}" >> "$GF_PATHS_HOME/.aws/credentials"
            echo "aws_secret_access_key = ${!secret_key_varname}" >> "$GF_PATHS_HOME/.aws/credentials"
            if [ ! -z "${!region_varname}" ]; then
                echo "region = ${!region_varname}" >> "$GF_PATHS_HOME/.aws/credentials"
            fi
        fi
    done

    chmod 600 "$GF_PATHS_HOME/.aws/credentials"
fi

# Convert all environment variables with names ending in __FILE into the content of
# the file that they point at and use the name without the trailing __FILE.
# This can be used to carry in Docker secrets.
for VAR_NAME in $(env | ggrep '^GF_[^=]\+__FILE=.\+' | gsed -r "s/([^=]*)__FILE=.*/\1/g"); do
    VAR_NAME_FILE="$VAR_NAME"__FILE
    if [ "${!VAR_NAME}" ]; then
        err"ERROR: Both $VAR_NAME and $VAR_NAME_FILE are set (but are exclusive)"
        exit 1
    fi
    info "Getting secret $VAR_NAME from ${!VAR_NAME_FILE}"
    export "$VAR_NAME"="$(< "${!VAR_NAME_FILE}")"
    unset "$VAR_NAME_FILE"
done

export HOME="$GF_PATHS_HOME"

if [ ! -z "${GF_INSTALL_PLUGINS}" ]; then
  warn "GF_INSTALL_PLUGINS is deprecated. Use GF_PLUGINS_PREINSTALL or GF_PLUGINS_PREINSTALL_SYNC instead. Checkout the documentation for more info."
  if [ "${GF_INSTALL_PLUGINS_FORCE}" = "true" ]; then
    OLDIFS=$IFS
    IFS=','
    for plugin in ${GF_INSTALL_PLUGINS}; do
        IFS=$OLDIFS
        if [[ $plugin =~ .*\;.* ]]; then
            pluginUrl=$(echo "$plugin" | cut -d';' -f 1)
            pluginInstallFolder=$(echo "$plugin" | cut -d';' -f 2)
            grafana cli --pluginUrl ${pluginUrl} --pluginsDir "${GF_PATHS_PLUGINS}" plugins install "${pluginInstallFolder}"
        else
            grafana cli --pluginsDir "${GF_PATHS_PLUGINS}" plugins install ${plugin}
        fi
    done
  fi
fi

exec grafana server                                         \
  --homepath="$GF_PATHS_HOME"                               \
  --config="$GF_PATHS_CONFIG"                               \
  --packaging=appjail                                       \
  "$@"                                                      \
  cfg:default.log.mode="console"                            \
  cfg:default.paths.data="$GF_PATHS_DATA"                   \
  cfg:default.paths.logs="$GF_PATHS_LOGS"                   \
  cfg:default.paths.plugins="$GF_PATHS_PLUGINS"             \
  cfg:default.paths.provisioning="$GF_PATHS_PROVISIONING"
