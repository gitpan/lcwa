dnl #
dnl #  aclocal.m4 -- Local M4 functions for GNU autoconf 2.x
dnl #  Copyright (c) Ralf S. Engelschall, <rse@en.engelschall.com>
dnl #
dnl #  NOTICE:
dnl #      all defined macros are named AC_*
dnl #      all defined and used variables are named acl-*
dnl #
dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  support for User Variables 
dnl ##
dnl ##########################################################
dnl
define(AC_UVAR_CODE,[dnl
if test .[$]ac_with_uvar = .yes; then
$1
fi
])
dnl
define(AC_UVAR_ANTICODE,[dnl
if test .[$]ac_with_uvar = .no; then
$1
fi
])
dnl
dnl
dnl -----------
dnl
dnl
define(AC_UVAR_INIT,[dnl
AC_ARG_WITH(uvar,dnl
[  --with-uvar             support for Runtime User Variable Setup],
ac_with_uvar=yes,
ac_with_uvar=no
)dnl
dnl
dnl # because since autoconf 2.3 the following two lines
dnl # are at AC_OUTPUT which is to late for us :-(
test "x$prefix"      = xNONE && prefix=$ac_default_prefix
test "x$exec_prefix" = xNONE && exec_prefix="${prefix}"
dnl
AC_UVAR_CODE(dnl
ac_uvar_editfile=/tmp/usrvar.tmp
rm -f $ac_uvar_editfile
echo "##" >>$ac_uvar_editfile
echo "##  RunTime User Variable Setup" >>$ac_uvar_editfile
echo -n "##  GNU autoconf Version " >>$ac_uvar_editfile
echo "AC_ACVERSION" >>$ac_uvar_editfile
echo "##  created: `date`" >>$ac_uvar_editfile
echo "##" >>$ac_uvar_editfile
echo "" >>$ac_uvar_editfile
)dnl
])dnl
dnl
dnl
dnl -----------
dnl 
define(AC_UVAR_VERB,[dnl
AC_UVAR_CODE(dnl
cat >>$ac_uvar_editfile <<'EOF'
$1dnl
EOF
)dnl
])dnl
dnl
dnl -----------
dnl 
define(AC_SET,[dnl
$1="$2"
AC_SUBST($1) dnl
])dnl
dnl
dnl -----------
dnl 
define(AC_UVAR_SET,[dnl
AC_SET($1, $2) dnl
AC_UVAR_CODE(dnl
    echo '$1="$2"' >>$ac_uvar_editfile
)dnl
])dnl
dnl 
dnl -----------
dnl 
define(AC_UVAR_SETQUOTE,[dnl
AC_SET($1, $2) dnl
AC_UVAR_CODE(dnl
    echo -n '$1="' >>$ac_uvar_editfile
    echo -n "$2" >>$ac_uvar_editfile
    echo '"' >>$ac_uvar_editfile
)dnl
])dnl
dnl 
dnl -----------
dnl 
define(AC_UVAR_SETCHK,[dnl
if test -z "[$]$1"; then
AC_UVAR_SET($1, $2) dnl
else
if test .[$]$1 = .NONE; then
AC_UVAR_SET($1, $2) dnl
else
AC_SUBST($1)dnl
AC_UVAR_CODE(dnl
    echo -n '$1="' >>$ac_uvar_editfile
    echo -n "[$]$1" >>$ac_uvar_editfile
    echo '"' >>$ac_uvar_editfile
)dnl
fi
fi
])dnl
dnl
dnl -----------
dnl 
define(AC_UVAR_SETCHKQUOTE,[dnl
if test -z "[$]$1"; then
AC_UVAR_SET($1, $2) dnl
else
if test .[$]$1 = .NONE; then
AC_UVAR_SET($1, $2) dnl
else
AC_SUBST($1)dnl
AC_UVAR_CODE(dnl
    echo -n '$1="' >>$ac_uvar_editfile
    echo -n "$2" >>$ac_uvar_editfile
    echo '"' >>$ac_uvar_editfile
)dnl
fi
fi
])dnl
dnl
dnl -----------
dnl
define(AC_UVAR_OUTPUT,[dnl
AC_UVAR_CODE(dnl
cat >>$ac_uvar_editfile <<'EOF'

##EOF##
EOF
if test x$withval = xyes ; then
    ${EDITOR-vi} $ac_uvar_editfile
    . $ac_uvar_editfile
else
    if test -r $withval ; then
        cp $withval $ac_uvar_editfile
        ${EDITOR-vi} $ac_uvar_editfile
        . $ac_uvar_editfile
        cp $ac_uvar_editfile $withval
    else
        ${EDITOR-vi} $ac_uvar_editfile
        . $ac_uvar_editfile
        cp $ac_uvar_editfile $withval
    fi
fi
rm -f $ac_uvar_editfile
)dnl
])dnl
dnl 
dnl 
dnl
dnl ##########################################################
dnl ##
dnl ##  check for ANSI compiler
dnl ##
dnl ##  Copyright (C) 1992, 1994 Free Software Foundation, Inc.
dnl ##  Francois Pinard <pinard@iro.umontreal.ca>, 1992.
dnl ##  Check for function prototypes.  Including a few ideas from
dnl ##  Brook G. Milligan <brook@trillium.botany.utexas.edu>.
dnl ##
dnl ##  taken from shar-4.0's aclocal.m4
dnl ##
dnl ##########################################################
dnl
AC_DEFUN(AC_C_PROTOTYPES,
[AC_MSG_CHECKING([for function prototypes])
AC_CACHE_VAL(ac_cv_c_prototypes,
[AC_TRY_LINK([#ifndef __STDC__
Syntax Error
#endif], [extern int test (int i, double x);
struct s1 {int (*f) (int a);};
struct s2 {int (*f) (double a);};],
  ac_cv_c_prototypes=yes, ac_cv_c_prototypes=no)])dnl
AC_MSG_RESULT([$ac_cv_c_prototypes])
if test $ac_cv_c_prototypes = yes; then
  AC_DEFINE(HAVE_PROTOTYPES)
  ANSI_CC=yes
else
  ANSI_CC=no
fi
AC_SUBST(ANSI_CC)
])dnl
dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  check for supported system type
dnl ##
dnl ##########################################################
dnl
dnl
AC_DEFUN(AC_SUPPORTED_CANONICAL_SYSTEM,[dnl
AC_REQUIRE([AC_CONFIG_AUX_DIR_DEFAULT])dnl

ac_config_sup=$ac_aux_dir/config.sup

# kludge for Solaris braindead sed which doesn't understand
# the \<n> syntax
if test "x`uname -a | grep 'SunOS 5'`" = "x"; then
    sed=sed
else
    sed=/usr/ucb/sed
fi

AC_MSG_CHECKING(for !supported! host   system type)
host=`$ac_config_sup $host_alias`
host_cpu=`echo $host | $sed 's/^\(.*\)-\(.*\)-\(.*\)$/\1/'`
host_vendor=`echo $host | $sed 's/^\(.*\)-\(.*\)-\(.*\)$/\2/'`
host_os=`echo $host | $sed 's/^\(.*\)-\(.*\)-\(.*\)$/\3/'`
AC_MSG_RESULT($host)

AC_MSG_CHECKING(for !supported! target system type)
target=`$ac_config_sup $target_alias`
target_cpu=`echo $target | $sed 's/^\(.*\)-\(.*\)-\(.*\)$/\1/'`
target_vendor=`echo $target | $sed 's/^\(.*\)-\(.*\)-\(.*\)$/\2/'`
target_os=`echo $target | $sed 's/^\(.*\)-\(.*\)-\(.*\)$/\3/'`
AC_MSG_RESULT($target)

AC_MSG_CHECKING(for !supported! build  system type)
build=`$ac_config_sup $build_alias`
build_cpu=`echo $build | $sed 's/^\(.*\)-\(.*\)-\(.*\)$/\1/'`
build_vendor=`echo $build | $sed 's/^\(.*\)-\(.*\)-\(.*\)$/\2/'`
build_os=`echo $build | $sed 's/^\(.*\)-\(.*\)-\(.*\)$/\3/'`
AC_MSG_RESULT($build)

ac_config_hc_dir=config

if test -r ${ac_config_hc_dir}/cpu-${host_cpu}.h; then
	host_cpu_H=1
else
	host_cpu_H=0
fi
if test -r ${ac_config_hc_dir}/cpu-${host_cpu}.c; then
	host_cpu_C=1
else
	host_cpu_C=0
fi

if test -r ${ac_config_hc_dir}/vendor-${host_vendor}.h; then
	host_vendor_H=1
else
	host_vendor_H=0
fi
if test -r ${ac_config_hc_dir}/vendor-${host_vendor}.c; then
	host_vendor_C=1
else
	host_vendor_C=0
fi

if test -r ${ac_config_hc_dir}/os-${host_os}.h; then
	host_os_H=1
else
	host_os_H=0
fi
if test -r ${ac_config_hc_dir}/os-${host_os}.c; then
	host_os_C=1
else
	host_os_C=0
fi
AC_SUBST(host_cpu_H)
AC_SUBST(host_cpu_C)
AC_SUBST(host_vendor_H)
AC_SUBST(host_vendor_C)
AC_SUBST(host_os_H)
AC_SUBST(host_os_C)
])dnl
dnl
dnl
dnl
define(AC_CONFIG_PARAMS,[dnl

AC_MSG_CHECKING(for name of user)
confuser="$LOGNAME"
AC_MSG_RESULT($confuser)
AC_SUBST(confuser)

AC_MSG_CHECKING(for name of host)
confhost="`uname -n`"
AC_MSG_RESULT($confhost)
AC_SUBST(confhost)

AC_MSG_CHECKING(for current date)
confdate="`date`"
AC_MSG_RESULT($confdate)
AC_SUBST(confdate)

])dnl
dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  check for fixed distribution tree and fix it if needed
dnl ##
dnl ##########################################################
dnl
dnl
AC_DEFUN(AC_FIX_DIST_TREE,[dnl
AC_REQUIRE([AC_CONFIG_AUX_DIR_DEFAULT])dnl

ac_fixdist=$ac_aux_dir/fixdist

AC_MSG_CHECKING(for fixed distribution)
# Make sure we can run fixdist
if $ac_fixdist -t >/dev/null 2>&1; then
    AC_MSG_RESULT(already fixed tree)
else
    AC_MSG_RESULT(vanilla tree => fixing...)
    $ac_fixdist
fi
])dnl
dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  check for generation mode: production or debug
dnl ##
dnl ##########################################################
dnl
dnl
define(AC_GENMODE,[dnl
AC_MSG_CHECKING(genmode)
AC_ARG_ENABLE(production,dnl
[  --enable-production     to enable procution code and disable debug],
GENMODE=production
CFLAGS="-O"
CXXFLAGS="-O"
LDFLAGS="-O"
LDXXFLAGS="-O"
if test X$GCC = Xyes; then
    CFLAGS="$CFLAGS -pipe"
    CXXFLAGS="$CXXFLAGS -pipe"
fi
,
GENMODE=debug
CFLAGS="-g -DDEBUG"
CXXFLAGS="-g -DDEBUG"
LDFLAGS="-g"
LDXXFLAGS="-g"
if test X$GCC = Xyes; then
    CFLAGS="$CFLAGS -ggdb3 -pipe"
    CXXFLAGS="$CXXFLAGS -ggdb3 -pipe"
	LDFLAGS="$LDFLAGS -ggdb3"
	LDXXFLAGS="$LDXXFLAGS -ggdb3"
fi
)dnl
AC_SUBST(CFLAGS)
AC_SUBST(CXXFLAGS)
AC_SUBST(LDFLAGS)
AC_SUBST(LDXXFLAGS)
AC_SUBST(GENMODE)
AC_MSG_RESULT($GENMODE)
])dnl
dnl
dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  support for Parts
dnl ##
dnl ##########################################################
dnl
define(AC_CONFIGURE_PART,[dnl
AC_MSG_RESULT()
AC_MSG_RESULT(__ $1 __)
])dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  check for Perl 5 module
dnl ##
dnl ##########################################################
dnl
define(AC_CHECK_PERL_MODULE,[dnl
AC_MSG_CHECKING([for Perl module $1 ($2)])
TMPFILE=/tmp/ac.$$
rm -f $TMPFILE 2>&1 >/dev/null
cat >$TMPFILE <<'EOT'
eval {
    require $1;
	if ('$2' ne 'ANY') {
		[$]is   = [$]$1::VERSION || '';
		[$]want = '$2';
	    [$]is     =~ s|^(\d+).(\d+)[$]|[$]1 * 100 + [$]2|e;
	    [$]want   =~ s|^(\d+).(\d+)[$]|[$]1 * 100 + [$]2|e;
	    die if (not [$]is or ([$]want > [$]is));
    }
};
if ([$]@) {
    print "failed";
} else {
    print "ok";
}
EOT
rc=`$PATH_PERL $TMPFILE`; 
rm -f $TMPFILE 2>&1 >/dev/null
if test ".$rc" = .ok; then
	HAVE_$3=1
    AC_MSG_RESULT([yes])
else
    HAVE_$3=0
    AC_MSG_RESULT([no])
fi
AC_SUBST(HAVE_$3)
])dnl
dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  check for latest Perl interpreter
dnl ##
dnl ##########################################################
dnl
dnl
define(AC_CHECK_PERL_INTERPRETER,[dnl
AC_MSG_CHECKING([for Perl interpreter])
AC_ARG_WITH(perl,dnl
[  --with-perl             force the usage of a specific installed Perl],
ac_perlprog=$with_perl
ac_perlvers=`$perlprog -v | grep version | sed -e 's/.* version //' -e 's/ built.*//' -e 's/ with.*//'`
,
TMPFILE=/tmp/ac.$$
rm -f $TMPFILE
touch $TMPFILE
c=0
for dir in `echo $PATH | sed -e 's/:/ /g'` /tmp; do
    for perl in perl5 perl miniperl; do
         if test -f "$dir/$perl"; then
             if test -x "$dir/$perl"; then
                 perl="$dir/$perl"
                 version=`$perl -v | grep version | sed -e 's/.* version //' -e 's/ built.*//' -e 's/ with.*//'`
                 versionnum="`echo $version | sed -e 's/\.//g' -e 's/_//g'`"
                 versionnum=`expr $versionnum - $c`
                 echo "$versionnum $version $perl" >>$TMPFILE
             fi
         fi
    done
    c=`expr $c + 1`
done
ac_perlprog="`cat $TMPFILE | sort -u | tail -1 | cut '-d ' -f3`"
ac_perlvers="`cat $TMPFILE | sort -u | tail -1 | cut '-d ' -f2`"
rm -f $TMPFILE
)dnl
AC_MSG_RESULT([$ac_perlprog v$ac_perlvers])
if test -f $ac_perlprog; then
    :
else
    AC_ERROR([required program ``perl'' not found])
fi
AC_SUBST(ac_perlprog)
AC_SUBST(ac_perlvers)
PATH_PERL=$ac_perlprog
AC_SUBST(PATH_PERL)
])dnl
dnl
dnl ##########################################################
dnl ##
dnl ##  check for MakeMaker install paths
dnl ##
dnl ##########################################################
dnl
define(AC_CHECK_PERL_MM_PATHS,[dnl
AC_MSG_CHECKING([for MakeMaker's private install paths])
TMPDIR=/tmp/ac.$$
rm -rf $TMPDIR 2>/dev/null
mkdir $TMPDIR
cat >$TMPDIR/Makefile.PL <<'EOT'
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Dummy::Dummy',
    'VERSION'	=> '0.0',
);
sub MY::postamble {
	'
dummy:
	@echo MM_INSTALLPRIVLIB=$(INSTALLPRIVLIB)
	@echo MM_INSTALLARCHLIB=$(INSTALLARCHLIB)
	@echo MM_INSTALLSITELIB=$(INSTALLSITELIB)
	@echo MM_INSTALLSITEARCH=$(INSTALLSITEARCH)
';
}
EOT
test "x$prefix" = xNONE && prefix=$ac_default_prefix
test "x$exec_prefix" = xNONE && exec_prefix='${prefix}'
eval "dir=$libdir"
( cd $TMPDIR; eval "$PATH_PERL Makefile.PL PREFIX=$dir/perl_private >/dev/null 2>/dev/null" )
for line in `make -f $TMPDIR/Makefile dummy | grep '^MM_INSTALL'`; do
	eval "$line"
done
rm -rf $TMPDIR 2>/dev/null
AC_MSG_RESULT([ok])
AC_SUBST(MM_INSTALLPRIVLIB)
AC_SUBST(MM_INSTALLARCHLIB)
AC_SUBST(MM_INSTALLSITELIB)
AC_SUBST(MM_INSTALLSITEARCH)
])dnl
dnl
