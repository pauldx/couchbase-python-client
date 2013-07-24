#! /bin/bash

cd `dirname $0`

for f in man[1-9]*/*[1-9]*.txt
do
   manpage=`echo $f | sed -e s,.txt\$,,`
   if test $f -nt $manpage
   then
       echo "Generate: $manpage"
       set -e
       a2x -L --doctype manpage --format manpage $f
       set +e
   fi
done

set -e
echo "Generate SVr4 layout"
rm -rf svr4
mkdir -p svr4/man1
mkdir -p svr4/man3couchbase
mkdir -p svr4/man3lib
mkdir -p svr4/man4
mkdir -p svr4/man5

for f in 1 3couchbase 3lib 4 5
do
   cp -pr man$f/*.$f svr4/man$f
done

echo "Generate BSD layout"
rm -rf bsd
mkdir -p bsd/man1
mkdir -p bsd/man3
mkdir -p bsd/man5

for dir in man1 man5
do
    for f in svr4/$dir/*
    do
       destname=bsd/$dir/`basename $f`
       sed -e s,3lib,3,g -e s,3couchbase,3,g $f > $destname
    done
done

for dir in couchbase lib
do
    for f in svr4/man3$dir/*
    do
       destname=bsd/man3/`basename $f | sed -e s,3lib,3,g -e s,3couchbase,3,g`
       sed -e s,3lib,3,g -e s,3couchbase,3,g $f > $destname
    done
done

# section 4 should be moved to section 5
for f in svr4/man4/*
do
    destname=bsd/man5/`basename $f | sed -e s,4,5,g`
    sed -e s,3lib,3,g -e s,3couchbase,3,g $f > $destname
done

echo "Generate Makeinclude"
echo "  BSD layout"

MAKEFILE=../Makefile.manpage.inc

cat > $MAKEFILE <<EOF
#
# This file is generated by running ./man/generate.sh
#

if MANPAGE_BSD_LAYOUT

EOF

for section in man1 man3 man5
do
   echo -n "${section}_MANS +=" >> $MAKEFILE

   for f in bsd/$section/*
   do
      echo -n " man/$f" >>  $MAKEFILE
   done
   echo "" >> $MAKEFILE
   echo "" >> $MAKEFILE
done

cat >> $MAKEFILE <<EOF

else

EOF

echo "  SVr4 layout"

for section in man1 man3lib man3couchbase man4 man5
do
   echo -n "${section}_MANS +=" >> $MAKEFILE

   for f in svr4/$section/*
   do
      echo -n " man/$f" >>  $MAKEFILE
   done
   echo "" >> $MAKEFILE
   echo "" >> $MAKEFILE
done

cat >> $MAKEFILE <<EOF

endif

EOF
