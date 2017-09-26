#!/bin/bash

set -e

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

: ${ODOO_CONF:=${ODOO_RC:='/var/lib/odoo/odoo.conf'}}

DB_ARGS=()
DB_ARGS+=("--config")
DB_ARGS+=("$ODOO_CONF")

function check_config() {
    param="$1"
    value="$2"
    if ! grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_CONF" ; then
        DB_ARGS+=("--${param}")
        DB_ARGS+=("${value}")
   fi;
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

DB_ARGS+=("--load")
DB_ARGS+=("web,web_kanban,dbfilter_from_header,isme_db_debrand")

function extra_config() {
    param="$1"
    value="$2"
    if [[ $value ]] ; then
        DB_ARGS+=("--${param}")
        DB_ARGS+=("${value}")
    fi;
}

extra_config "proxy-mode" "$PROXY_MODE"
extra_config "database" "$DATABASE"
extra_config "db_maxconn" "$DB_MAXCONN"
extra_config "update" "$UPDATE"
extra_config "init" "$INIT"
extra_config "osv-memory-count-limit" "$OSV_MEMORY_COUNT_LIMIT"
extra_config "osv-memory-age-limit" "$OSV_MEMORY_AGE_LIMIT"
extra_config "max-cron-threads" "$MAX_CRON_THREADS"
extra_config "workers" "$WORKERS"
extra_config "limit-memory-soft" "$LIMIT_MEMORY_SOFT"
extra_config "limit-memory-hard" "$LIMIT_MEMORY_HARD"
extra_config "limit-time-cpu" "$LIMIT_TIME_CPU"
extra_config "limit-time-real" "$LIMIT_TIME_REAL"
extra_config "limit-time-real-cron" "$LIMIT_TIME_REAL_CRON"
extra_config "limit-request" "$LIMIT_REQUEST"

# Change uid based on env
CUID=${CUID:-1000}
CGID=${CGID:-1000}
usermod -u $CUID odoo
groupmod -g $CGID odoo
usermod -g $CGID odoo

# change owner
chown -R $CUID:$CGID /etc/odoo/
chown $CUID:$CGID /var/lib/odoo
chown $CUID:$CGID /mnt/extra-addons
chown $CUID:$CGID /mnt/extra-addons2
chown $CUID:$CGID /mnt/extra-addons3

# Copy conf file if not exists
if [ -e $ODOO_CONF ] then
    cp /etc/odoo/odoo.conf $ODOO_CONF
fi;

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec gosu $CUID:$CGID odoo "$@"
        else
            exec gosu $CUID:$CGID odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        exec gosu $CUID:$CGID odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
