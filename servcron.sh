servcron.substitute()
{
    local reslist devlist libdir includedir bindir cmd i perl_version \
    vendor_perl \
    cmdlist='dirname basename cat mv sudo cp chmod ln chown rm touch
    head mkdir perl mktemp shred grep egrep sed systemctl python'

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
    etcdir=/usr/local/etc/
    \builtin source <($cat<<-SUB
 
servcron.status()
{
    declare -a Units=($(<$etcdir/servcron.conf))
    declare -a Res=(\$($systemctl --no-pager --property=Id,ActiveState,SubState \
    show \${Units[@]} | $perl -pe 's;\n;@;g' | $perl -pe 's;@@;\n;g'))
    for((i=0;i<\${#Res[@]};i++));do
        $egrep "inactive|dead" <<<\${Res[i]} || continue
        \builtin printf "%s\n" \$i
    done
}
servcron.reconfig()
{
    local conffile=\${1:-"conf/servcron.conf"}
    $cp -f conf/servcron.conf $etcdir/servcron.conf
    $chmod u=r $etcdir/servcron.conf
}
SUB
)
}
servcron.substitute
builtin unset -f servcron.substitute
