#!/bin/sh

# query and output hardware infi

[[ ${EUID} -ne 0 ]] && {
    echo "*** must be root to acquire completed hardware info" 1>&2
    exit 1
}

product_model=$(< /sys/class/dmi/id/product_name)
product_serial=$(< /sys/class/dmi/id/product_serial)
board_model=$(awk '{ if ( NR == 1 ) { print $2 } }' /proc/bus/pci/devices)

eval $(awk '
    BEGIN { FS = "[: \t]+"; count = 0 }
    {
        if (NF == 2 && $1 == "model") {
            model = $2
        } else if ($1 == "vendor_id") {
            if ( $2 == "GenuineIntel" ) {
                vendor = "intel"
            } else if ($2 == "AuthenticAMD") {
                vendor = "amd"
            }
        } else if ($1 == "stepping") {
            stepping = $2
        } else if ($1 == "cpu" && $2 == "family") {
            family = $3
        } else if ($1 == "cpuid" && $2 == "level") {
            cpuid = $3
        } else if ($1 == "physical" && $2 == "id") {
            count ++
        }
    }
    END {
        print "cpu_count=" count;
        print "cpu_id=" vendor "-" model "-" family "-" stepping "-" cpuid
    }' /proc/cpuinfo)

# sample output of `lshw -short`
# /0/1/0.0.0    /dev/sda    disk           160GB ST3160815AS
# /0/2/0.0.0    /dev/cdrom  disk           DVD+-RW GSA-H73N
# /0/3/0.0.0    /dev/sdb    disk           1TB WDC WD10EARS-00M
eval $(lshw -short 2>/dev/null | awk '
    BEGIN { FS = "[ \t]+"; count = 0; }
    {
        if ($3 == "disk") {
            MODEL=""
            for (i = 5; i <= NF; i++) {
                if (MODEL == "") MODEL = $(i)
                else MODEL = MODEL " " $(i)
            }
            disks[count][0] = $4
            disks[count][1] = "\"" MODEL "\""
            count ++
        }
    }
    END {
        print "declare -A disks;"
        for (i = 0; i < count; i++) {
            print "disks[" i ",size]=" disks[i][0] ""
            print "disks[" i ",model]=" disks[i][1] ""
        }
    }')

declare -A nics

count_nics=0
for i in `find /sys/class/net/eth*`; do
    slot=${i:18}
    slot=$((slot + 1))
    mac=$(< $i/address)
    vendor=$(< $i/device/vendor)
    device=$(< $i/device/device)
    vendor=${vendor:2}
    device=${device:2}
    eval "nics[${count_nics},slot]=${slot}"
    eval "nics[${count_nics},mac]=${mac}"
    eval "nics[${count_nics},idref]=${vendor}${device}"
    (( count_nics ++ ))
done


# # ipmitool lan print|grep "Address"
# IP Address Source       : Static Address
# IP Address              : 10.10.0.67
# MAC Address             : 78:2b:cb:4e:4f:97

# TODO

echo "<asset id='' name='' location=''
    department='' usage='' contact='' warranty='' checked='false'>
    <logs>
        <log date='' note='购买'/>
    </logs>
    <hardware model='${product_model}' serial='${product_serial}' service=''>
        <board idref='${board_model}'/>
        <cpu idref='${cpu_id}' count='${cpu_count}'/>
        <memory model='ddr3-1333' banks='4'>
            <bank slot='1' size='4GiB'/>
            <bank slot='3' size='4GiB'/>
        </memory>
        <storage>"

count_disks=$((${#disks[@]} / 2))
for (( i = 0; i < ${count_disks} ; i ++ )) ; do
    echo "            <disk model='"${disks[$i,model]}"'  \
        interface='sata' size='"${disks[$i,size]}"'/>"; \
done

echo "        </storage>
        <nics>"

for (( i = 0; i < ${count_nics} ; i ++ )) ; do
    echo "            <nic slot='${nics[$i,slot]}' idref='${nics[$i,idref]}' mac='${nics[$i,mac]}'/>"
done

echo "        </nics>
        <ipmi mac='' v4=''/>
    </hardware>
    <software os='' version=''/>
</asset>"
