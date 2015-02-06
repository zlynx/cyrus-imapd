AC_DEFUN([CYRUS_BERKELEY_DB_OPTS],
[
AC_ARG_WITH(bdb-libdir,
	[  --with-bdb-libdir=DIR   Berkeley DB lib files are in DIR],
	with_bdb_lib=$withval,
	[ test "${with_bdb_lib+set}" = set || with_bdb_lib=none])
AC_ARG_WITH(bdb-incdir,
	[  --with-bdb-incdir=DIR   Berkeley DB include files are in DIR],
	with_bdb_inc=$withval,
	[ test "${with_bdb_inc+set}" = set || with_bdb_inc=none ])
])

AC_DEFUN([SNERT_BERKELEY_DB],[
AS_IF([test ${with_bdb:-yes} != 'no'],[
	AC_REQUIRE([CYRUS_BERKELEY_DB_OPTS])
	echo "Check for Berkeley DB support..."

	bdb_save_LIBS=$LIBS
	bdb_save_CFLAGS=$CFLAGS
	bdb_save_LDFLAGS=$LDFLAGS

	dnl Short list of system directories to try.
	if test -d "$with_bdb_inc" ; then
		BDB_DIRS="$with_bdb_inc"
	elif test -d "$with_bdb/include" ; then
		BDB_DIRS="$with_bdb/include"
	else
		BDB_DIRS="/opt /usr/pkg/include /usr/local/include /usr/include"
	fi

	dnl Find all instances of db.h
	AC_LANG_PUSH(C)
	bdb_best_major=-1
	bdb_best_minor=-1
	for h in `find $BDB_DIRS -name db.h 2>/dev/null`; do
		AC_MSG_CHECKING($h)
		I_DIR=`dirname $h`

		dnl Version subdirectory.
		v=`basename $I_DIR`
		if test $v = 'include' ; then
			d=$I_DIR
			v=''
		else
			d=`dirname $I_DIR`
		fi
		d=`dirname $d`

		dnl Determine matching lib directory.
		if test -d "$with_bdb_lib" ; then
			L_DIR="$with_bdb_lib"
		elif test -d $d/lib64/$v ; then
			L_DIR="$d/lib64/$v"
		elif test -d $d/lib/$v ; then
			L_DIR="$d/lib/$v"
		elif test -d $d/lib64 ; then
			L_DIR="$d/lib64"
		else
			L_DIR="$d/lib"
		fi

		dnl Don't need to add system locations to options.
		if test ${I_DIR} != '/usr/include' ; then
			CFLAGS="-I$I_DIR $CFLAGS"
		fi
		if test ${L_DIR} != '/usr/lib64' -a ${L_DIR} != '/usr/lib' ; then
			LDFLAGS="-L$L_DIR $LDFLAGS"
		fi

		dnl Extract the version number.
		bdb_major=`grep DB_VERSION_MAJOR $h | cut -f 3`
		if test -n "$bdb_major" ; then
			bdb_minor=`grep DB_VERSION_MINOR $h | cut -f 3`
			bdb_create='db_create'
		else
			dnl Assume oldest version commonly found used by BSD variants.
			bdb_major=1
			bdb_minor=85
			bdb_create='dbopen'
			check_libc='c'
		fi

		AC_MSG_RESULT(${bdb_major}.${bdb_minor})

		dnl Library search based on include version directory.
		for l in $v db $check_libc ; do
			if test "$l" != 'c'; then
				LIBS="-l$l $LIBS"
			fi
			bdb_name=$l

			AC_MSG_CHECKING([for $bdb_create in lib$bdb_name])
			AC_LINK_IFELSE([
				AC_LANG_SOURCE([[
#include <stdlib.h>
#ifdef HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif
#include <db.h>

int
main(int argc, char **argv)
{
#ifdef DB_VERSION_MAJOR
	DB *db = NULL;
	return db_create(&db, NULL, 0) != 0 || db == NULL;
#else
	DB *db = dbopen("access.db", 0, 0, 0, NULL);
	return 0;
#endif
}
				]])
			],[
				found=yes
				AC_MSG_RESULT(yes)
				AC_DEFINE_UNQUOTED(HAVE_DB_H)
				if test $bdb_major = 1 ; then
					AC_DEFINE_UNQUOTED(HAVE_DBOPEN, 1)
				else
					AC_DEFINE_UNQUOTED(HAVE_DB_CREATE, 1)
				fi

				dnl Assume newest is best.
				if test $bdb_major -gt $bdb_best_major \
				-o \( $bdb_major -eq $bdb_best_major -a $bdb_minor -gt $bdb_best_minor \); then
					bdb_best_major=$bdb_major
					bdb_best_minor=$bdb_minor
					if test -n "$l" ; then
						BDB_I_DIR=$I_DIR
						BDB_L_DIR=$L_DIR

						AC_SUBST(HAVE_LIB_DB, "-l$l")
						AC_SUBST(CFLAGS_DB, "-I$BDB_I_DIR")
						AC_SUBST(LDFLAGS_DB, "-L$BDB_L_DIR")

						AC_DEFINE_UNQUOTED(HAVE_LIB_DB, "-l$l")
						AC_DEFINE_UNQUOTED(LDFLAGS_DB, "-I$BDB_I_DIR")
						AC_DEFINE_UNQUOTED(CFLAGS_DB, "-L$BDB_L_DIR")
					fi
				fi
			],[
				AC_MSG_RESULT(no)
			])
			LIBS="$bdb_save_LIBS"
		done

		LDFLAGS="$bdb_save_LDFLAGS"
		CFLAGS="$bdb_save_CFLAGS"
	done
	if test $bdb_best_major -gt -1; then
		bdb_version="$bdb_best_major.$bdb_best_minor"
		AC_DEFINE_UNQUOTED(HAVE_DB_MAJOR, $bdb_best_major)
		AC_DEFINE_UNQUOTED(HAVE_DB_MINOR, $bdb_best_minor)
		AC_MSG_RESULT([checking best Berkeley DB version... $bdb_version])
	else
		AC_MSG_RESULT([checking best Berkeley DB version... not found])
	fi
	AC_LANG_POP(C)

	AH_VERBATIM([HAVE_DB_MAJOR],[
/*
 * Berkeley DB
 */
#undef HAVE_DB_MAJOR
#undef HAVE_DB_MINOR
#undef HAVE_DB_CREATE
#undef HAVE_DBOPEN
#undef HAVE_DB_H
#undef HAVE_LIB_DB
#undef LDFLAGS_DB
#undef CFLAGS_DB
	])

	LDFLAGS="$bdb_save_LDFLAGS"
	CFLAGS="$bdb_save_CFLAGS"
])
])
