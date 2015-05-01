{%- load_yaml as vars %}
{{ vars }}
{%- endload -%}
#!/bin/bash

PROGPATH=$(realpath ${BASH_SOURCE})

DWORK=$(dirname ${PROGPATH})
PROG=$(basename ${PROGPATH})
LOG=/tmp/${PROG}.log

if ! tty -s ; then
    trap ":" INT QUIT TSTP
    exec > ${LOG} 2>&1
    set -x
fi

source ${DWORK}/svc-functions.sh

export LOGGER_TAG="backup.${PROG}@${HOSTNAME}"

set_sandbox

REDIS_BAK_DIR=$(realpath {{ vars.bak_dir|default('/home/data/redis.bak') }})
REDIS_DB_DIR={{ vars.db_dir|default('/home/data/redis') }}
REDIS_DB="{{ vars.dbs }}"

pushd ${REDIS_BAK_DIR} > /dev/null
if [ $? -eq 0 ] ; then
    enable_sandbox ${REDIS_BAK_DIR}

    for db in ${REDIS_DB}; do
        log_and_run "cat ${REDIS_DB_DIR}/${db}/${db}.rdb | gzip -c > ${db}.$(date +%Y%m%d-%H%M).rdb.gz" || DOMAIL=1
    done

    # cleanup obsoleted files
    [ -d ${REDIS_BAK_DIR}/obsoleted ] || mkdir ${REDIS_BAK_DIR}/obsoleted

    find ${REDIS_BAK_DIR} -maxdepth 1 -name "*.gz" -mtime +7 -exec mv '{}' ./obsoleted/ \;

    disable_sandbox

    popd > /dev/null
else
    DOMAIL=1
fi

unset_sandbox

if [[ ${DOMAIL:-0} -ne 0 ]] ; then
    cat ${LOG} | mail -s "${LOGGER_TAG} failed" root
fi
