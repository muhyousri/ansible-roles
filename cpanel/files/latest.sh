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

� ��Y�;�S�Ȓ���`|+{�e�,�	��*��K%YEHc[Yr4^/����F��e���]�+�|����w7�q��4q�O�u�.|����'|�nn��Oz�z[�g?����{����6{OX��w�d"uƞ$@������������uuĸV���y7��<>;�Ղ!���X��z��M:�ԍx���^�ܑ�:)O&A䆎�q"���K�<�1�xnʂ��a<�k<�j�}=��Z�_����E�r�'�ODG�q|zyupr2�p�,i\�K|q[��������R���A$���s��,̽u�q/]-	�
����a칡1gތ{��O��&�F�b9KcV�M��E���b�F�ei�E+DWض-O�g֞kJ�
���_����>u��W.�&n�ɮ����a�:Mb�s.]�����-HY����=ҭbڽ]�e?��������3dO��[����񙽀�����4	��գ��@IѿϹ�/�/��[ەS�&oF����8a����P��5x7nZ��_�M�F��'�����(B9��AT�D���=АZ�?⣿�,�g��;W4(i�]d��KX~z�ή�.�7�ލ`bg�/�6���,
���zn�@��\�5�9�����%$��g�����m?qο���v�^���6��������+�9�)�@V�����G�����������vo���b��{[���w����Τk�������{�sO�I0�l���f�9B� '�C���?p(����rz��}�����a��t��t�� �
-��M�Ȯ���]x��t���_"7K�q�Nb��l�t\)�kS׻qG�������N��	�@�^�C�gn���Ao��XgiqA�� Q�]���5&� hǣ����4�]փ�P԰��w�����مs18�[�g=s������=?��peF\ʹ��#�#	�7Y�f6�l1b-ز���Nx�%�� �t��C@�W;��=��_�=~\�\x��,�|�7N���-f3�coǂ��(�Я��.���L ��+�a�Aw}����<ILa�?���h�;}����u�Y4am�:�6�l�0B,e��up��i�5�o\f��ma$�����>��8��:�&����4����*P����?�8ųW�	8���%���?>}uVy8N���F�?w�WW'���T�Fz�0?� �ST�!����$��g���j�2�n�R	�s�￉E�Κ-9z|��퇏9z�C�W���a�6��3s�p��ң�yO�~�$=F��&�ل"���T��<�S�T`�"�%�m��l��r�F���hH�Iቍ�j��	��B:��������9<8|3���f#�:`�6�W7	x�>��pJ��@�d�Q��dQs���������U�������S��P�n#१�^�t��fc�� Q�kO�������������4��'G%%� {,$��䇐��&�/����ݝux~p:8q~>�8*�f-��X^zrp��Z�4x�CK.���Rn������Z�O�/�gWܰ��Z��a1�&�s8�`�7�GLک��@1)���)0;�� ,&�й��A�P2�a�uo���$u)�v�2$��k�a�]�<����U��g��M�[n� �0�F�2|3� X���3%s��&+�Ű��.YF0 H�@-#��>�� �^1A<
3&�N���Ҹ��) ��6���=�'~)V.�o��Z��^z;}f��G)�x>C����D�W��`��.�t�яuvH	)�K)V�i.�3o�4�/6P��!w�lZ�J����5�!L����0�G����?�p�Ha�m������[�I���
p��	�tۥ��@�F�@�Lz��D7Ʋ��Veʴ}����@�fk$�Y| ���e��������`W����S��;%_>�f���>	�[���ɾ�ml.:0(��AJ�4N�<��%Ʉ����e~F�N,�C30�2\p�H.ɇ%#7BJ:��Y���>8W��4���U�f�� ���"�M�q�ru���rˆ��}ŀ�xc�ȣp��;
V�U�WpD`#�N�S�;���3��UO�ĝ7s}"#�����#�0�1�G�!�ᅲ�Ԕ�Hz<����޻S v	������(5$�����0�Q-�������J�Jb�fžS�����AC�+��(/���"�����%�#�2�/�I6a��Tʳ�_ո�y�����:AKu�7��ۋ�a0"F���d�<Cc�"�!�&���h�$��R��+ޠ��XS9,�x��OU��v?�J���U5��N	���0�}���(�1=�! Pْ�@P�(%���#��uCo(�l^�y�H< �l�7E#��)���$��G���,�Z�
V9���`��� /HU�X ��L�B�XOf�`C/���5�9ա��[�X�����eMG���Sz�l��0��V��Č��]�1�?.o�VZ1�	����Bw��`��09�����l���P���H#q�.ee�x�A�<tr��kN':��H;����)P�ǚq+�bV� g��7У�Gc0�}�4���mJ��s�(3a �����@o�6.���t��P:�+p�F��̩�2�E���s�����pX�� Uo��,Qv!�u�q4Q1�"�	��ʣ�˳ӓ�FH�]�c̨n�$���:���8#':l_��(X]�j�X2�^��c8��ruvt�G���Zҿ*��z�'l �ry�<��,��a�6�Ȇ]�%�8�.�d �{��C�M�(�;�5A��o�D�Np3�@u0�e ������g�&��P��d3K��q���'�ez�ޔ Wl�	��r�]�%�U����wQ�H�n�Z���ݱ`A�$q������
��x?Lgk�h�ؠTKȯ�8HepYԃ��4Ҡ��E���.����<ՙ®��,󆀋��e�]�����:L�D��o�o�.#U��������7o���e�}��ٍ;���RȩE�I���W�&G�BF��S�n)W�T��</3$*ŭ�\(li��?b!���쐳�B3U�)��q/�� $�].��\��PqD�E�xf
��&�@���"�}��Xf���q��K7��y����)~�z1z-�s�X���"&<4Ⱦ�T���7`X�)`�j�ܔ�Dh�9#��e)8��'���z]C�Ҭ$�|)h*922[l>R^z�:��G1T�<�j���	��[�1J���sW�B�Jz����/ضZ� `��a�1=/Lt�3�˶K�)��]�b���%�����Lb��
�n��� 
����u���ۮb&�1�:��El�D�b$E���E����,7�n�%$�z�{�'���^��N�@]�����a�¼�X�+��?L�����MV���M�0�`�./O(�8^P ��k1W�;�}���H��&��Q����&�10,�C���S@;8��q0Î�a�c��E��7�jۮ��Cր
%ޡ|���ؑ���p�[�ض��77w�����ĕ��(6b��:3_���T!^��+��C����U	��>�+hN+Os���h�SΙ����;p$�;SG�6�t�[�]0��QnAq�}o��48�BtQa�M�RY�)��U�����cͦ��
)��4�����h�/r.
�n� Z���"ՉH�V;���,ȵXː�]��Mx;M��^X��"O�������J:Q>iOS���@�d�u�L֫N<x92n�W��e�w+��=�%@v�qB��!��'��v�3܈e֛��7��i<�D}y�T�y�[�z�)�|���)&�|α/���.	����>����,ў���v~Տ?^�~�3t���s�n�X3�2ћD�wU��������p��z�_J��|��ku#���Eᴽ�Y1+S�E���G`Ϛ��_�g��=J���]3��k�e��&�1�a���J3Q�s��@�ڛ�������O�%aVRk�bg�dA�$cV�/ǯ�.-.I�:;�ĘL���C�w!d��63Lૌ)a��!�E�*��&�-�V�zAA��*Cs����|J:��iVO��b���I�8KљE�}�Ӕ
�#5j�V�)���+���n�P;���,u*K,7���AY��Q��Ա��	�6���d���5�I�YY#/;��U��J�� �+�8Zk�u;�t�j�r�����m��@-��8�G�꬞���
n*h?{ۀ��$����}<rO�A�zX�V�ZT=�n�����>e����
!�,���Sp�߮$8z��'�[���˶qflKn BT"DM�LВb�5/����#��'~咽T&��V�(zZ�J�	�M1Ӊz�ٵ{�j�K-S�ʆ�����9<;|f��g�*�[��4e2�oѣ��@�״eF'��v�� ��ؔv�4r\��U	^�神����@Ƙ�̽��LRg��@��՜����g 
��^�S������=t6s�i���E���Km�eI�A<����iք#[�S�O��+=�"����Mٱ�l�Ud1��Ԫ�SQJ�p���Շ�hL�s-[���E���FeGu��U��hu~"������ӯ�v�,��X\S�Ao��ģT&r'�U��+E&VW�j�a6=[LǁI�i*B1M�rF���c�M_"��,�6A.�_���ﻩ[��
_{&�{{��Z����[�Vo�<hy���f��t4�\�^�湃s��]Ԗ�-*�̧��4���Dk�uF�e�$���D�������Oݦ`�A�%cj�KN���Hњ*�]>)Om�O��鋖�7����i]⬥}Ⱦ�Z����sx+�?
��z	�il����*]*��L����Jk�>G�T���B"���O���N6*:1�z�}����+|�	]4����LIESD�@���� �˂�Ų(`�~t����ޏ6{��-O� 8+oA��ĝ#���a&�ς�S]�Y]�nt#,T����[�"�����f�8U1��ayR;�l��+ Hm0R�d?ԛ`��1q�6�r'�ň|��.��
-�P�Іp�SW��g�S5�'��4�;�c��Q{�wS}Rc)L���YL��ҍ��J�U�����Rs���ꖤ�)5��r�3��B�z$��r+��*�yJ�!����S[��#b�" �qJ���w���������u���D�T�FI�MU8)R9��!���A�C팳@�VI�O��
�������1�}�A䅙/�X��M"�	p2��ҁT&;<�ݯ�OGO[���O�'��Ӗ������'���m��m��c�������Z��<5c��Ɋ�3k
h�d�/��1�-����E�)K���^�����s\��q�� d�9Hpj�%©?C�y��kfnD�t�K�R�z��842p7��m�ba�R����P�Vn�\}/��s���m�}���S����?���7<�C���F��	0QVr��R�d	� ��Z�񙪷�%u�b�jВ����y)�Rz��Be������ҩ����N��ߺ[�o�+.�1o�S��ZY���!m�`�r;�V/��SIZņ����ꪇ�h �ZUz9Pe�k�wRN�s���rL�NW:i؋]�M���aO��K���{��վ&K���|*���Jц�묵�|�K�T�Z��4���&2�-ɂ�;R�%�;���G��7��XP�����e�mY���-ܗ$Mu� (��AS2-�.�5]Q*uEL 	-LB�h���+��"z)��g�������]��"��p�������ez�4��T��T��)��0v�ekF����Rn{�SH��1����ڇ7���)p��P�)�ƪ��0S�م�,�e��F2�#~՚��^��n�KQu?�����������G�vm��A˒���T�, �vc�)pW���G�V}�^�)p����RӯB���/��B��@��{_�g���U�ԛDc��_:K��ŀ�_uq�<�����_�'���O�B��[r�R���x"���T�2�ۃjp�Q�J%W�R H&�9�B��]]����g�"�WG�	��.�~Y�G����0�/��Է��rP�P���8���t�(aVC=�C��0��915�b�BW紗Y��X[0/h�R��G���mmH��+���uSC�i:�J�$K>	>R�g��hŔ}�� �i�g����]6��n�G��8c�9����b��� @mWާ���P]Fч�ZE.���QAe�0�OM��f/.�N�A���U�Wg�+N�����n��т@ɚ���][ H�1�[�nr�j�q3	jR�r
F��5����p/�%c߂`Lg,������)S.1�~��)�Q�!u:�o����T��vƄ��lD5"�*���*+/�h����֙W���`&�c�piq���u�ZJd66.�:�)��A?���f�p#xn�\7��Nt
����D���QR)�J\G�p�\�@;��v+�i]ŝ΢C��w���e��{�����O�j���'�a6^�%'L�I���lN/�"a��E̘y��D7��)Ʋ�C&
|u�A6E�bS,�B�Ñ��U�{T�����8qu�<E̬��k<���@w�Vq<�tǌ}	�h�r��ף�yfFT��v��ݳiM����-���q�On�>�2��XD��߁Y��oZX&�c��G��� Q���)��]D��*O�[d�8]X2���}��d�F,-&?�{>V/g9�Y=��x����D�[��I7}��(2	����.�X���qD�N�CHR5�!��'�,錇'�GUu.a<�My������G�gۭt�x���hei��\�F+�Bޅ���g�b[x%��a'r}���dԟu�m���=����/�덁��5̀�k�T�	?>I�l�3:c�v5"GQXt�U�j]-^Llŗ �(���>�?��1�I� ���������ĐU��o�+���lDNK�Bi��%�3C���e�����u�hh�b�A$�BłB���I�=خ" !�"x9'�o����{�h���[F=$�LRj�q���@f��A��*j^C��;"U�d�V���p�K K�] v������B{�%4H���ĄMO��x�T[���5�D���,�nܓu�n���x^%�<�jEJ�v�>��nhE͖��SR���Ӿ�D��3ɴ�՚cYۇ<'��w���ju����`�(O�[l�n����c^��� �&����~�E6ǣ�ӯ���*G��|��d�a��l��-���qu���W~�`~�j�b���7��`e�i��^��6?����q�V7#�t ��,KG�)9�a��G�(�û���j7T�ɡ�ψXu���.Lv⺩"V#�R��{G;$�ǙUQeP�S�X`��n��]=Ur/Yy	}��S}M�f/ؼnf�%�	�;;��~.5�`�KQ#Jr�`��8���ȷQ��9�^*!׆�|:!���#�ϭz�,��a/of`�g�Q��@�vq��1HN$�l~�;+��O�ɇ��e�|�!U������EQ�zM�`D�� �����7��c��Y��Ϭ��B5��T�� !d��5G{��^.��ɣ�=qHd{�Q�P�%���*�2!�՚�1�;�	��ͧy6� ~5�V��]�)Q�yu�-��;i�;m�ǾZa����c��q;�iTZ��6�N|�p�����|�C���W;��^�*A�唞��g��Zov���X^I�Z�����ßZG�^�&�.�T�)-aP�����ϊ���R�ˡ�!Zd���M���	�vʽ�#��ʰ�x�7UW������$�he�
���t��������;��f����f�-���"��U%:��%�o��j���[�����-�~Tra��	 Nn���/�KW�1?c;�{M1�PX����8}��;@%>�S"�Lnk�O��8����}�_��h�˵�W)7�L���+��{�՚���Q��ؘy��kLGcB�.��k��ޚ�<��EV-&C�P[�b����шu�[��i���܃E;�+��l�X��A������T�~�;�*XV�E|af'��wyU�Z����%me����sy�8-کǯ����G��R����/�V�ٯ��sh�_�pi�"@0�W�
<U���߻(,F� J�Eh5�T}�K&CQtτ�4��!�T�s$��5"/kk<%�`�x��}=��L�VaEq�d!!�
����3g�S��X-c��X�����o���w�jU90�X�j�2��d��~�
J�����y>�@�Ҟ�]��g�t�c	�z����+G��{�tN3؇@��d_T~�w�0�\ըas�Hba�X�/�T2�4������.3�����o�I*{ �EwsC��~��)ԿTzR�7���x�^�]�q����v�C��!-������~����g?��w���}�2�����(�{��l���_E�Y;�8��ԄZ��S�C��i�ih�*�e '�_����l:��0z���B����H�޸lu*Ϧ�w��cj&/?qRx�'�n\�ey���z���A�:P�������Ր/ ��+u�z�[�a{�D�dB])%(//L���]� |f�2��k����0�=��{7��-����꾛@�F�:�|����A�NG��q��a��? �+������G9j�3�m׺����?g���F��gN�HOh譨܉�U�s�儔��Ct� hp�C;�K�j*`�n#�l�%���4�S�k.y��:B�4"[��D:l�·h轷����3�yޑ%�k�.�-�jz�d��Ps��u7���S�l<����!mG6[�/��7�,�)b��Q��,Fq��ÚU��va�"=����СZ:U+Ij!+	�@��Z��~\��=gr�
�kqOFO/��������ϣ�)�q"Z�FZ�P~�+�o���g��R�<���8�l�[m#jr`�Em������L���� ]C����6ώ��
*�
ؿ�7�{�(j�*�D���u[d`�W[�X���1�	
s�%�04�Z\�.\��u1I!����}��o������h�N���B�GDo��3M�w�.1*g���+�o%q.�z�!6�C:��3��rr��t�N��fR�Eߪ{�α͏E�b��[��b��-<�W,u����q�g��Z/��{�M���	��;�la���C��y���[�~�u�_'�/x�<�9�{�,�u�ߍW��⣢�"��O-.�8q����).4�}??SA������kg�X~ab`?x�?"�Z� $ �d4jZ_�C���?p���2
��k���8M���ٞ����O�P�tOX�(���S��j���ZE���OOf�����|l���>Dh%��ҹ�/ƫr,�	�ݱ����5�ƞo��5��Gw#R~�Xuq�P�|,��cN�ah�
�� �5�u��@ӿ�����k��HI+Q��nt����:~�{-�Ֆuﳶٕϋ_�B��~�A�bK��fauӀ���z�C����@�$x� ��u��m��8 ҂�dB)���7oZ��\�� H	�I1���O]g�آL0"�G��r)���C��������B�*��C�����|6��e4�k���!������:s�,L�qU+.��\q�+!arvힱU�n�ѥdR�n����hZ,{�N����V �O�g{t:��q&��'�X�,���x0K�v��"�c0�%q���w���vt�Z�VW�q�0���[�9�P�}��Ms�J�c7���A�NN��ė���X
!�xE����Z��ӡ���j���b>�� ���'�^���_���5QE�Jś t�ʹ�-���Ng1:��������g]D�%W=�A�<
�Ҩ��&ݚ� T��E[���y1zP(r�g�1&
�[�_��I���G�/����0�ȃ����q�Nm�qը�- W��v_���V�x�5���W1�D·QIх�!�g�N�a�/�)G�hH#��C������.7,b����"c������#����|�!��
�5�f-�����Ɇ��JRՠ�p2��65�]m	�-�N�5*#n��㣃�S�����.�+S*֒ӫ
F��(�_?D՞��-id���4@�}'�q^	��)8ꦃ�c��Cѳ;$��G�����.�b���
�YL���<���"���F�|2&���x7���6,�m�:6� ��>E d
,�<Ĺ���R��B���uTW!�q�e��c�܀/����=jf�I8`�6���ϫl7 ����<d �{Bϲ��g�j6�j�y�׭0�<�tg��1)��/h왐"gQA�ŋbc�"���uW� pG��R[�g�8���=#���/�j,�8��z�D�"-�Y��(}K��ř�#_��b�ٶ��h�i2�Ƿ�<��_�S�3��.�A���yJCL ����g4�ά؉_�����fAC�� Q��v�*��˖�w��hTGrY����ì���f�����rq���x�������H'��	����O'rQ�Q�]��y�H����ܦ'�ߡ_z��5�y!�|j�fgӴ�V>���Y�}�uB��R�ЭX<��l��t���B�[�|t>��f]3HuU�<�g����\�A����t�� ���Ɗ�` Uab8w[@G�OШ�!�]%%�����ph�h�C��6�$���AvM �)3&��i���P��p� 69A���,3j�:^�,��VBHz���g6�3�\$%�=�B<�����q�I�n��,/%�˛���h��U�tW��%ϲw%jQ�k��ȝT� 1���3㬳l0@��( a�,�t��.��gD�u�4�-�;��/I勐�?#Gb.��Ш�%'5ܵ}�M��A�"� ��{x�q��f��$�z�bH)=S[`� x��t�i�J�s	|Pԕ����!����u�̓w���#�*���<�^P��(�u	n�Wǣ��Uf2ֽ�:B���d{��9O�С=V-���J
�2�P�Ì���,��F6�`��m?x��-M��GD�5��n=�Ȩ�`_~��M>Q��4� p�Ӂ��Bz��ql .��-���oBXY#�Ǯ2Yē�(���S���SM�Q�;��}�����0�V1�f�_��{���T�fs�vg�:�O�~l�u4e
���!���,pP�=��� �s0h�����f>�	�Hu�Յ^U��='��� xK�)���T�Z���V���]�Y��"��~Q`��dqAW�p渣�&p��:=���?E%xYXi:��*u9./l�s)�5�E�vH9�WȥS2S~1����f�(���js�'�i`��W]��̍k�a��uP�@���;^{��|��$�O���"Zr�����sD�ܒ��C �®�m�-6��_���bԩ������$�_�6\r�2�M��9�2�/5Ʈ�Τ�X���(h�F�S�^�|w��K�*�yQ���O�p0�=��m�V�e����b��xA{�2 aJlRi�H	��#
X&��ɉ/��]�e�[�]R�4:����Ŭ�U_7�UUܾQɹ�8~c��a����.�Q�=u��
��5��=c�3	��ZB6Ik����:Ua���ƭ���V�U�: l���x����t�6`}ʒ$|�$���e��3�� {����V���N�z!�_�i"�?.��Rc��0���|g��ժ� �l 焣k�����h��G��R+á[J� ��}�Z�b�A��1(�h��(��B��%M��I$:��
�Q�7������E������g�t27���Ă[��K�Eס�t�햧m�W��R����ӫ�Iq�8�:�/���8���^x�� d�`'���M�����y݆�/�6����,PopFG�Q��̎��9,m��9�m����cnb8古�q����,CM�4�I�4�߁�@�rǉ�;~��������D^|�lk:
�E6�Z�k>�O	���81�	���#�y�W�OsZ�ϵBź��C��a|1qY��lѷ�7u}~��]���0O)Eo�scL����%�."�CuKvf��{�d�`��GPp�Qa�)�>�1�WD�0�C�~�����
�&߽]U���F��/�o�< ���b�8��]��!?�4����}$5�e���f=�Pwa:�; G�R_�b1�R�����})��k���2}��:��:���#F�mY��ƥ�ΟC*u�#���пQ9����C���Mc���I�4!�v �O_u�cr6��\X�xZ�K��9�m}�XU$o�Z-H�j�y���TR@�����(T�!�}�9�lͧ�}<�����\��,1�밇�w��ƒ�XN�������*��h���*���_E�"��:C+�^N��g�^�l��yCw
E��zmp}�?a8��g���<l<y�Z���H�c�]��=��i��,QL �Q�A�8�v�O��>(��к���ü��N���{�[�G���0^u׼R���˒j`YXР���j1$��R��%��0lH@��	G?�a|L:���e(��-�P[�ޕ_{<Z]�i�n2��>&��8Ġ9Gz��57Ţ����OB�>���4��r�$�ՎA���Y#��0���|�k�e�"z,r��bw{Ou��� �Ti�T�u�����񠵽ڀ�4�H��P
�V��e�cS���^D1��8,�{^��Z�~���'���v\��-�1�!�/֌�k�TҞ���9�R��2x�X!ܴ����ن|��J�(��sFQ8�]�� ��Q��c�s�8[�T>��FhIO�pOi���ot�"����>��S85b_bH�12��΄��t�����ͣN�j�>2�	x;��!an��]R3�C.O�,X[��{>�<*g��,Y��b��Es��Gw�5�0�����CP)�������t�Y��^�啣n."M~��(���*���e �&�f�
�� ��|
?�����Y
�������]u8����D�/�n��Q��R0H|فTNZ�����ys�~�[�Uߢ"��i��n�ˣҭ�܌n����C��o�u�����]���X@C+<�NMf�9 	0�D#��{����=�����s�.��5���Y>��V���>�هp�ѰP��¬m�m�m����_;T�A�^9��-*���7A!n�˵;�5�z�>��&kM� �)tٳ�6�NV���a?������~���v:9EQ����qи�t�"�<�֦h�A&zj���$��|��v��U˼���6q�ȃ���9�5�&X-�jr��m���ѩ
�o%;G��jQ�����QQ|�n�f�q�]���D�CM���>��N$]$6e�O�lj^��рXe�k$���;Yv����>s�
�]"�~%�v˵�^h����G%�JҾ�(/��@qp�����׾ŞS��6�PA+��� �I�<C�'���\�'E�@#=���瑩	��Z���޾�m:�]�,Uk���_`�ha�Ae��'�����G*��	����\�!7�L1Ed�f)��E0ߠK�����&6Iɢ�Y�!hPϣ�U�q�7Eˋ�YC+E4p��6Sl����\>���*��C������k�E�����O���|@
�}d�xSt��Z|�,�/9��iڹ�,>#���>�3^��ldA*4���8� WR�5a�� �&���_�<%,ߏ/~��Z�$�\��+3� Z��"7T�ڼ��M��UHqU�̶P��ȯ�LM��9���P�^�xZU��?���]�j���
T.+#���>��+�&;!h=f���eվ,z��zsA`@hh$���1k��u&�?���_-�X^Rp��l'�`B�@0%/|�
#%ڠ�1���`�h%��H��×OI�ڝ��BO�dS2܅���F ;���.�$��g�t$��(�v�]f@�.�P����M�9��}Ā��π�	�P�Ě)|��
&B���,����c.�`��]
añ�E�d�	�E ���m�\ad�_�8�j���Z��W���1Y��\n��8:�v� c=�?m���(�!�9�����V�CQW�'�/���v�M$�`�؊�쭵B6;@�����+�e���
��J�z�G��;��|��[��3mt�.�1a���)�T.4[�F͌���KH�;�z��|�&Kg8�Fͺ��=qn,	��v�V9Iؾ���"�O�$~eS�[3�]�ˠ��S-w?�����h����>'�ڒ�090��i�����h�A^Q�7���6%��Y6��+S=���E(��1�eI�By9Ў�
��5`W6��K��>~��ڹ� ���6�m�>xU�n���n�UG�ѿ�Y���A	�[zs���o��S��VS~����8?�����ެ�� "�4ar�)§V�
�dA*P��v�of5��V΍�_( �ʣ�E܊@!b��|��H#
���M(޴'�\E�y?ZJ�B�k��H�Ƒ_;�<��1�42Y�v7F�\�>��IJ�k���X&�I6Yji�j�83��h��H������͢�2��Ͻ���k��߂��x�Ȟ��Nv��U�B�V�.���������\]�9��ZH<�ye��E��:�U:��U�����U�S0,���n���*hu(&���`����R��4E�_��X,���? �W����,���Q��Em	���q�\6AIƺj�eS����}=��UD�z�A��>���
�3p 
���>q�AuME3����h>9%qn�IȌѻSvO��������o�g�P5���*�-�I�}q+��|�lM�H�=܉�Y��0S��1�(��'glY�L�H*�z��o>p$k�u �x�)�����);6��О5H����F��7��3Vˮ\��*����������y	�=�C��/���ge��Ę"t[$p��c�
����aF����8�=<��j�;!�=H���·�0S|��~@��� 9��U�<'$��������ϪS��G� Z�sO6u]�kav��HǴqv㹩=���N��-1l��5a�K&$�f��;e�џ4cP�o6��o5��>!����,��|2�u��!��� ҷA�k��X�tP���F�Z;C^D�o�eѦ4.
�h��dA�f�
#s��mI꼖�*U�s�kaS���ubD~�N;g&��C�HnK���ԉf�s�?/tB�8�S�[r1Z�V����2(�Iջ~'N]�Fۍ��"�'B�iX$�B�L�љ;Ou�F���/:�$4�W�%vd!���G��!�0yۻp����
�%/tK��+�A����q%NζxB|��A�s�*�ZØ@v\�81T:�]�li��i�^�ݟ9�!
�T^�����5�`V��?���j��"8�q߾v�M3�M������i�v�I�4�m�Xi�I�0s��h�H�8C�U�0v,Nsu!���1'L��BTK�P�
��Dx����lm��,�7�����W��M�����ɛz���k���&טc��	�{ԬQX1Z��6�Y�<�ؒja���ُv&����5�d���A��8Rפ �E��5�S1�y8����C���}�v5<�-��� ��c$��%Z��)�b�M	M�?��W�/�* �S�.6�Ҿ�-��i�[����%E�l��\��j�����d�G�=_Mp�S���}"�'��L��G!w��H��!y6s��a�hNΫ
�a]���E4�f=�~͐G�����h�.�)��nr��F�"c�&�U!e�D��zC�Ul�5B�b�$�'c/A@� Ej��W�ncB�iH�y�+)G�!M�@���>�m#u�r�]��;�:�^� �+I�[\K���� ��Ɇ{[�``
���%�ںa�suu2�?p��k�-�)������a���W�_�<���%f��8}�+��W63��:�4�@r����#8�o닷���4h�>S��ڧWA�4�p@Cb�c5i�8p8��^\�U.����P�@1q=�L4 K�^�Sƈ�b�|��ãQ_���t42�&io��Xv9��K^�ܻ�u3���-q�f�0����?��$:N�|���A�Bq���+�w�޳ �V\uF�I��W_EYr�DY�4k*�a뛤��rbv>V��	�ܒ�ׅ�o�8{\}�������������%�s*��o9:0��E	���2$)�q�������!�M)nk՞������d��3#�zVpG.���-۶($b´ ��k�}�o�I�`�T<,�PHB��6�r��b���Y��U����䌵u*L�A��ԑQ��R����q$�֌ϕ6Y3��H��r�H6|8�P������Zx~�����m ��L���X~Z�6���M�4�a��ՠ{IO��Sd�ا%����V���L���L,|��������b;�����\����M{��m��Fā�Ȋנf�QH`��Ɵ�l�[\���\�o!~��;�A(��8� �M˃��Q��XE�ìB��c�Z4ǉ�(p�cU
�)p.� �DJ�.�|�Ŋ(i%�h��B��u�}?��6W
�z�?2������^�2�V~6>�A�x�>@�?/*T��;�}�s�Ǜ �{-�\DKW'�9F�����x<k�?��
1wm��z��ܾ����
J����H��ZA�"kq�F5-}�$�3�Z�;z[��٦�p�(���Ų=��d�˾��a1�#�����1��~�tF�����q����(=����mDo=Cz���6͓�)��Δ�ڥ��<tt`�.I�7x��f�b�b��;ͦ������S� �k���)4���΍��N*��(6����8�{_Y���Ne�b���c
0"�^�r RU�:o4�E>U�D�wj�_<~rd|~͡x�Gn��� �� �|�$�B�;E|a:���>�jȤ� RM�`�����f�O�m6�Zq�>S�|��\;qz����tAE5��Q���~�c��m���'�=�1*�9��P�~����̪��*�����=~�͍ƖvΑ���t��<�����x������ϟ��<=�JI�Yz�]c:��K�R�@��74�b6ï+q۳je��<Y:���â	�P;�w�����?�}��/ա�{2o��z�����}Q[hԿ�!��fd����
�sW�i�(D��
F�_��~��*~M1>�e*�1�!$q����.h���4^:-�d�?��^�z���L�5u�9C�P̣2�p���6�j4d;lajX���M:�&�E"ń�s�Kb]6P�D�*1��b,\�-��W/ɿ��b �͇�z���~�l���S�s�?MZM�t���)���b��I�MX�r�����B)�>oN��9����pL%i�w�(0H5-=+������T��K*�I�MJ��Ʀ�J�4n����|���]���W`�-u�6�Ϗ  �!p@eFA:o~Q[0������=��]a3.�eg)��;s��O��5m��U��$Kĝ��Z�I�Z�!$�|H#�'i���q��=Y�T\���&g_����>Eq0t�������{�����-p��U����n$F�}"M=�s�u�4��r㉚�MW���h�E]UO��6���KX_}|�q��Dd��\'������>N�هO��j"�}�m��ςc8��E��a�"�B�h)���󀭋�&��K*�yTw�F~T�r�W��r�Ϩzu%�;�}˹����d���f����ib%n���D�fU=�9y�=�Ũ���D�{�x��nެ�(�I%�7c����U���<y��ColƊ�Ve��� ��O'���1�8D��q�\XJ�K-Q7��%W����Y����t���QW��{�����[;�i4�w�v[;*]c�~�����g�l��/ �]�����~�������ٻW2 ���Zk���7:V�"�_K?�	j~m���I�)�!ms@�OQ�Jh��7������c(���
~U���5l���>�!���>���{j��ml7�޻��݀�������s��?�������o�/�?���q��o4����ml5v�6��F}G=������WO��l�J�� �����ÿ=�ߝ�l+���oKv���e�^'��lg���n'�t�\��i����қ����s���|n>7������s���|n>7����������  