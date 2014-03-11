#!/bin/sh

# script to fix invalid rra data, replace w/ NaN

nan_str()
{
    local rrd=$1; shift

    local n=$(rrdtool info ${rrd} 2> /dev/null | grep "ds\[\S*\].index" | wc -l)
    [ $n -eq 0 ] && return

    local nan="NaN"
    while [ ${n} -gt 1 ] ; do
        nan=${nan}"</v><v>NaN"
        n=$((n - 1))
    done

    echo -n ${nan}
}

update_rrd()
{
    local method=$1; shift
    local rrd=$1; shift
    [ $# -eq 0 ] && return

    local nan=$(nan_str ${rrd})
    [[ -z ${nan}} ]] && return

    local arg=""

    case "${method}" in
        'value')
            while [ "$*" ] ; do
                arg=${arg}" -e s:$1:${nan}:g"
                shift
            done
            ;;
        'date')
            while [ "$*" ] ; do
                local prefix="<row><v>"
                local suffix="<\/v><\/row>"
                datetime=$(LANG=C date --date="@$1" +"<!-- %Y-%m-%d %H:%M:%S %Z / $1 --> ")
                local e="/ $1 --> <row>.*/c${datetime}${prefix}${nan}${suffix}"
                arg=${arg}" -e \"${e}\""
                shift
            done
            ;;
        'line')
            while [ "$*" ] ; do
                local e="$1 c\\\\${nan}"
                arg=${arg}" -e \"${e}\""
                shift
            done
            ;;
        *)
            ;;
    esac

    [[ -z ${arg} ]] && return

    local xml=a.xml

    echo ">>> dump ${rrd} to ${xml}"
    rrdtool dump ${rrd} ${xml}

    echo ">>> modify ${xml}"
    local sed_cmd="sed -i"
    arg=${sed_cmd}${arg}" ${xml}"
    eval ${arg}

    echo ">>> restore ${xml} to ${rrd}"
    rrdtool restore ${xml} ${rrd} -f

    rm -fr ${xml}
}

update_rrd_by_date()
{
    update_rrd date $*
}

update_rrd_by_line()
{
    update_rrd line $*
}

update_rrd_by_value()
{
    update_rrd value $*
}

update_rrd_by_date cpu.rrd     
update_rrd_by_date proc.rrd    
update_rrd_by_date stat.rrd    
update_rrd_by_date io.rrd      
update_rrd_by_date tcp.rrd     
update_rrd_by_date udp.rrd     
update_rrd_by_date net-lan.rrd 
update_rrd_by_date net-wan.rrd 
