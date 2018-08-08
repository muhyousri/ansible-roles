#!/bin/sh
# This script was generated using Makeself 2.1.3
INSTALLER_VERSION=v00068
REVISION=c2e2e8990403b61354cac65e75ddcecd061f914f

CRCsum="2388030911"
MD5="a4414f61b2385ab3d5bac79431f12a7d"
TMPROOT=${TMPDIR:=/home/cPanelInstall}

label="cPanel & WHM Installer"
script="./bootstrap"
scriptargs=""
targetdir="installd"
filesizes="18698"
keep=n

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_Progress()
{
    while read a; do
	MS_Printf .
    done
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_Help()
{
    cat << EOH >&2
Makeself version 2.1.3
 1) Getting help or info about $0 :
  $0 --help    Print this message
  $0 --info    Print embedded info : title, default target directory, embedded script ...
  $0 --version Display the installer version
  $0 --lsm     Print embedded lsm entry (or no LSM)
  $0 --list    Print the list of files in the archive
  $0 --check   Checks integrity of the archive
 
 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target NewDirectory Extract in NewDirectory
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --force               Force to install cPanel on a non recommended configuration
  --skip-cloudlinux     Skip the automatic convert to CloudLinux even if licensed
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH=$PATH
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
    MD5_PATH=`exec 2>&-; which md5sum || type md5sum`
    MD5_PATH=${MD5_PATH:-`exec 2>&-; which md5 || type md5`}
    PATH=$OLD_PATH
    MS_Printf "Verifying archive integrity..."
    offset=`head -n 388 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
	crc=`echo $CRCsum | cut -d" " -f$i`
	if test -x "$MD5_PATH"; then
	    md5=`echo $MD5 | cut -d" " -f$i`
	    if test $md5 = "00000000000000000000000000000000"; then
		test x$verb = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
	    else
		md5sum=`MS_dd "$1" $offset $s | "$MD5_PATH" | cut -b-32`;
		if test "$md5sum" != "$md5"; then
		    echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
		    exit 2
		else
		    test x$verb = xy && MS_Printf " MD5 checksums are OK." >&2
		fi
		crc="0000000000"; verb=n
	    fi
	fi
	if test $crc = "0000000000"; then
	    test x$verb = xy && echo " $1 does not contain a CRC checksum." >&2
	else
	    sum1=`MS_dd "$1" $offset $s | cksum | awk '{print $1}'`
	    if test "$sum1" = "$crc"; then
		test x$verb = xy && MS_Printf " CRC checksums are OK." >&2
	    else
		echo "Error in checksums: $sum1 is different from $crc"
		exit 2;
	    fi
	fi
	i=`expr $i + 1`
	offset=`expr $offset + $s`
    done
    echo " All good."
}

UnTAR()
{
    tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
}

finish=true
xterm_loop=
nox11=n
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    --version)
    echo "$INSTALLER_VERSION"
    exit 0
    ;;
    --info)
    echo Installer Version: "$INSTALLER_VERSION"
    echo Installer Revision: "$REVISION"
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 84 KB
	echo Compression: gzip
	echo Date of packaging: Mon Oct 16 16:04:08 CDT 2017
	echo Built with Makeself version 2.1.3 on linux-gnu
	echo Build command was: "utils/makeself installd latest cPanel & WHM Installer ./bootstrap"
	if test x$script != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"installd\"
	echo KEEP=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=84
	echo OLDSKIP=389
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 388 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 388 "$0" | wc -c | tr -d " "`
	arg1="$2"
	if ! shift 2; then
	    MS_Help
	    exit 1
	fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - $*
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir=${2:-.}
	if ! shift 2; then
	    MS_Help
	    exit 1
	fi
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --xwin)
	finish="echo Press Return to close this window...; read junk"
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
	--force)
	scriptargs=" --force"
	shift
	;;
    --skip-cloudlinux)
	scriptargs=" --skip-cloudlinux"
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

case "$copy" in
copy)
    SCRIPT_COPY="$TMPROOT/makeself$$"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2
    ;;
phase2)
    finish="$finish ; rm -f $0"
    ;;
esac

if test "$nox11" = "n"; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm rxvt dtterm eterm Eterm kvt konsole aterm"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test "$targetdir" = "."; then
    tmpdir="."
else
    if test "$keep" = y; then
	echo "Creating directory $targetdir" >&2
	tmpdir="$targetdir"
    else
	tmpdir="$TMPROOT/selfgz$$"
    fi
    mkdir -p $tmpdir || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target OtherDirectory' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x$SETUP_NOCHECK != x1; then
    MS_Check "$0"
fi
offset=`head -n 388 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 84 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

MS_Printf "Uncompressing $label"
res=3
if test "$keep" = n; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

for s in $filesizes
do
    if MS_dd "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; UnTAR x ) | MS_Progress; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
echo

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$verbose" = xy; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval $script $scriptargs $*; res=$?;
		fi
    else
		eval $script $scriptargs $*; res=$?
    fi
    if test $res -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test "$keep" = n; then
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res

‹ ÈåYì;ýSÛÈ’ùÙÅ`|+{ƒe›,á	œ„*°ÉK%YEHc[Yr4^/øþöëî™‘F¶àe÷ê¥Þ]­+Ì|ôôôôw7×qœŠ4q§OþuŸ.|¶·¶è'|–nn÷ºOzÏz[½g?ý´µÕ{Òíõ¶6{OX÷Éwød"uÆž$@ˆÇÖý³ùÿ£ŸõµÎuuÄ¸V³™Ýy7¸¸<>;­Õ‚!ûÈÖX›³zçÖM:ÞÔxØñá^‡Ü‘¿:)O&Aä†Ž‡q"êìóKÇ<ª1øxnÊ‚È†a<Šk<¼j¢}=«ƒZ‡_¼œ½‚EÇrš'ìODG¬q|zyupr2¸p’,i\ÞK|q[íðýÑî—éÌÿR«­³A$²„³sž„,Ì½uƒq/]-	Ý
«ê¬í£aì¹¡1gÞŒ{ã˜ÕO‚è&ˆF¬b9KcV†MûÂˆµEåúÒb¢Fei®E+DWØ¶-O›gÖžkJ³
ÈË÷_…½ö>uãÌW.à»&nâÉ®¹¾÷á—aÏ:Mbs.]Úûñý-HYˆšó=Ò­bÚ½]¶e?·»µóÁÅÉë³3dOœÚ[Á°ù©ñ™½€ÝîóÖÝ4	¢”Õ£¸¾@IÑ¿Ï¹¨/¬/òÕ[Û•Sÿ&oF·¢«²8a£„» Pìþ5x7nZ¯§_ÓMFÿ¯'ÿ™‚(B9š¸ATÂDŠÿÆ=ÐZœ?â£¿ç,Šgìÿ;W4(i›]d‘”KX~zÆÎ®Þ.˜7æÞ`bg¡/ž6ƒ³,
¹¹äznÅ@¾ñ\ 5Â9»‘ëàá%$»ögõÿµ¶ÿm?qÎ¿¿ýïvÚ^²ÿÏ6»Ïÿ²ÿßÙþ+Ï9‚)Ž@Vò×çÿçGé˜éÊïùÖææÊÿvo³·ýbðÿ{[ÛÉÿw’ÿ’ë¹Î¤kÏÚÚüø¹É{ðsOçI0§l³ÛÛfÞ9BØ 'ÞC£÷ç?p(Áì‚žÜrzú¸}‰«ñô›aŽÓtÚïtŠ ð
-¯ûM·È®ÿÁ½]x²¯t˜ó_"7KÇqüNb‚þl‡t\)÷kS×»qG¹Óê÷ûêÛN­–	Î@»^ºCßgn‚‡ØAoâáXgiqA¾â Q’]‹³„5&à hÇ£àÈñù4³]ÖƒíPÔ°ÐŽwèûáÙÉÙ…s18Â[ï²g=søÃàääì=?ƒ­peF\Ê¹ŽÁ#¹#	Ö7Yƒf6àl1b-Ø²ïÀœNxš%‘œ ÷tÍçC@ÛW;Øý=ú¹_ï¾=~\ì\x¿Ë,«|’7Nš›Û-f3ëcoÇ‚Ÿê(˜Ð¯¸Ó.­ëîL ÊÉ+àaÀAw}æóë¼<ILaŽ?ÿòºÙh±;}œóöòu“Y4am°:ƒ6ølÁ0B,e³õup™—ià5Ïo\f×êma$Óù”‹>¸¸8»¨:œ&àðÒó4×ÝÈ*Púƒ‡¿?¸8Å³WÇ	8ûÃ%­œÿ?>}uVy8NàáßFï?wóWW'’ìêTùFzï0?€ úSTß!ìþÀá$ûçg—Ç—jà2ön¸R	—sÑï¿‰E¹Îš-9z|ƒÒí‡9zÉCÔWæèùa¿6åÑ3sôpæ”Ò£¯yOÓ~ÿ$=F£¤&æÙ„"÷®T Œ<¾S¨T`Ö"ñ†%âm¥ël²ôrïF®ÇåhHµIá‰“j¸	¦ŽB:–çüÇÕñàÂ9<8|3 ßáf#ž:`¬6ÔW7	xÚ>šŽpJþ¢@ãd­Q¬—dQsÿàâõ»–Ž°¤U¦½· µºSƒàPá·n#à¥§©^¨tèÁfc¿¥ Q¶kO¦¬±¿“ÈÈþòê„»4¡ 'G%%› {,$¦òä‡•©&Ì/±ÆàôÝux~p:8q~>¸8*‹f-¤ÕX^zrpúÚZ‘4x¶CK.öÙRn¬þåàõÀZ”O½/€gWÜ°îæ¦Zôa1°&Ñs8Þ`Ö7ƒGLÚ©ÈØ@1)ŸÀù)0;æò ,&î¦Ð¹ÔÏAµP2—a½uoÀ¨ó$u)ävÓ2$°äk»aÂ]Ž<æÙþUÁúgœÃMâ[nð §0ØFŽ2|3¡ XÀ‚î3%s€ä&+ˆÅ°»œ.YF0 H£@-#‰ž>¼Å ô^1A<
3&¥N…™Ò¸¼í—) ›ý6›ÍØ=œ'~)V.òo˜¾Z­ö^z;}f¼¨G)¼x>CŒƒ”ÍDÝW’Ð`üÏ.Ýtñ ÑuvH	)åK)V±i.3oÜ4À/6P£è!w£lZÞJïûúü5ü!Lˆ¢Š‘0§GÆõÿÇ?úpôHaÔm —÷Àãï[ÞIˆ¬Ñ
pÍä	»tÛ¥ó»@ÎF·@·Lzý…D7Æ²ò’…ñVeÊ´}†Š°ç@Èfk$ÎY| ßÒòeÚíãñ¨‡‚‹`W«‚ˆÕSùî‰;%_>Ìfõú€>	Á[ëüúÉ¾ëml.:0(·—AJÚ4N‹<úª%É„®øàÕe~FÛN,©C30¶2\p§H.É‡%#7BJ:¸²Yð÷—>8Wºô4‰‰ÁUÛf¯Ü ÄÇÊ"‘M§q’ru€´ÉrË†þâ¨}Å€›xcŠÈ£p¤Ü;
V³U˜WpD`#ÿN™SÓ;é÷á·3¹äUO’Ä7s}"#¸‘ÿ®¡#¹0–1€G˜!óá…²ßÔ”ÂHz<€Œ†ÔÞ»S v	÷âÉè­ïü(5$¸‚ôïÜ0ðQ-µ¯ºýÕJâJbé¹fÅ¾SžÎâäæ­AC¦+éé²(/˜˜À"¹Á™ÈÍ%‹#Õ2€/‚I6a´êTÊ³ƒ_Õ¸âyˆ——‰˜:AKuø7ËèÛ‹£a0"F¹›„dÒ<CcÎ"‹!¿&Õ Ýh—$Ö¤RŒœ+Þ ¶ŒXS9,ÞxûóOUÓÈv?“J¤–üU5ÀñN	«ðü0à}œ©Ú(î1=Ì! PÙ’Ï@P–(%íðþ#§ØuCo(µl^¼yüH< ¢l7E#õà)ÁÔ$µ–GÆ×Ü,šZ¤
V9‰ãÒ`°Î¤ /HUX çÓL¹B°XOf¢`C/šÌ°5¬9Õ¡ðý[µX…ÿœ§ËeMG‰¯ÖSzlÌÝ0ë¢˜VÌëÄŒô²]ß1?.o‰VZ1Ê	ˆÇ”ÝBwËñ`èÌ09¥±ƒù­lŠúÁPäô’H#qÎ.eeÉxËAâ<tr­ðkN':£ŒH;“¹øÐ)P¤Çšq+¡bV‚ gÏÌ7Ð£šGc0½}î¨4‘ŸÛmJÚës(3a ý»âöû@oæ›6.–®¹tµ°P:Ï+p±FœÑÌ©ò2ñ¬Eò¬Âs¤´«Ÿ»pXˆ– Uoˆ¶,Qv!úuñq4Q1 "¶	ôÂÊ£ÓË³Ó“¨FHë]«cÌ¨nØ$·£É:¿¶Û8#':l_†Â(X]–j«X2É^²ëc8¯îruvtÖGËð¥ZÒ¿*„‘zÆ'l —ry²<¤‰,ŸŒaš6€È†]Ï%á8Ò.Ôd µ{ÉáC÷MÍ(€;5Aúî­oºDøNp3é@u0Ãe Ëþ¤Èõ¡g¡&ŽéPþÐd3K°qÅðí'÷ezŠÞ” Wl‚	åår·]²%ßUàÀ‹¤wQ¢HnåZÀ¾ÿÝ±`Až$qÔ¼õ¢ÐÃ
ÙÓx?Lgk¢h«Ø TKÈ¯Ð8HepYÔƒáÉ4Ò ŠåE¤¦Ñ.‡êÔ<Õ™Â®šò,ó†€‹ó·—Äeä]°¿¼ÍÅ:LÑD™o¹o¥.#U«Ñô¢¢ëØû7oÙÉÕeÞ}ÑëÙ;€°ÐRÈ©EÃI¦áäWÿ&GæBFø¸Sân)W”Tîç</3$*Å­é\(li‡ð?b!ÆñÉì³¿B3U†)„–q/“ $‰].ÞŸ\•PqDóE¢xf
àÄ&¸@Ýî†â"Ù}¤äXf“„öqÀçK7ÔÊyÿ®ÜÖ)~§z1z-¶s·Xà€Î"&<4È¾î‘TºÎÑ7`X—)`Šj’Ü”´DhÄ9#Áæ¾e)8«ù'‡›z]CŸÒ¬$á|)h*922[l>R^z¨:ÕóG1T¹<ÛjíÔÊ	•ë[‰1Jµ™œsWÂŒŠBJzêµì‡Šï/Ø¶Z¬ `ý¥aô1=/Lt 3¿Ë¶KÅ)êÌ]õbˆúå%ûúõîØLbÍÔ
Ønƒœ£ 
Ž®Ÿ°u® Û®b&ñ1¼:åýElÿî££D–b$EŽÖçE®ÀëÇ,7în·%$ézÚ{×'¿Ë^¼¨N@]Ôàà½¦a¨Â¼¥XÓ+‰¯?Lµœ¯ÄÂMV…¹‚M²0¦`Á./O(±8^P ÃÐk1Wû;ð}ÌàÕHµ€&§•QŠÁÐƒ&à10,”C’øS@;8ü—q0ÃŽœa¤cƒ™E¤À7ÐjÛ®ÕÔCÖ€
%Þ¡|£¤Ø‘‹ššp¦[¬Ø¶Âé77wÿüºÌÄ•¢Š(6bóª:3_Þ¦åˆT!^¡å+˜‚CŸ³‡–U	‘Ú>Û+hN+Os¡ÕÓhçSÎ™‚ öÁ;p$·;SG›6•t£[Õ]0ˆâ±QnAq“}oâÔ48½BtQaMRY×)ê˜U¦úÕêÙcÍ¦šÂ
)í÷4Œ­¥˜ëh˜/r.
Ðnî¶ Z†óº"Õ‰HµV;ÁÓÃ,ÈµXË„]¢Mx;M°Î^X â"OŸ–Ûæ÷ØÖJ:Q>iOSÚÛØ@Âd“u«LÖ«N<x92n×WÝÂeâw+¹òŸ=¥%@vœqB‰Ì!Öá'þÇvï3ÜˆeÖ›ƒË7¨Öi<•D}y·T‡y [ zü)¼|áÒÊ)&§|Î±/ÁÏÉ.	Œ¨>¢ˆ”Þ,Ñž¡¬v~Õ?^Ÿ~î3t´ÿØs—n®X3”2Ñ›D wUªÜêøü¶ƒ–p¨ìzè¢_J‰õ|¾Ïku#–Œá¶Eá´½ñY1+SìE­´ßG`Ïšùá°_ýgâí=JÀµ›]3²»k”eéÌ&ì1×a©ÀöJ3Q s‡@äŠÚ›µ¼ˆû ÐŒO%aVRkôbg•dA¯$cV™/Ç¯„.-.IÎ:;ÏÄ˜L©Â‚Cê€w!dÙ63Là«Œ)a¯Ô!ÔEª*¼¸&‰-ÇV‹zAA£Š*Cs÷¿™è|J:‰iVOÁûb¿¾•Iµ8KÑ™Eí}ÍÓ”
‹#5j×V‹)…œ£+¥Ïè n™P;ø²ã,u*K,7èõÀAY­¸Qà‚Ô±ÍÕ	´6¬þÁd¿›å5ãI¶YY#/;“ÝUÔÒJ—Û µ+ª8Zku;ôtÚj rî´À±¹Ùmýï@-–í8âGÔê¬ž”°â±
n*h?{Û€÷­$¸ìðÑ}<rOëA®zXÈV‹ZT=›n×¦ÕÀŸ>e±·ãñ
!¨,«œSpÙß®$8zðÐ'§[ÛÏ±Ë¶qflKn BT"DM¹LÐ’b5/ÙÞûÛ#åà¥'~ï¦žT&”ÔVí(zZÞJ§	¥M1Ó‰zªÙµ{­jëK-SøÊ†íüýøÊ9<;|fÒîg‹*’[¥ë4e2ÅoÑ£•¦@Ð×´eF'´”vÉû ¨¾Ø”vÄ4r\›‚U	^÷ç¥ž·²±È@Æ˜ðÌ½‡†LRg’á@ÌüÕœ¨ÌÈÚg 
øþ^šSÔ¹›“—ä=t6s†iÜÁ–Ež‰˜KmãeI‚A<¦§ÑèiÖ„#[ÀS¢O¸Ô+=¡"¨®£îMÙ±Õl£Ud1€åÔªáSQJÔpç×ÙÕ‡óºhL•s-[ÜÆ€E¾›øFeGuØÜU¦±hu~"þù»´„ôÓ¯ív§,ÄúX\SžAoùÄ£T&r'‚Uäé+E&VW‘jža6=[LÇIà¾i*B1MþrF±”‹cˆM_"•÷,½6A.…_²˜´ï»©[Ž½
_{&ê{{õ¹Zú€ðò[Vo¼<hyõ¨ŸfžÊt4¨\ß^êæ¹ƒs¦’]Ô–ú-*îƒÌ§¢ê4¦ó’éDk»uF™eÐ$‰·ÕDž†¥ÐçÃúOÝ¦`¢Aœ%cjðKNÜßãHÑš*‡]>)Om—O²˜é‹–±7»´°–i]â¬¥}È¾æZ“‚ ÿsx+¸?
±¼z	¦ilƒè‹â*]*«ºL¶Ž³Jk™>GÖT©ÓâB"¸ÎèOÓÊÌN6*:1Þz—}Áí¯Ãå+|É	]4ñåûŠLIESDÁ@—ñ„¥È “Ë‚šÅ²(`¿~t±ðŽÞ6{Ïø-OÖ 8+oAÌÙÄ#‹Á¶a&ÿÏ‚ëS]õY]‡nt#,T‡ÉÅù[‰"–Èü˜‚fò8U1ŸÒayR;·l…ú+ Hm0Rîd?Ô›`þª1q±6´r'Åˆ|’¶.Äì„
-øPªÐ†p•SW¿èƒgÏS5–'£Î4ö;Ôc»žQ{ÞwS}Rc)L¢µYLŸãÒü©J©UŠî÷³Rs†ÔÊê–¤—)5¥´r©3¯ÌBÕz$‡«r+Åª*•yJà!«Ë‹S[€á#bÛ" šqJŽ¢àw¥‚ÔÞÀðÀèïu©‚½DÓT¦FIœMU8)R9ãä!¦çä›A CíŒ³@¨VIŠO¨ê
ì¤óáÀÌà¶ú1—}ŽAä…™/¸X·M"æ	p2üßÒT&;<ÐÝ¯ÍOGO[íæÇOþ'ûóÓ–ýãËæËþ'»ùÑmÿÞmÿ§c­—ÅÄèØZ®í®Œ<5c…åÉŠÇ3k
hœdî/1•-¯–‰½E’)KÐÊÇ^›þÂÅüs\”óqî d®9HpjŒ%Â©?CÎy‹‘kfnD¥t€KìR¢zéï842p7ÂùmìbaRÆÛ­ŽPºVn\}/·ßsÁš®mÝ}ÙôÝSºÄñÏ?Â7<ÁC˜‹ŽF©Ó	0QVrõÎR«d	æ ‹ûZ«ñ™ª·õ%u¬b³jÐ’‚•Öy)ñRzûÝBeÃòžÅøÕÒ©˜Á€ÉNõößº[Ýoë+.Ð1o°S“¯ZYÁ¶Î!m’`´r;³V/ñ°úSIZÅ†º‚™êª‡ƒh §ZUz9Pe“kìwRNásäØírLÜNW:iØ‹]¶Mù¨¥aOºÎKœ¯ù{…êÕ¾&K¦›¿|*ˆÏJÑ†°ë¬µ³|íKÝTªZ„Ù4Á“¾&2ª-É‚ë;Rœ%õ;’²°Gñ¤7”ÂXP“Ìÿ´÷eémYºõÌ-Ü—$Mu (‘´AS2-Ñ.µ5]Q*uEL 	-LB¢hŠýÔ+éô"z)½’gˆˆ‘’‡ªû]¢Ê"ópâÄþ£÷‹ºez¹4õÀTøÅT¼¢)¼é0vÓekFªªî¼ƒŒøRn{˜SHõÏ1­‹öÜÚ‡7ðòà)p„€Pâº)ÌÆª°Ö0SÜÙ…š,¶e³ÏF2û#~ÕšÎÉ^ÛånÖKQu?ÚÝùº¢‡þ¡šªçGÑvmÞôAË’ÞóñTÝ, ÃvcË)pWËãïGV}ë^Å)p×ö¾ØRÓ¯B³«÷/½¾BÛü@º˜{_Žgô¾•UúÔ›Dcïß_:Kƒ™Å€‹_uqÅ<ýÀìÁô_€'ªºOÉBŽ–[rµR³©ò§x"’ÅîTõ2†Ûƒjp”Q¬J%WðR H&ª9øB¨Ø]]›ïð±ºúgÜ"úWG¹	üð.‹~Y¯G€‚¼Ÿ0£/”ÒÔ·‡rPÞPØö¦8Ëòštû(aVC=îCËÁ0Öö915ŠbÜBWç´—Yá×X[0/hõRßíG¤±mmH³á+¨¸áuSCó¼i:ŒJý$K>	>R‹gª§hÅ”}·¹ ói÷g¹žöè]6…¹n÷G©ê8c—9½š€¬bœ¡È @mWÞ§Šó†îP]FÑ‡»ZE.¦±»QAeá0ËOMÕêf/.æN£A—¬ŽUûWgÒ+N÷ßàÖìnÛØÑ‚@Éš¶‹®][ H—1¡[ìnrèjÙq3	jRár
F—5ÇÖø‰p/ô%cß‚`Lg,¯ªäƒÌúà)S.1“~œß)½Q×!u:Îo¿ûþªT±ðvÆ„þÙlD5"˜*ýíÀ*+/ÖhˆíÄåÖ™Wá‰ò`&§cÅpiq²³ï„„œuÞZJd66.è:Å)ö¤A?ÜðŒfÙp#xnÐ\7ÉöNt
ãðù“D»À¡QR)ˆJ\GŠpÊ\Ÿ@;¸“v+ªi]ÅÎ¢CÃ×wñßÿeÓÀ{ûûŸÿøOýjÑù¾'Ìa6^Ð%'L§I“ª…lN/Â"a×ÏEÌ˜y´ïºD7›Ò)Æ²ìC&
|uãA6E•bS,…BÃ‘Ð°Uÿ{Tûåüüü8qu¸<EÌ¬¢‚k<ŒÏÑ@wÁVq<ŠtÇŒ}	©h‘r¨º×£×yfFTçÓvô²Ý³iMµº¦‚-§é¼ÅqÊOn‡>ü2ø®XDñÉßY°ÃoZX&ócì­G¾ê‹ Q„¢¼)šâ]Dïç*O¯[dŒ8]X2Ûí÷}³àd•F,-&?è˜{>V/g9µY=ÍûxìöðÍDÍ[ÞÄI7}Öœ(2	Žº“ù.ñX¦ˆ¶qDŽNÌCHR5«!û˜'ƒ,éŒ‡'ÍGUu.a<™My“ýæž÷ÂáGÔgÛ­tµx·ûŽhei¨…\æF+”BÞ…¨•çgîb[x%‚ða'r}ôÑÉdÔŸu‹móýó=¥€•Þ/Ìë—ª5Í€’k³TŽ	?>IÓl‚3:cƒv5"GQXt‹Uºj]-^LlÅ— ù(¶Ïâ>¢?Š€1ÛI‹ ƒÓù”¬²¹¹ÉÄUèŸo…+´×ÞlDNK¡Bi…äª%…3CÃû¢eòíâƒ¨Üu‘hh¶bÜA$ªBÅ‚BºÀíI…=Ø®" !á"x9'ÚoæÚÏï{ôh·°è[F=$ëLRj‰qîÎñ¶@f¾½AŠ¤*j^C¿¼;"U±d¡VðŠp¯K K] vÒÞô®õÕB{à%4H«óÄÄ„MOôÜxçT[÷å‰5¤D±¾é,ònÜ“uÂn“äˆòx^%Ý<íjEJ¶vÅ>Ï¤nhEÍ–¢ºSR®®‰Ó¾—D­à¤3É´ÇÕšcYÛ‡<'³wüÃ™ju öÀÈ`·(O±[lîn»Å´ßc^ì¥¨ “&º¥éì~ E6Ç£šÓ¯¥‡Ê*GÉæ|Áñ¶d¹a†Îl Æ-ÿª£qu‚W~Ÿ`~âªj˜b Üá7´äŸ`eÆi—Ø^àž6?ÕéïßqŽV7#—t û¼,KG¾)9¯a÷Gô(öÃ»®ºç»j7TïÉ¡ëÏˆXuûèâ.Lvâº©"V#ÐR©þ{G;$¬Ç™UQeP¹SÕX`ÍänÊÏ]=Ur/Yy	}ÞæS}Mâf/Ø¼nf˜%÷	Î;;ÇÂ~.5Ü`¤KQ#Jr™`›¨8‰÷ØÈ·QÞã9“^*!×†Á|:!¼ÁÔ#“Ï­z’,ÂÅa/of`œgàQ­Ê@Ÿvq¨í1HN$Ðl~Ù;+ðî¶œëOØÉ‡§ÄeÃ|é¬!Uõëþ«¬ßEQÅzM§`D³ï– ººçÊã7×c™éYªµÏ¬ÜüB5™TËÏ !dœ¹5G{±ç„^.ÔÉ£þ=qHd{óQ‡PÔ%–àê*à2!Õš¡1À;’	ûéÍ§y6ø ~5ÑVýë]Ä)Qyu„-îü;i·;mÊÇ¾ZaëõècÔØq;€iTZ• 6ÕN|øp¤–µªÙ|ñCëñ³ÃW;•¨^¡*A§å”ž¨ÅgÊÿZov³®×X^IZ¨ýäèùÃŸZG¯^‚&£.½T¬)-aP¥‘ÎÍåƒÏŠ©Ôîº¢R·Ë¡’!ZdÁäM³ù¶	vÊ½²#ˆ¦Ê°àxŽ7UWúÎùéý¹$ôheÈ
ªÚétÞößÁ³­¤Ó;¾¨f½¾ÿ€fð-þƒÈ"âõU%:ŒÛ%²oŽ»j¶³¤[»—÷Ü£-Ç~Tra¢Ò	 Nn¶ª÷/¡KWž1?c;á{M1®PXú¥Ô¿8}Žó;@%>±S"ÿLnkäOðó8áŸÇùí}õ_ãÓhÏËµ¡W)7ê’L÷ï«ê+‘¥{÷ÕšµÄýQˆØ˜yÊèkLGcBÐ.ûkãéÞš‘<åÖEV-&CšP[ÂbðŠ…ðÑˆuì[‚„i¼”ïÜƒE;¨+¢l¡X¡‚Aë¾×ôžáT~„;ñ*XVä–E|af'ôÓwyUžZÿùš±%me²¶¶ÄsyÛ8-Ú©Ç¯ÐÔ×¢GÚÈRã¨ŸÌ/ÇV”Ù¯²sh¦_¿piæ"@0ÊW…
<Uª­ß»(,FÇ J‚Eh5ÊT}ðK&CQtÏ„¢4•ñ!„T«s$áÍ5"/kk<%Í`÷xúª}= ¢L‹VaEqŸd!!Ú
óÔÃá3g—S„“X-c–œXäÈÚ«ÃoÀÌw¿jU90ØXÑjä2¬Ód‹Õ~ˆ
J­Ãú©‰y>Ï@ÚÒž÷]ÓögÓtØc	³z¥¡êÝ+G‘€{½tN3Ø‡@€d_T~¨w´0ì\Õ¨asHbaÁXÙ/çT2ï4¦¡Õû€ï.3ó ¸ú›ÞÆoÕI*{ ›EwsC†¸~ôÆ)Ô¿TzRÄ7âÎñ•x’^¨]ÒqˆŽ€¯väC”!-£õõõÈù~ðòÙãg?ŸÓw§Œê—}œ2¸áÂ–£§þ(®{ÌÔlÝÉÂ_EçY;ï8êïÔ„Z„S’Cøói–ihÜ*íe 'ï_û³èál:¸ó0zöüçBÓÌñ€úHÝÞ¸lu*Ï¦äwÒßcj&/?qRxë'ôƒn\Ûeyˆ¥ìzà¦ãA„:P®õþŽ†«¥Õ/ î»þ+uíz„[Ýa{ÐD„dB])%(//LÑóü]ì |fì†2ÉÓk³Žòþ0œ=¨{7˜Ä-ßåÇúê¾›@¦FÇ:·|µ¨ŠƒAÚNG¿¦q±ŠaÚà? Ã+Ÿ•õàÉG9jà3Õm×ºùðÚÌ?gíèŸFØgN–HOhè­¨Ü‰þUßså„”ÔîCt hp©C;ËKj*`Žn#“l¸%¸¹ñ4¤S½k.yéÌ:B®4"[®ÉD:lÂ·hè½·öÀà»ì¢3˜yÞ‘%ákº.Ì-‚jzºdÀÑPsö u7™¢’SŒl<’”²¹!mG6[Æ/­ä7°,í)bàÀQÉäž,Fq½ÏÃšU†ç³vaÜ"=°ø•ÃÐ¡Z:U+Ij!+	£@Æ÷Z ~\Úé˜=grƒ
ükqOFO/Žþ÷à“ž‚¯Ï£ï)³q"ZÖFZÎP~Œ+ßo×ð©ÓgÄRíŠ<ö†«8¨l˜[m#jr`„Em®´ÉæÏÕL§è÷ø ]Cì÷“º6ÏŽïà
*ÿ
Ø¿Œ7Å{²(jø*ÊD•þ†u[d`ºW[ªX‘»·1°	
s%ð04˜Z\ü.\ã ßu1I!†óÍÝ}‘¢o°°„ßù²h¦NÉàBGDoªª3Mçwª.1*gÁÚ÷+­o%q.Ûz¨!6ìC:€3½ rr‘ùtšNÎÀfR×Eßª{¾Î±ÍEŽb³œ[ü´bžÜ-<¹W,u¢îäÓq¯g›á”Z/æà{‰MïæØ	åÈ;ólaŽ†ŸC¨úy•î[é~´uÿ_'‰/xž<€9¯{ø,Ðu¨ßW±ëâ£¢Ø"ÐO-.Á8q€ ¶â).4Ô}??SAâùÏØú‹kg­X~ab`?xŽ?"òZº $ Ÿd4jZ_ÕCˆÂ?p˜”¬2
Úðk°ª°8Mñ½“ÙžàÈËßOÃPýtOXæ(ªøñ‘§S«ŠjÇùZEæðíOOfª…†¦ƒ|l´×ý>Dh%ªðÒ¹¯/Æ«r,Ø	çÝ±Ä×Øº5ÉÆžoþƒ5®ïGw#R~¬Xuq‘P¥|,ÙþcN½ahÏÂ™
ÏÎ í5øu¸‚@Ó¿µÅÛ·žkìîHî€I+QŽËntíÊ»ò:~à³{-°Õ–uï³¶Ù•Ï‹_êBãÓ~‡A×bKÙÝfauÓ€ØúšzêC®…ùÚ@Ø$xÑ ùÆuÔÆm‰€8 Ò‚¼dB)–ðÍ7oZÈö\ÃÛ H	¨I1ø”µO]gªØ¢L0"ÀGà‡r)Ž”C»©Óýû²  BÛ*…€CãüÕûé|6îÔe4ºkÁÁâ!ÁûŽšó¶:sç,L‹qU+.ýâ¯\qÏ+!arvíž±U¯n×Ñ¥dRÏn†¼¼ÚhZ,{–N»€µëŠV í¸O‚g{t:µ¬q&éÌ'å©XŸ,«ýÛx0K¼vÙØ"Àc0œ%q¯Øÿw¡˜ÇvtîZáVW»q¬0Œ†[é¥9êP‡}ÔèMsÐJ c7²©ìA’NNÜâÄ—×ÇïX
!ëxE’ûåÞZžïÓ¡¦ÚÎjü£øb>Ð¼ À€ð'©^Äè¤_õªÊ5QEñJÅ› tùÍ´ï-ÊÍáNg1:¥ë·÷‚Úîg]DÐ%W=˜A<
°Ò¨¦&ÝšÓ TŠÆE[‰ïày1zP(rg…1&
ó[ê_€ÇI£ý¡Gü/¥ãüö0ýÈƒÎêÒòq÷Nmó²qÕ¨í- W»„v_…ñÑVãxÀ5ŒÃùW1¹DÎ‡QIÑ…®!°gãN”a‘/À)G˜hH#€ôC„ó‘‘À¨¥Ä.7,b³€ï"cëÆ¸„•#“™æù|˜!Ê°
Û5µf-ú¥º®î³É† JRÕ æp2Îí65¾]m	¾-™NÛ5*#nìÑã£ƒïŸ€ÞS€™ûŒ‘.ø+S*Ö’Ó«
Fˆ‘(_?DÕžú¯-id´°èš4@‹}'Ñq^	þ)8ê¦ƒˆcÍæCÑ³;$´ÄG”‡ø¾Õ.²bÀ¸ñ
ØYL±ö<Õÿ"ù‰ËFÐ|2&‚ªÆx7ÍÔñ6,ë®m:6é  ÂÛ>E d
,–<Ä¹ðþüRö¿BÙôíuTW!€qõe¦˜cŒÜ€/ž¢æ¸ú=jfñI8`ü6è·ÏÏÏ«l7 ¦íº<d ì{BÏ²ˆgÃj6³jŒy‹×­0’<©tg«£1)¥õ/hì™"gQAºÅ‹bcè„"†»»uWã pGõÌR[«gŠ8ªÕ‘=#¬—¦/“j,Ü8¹zèD·"-ÀYš·(}K‘æ¼Å™¼#_´„b·Ù¶ÿÏh×i2üÇ·Ù<ºÈ_¼S—3ÛÜ.ÞAîê°ÁyJCL ÖÆêäg4œÎ¬Ø‰_™ÄfACˆ› Q¡©vÆ*‹éË–žw¡ó£hTGrYÁ£‰‚Ã¬éýášf‚ò÷þŽrqù¼ªxù®úÔü¦÷H'œò	¥éú¤O'rQªQ·]ÍÕy¤HŸ“´øÜ¦'ƒß¡_zð•Í5y!ƒ|jÓfgÓ´V>¥´ùYª}ÓuBç¥R´Ð­X< ílÄñ“tù„ëBáƒ[—|t>¯öf]3HuUÀ<Ég½¾žÇ\ÝA«Êï“t¨˜ õÿ¾ÆŠ¡` Uab8w[@GõOÐ¨¨!’]%%‹·ôÃñphhôC·‡6å$õ³‹AvM )3&À“i†û–P‘ÙpŒ 69A‹¯’,3jü:^ˆ,ßùVBHzÙ÷„g6¡3Ñ\$%­=üB<þ‹—‡ŠqûIñnûå‹,/%·Ë›µÍÆh¼¹UÃtWþ½%Ï²w%jQk÷‚ÈT» 1Îõ3ã¬³l0@“ð( aê,ôtÐï.‡ŽgDÈu—4ƒ-ï; £/Iå‹¤?#Gb.¡¹Ð¨±%'5Üµ}—M©çAÉ"· Û¼{x€qœ™fºÙ$á’z±bH)=S[`à x ‘t¬iJÅs	|PÔ•üƒ–˜!·®¬®uðÌ“wˆíË#˜*þüý<›^Pàà(¾u	nÑWÇ£˜ÇUf2Ö½Ñ:Bò²ã·êd{’‘9OÁÐ¡=V-å‹„¯J
¶2ºPÙÃŒøùŒ,õð®F6 `’Ñm?xð€-MºGDÝ5än=¼È¨Ã`_~šœM>QµŸ4ñÂ pºÓˆäBzÝÂql .êÇ-£ÀÙoBXY#†Ç®2YÄ“£(îžƒS›¤ÙSMœQ¿;°Ü}õêÅë0ÆV1€f_‡Ž{†–®TùfsÐvg½:OÊ~lèu4e
¾·§!Ä‡,pPæ=Õ¦™ ¦s0hÿœøÿf>Õ	¹Hu×Õ…^U¢ý='››Å xK¤)á£ÜT·ZÀˆ›VçÖÞ]‹Y±"ÿÂŽ©~Q`ØêdqAWåpæ¸£†&p–ª:=À“çª?E%xYXi:ñÇ*u9./l™s)Ê5íE¡vH9¯WÈ¥S2S~1ÄÀÒðfá(ÙÒõjsÖ'×i`ÅáµW]ãçÌkÿaÌÝuP®@Žòš³;^{Íó|¦à$ßO§Éé¯"Zr³…®„sDÝÜ’‚ºC ¸Â®æm‡-6¥Î_ÜåübÔ©ùåù·ŸÔ$í_·6\ró2›Mû™9ý2ô/5Æ®úÎ¤§X´³¿(hF£Sù^€|w„ðK‚*«yQô Oôp0Î=ÀÒm€Væe‚Œ·ªbÌëxA{Í2 aJÂ’lRiH	‚¥#
X&îä¢É‰/§¬]£eì[¥]R˜4:ÞæÔäÅ¬ÔU_7ªUUÜ¾QÉ¹—8~c¯†aš¦Ó.êQÆ=uñï€
×Á5¶Ú=cÔ3	çêZB6Ikª„šð:UaÁô’Æ­À‚–VÐU§: l¡³éxÔÿ•ýtü6`}Ê’$|ã$·‚£e«Ç3ú€ {‘çýV´µÍN†z!Ð_Ši"¢?.î—ëRc™¹0†Ñß|göôÕªô ªl ç„£k²û„èh“ÓGš”R+Ã¡[J– ©‰}âZ¼b¿AÐä1(ñh•÷(ÜÇB•¯%Mš I$:ƒí
ñ®Q´7µ¬ŽØÉœE§äíûýãgt27¨®°Ä‚[¶àK£E×¡ît„í–§m£W¬ÕRû…ÇÒÓ«ûIq÷8à:ß/ÔÍâ8¿È^x÷ã d‡`'ÔØÚMêêÍÞyÝ†Ý/Â•6üªÍÉ,PopFGãQ•†ÌŽƒ‰9,mÌéï‘°9¦m¡æÌÃcnb8å¤ËqÁ™ùü,CM¼4åI4ß”@³rÇ‰ù;~èÿìÑ£óó¤ð¶D^|Ülk:
ËE6ÝZð¼‘k>O	Ëã81«	¬¤»#ç›y‚WÙOsZ—ÏµBÅº€÷Cû‚a|1qY²ëlÑ·ƒ7u}~‹]–÷0O)EoàscLØ÷¬°%ø."ŠCuKvfˆ¨{Ýd¢`«ƒGPpÈQaÄ)Á>Ò1¸WD0±Cèš~ØÏº·
Ê&ß½]UµÃÈFéÍ/ûoï< ´ÍÍbü8¨ê]†˜Â!?Î4Žú»þ}$5ée‹á€êf=ÈPwa:¨; G¬R_©b1áRÄø…Í­})¹ýkúæÖ2}»:í¡×:‡€˜#FØmYŠàÆ¥¢ÎŸC*u‡#üªÐ¿Q9ôÞíC€–èœMcÓŠóIŠ4!Ÿv –O_uõcr6¢î‰\XóšxZ°K›9æ‰m}ÃXU$oÍZ-Håj“y»úÐTR@—¦¢¡›(Tê£!‹}ˆ9“lÍ§´}<±¹„³È\©«,1Èë°‡€w·—Æ’þXN—Ž±ëàí*ðÚh„‘Ë*Ï ¥_E‘"ËÒ:C+þ^N†¯gê^Ôlâ´óyCw
Eízmp}š?a8“Ãg»ŒŸ<l<yÃZŽŠ›HÕcð]Àú=ôÛiõî,QL ¾QéAÓ8²v£OÑ¬>(ˆ½Ðºù«Ã¼ïùN½¿ü{î[íGáò0^u×¼RúýûË’j`YXÐ ü‰Žj1$”áRøî«%Þï0lH@øë	G?Êa|L:ãéÙe(‚€-ØP[¢Þ•_{<Z]Ãién2ŸŠ>&ëð8Ä 9Gz­‹57Å¢Áì¤Ñë—OB·>±Ö4Ãñr¡$ÿÕŽA–à‘Y#×Û0úáö|ôk²e³"z,rùÞbw{OuŽ½¦ ªTiíTÜu‹œ·‘Êñ µ½Ú€“4ïHP
²V¨þe‚cSô²¤^D1ÓÄ8,Ñ{^•ÐZÈ~÷Ãã'‡ü©v\«¹-‡1™!½/ÖŒ„kÏTÒžÆÍè9»Rë2x÷X!Ü´ÖÂ–¡Ù†|“òJÝ(ûsFQ8…]Öñ ÖQÆðcÒsŸ8[ÉT>½¿FhIO£pOi·ùÜot¡"˜Ÿ³é>çåS85b_bH«12Ú×Î„žçtËª×êÔÍ£NÙjî>2¹	x;é!an‘†]R3ñ¤C.Oë–,X[§«{>–<*g…¹,Yšbþ¬Es…ÇGwÊ5ò½0¶›€CP)¬’‰Ýü±åtÐYëë^å•£n."M~žý(–Œö*ò¢²óÓe ô&Ãf
†â¨ º÷|
?ºéüÁØY
ÏÎéÙýéç]u8–¥¿ã»Dç/ïn ÛQä÷R0H|ÙTNZÜÔÃ÷Ôys«~¯[½Uß¢"ø§iþ‰nÝË£Ò­í¼ÜŒnåêæöCèùoêuêü°Ô]ÆþÓX@C+<ºNMfµ9 	0¯D#÷Ä{ÿ©ÃÚ=„àÜÕÏsÅ.óÒ5áÇãY>›¦V‘äÉ>ýÙ‡p™Ñ°P³”Â¬mómôm´Ôë_;T‘Aø^9Ðý-*·“¯7A!nÜËµ;Î5âz> &kMÏ ç)tÙ³å6ªNVŒ“„a?£›ƒíâð~Õþ¥v:9EQ¡µ‹èqÐ¸³t†"‡<³Ö¦h³A&zjÀÀÊ$³ù|â˜ßvàÀUË¼¥ó­Ð6q¬Èƒ®¬ƒ9ò5£&X-Šjrý mªîáÑ©
¡o%;G£ñ“jQ¾“–šQQ|í±nÈfÐq©]þøØDÏCM›¨á>âN$]$6eýOúlj^ÁÃÑ€Xe²k$…š«;YvÓý„>sœ
’]"Ö~%švËµŒ^hÐãž·­G%èJÒ¾ (/ˆ¦@qp€˜åË¢×¾ÅžSÜÌ6ÜPA+’„† ¯Iù<CŒ'µËó›\'Ež@#=Šú³ç‘©	ÞáZÐÒêÞ¾Úm:ð˜]é,UkóÉ¹_`ÜhaöAeñÂ'‰ÎõÛËG*·Ç	«Îáã\á!7“L1Ed—f)‹•E0ß K…å–¾Ö&6IÉ¢ãYµ!hPÏ£½Uøq­7EË‹€YC+E4pù½6Sl‹ü­Ç\>ƒ³í*ÄÔCã‰ýíÑ¸èkÙE¡½ñØO¾¥Ð|@
}dÿxStô¸Z|Ÿ,²/9áÙiÚ¹ˆ,>#õÞ°>Ï3^ìÚldA*4±¦8í WR‡5aëõ Í&èšÕÖ_¿<%,ß/~Ô…Z±$—\˜È+3Ö Zà»ì"7TÇÚ¼ÀÑM°êUHqUþÌ¶PñØÈ¯¯LM®Õ9ÑÖÔPÔ^¾xZU™ª?þÝœ]¿j©ô©
T.+#àã«â>¯ˆ+ï&;!h=fž’›eÕ¾,zàøzsA`@hh$ž¡òŠ1kíÌu&°?ƒ¹œ_-ÎX^Rp«l'õ`B…@0%/|
#%Ú –1 òˆê`Íh% ¨Háë«Ã—OIôÚÛâBOådS2Ü…ñÄßF ;§‘›.Æ$Š¡gŸt$­ù(²vè]f@Ú.ÊP—ëŽøMè9÷}Ä€ÒÆÏ€Î	²PÐÄš)|Ë¥
&B™ª®,Úðˆ¥c.°`¬‚]
aÃ±‹E¿d“	½E ›³±mñ\ad¡_·8‹j‰¬áZË½WŒ†Ò1Y¶–\n¾ä”8:êv† c=ä?m„¶¤(Þ!…9­¦§ÁVòCQW…'·/¼ˆªv¦M$Ô`üØŠëì­µB6;@ÈËëÏ+äe²Š
ƒ‘JÑz—GÆË;ÕÃ|ßÂ[íï3mtÒ.1aøÿ»)“T.4[‹FÍŒþ·¹KHå;êz…È|Š&Kg8ôFÍºŒ“=qn,	¨ˆvÚV9IØ¾ô¯Ï"®OÚ$~eSð[3Ÿ]ãË ªÎS-w?¡Ÿºèþh²ÅïŠ>'ºÚ’É090¹…iâó‘êÔá“h‡A^Q¶7ðõá«6%†×Y6¨î°+S=ðŠŸE(ÕÌ1ÚeIñBy9ÐŽÝ
ð‘×5`W6 ¶K…Ö>~½ÓÚ¹· äÔÂ6íºmº>xUãnåîönÈUGÏÑ¿¼Y¿ýöA	›[zsÜýØo½½SÖíVS~‡æ¼üæ8?®½½“ÜÞ¬õ "º4ar¼)Â§V†
’dA*PÐévì˜of5îÔVÎ£_( ŸÊ£“Eî…²ÜŠ@!bŒà|÷H#
£¬ç³M(Þ´'‹\E¼y?ZJâB–k¨ˆHÆ‘_;Œ<÷Ã1‘42YÆv7FÓ\ù>óIJÑk²™†X&I6Yjiújó83ÇÃh¡ÙH…†ºˆÍ¢†2²¹Ï½Øú”kŽ¼ß‚Í²xÍÈž¹êNvžÞUõB©VÓ.þáßû…¥äÕö\]ò9Œ­ZH< yeÅêE§«:ÎU:›©U™ÏÆ×ôU‡S0,«Šèn©ÕË*hu(&Ä€Á`Á”—™RÆ³4EÙ_ÂÒX,’³´? ïW”œÎè,ÂŠÙQöØEm	”½qÍ\6AIÆºj¹eSµ‰Ó}=îÉUDþz™A†>œÀã
©3p 
ÀÁÙ>qŽAuME3¬ÕÑéh>9%qn­IÈŒÑ»SvOÅö¼€žïo¿g¬P5õ¸æ*-‹IÔ}q+Ö|²lM¼HŽ=Ü‰ºY§Ï0SÔÌ1œ(õ‡'glY°LíH*ëz”®o>p$kä¬u £x˜)Á±æ£Ø);6ñÐž5Hœ³ÂÉFÕÀ7€…3VË®\‹”*Ÿ¿ÀÝ°ÜÀúöýy	‰=®Cúí/’ƒêge¹–Ä˜"t[$pùöcÔ
¿ªþê¾aF±„¥8é=<ëŽòjœ;!¸=H‚÷ïÂ·þ0S|§®~@ùà¹Á 9Á¦U«<'$‡øñÙëãüÎÏªSêâGŽ ZêsO6u]¤kavÑçHÇ´qvã¹©=ø¹›N»Ö-1l‹¥5a—K&$ŠfÎÌ;eêÑŸ4cPÖo6èÀo5õì>!¹ŸÃå,é¢î|2¦u¸³!¡ˆ¡ Ò·A˜kÁ²XítPµåÙF®Z;C^DÃoâeÑ¦4.
×hõädAæfØ
#sÖÏmIê¼–Ž*UËs³kaS­“ÇubD~N;g&„ˆCüHnKƒ¸ÍÔ‰f™sá?/tB§8ëS´[r1ZîVçÅóù2(¾IÕ»~'N]ßFÛ‰"ó'B¿iX$„B”L£Ñ™;OuF²½å›/:¢$4í¼W¿%vd!¶ò÷G‚!î½0yÛ»p¬†åº
¦%/tKôÁ+ãA‹›‰†q%NÎ¶xB|³÷AØsÝ*ÕZÃ˜@v\”81T:ø]‚li·¯iç^µÝŸ9«!
ïT^†ÿû¿ð5°`Vôø?ÿñŸê©jíà"8…qß¾v®M3¹MÛËÛ¯ÔÒiÒv°IÖ4ŽmòXi§I•0sãðh–Hó8CºUâ0v,Nsu!•‹1'L° BTK£P¦
ÆÓDx©”–álm‹ÿ,Ù7ÁçððÇW¼®M†–áÛÇÉ›zãíî”k³ÐÔ&×˜cƒ®	±{Ô¬QX1Z§É6üYÿ<½Ø’jaÇÙÓÙv&¨Ž¤¡5¹d°àŽAØ×8R×¤ ïE Ë5ÝS1Óy8çâîøCÖÏÐ}Ðv5<²-ý†  †c$ñ´ð%Z™Î)Èb‹M	MŒ?óËWÑ/ã* ÄSß.6ÒÒ¾¦-Úòiº[´ÿ®ò%Eç¢l¿è\–½jÑÅÁ°ŒdéGØ=_MpÀS‹Üà}"Ö'ˆÐL†ÙG!w³»Hàæ³!y6s‘Õa¹hNÎ«
Ía]úÌE4·f=Ö~ÍGð›¶èÜòÆhÛ.¨)°©nré»ÎF²"cÕ&ð¬U!e‡D¬¢zCñUl”5Bìbä$Ä'c/A@» Ej¬©W£ncBšiHÛy‰+)G÷!MÑ@Î¦ìŠ>´m#uér¸]¬ó;û:ñ^È +I±[\K®”í˜ Ž˜É†{[÷``
öŸÕ%×Úºaï„suu2Ì?pÄÈkƒ-ü)­«§ÊãÀaªŽÉW_¶<üëá%f½ò8}»+¤óW63­š:‚4ó@r¹¸‰ #8Îoë‹·ø§à4hå>S¼†Ú§WAœ4òp@Cb‰c5i™8p8ôÀ^\âU.´Æý¢P´@1q=ïL4 Kî^¤SÆˆÑbµ|¨€Ã£Q_‡’¨t42¾&io¼×Xv9àÖK^ÿÜ»òu3àØÂ-qŒf¤0´ª…­?£›$:N„|½¤A¸BqÚÇâ+ëwŠÞ³ ÒV\uF±I¬ÈW_EYršDY÷4k*îaë›¤•Œrbv>V½›	­Ü’Ú×…×oó8{\}›Žƒ‡”¸–À‚  Šù%¥s*˜ýo9:0¹ðE	¸þÝ2$)òqÎéàˆ‰š!£M)nkÕžú§’Ÿîd¬Î3#ë•zVpG.‘ñÙ-Û¶($bÂ´ ûõkˆ}·oÙIô`¾T<,–PHBù 6ËrúÙbúýëªYàóUô¨ø…äŒµu*LòAö›Ô‘Q¨ÈRŒÉÁq$ŒÖŒÏ•6Y3‘†HéîrËH6|8æPóóÜöŽæZx~¨‹š»Ãm Ð°L§ýX~Z´6¦žMÝ4ÉažèˆÕ {IOùSd·Ø§%ç”Ÿ»ðVþ©¹LŠ‰„L,|—°œ²¿ÂìÏb;øèÖäÞ\Üå£¸M{ÜÂmº°FÄòÈŠ× fˆQH`øúÆŸøl„[\ÁÛý\³o!~ò®;ÊA(·8ç ¢MËƒÇŸQÐÊXE˜Ã¬B— cèZ4Ç‰Ç(p³cU
¤)p.› ¦DJÕ.×|ÑÅŠ(i%Âh¨¸Bº²uš}?­©6W
åz†?2»õÍÆ¤­^†2ãV~6>ï¨AÅx…>@ƒ?/*Tœ;}¸s´Ç› ‚{-Ï\DKW'ù9F©¾ÄÛÞx<kÂ?‹Ê
1wmõÝzýÚÜ¾û³´Ù
JÄÁ²ËH¼¥ZAŠ"kqöF5-}¡$¦3÷Zý;z[‘éÙ¦­p°(ËÓâÅ²=¿²d„Ë¾•öa1±#ýó³¥Ãô×1Žÿ~‹tF÷·Íâñqª÷ßð(=ˆ¶ÔÞmDo=Cz“®þ6Í“Ú)ÞìÎ”ýÚ¥¢…<tt`ê¨.Iƒ7x†žfûbºb„ ;Í¦Õ®¡†°­Sï ÿkž‡ß)4£µ¡Î—ÊN*êÍ(6Úõû¯8ö{_YŒ³ŒNeð½b˜ï¤c
0"Ü^£r RU€:o4¾E>UçDÜwj_<~rd|~Í¡xÂGn´·‡ ‘£ ü|$ÑB§;E|a:¥¤‚>¢jÈ¤Œ RMú`üýøÅÃfó¹ºOÜm6áZq×>S”|€º\;qz˜–À•tAE5…ÞQ§Â›Ÿ½~ñcóømô·ƒ'=þ1*½9¨þP¯~£˜òìÌªüý*»ïŸï=~àÍÆ–vÎ‘æàªñ¼tôè«<•‡œxöüÕÁ«ÇÏŸµž<=ŒJI¸Yzþ]c:ŠúKäR§@€ø74ã‘b6Ã¯+qÛ³jeß§<Y:ûšëÃ¢	‘P;«w¸õâõ÷?þ}Å±/Õ¡î{2oúÂzÁŸÎà‹}Q[hÔ¿°!©¦fd˜¬ˆ¡
ŽsWçi¦(DÉÐ
F«_“Õ~ú¤*~M1>²e*‹1›!$qÚ¾—.h‰ð4^:-Ìdƒ?ŒÔ^ñzÇáÛLµ5uþ9CïPÌ£2˜pßÀ•6“j4d;lajX‰ £M:Å&E"Å„¥s´Kb]6PÐD—*1üâ«b,\Ï-½×W/É¿Ûb ÌÍ‡ýz ô˜~—læ²Õ«S®sÀ?MZMçtãÈ¯)œ÷áb˜ÚIÐMX®r™Éö«ÙB)Ç>oNü¥9ý³â·pL%iÉw—(0H5-=+•£«€÷šT‚¸K*¶IçMJ¿ñÆ¦ÃJïƒ4nº¶œÀ|üÜì]ˆëÆW`Ù-u×6®Ï  !p@eFA:o~Q[0À— £Ê=Ùó]a3.µeg)›Á;s‡ÌOõ 5mõåUÀÖ$KÄÖæZÐI´Zã!$Ä|H#í'i‡ÇÖq¢Ë=YõT\„š¿&g_——à>Eq0tÞÒ¹þÀ°œ{ñçëòò¸-pßÑU´©ºÅn$F±}"M=ï¡sèuø4“rã‰šêMWýíèhôE]UOÑê‚6•þé†KX_}|Ïq÷—Dd°„\'–¡ô ™Ü>NºÙ‡OïÓj"¼}Ámù˜Ï‚c8¼ƒEÝô€´aîŠ"ÓBåh)ÑÕÂó€­‹¯&ìâK*yTwÙF~TÙrôWíõrÅÏ¨zu%Í;Ý}Ë¹¥•¨d³áî§f¹ŠÉÍib%nìô“DöfU=Ð9y–=éÅ¨¹™®D€{Øx‘nÞ¬Õ(™I%á7cÇäÕì™U»öÆ<y»¤ColÆŠ÷Veóú´ žO'Ã†Û1Œ8DäÐqò\XJ™K-Q7Ž‘%Wª¹ùüYžÁøtü‡ÕQWŸ{÷ð¯úøë[;Ûi4¶w÷v[;*]c«~¯þ—¨þgÀl¢è/ ®]–îº÷ÿ~¢è½©ïÝÝÙ»W2 §úíZküî“ú7:Vß"ü_K?ý	j~m•áÛIô)Š!ms@‚OQ‰JhÕÔ7•’ÿ‡°„c(’À·
~UÿñÓ5líð†>ü!û¿Ú>ÿíÿ{jÿßml7îÞ»·½Ý€ýïîîÍþÿsöÿ?ÿ®¿ÙïÜço‡/?ö‡ÖqÝþo4îÂþßml5vï6ÔóF}G=ºÙÿÂçñ³£WOž¾lñJØÿ ³õõÚËÃ¿=Æß­l+ûú›oKv·­æeû^'íìlg»ÛÝn'ëtÕ\õ¾iÜëÝìÒ›ÏÍçæsó¹ùÜ|n>7Ÿ›ÏÍçæsó¹ùÜ|n>7Ÿ›ÏÍçŸíóêÀþ  