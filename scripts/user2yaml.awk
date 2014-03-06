#!/usr/bin/awk -f

function check_var(required, output, key, value)
{
    # check value is null or not
    null = (value ~ /^\s*$/)

    # if key is required, then value can't be null
    if (required) {
        if (null) {
            print "LINE " FNR " required field (" key ") is null, ignore" > "/dev/stderr"
            next
        }
    }

    if (output && !null) print key ": " value
}

BEGIN {
    FS = "|"

    FIELD_REQUIRED[1] = "uid"
    FIELD_REQUIRED[2] = "sn"
    FIELD_REQUIRED[3] = "givenName"
    FIELD_REQUIRED[4] = "mail"
}

{
    if (NF < 4) {
        print "incomplete line, ignore!" > "/dev/stderr"
        next
    }
    if ($1 ~ /^#/) {
        #print "LINE " FNR " comment, ignore"
        next
    }

    # check only
    for (i = 1; i <= 4; i++) {
        check_var(1, 0, FIELD_REQUIRED[i], $i)
    }

    if (NR > 1) print "---"
    for (i = 1; i <= 4; i++) {
        check_var(1, 1, FIELD_REQUIRED[i], $i)
    }

    if (NF > 4) check_var(0, 1, "password", $5)
    if (NF > 5) check_var(0, 1, "mobile", $6)
    if (NF > 6) check_var(0, 1, "ou", $7)
}
