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

MONGO_BAK_DIR=$(realpath {{ vars.bak_dir|default('/home/data/mongo.bak') }})
MONGO_DB="{{ vars.dbs }}"

pushd ${MONGO_BAK_DIR} > /dev/null
if [ $? -eq 0 ] ; then
    enable_sandbox ${MONGO_BAK_DIR}

    [ -d ${MONGO_BAK_DIR}/tmp/ ] || mkdir ${MONGO_BAK_DIR}/tmp/

    for db in ${MONGO_DB}; do
        rm -fr ${MONGO_BAK_DIR}/tmp/${db} || DOMAIL=1
        log_and_run mongodump --journal --db ${db} --out ./tmp || DOMAIL=1
    done

    log_and_run tar -cvzf mongo.$(date +%Y%m%d-%H%M).tgz -C ./tmp ${MONGO_DB}
    rm -rf ${MONGO_BAK_DIR}/tmp/*

    # cleanup obsoleted files
    [ -d ${MONGO_BAK_DIR}/obsoleted ] || mkdir ${MONGO_BAK_DIR}/obsoleted

    find ${MONGO_BAK_DIR} -maxdepth 1 -name "*.tgz" -mtime +7 -exec mv '{}' ./obsoleted/ \;

    disable_sandbox

    popd
else
    DOMAIL=1
fi

unset_sandbox

if ! tty -s ; then
    if [[ ${DOMAIL:-0} -ne 0 ]] ; then
        cat ${LOG} | mail -s "${LOGGER_TAG} failed" root
    fi
fi
