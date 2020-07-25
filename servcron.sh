servcron.substitute()
{
    local reslist devlist libdir includedir bindir cmd i perl_version \
    vendor_perl \
    cmdlist='dirname basename cat mv sudo cp chmod ln chown rm touch
    head mkdir perl mktemp shred grep egrep sed systemctl ssh'

    declare -A Devlist=(
    )
    cmdlist="${Devlist[@]} $cmdlist"
    for cmd in $cmdlist;do
        i=($(\builtin type -afp $cmd))
        [[ -z $i ]] && {
            [[ -z ${Devlist[$cmd]} ]] && reslist+=" $cmd" || devlist+=" $cmd"
        }
        \builtin eval "local ${cmd//-/_}=${i:-:}"
    done
    [[ -n $reslist ]] && {
        \builtin printf "%s\n" "$FUNCNAME Require: $reslist"
        return
    }
    [[ -n $devlist ]] && \builtin printf "%s\n" "$FUNCNAME Optional: $devlist"

    perl_version="$($perl -e 'print $^V')"
    vendor_perl=/usr/share/perl5/vendor_perl/
    libdir=/usr/local/lib
    includedir=/usr/local/include/
    bindir=/usr/local/bin/
    etcdir=/usr/local/etc/servcron/
    banner=/etc/ssh/banner
    port=${CONAGENTREMOTEPORT:-22}
    \builtin source <($cat<<-SUB

servcron.status.pull()
{
    local help="[host] [port]"
    local host=\${1:?\$help}
    local port=\${2:-$port}
    $ssh -T servcron@\$host -o port=\$port 2>&1 |
}
servcron.status.push()
{
    [[ -w $banner ]] || {
        \builtin echo "$banner invalid."
    }
    $cp /dev/null $banner
    declare -a Units=(\$(<$etcdir/servcron.conf))
    declare -a Res=(\$($systemctl --no-pager --property=Id,ActiveState,SubState \
    show \${Units[@]} | $perl -pe 's;\n;@;g' | $perl -pe 's;@@;\n;g'))
    for ((i=0;i<\${#Res[@]};i++));do
        $egrep -q "active|dead" <<<\${Res[i]} || continue
        \builtin printf "%s:" \$i >> $banner
    done
}
servcron.reconfig()
{
    local conffile=\${1:-"conf/servcron.conf"}
    $mkdir -p $etcdir
    $cp -f conf/servcron.conf $etcdir/servcron.conf
    $chmod u=r $etcdir/servcron.conf
}
SUB
)
}
servcron.substitute
builtin unset -f servcron.substitute
