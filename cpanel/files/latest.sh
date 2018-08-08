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

� ��Y�;�S�Ȓ���`|+{�e�,�	��*��K%YEHc[Yr4^/����F��e���]�+�|����w7�q��4q�O�u�.|����'|�nn��Oz�z[�g?����{����6{OX��w�d"uƞ$@������������uuĸV���y7��<>;�Ղ!���X��z��M:�ԍx���^�ܑ�:)O&A䆎�q"���K�<�1�xnʂ��a<�k<�j�}=�
����a칡1gތ{��O��&�F�b9KcV�M��E���b�F�ei�E+DWض-O�g֞kJ�
���_����>u��W.�&n�ɮ����a�:Mb�s.]�����-HY����=ҭbڽ]�e?��������3dO��[����񙽀�����4	��գ��@IѿϹ�/�/��[ەS�&oF����8a����P��5x7nZ��_�M�F��'�����(B9��AT�D���=АZ�?⣿�,�g��;W4(i�]d��KX~z�ή�.�7�ލ`bg�/�6���,
���zn�@��\�5�9�����%$��g�����m?qο���v�^���6��������+�9�)�@V�����G�����������vo���b��{[���w����Τk�������{�sO�I0�l���f�9B� '�C���?p(����rz��}�����a��t��t�� �
-��M�Ȯ���]x��t���_"7K�q�N
3&�
p��	�tۥ��@�F�@�Lz��D7Ʋ��Veʴ}����@�fk$�Y| ���e��������`W����S��;%_>�f���
V�U�WpD`#�N�S�;���3��UO�ĝ7s}"#�����#�0�1�G�!�ᅲ�Ԕ�Hz<����޻S v	������(5$�����0�Q-�������J�Jb�fžS�����AC�+��(/���"�����%�#�2�/�I6a��Tʳ�_ո�y�����:AKu�7��ۋ�a0"F���d�<Cc�"�!�&���h�$��R��+ޠ��XS9,�x��OU��v?�J���U5��N	���0�}���(�1=�! Pْ�@P�(%���#��uCo(�l^�y�H< �l�7E#��)���$��G���,�Z�
V9���`��� /HU�X ��L�B�XOf�`C/���5�9ա
��x?Lgk�h�ؠTKȯ�8HepYԃ��4Ҡ��E���.����<ՙ®��,󆀋��e�]�����:L�D��o�o�.#U��������7o���e�}��ٍ;���RȩE�I���W�&G�BF��S�n)W�T��</3$*ŭ�\(li��?b!���쐳�B3U�)��q/�� $�]
��&�@���"�}��Xf���q��K7��y����)~�z1z-�s�X���"&<4Ⱦ�T���7`X�)`�j�ܔ�Dh�9#��e)8��'���z]C�Ҭ$�|)h*922[l>R^z�:��G1T�<�j���	��[�1J���sW�B�Jz����/ضZ� `��a�1=/Lt�3�˶K�)��]�b���%�����Lb��
�n��� 
����u���ۮb&�1�:��El�D�b$E���E����,7�n�%$�z�{�'���^��N�@]�����a�¼�X�+��?L�����MV���M�0
%ޡ|���ؑ���p�[�ض��77w�����ĕ��(6b��:3_���T!^��+��C����U	��>�+hN+Os���h�SΙ����;p$�;SG�6�t�[�]0��QnAq�}o��48�BtQa�M�RY�)��U�����cͦ��
)��4�����h�/r.
�n� Z���"ՉH�V;���,ȵXː�]��Mx;M��^X��"O�������J:Q>iOS���@�d�u�L֫N<x92n�W��e�w+��=�%@v�qB��!��'��v�3܈e֛��7��i<�D}y�T�y�[�z�)�|���)&�|α/���.	����>����,ў���v~Տ?^�~�3t���s�n�X3�2ћD�wU��������p��z�_J��|��ku#���Eᴽ�Y1+S�E���G`Ϛ��_�g��=J���]3��k�e��&�1�a���J3Q�s�
�#5j�V�)���+���n�P;���,u*K,7���AY��Q��Ա��	�6���d���5�I�YY#/;��U��J�� �+�8Zk�u;�t�j�r�����m��@-��8�G�꬞���
n*h?{ۀ��$����}<rO�A�zX�V�ZT=
!�,���Sp�߮$8z��'�[���˶qflKn BT"DM�LВb�5/����#��'~咽T&��V�(zZ�J�	�M1Ӊz�ٵ{�j�K-S�ʆ�����9<;|f��g�*�[��4e2�oѣ��@�״eF'��v�� ��ؔv�4r\��U	^�神����@Ƙ�̽��LRg��@��՜����g 
��^�S������=t6s�i���E���Km�eI�A<����iք#[�S�O��+=�"����Mٱ�l�Ud1��Ԫ�SQJ�p���Շ�hL�s-[���E���FeGu��U��hu~"������ӯ�v�,��X\S�Ao��ģT&r'�U��+E&VW�j�a6=[LǁI�i*B1M�rF���c�M_"��,�6A.�_���ﻩ[��
_{&�{{�
��z	�il����*]*��L����Jk�>G�T���B"���O���N6*:1�z�}�����+|�	]4����LIESD�@���� �˂�Ų(`�~t����ޏ6{��-O� 8+oA��ĝ#���a&�ς�S]�Y]�nt#,T����[�"�����f�8U1��ayR;�l��+ Hm0R�d?ԛ`��1q�6�r'�ň|��.��
-�P�Іp�SW��g�S5�'��4�;�c��Q{�wS}Rc)L���YL��ҍ��J�U�����Rs���ꖤ�)5��r�3��B�z$��r+��*�yJ�!����S[��#b�" �qJ���w���������u���D�T�FI�MU8)R9��!���A�C팳@�VI�O��
�������1�}�A䅙/�X��M"�	p2��ҁT&;<�ݯ�OGO[���O�'��Ӗ������'���m��m��c�������Z����<5c��Ɋ�3k
h�d�/��1�-����E�)K���^�����s\��q�� d�9Hpj�%©?C�y��kfnD�t�K�R�z��842p7��m�ba�R����P�Vn�\}/��s���m�}���S����?���7<�C���F��	0QVr��R�d	� ��Z�񙪷�%u�b�jВ����y)�Rz��Be������ҩ����N��ߺ[�o�+.�1o�S��ZY���!m�`�r;�V/��SIZņ����ꪇ�h �ZUz
F��5����p/�%c߂`Lg,������)S.1�~��)�Q�!u:�o����T��vƄ��lD5"�*���*+/�h����֙W���`&�c�piq���u�ZJd66.�:�)��A?���f�p#xn�\7��Nt
����D���QR)�J\G�p�\�@;��v+�i]ŝ΢C��w���e��{�����O�j���'�a6^�%'L�I���lN/�"a��E̘y��D7��)Ʋ�C&
|u�A6E�bS,�B�Ñ��U�{T�����8qu�<
���t��������;
<U���߻(,F� J�Eh5�T}�K&CQtτ�4��!�T�s$��5"/kk<%�`�x��}=��L�VaEq�d!!�
����3g�S��X-c��X�����o
J�����y>�@�Ҟ�]��g�t�c	�z����+G��{�tN3؇@��d_T~�w�0�\ըas�Hba�X�/�T2�4������.3�����o�I*{ �EwsC��~��)ԿTzR�7���x�^�]�q����v�C��!-������~����g?��w���}�2�����(�{��l���_E�Y;�8��ԄZ��S�C��i�ih�*�e '�_����l:��0z���B����H�޸lu*Ϧ�w��cj&/?qRx�'�n\�ey���z���A�:P�������Ր/ ��+u�z�[�a{�D�dB])%(//L���]� |f�2��k����0�=��{7��-����꾛@�F�:�|����A�NG��q��a��? �+������G9j�3�m׺����?g���F��gN�HOh譨܉�U�s�儔��Ct� hp�C;�K�j*`�n#�l�%���4�S�k.y��:B�4"[��D:l�·h轷����3�yޑ%�k�.�-�jz�d��Ps��u7���S�l<����!mG6[�/��7�,�)b��Q��,Fq��ÚU��va�"=����СZ:U+Ij!+	�@��Z��~\��=gr�
�kqOFO/��������ϣ�)�q"Z�FZ�P~�+�o���g��R�<���8�l�[m#jr`�Em������L���� ]C����6ώ��
*�
ؿ�7�{�(j�*�D���u[d`�W[�X���1�	
s�%�04�Z\�.\��u1I!����}��o������h�N���B�GDo��3M�w�.1*g���+�o%q.�z�!6�C:��3��rr��t�N��fR�Eߪ{�α͏E�b��[��b��-<�W,u����q�g��Z/��{�M���	��;�la���C��y���[�~�u�_'�/x�<�9�{�,�u�ߍW��⣢�"��O-.�8q����).4�}??SA������kg�X~ab`?x�?"�Z� $ �d4jZ_�C���?p���2
��k���8M���ٞ����O�P�tOX�(���S��j���ZE���O
�� �5�u��@ӿ�����k��HI+Q��nt����:~�{-�Ֆuﳶٕϋ_�B��~�A�bK��fauӀ���z�C����@�$x� ��u��m��8 ҂�dB)���7oZ��\�� H	�I1���O]g�آL0"�G��r)���C��������B�*��C�����|6�
!�xE����Z��ӡ���j���b>�� ���
�Ҩ��&ݚ� T��E[���y1zP(r�g�1&
�[�_��I���G�/����0�ȃ����q�Nm�qը�- W��v_���V�x�5���W1�D·QIх�!�g�N�a�/�)G�hH#��C������.7,b����"c�
�5�f-�
F��(�_?D՞��-id���4@�}'�q^	��)8ꦃ�c��Cѳ;$��G�����.�b���
�YL���<���"���F�|2&���x7���6,�m�:6� ��>E d
,�<Ĺ���R��B���uTW!�q�e��c�܀/����=jf�I8`�6���ϫl7 ����<d �{Bϲ��g�j6�j�y�׭0�<�tg��1)��/h왐"gQA�ŋbc�"���uW� pG��R[�g�8���=#���/�j,�8��z�D�"-�Y��(}K��ř�#_��b�ٶ��h�i2�Ƿ�<��_�S�3��.�A���yJCL ��
�2�P�Ì���,��F6�`��m?x��-M��GD�5��n=�Ȩ�`_~��M>Q��4� p�Ӂ��Bz��ql .��-���oBXY#�Ǯ2Yē�(���S���SM�Q�;��}�����0�V1�f�_��{���T�fs�vg�:�O�~l�u4e
���!���,pP�=��� �s0h�����f>�	�Hu�Յ^U�
X&��ɉ/��]�e�[�]R�4:����Ŭ�U_7�UUܾQɹ�8~c��a����.�Q�=u��
��5��=c�3	��ZB6Ik����:Ua���ƭ���V�U�: l���x����t�6`}ʒ$|�$���e��3�� {����V���N�z!�_�i"�?.��Rc��0���|g��ժ� 
�Q�7������E������g�t27���Ă[��K�Eס�t�햧m�W��R����ӫ�Iq�8�:�/���8���^x�� d�`'���M�����y݆�/�6����,PopFG�Q��̎��9,m��9�m����cnb8古�q����,CM�4�I�4�߁�@�rǉ�;~��������D^|�lk:
�E6�Z�k>�O	���81�	���#�y�W�OsZ�ϵBź��C��a|1qY��lѷ�7u}~��]���0O)Eo�scL����%�."�CuKvf��{�d�`��GPp�Qa�)�>�1�WD�0�C�~���
�&߽]U���F��/�o�< ���b�8��]��!?�4����}$5�e���f=�Pwa:�; G�R_�b1�R�����})��k���2}��:���:���#F�mY��ƥ�ΟC*u�#���пQ9����C���Mc���I�4!�v �O_u�cr6��\X�xZ�K��9�m}�XU$o�Z-H�j�y���TR@�����(T�!�}�9�lͧ�}<�����\��,1�밇�w��ƒ�XN�������*��h���*���_E�"��:C+�^N��g�^�l��yCw
E��zmp}�?a8��g���<l<y�Z���H�c�]��=��i��,QL
�V��e�cS���^D1��8,�{^��Z�~���'���v\��-�1�!�/֌�k�TҞ���9�R��2x�X!ܴ����ن|��J�(��sFQ8�]�� ��Q��c�s�8[�T>��FhIO�pOi��
�� ��|
?�����Y
�������]u8��
�o%;G��jQ�����QQ|��n�f�q�]���D�CM���>��N$]$6e�O�lj^��рXe�k$���;Yv����>s�
�]"�~%�v˵�^h����G%�JҾ�(/��@qp���
�}d�xSt��Z|�,�/9��iڹ�,>#��
T.+#��
#%ڠ�1���`�h%��H��×OI�ڝ��BO�dS2܅���F ;���
&B���,����
añ�E�d�	�E ���m�\ad�_�8�j���Z�
��J�z�G��;��|��[��3mt�.�1a���)�T.4[�F͌���KH�;�z��|�&Kg8�Fͺ��=qn,	��v�V9Iؾ���"�O�$~eS�[3�]�ˠ��S-w?�����h����>'�ڒ�090��i�����h�A^Q�7���6%��Y6��+S=���E(��1�eI�By9Ў�
��5`W6��K��>~��ڹ� ���6��m�>xU�n���n�UG�ѿ�Y���A	�[zs���o��S��VS~����8?�����ެ�� "�4ar�)§V�
�dA*P��v�of5��V΍�_( �ʣ�E܊@!b��|��H#
���M(޴'�\E�y?ZJ�B�k��H�Ƒ_;�<��1�42Y�v7F�\�>��IJ�k���X&�I6Yji�j�83��h��H������͢�2��Ͻ���k��߂�
�3
���>q�AuME3����h>9%qn�IȌѻSvO��������o�g�P5���*�-�I�}q+��|�lM�H�=܉�Y��0S��1�(��'glY�L�H*�z��o>p$k�u �x�)�����);6��О5H����F��7��3Vˮ\��*����������y	�=�C��/���ge��Ę"t[$p��c�
����aF����8�=<��j�;!�=H���·�0S|��~@��� 9��U�<'$��������ϪS��G� Z�sO6u]�kav��HǴqv㹩=���N��-1l��5a�K&
�h��dA�f�
#s��mI꼖�*U�s�kaS���ubD~�N;g&��C�HnK���ԉf�s�?/tB�8�S�[r1Z�V����2(�Iջ~'N]�Fۍ��"�'B�iX$�B�L�љ;Ou
�%/tK��+�A����q%NζxB|��A�s�*�ZØ@v\�81T:�]�li��i�^�ݟ9�!
�T^�����5�`V��?���j��"8�q߾v�M3�M������i�v�I�4�m�Xi�I�0s��h�H�8C�U�0v,Nsu!���1'L��BTK�P�
��Dx����lm��,�7�����W��M�����ɛz���k���&טc��	�{ԬQX1Z��6�Y�<�ؒja���ُv&����5�d���A��8Rפ �E��5�S1�y8����C���}�v5<�-��� ��c$��%Z��)�b�M	M�?��W�/�* �S�.6�Ҿ�-��i�[����%E�l��\��j�����d�G�=_Mp�S���}"�'��L��G!w��H��!y6s��a�hNΫ
�a]���E4�f=�~͐G�����h�.�)��nr��F�"c�&�U!e�D��zC�Ul�5B�b�$�'c/A@� Ej��W�ncB�iH�y�+)G�!M�@���>�m#u�r�]��;�:�^� �+I�[\K�
���%�ںa�suu2�?p��k�-�)������a���W�_�<���%f��8}�+��W63��:�4�@r����#8�o닷���4h�>S��ڧWA�4�p@Cb�c5i�8p8��^\�U.����P�@1q=�L4 K�^�Sƈ�b�|��ãQ_���t42�&io��Xv9��K^�ܻ�u3���-q�f�0����?��$:N�|���A�Bq���+�w�޳ �V\uF�I��W_EYr�DY�4k*�a뛤��rbv>V��	�ܒ�ׅ�o�8{\}�������������%�s*
�)p.� �DJ�.�|�Ŋ(i%�h��B��u�}?��6W
�z�?2������^�2�V~6>�A�x�>@�?/*T��;�}�s�Ǜ �{-�\DKW'�9F�����x<k�?��
1wm��z��ܾ����
J����H��ZA�"kq�F5-}�
0"�^�r RU�:o4�E>U�D�wj�_<~rd|~͡x�Gn��� �� �|�$�B�;E|a:���>�jȤ� RM�`�����f�O�m6�Zq�>S�|��\;qz����tAE5��Q���~�c��m���'�=�1*�9��P�~����̪��*�����=~�͍ƖvΑ���t��<�����x������ϟ��<=�JI�Yz�]c:��K�R�@��74�b6ï+q۳je��<Y:���â	�P;�w�����?�}��/ա�{2o��z�����}Q[hԿ�!��fd����
�sW�i�(D��
F�_��~��*~M1>�e*�1�!$q�
~U���5l���>�!���>���{j��ml7�޻��݀�������s��?�������o�/�?���q��o4����ml5v�6��F}G=������WO��l�J�� �����ÿ=�ߝ�l+���oKv���e�^'��lg���n'�t�\��i����қ����s���|n>7������s���|n>7����������  