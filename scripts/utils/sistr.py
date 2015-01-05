#!/usr/bin/env python
# -*- coding: utf-8 -*-

def sistr(value, prec=None, K=1024.0, k=1000.0, sign='', blank=' '):
    '''
    Convert value to a signed string with an SI prefix.

    The 'prec' value specifies the number of fractional
    digits to be included.  Use 'prec=0' to omit any
    fraction.  If 'prec' is not specified or None, the
    precision is adjusted to make the returned string 6
    characters (without the sign).

    The 'sign' character is used for positive values.
    Negative values are always prefixed with '-'.

    Uppercase 'K' is the scale factor for values above
    1.0 and lowercase 'k' scales values below 1.0.

    The 'blank' character is used as the SI prefix for
    values between k and K, i.e. value without an SI
    prefix.  Set 'blank' to None, False or '' if no
    alignment is required.

        name symbol   10**   symbol name
        =================================
        deca   da    +  1 -     d   deci
        hecto  h     +  2 -     c   centi
        - - - - - - - - - - - - - - - - -
        Kilo   K     +  3 -     m   milli
        Mega   M     +  6 -    /u   micro
        Giga   G     +  9 -     n   nano
        Tera   T     + 12 -     p   pico
        Peta   P     + 15 -     f   femto
        Exa    E     + 18 -     a   atto
        Zetta  Z     + 21 -     z   zepto
        Yotta  Y     + 24 -     y   yocto
        ---------------------------------
        Xona   X     + 27 -     x   xonto
        Weka   W     + 30 -     w   wekto
        Vunda  V     + 33 -     v   vunkto
        Uda    U     + 36 -     u*  unto
        Treda  TD*   + 39 -    td   trekto
        Sorta  S     + 42 -     s   sotro
        Rinta  R     + 45 -     r   rimto
        Quexa  Q     + 48 -     q   quekto
        Pepta  PP    + 51 -    pk   pekro
        Ocha   O     + 54 -     o   otro
        Nena   N     + 57 -    nk   nekto
        MInga  MI    + 60 -    mk   mikto
        Luma   L     + 63 -     l   lunto

    The prefixes below the line are non-sanctioned SI
    and are only used until the symbols marked * to
    avoid ambiguity.  The symbols above the dotted
    line are not used and '/u' is returned as 'u'.

    See http://en.wikipedia.org/wiki/Binary_prefix or
    http://www.bipm.org/en/si/prefixes.html and maybe
    http://jimvb.home.mindspring.com/unitsystem.htm
    '''
    s, v, p = sign, float(value), None
    if v < 0.0:
        s, v = '-', -v
    if v < K:
        if v >= 1.0:
            p = blank
        elif k > 10.0:
            for f in iter('munpfazyxwv'):  # no unto, ...
                v *= k  # scale up
                if v >= 1.0:
                    p = f
                    break
    elif K > 10.0:
        for f in iter('KMGTPEZYXWVU'):  # no Treda, ...
            v /= K  # scale down
            if v < K:
                p = f
                break
    # format value
    if p is None:  # too large, small or invalid K, k
        return "%.1f" % value
        #return "%.0e*" % value
    elif prec is None:
        if v < 100.0:
            if v < 10.0:
                prec = 3
            else:
                prec = 2
        else:
            if v < 1000.0:
                prec = 1
            else:
                prec = 0
    elif prec < 0:
        prec = 0 # rounds
    return "%s%0.*f%s" % (s, prec, v, p)

if __name__ == '__main__':
    x = 17
    while x < 1.0e18:
        print sistr(x), x
        x *= 17
    x = 0.12
    while x > 1.0e-18:

        print sistr(x), x
        x *= 0.12

    print sistr(1000), 1000
    print sistr(1024), 1024
    print sistr(1000, K=1000), 1000
    print sistr(1024, K=1000), 1024
    print sistr(0), 0

