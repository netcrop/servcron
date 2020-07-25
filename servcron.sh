servcron.substitute()
{
    local reslist devlist libdir includedir bindir cmd i perl_version \
    vendor_perl \
    cmdlist='dirname basename cat mv sudo cp chmod ln chown rm touch
    head mkdir perl mktemp shred grep egrep sed systemctl ssh cut'

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
    systemdlibdir=/lib/systemd/system/
    port=${CONAGENTREMOTEPORT:-22}
    \builtin source <($cat<<-SUB

servcron.install.pushcron()
{
    \builtin declare -F servcron.push >/dev/null || {
        \builtin echo "servcron.push not defined."
        return 1
    }
    bash.fun2script servcron.push $USER:$USER u=rx,go=
    $sudo $cp conf/servcron.push.service $systemdlibdir
    $sudo $cp conf/servcron.push.timer $systemdlibdir
    $sudo $chmod go=r $systemdlibdir/servcron.push.service
    $sudo $chmod go=r $systemdlibdir/servcron.push.timer
    $sudo $ln -fs $systemdlibdir/servcron.push.timer \
    $systemdlibdir/timers.target.wants/servcron.push.timer
    $sudo $systemctl enable servcron.push
    $sudo $systemctl enable servcron.push.timer
    $sudo $systemctl start servcron.push
    $sudo $systemctl start servcron.push.timer
}
servcron.uninstall.pushcron()
{
    $sudo $systemctl stop servcron.push
    $sudo $systemctl stop servcron.push.timer
    $sudo $systemctl disable servcron.push
    $sudo $systemctl disable servcron.push.timer
    $sudo $rm -f $systemdlibdir/servcron.push.service
    $sudo $rm -f $systemdlibdir/servcron.push.timer
    $sudo $rm -f $systemdlibdir/timers.target.wants/servcron.push.timer
    $sudo $rm -f /var/lib/systemd/timers/stamp-servcron.push.timer.timer
    $sudo $systemctl daemon-reload
}
servcron.pull()
{
    local help="[host] [port]"
    local host=\${1:?\$help}
    local port=\${2:-$port}
    local res=\$($ssh -T servcron@\$host -o port=\$port 2>&1 |$cut -d' ' -f1)
    $egrep -q ":servcron@\$host:" <<<\$res || {
        $cp /dev/null $etcdir/pull
        return 
    }
    \builtin printf "\$res" > $etcdir/pull
}
servcron.push()
{
    [[ -w $banner ]] || {
        \builtin echo "$banner invalid."
        return 1
    }
    $cp /dev/null $banner
    declare -a Units=(\$(<$etcdir/servcron.conf))
    declare -a Res=(\$($systemctl --no-pager --property=Id,ActiveState,SubState \
    show \${Units[@]} | $perl -pe 's;\n;@;g' | $perl -pe 's;@@;\n;g'))
    for ((i=0;i<\${#Res[@]};i++));do
        $egrep -q "inactive|dead|failed" <<<\${Res[i]} || continue
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
