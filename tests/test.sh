export GNOME_ENCFS_TEST=""

expect() {
	echo "# EXPECT: $1"
}

if [ ! -e ./tenv.tar ] ; then
    echo "Abort. Not in testing environment."
    exit 1
fi

GENCFS="$PWD/../gnome-encfs"
TENV="$PWD/tenv"

# clean up mounts
for MPOINT in $TENV/m* /dev/null ; do
    fusermount -u $MPOINT > /dev/null 2>&1
done

# recreate test environment
rm -rf $TENV
tar xf tenv.tar

# clean up keyring
$GENCFS -l | grep "mount point" | grep "/tenv/m[0-9]" | awk {'print $4'} | \
    while read MP ; do $GENCFS -r $MP ; done

# start tests

expect "no listed items"
$GENCFS -l

expect "succeeding add (1)"
$GENCFS -a $TENV/e1 $TENV/m1 --password p1 --proceed n --amount y
expect "1 listed item (1)"
$GENCFS -l

expect "failing add - mount point in use"
$GENCFS -a $TENV/e1 $TENV/m1 --password p1 --proceed n --amount y
expect "1 listed item (1)"
$GENCFS -l

expect "succeeding add (2)"
$GENCFS -a $TENV/e2 $TENV/m2 --password p2 --proceed n --amount y
expect "2 listed items (1,2)"
$GENCFS -l

expect "succeeding add (3a)"
$GENCFS -a $TENV/e3 $TENV/m3a --password p3 --proceed n --amount y
expect "3 listed items (1,2,3a)"
$GENCFS -l

expect "succeeding add (3b)"
$GENCFS -a $TENV/e3 $TENV/m3b --password p3 --proceed n --amount y
expect "4 listed items (1,2,3a,3b)"
$GENCFS -l

expect "2 succeeding mounts (3a,3b)"
$GENCFS -m $TENV/e3
expect "2 mounted paths (3a,3b)"
mount | grep "/tenv/m[0-9]" | sed -e "s/user=\w\+//"

for MPOINT in $TENV/m3* ; do
    fusermount -u $MPOINT 2>&1
done
expect "no mounted paths - all unmounted"
mount | grep "/tenv/m[0-9]"

expect "4 succeeding mounts (1,2,3a,3b)"
$GENCFS -m
expect "4 mounted paths (1,2,3a,3b)"
mount | grep "/tenv/m[0-9]" | sed -e "s/user=\w\+//"

expect "4 failing mounts - already mounted"
$GENCFS -m

for MPOINT in $TENV/m* ; do
	fusermount -u $MPOINT 2>&1
done
expect "no mounted paths - all unmounted"
mount | grep "/tenv/m[0-9]" | sed -e "s/user=\w\+//"

$GENCFS -r $TENV/m3a
expect "3 items (1,2,3b)"
$GENCFS -l

$GENCFS -e $TENV/m3b --password p3 --epath $TENV/e3 --mpoint $TENV/m3a --amount y
expect "3 items (1,2,3a)"
$GENCFS -l

$GENCFS -e $TENV/m3a --password px --epath $TENV/e3 --mpoint $TENV/m3a --amount y
expect "3 items (1,2,3a)"
$GENCFS -l

expect "1 failing mount (3a) - wrong password"
$GENCFS -m $TENV/m3a
expect "no mounted paths"
mount | grep "/tenv/m[0-9]" | sed -e "s/user=\w\+//"

$GENCFS -e $TENV/m3a --password p3 --epath $TENV/e3 --mpoint $TENV/m3b --amount y
expect "3 items (1,2,3b)"
$GENCFS -l

expect "1 succeeding mount (3b)"
$GENCFS -m $TENV/m3b
expect "1 mounted path (3b)"
mount | grep "/tenv/m[0-9]" | sed -e "s/user=\w\+//"

fusermount -u $TENV/m3b 2>&1

expect "no mounted paths - all unmounted"
mount | grep "/tenv/m[0-9]" | sed -e "s/user=\w\+//"

expect "failing edit (3b->2) - mount point in use"
$GENCFS -e $TENV/m3b --password p3 --epath $TENV/e3 --mpoint $TENV/m2 --proceed n --amount y
expect "3 items (1,2,3b)"
$GENCFS -l
expect "autostart on"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"
expect "2 succeeding edits"
$GENCFS -e $TENV/m1 --password p1 --epath $TENV/e1 --mpoint $TENV/m1 --proceed n --amount n
$GENCFS -e $TENV/m2 --password p2 --epath $TENV/e2 --mpoint $TENV/m2 --proceed n --amount n
expect "autostart on"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"
expect "autostart content"
cat autostart.desktop
expect "1 succeeding edits"
$GENCFS -e $TENV/m3b --password p3 --epath $TENV/e3 --mpoint $TENV/m3b --proceed n --amount n
expect "autostart off"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"

# clean up keyring
$GENCFS -l | grep "mount point" | grep "/tenv/m[0-9]" | awk {'print $4'} | \
    while read MP ; do $GENCFS -r $MP ; done

expect "no listed items"
$GENCFS -l
expect "autostart off"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"

