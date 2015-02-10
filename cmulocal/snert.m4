dnl
dnl SNERT_FIRST_PACKAGE(name, headers, functions, [extra_ldflags[, extra_libs[, static]]])
dnl
AC_DEFUN([SNERT_FIRST_PACKAGE],[
	pkg_name="$1"
	pkg_headers="$2"
	pkg_functions="$3"
	pkg_extra_ldflags="$4"
	pkg_extra_libs="$5"
	pkg_use_static_lib="$6"

	dnl Assumes common naming convention with_NAME, libNAME.*, and NAME.h
	pkg_lib=`echo $pkg_name | tr [A-Z], [a-z]`

	dnl Fetch values of with_* options.
	eval pkg_with=\$with_${pkg_lib}
	eval pkg_with_inc=\$with_${pkg_lib}_inc
	eval pkg_with_lib=\$with_${pkg_lib}_lib

	dnl Strip mysterious outer single quotes.
	eval pkg_with=`echo $pkg_with`
	eval pkg_with_inc=`echo $pkg_with_inc`
	eval pkg_with_lib=`echo $pkg_with_lib`

dnl Include package by default.
AS_IF([test ${pkg_with:-yes} != 'no'],[
	echo
	echo "Check for $pkg_name..."
	echo

	saved_libs=$LIBS
	saved_cflags=$CFLAGS
	saved_ldflags=$LDFLAGS

	AS_IF([ test -d "$pkg_with_inc" ],[
		pkg_dirs="$pkg_with_inc"
	],[ test -d "$pkg_with/include" ],[
		pkg_dirs="$pkg_with/include"
	],[
		dnl Search order significant.
		pkg_dirs="/usr/pkg/include /usr/local/include /usr/include"
	])

	dnl Find all instances of pkg_header.
	found='no'
	for h in $pkg_headers; do
		for I_dir in $pkg_dirs; do
			AS_IF([ test ! -f "$I_dir/$h" ],[
				continue
			])
			AS_IF([ test "$I_dir" != '/usr/include' ],[
				CFLAGS="-I$I_dir $saved_CFLAGS"
			],[
				CFLAGS="$saved_CFLAGS"
			])

			dnl Remove any previous cached result.
			eval unset AS_TR_SH(ac_cv_header_$h)
			AC_CHECK_HEADER([$h],[
				AC_DEFINE_UNQUOTED(AS_TR_CPP(HAVE_$h),[1],[ ])
dnl				AH_TEMPLATE(AS_TR_CPP(HAVE_$h))
			])

			dnl No need to repeat the library check once found.
			test "$found" = 'yes' && break

			dnl Find matching library.
			pkg_dir=`dirname $I_dir`
			for L_dir in $pkg_with_lib "$pkg_dir/lib64" "$pkg_dir/lib"; do
				AS_IF([ test ! -d $L_dir ],[
					continue
				])
				AS_IF([ test "$L_dir" != '/usr/lib64' -a "$L_dir" != '/usr/lib' ],[
					LDFLAGS="-L$L_dir $pkg_extra_ldflags $saved_LDFLAGS"
				],[
					LDFLAGS="$pkg_extra_ldflags $saved_LDFLAGS"
				])

				AS_IF([ test "$pkg_use_static_lib" = 'static' ],[
					LDFLAGS="$pkg_extra_ldflags $saved_LDFLAGS"
					lib="$L_dir/lib$pkg_lib.a"
				],[
					dnl Don't care if static or dynamic.
					lib="-l$pkg_lib"
				])
				LIBS="$saved_LIBS $lib $pkg_extra_libs"

				dnl Remove any cached result.
				for f in $pkg_functions ; do
					eval unset ac_cv_func_$f
				done

				AC_MSG_RESULT([looking for -l$pkg_lib with -L$L_dir ...])
				AC_CHECK_FUNCS([$pkg_functions],[
					found=yes
				],[
					:
				],[
					$pkg_extra_libs
				])
				test "$found" = 'yes' && break
			done
			test "$found" = 'yes' && break
		done
	done

	AS_IF([ test "$found" = 'yes' ],[
		dnl Declare shell variables for AC_SUBST().
		eval AS_TR_CPP(CFLAGS_$pkg_lib)="-I$I_dir"
		eval AS_TR_CPP(LDFLAGS_$pkg_lib)="-L$L_dir"
		eval AS_TR_CPP(HAVE_LIB_$pkg_lib)="$lib"

		dnl Declar #define macros.
		AC_DEFINE_UNQUOTED(AS_TR_CPP(CFLAGS_$pkg_lib), "-I$I_dir",[$pkg_name],[ ])
		AC_DEFINE_UNQUOTED(AS_TR_CPP(LDFLAGS_$pkg_lib), "-L$L_dir", [$pkg_name],[ ])
		AC_DEFINE_UNQUOTED(AS_TR_CPP(HAVE_LIB_$pkg_lib), "$lib", [$pkg_name],[ ])

dnl		AH_TEMPLATE(AS_TR_CPP(CFLAGS_$pkg_lib))
dnl		AH_TEMPLATE(AS_TR_CPP(LDFLAGS_$pkg_lib))
dnl		AH_TEMPLATE(AS_TR_CPP(HAVE_LIB_$pkg_lib))
	])

	LIBS="$saved_libs"
	CFLAGS="$saved_cflags"
	LDFLAGS="$saved_ldflags"
])
])

dnl
dnl SNERT_SQLITE3
dnl
dnl Depends on SNERT_PTHREAD
dnl
AC_DEFUN([SNERT_OPTION_WITH_SQLITE3],[
	AC_ARG_WITH([sqlite3], [[  --with-sqlite3[=DIR]    SQLite3 package, optional base directory]])
	AC_ARG_WITH([sqlite3-inc], [[  --with-sqlite3-inc=DIR  specific SQLite3 include directory]])
	AC_ARG_WITH([sqlite3-lib], [[  --with-sqlite3-lib=DIR  specific SQLite3 library directory]])
])
AC_DEFUN([SNERT_SQLITE3],[
	SNERT_FIRST_PACKAGE([SQLite3],[sqlite3_open],[$LDFLAGS_PTHREAD],[$HAVE_LIB_PTHREAD],[static])
	AC_SUBST(CFLAGS_SQLITE3)
	AC_SUBST(LDFLAGS_SQLITE3)
	AC_SUBST(HAVE_LIB_SQLITE3)
	AH_VERBATIM(HAVE_LIB_SQLITE3,[
#undef HAVE_SQLITE3_H
#undef HAVE_SQLITE3_OPEN
#undef CFLAGS_SQLITE3
#undef LDFLAGS_SQLITE3
#undef HAVE_LIB_SQLITE3
	])
])


AC_DEFUN([SNERT_OPTION_WITH_SASL2],[
	AC_ARG_WITH([sasl2], [[  --with-sasl2[=DIR]    SASL2 package, optional base directory]])
	AC_ARG_WITH([sasl2-inc], [[  --with-sasl2-inc=DIR  specific SASL2 include directory]])
	AC_ARG_WITH([sasl2-lib], [[  --with-sasl2-lib=DIR  specific SASL2 library directory]])
])
AC_DEFUN([SNERT_SASL2],[
	SNERT_FIRST_PACKAGE([SASL2],[sasl/sasl.h sasl/saslutil.h],[prop_get sasl_checkapop])
	AC_SUBST(CFLAGS_SASL2)
	AC_SUBST(LDFLAGS_SASL2)
	AC_SUBST(HAVE_LIB_SASL2)
	AH_VERBATIM(HAVE_LIB_SASL2,[
#undef HAVE_SASL_SASL_H
#undef HAVE_SASL_SASLUTIL_H
#undef HAVE_SASL_CHECKAPOP
#undef HAVE_PROP_GET
#undef CFLAGS_SASL2
#undef LDFLAGS_SASL2
#undef HAVE_LIB_SASL2
	])
])


