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

$GENCFS -e $TENV/m3b --password p3 --epath $TENV/e3 --mpoint $TENV/m3a --amount y --encfs-config default
expect "3 items (1,2,3a)"
$GENCFS -l

$GENCFS -e $TENV/m3a --password px --epath $TENV/e3 --mpoint $TENV/m3a --amount y --encfs-config default
expect "3 items (1,2,3a)"
$GENCFS -l

expect "1 failing mount (3a) - wrong password"
$GENCFS -m $TENV/m3a
expect "no mounted paths"
mount | grep "/tenv/m[0-9]" | sed -e "s/user=\w\+//"

$GENCFS -e $TENV/m3a --password p3 --epath $TENV/e3 --mpoint $TENV/m3b --amount y --encfs-config default
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
$GENCFS -e $TENV/m3b --password p3 --epath $TENV/e3 --mpoint $TENV/m2 --proceed n --amount y --encfs-config default
expect "3 items (1,2,3b)"
$GENCFS -l
expect "autostart on"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"
expect "2 succeeding edits"
$GENCFS -e $TENV/m1 --password p1 --epath $TENV/e1 --mpoint $TENV/m1 --proceed n --amount n --encfs-config default
$GENCFS -e $TENV/m2 --password p2 --epath $TENV/e2 --mpoint $TENV/m2 --proceed n --amount n --encfs-config default
expect "autostart on"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"
expect "autostart content"
cat autostart.desktop
expect "1 succeeding edits"
$GENCFS -e $TENV/m3b --password p3 --epath $TENV/e3 --mpoint $TENV/m3b --proceed n --amount n --encfs-config default
expect "autostart off"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"

# clean up keyring
$GENCFS -l | grep "mount point" | grep "/tenv/m[0-9]" | awk {'print $4'} | \
    while read MP ; do $GENCFS -r $MP ; done

# test EncFS config file custom location (encfs5)
expect "succeeding add with a custom EncFS5 config file (1)"
mv $TENV/e1/.encfs5 $TENV/e1_encfs5
$GENCFS -a $TENV/e1 $TENV/m1 --password p1 --proceed n --amount n --encfs-config $TENV/e1_encfs5
expect "1 listed item (1)"
$GENCFS -l

expect "1 succeeding mounts (1)"
$GENCFS -m $TENV/e1
expect "1 mounted paths (1)"
mount | grep "/tenv/m[0-9]" | sed -e "s/user=\w\+//"

for MPOINT in $TENV/m1* ; do
        fusermount -u $MPOINT 2>&1
done
expect "no mounted paths - all unmounted"
mount | grep "/tenv/m[0-9]"

expect "succeeding edit to set back EncFS5 config file to its default location (1)"
mv $TENV/e1_encfs5 $TENV/e1/.encfs5
$GENCFS -e $TENV/m1 --password p1 --epath $TENV/e1 --mpoint $TENV/m1 --proceed n --amount n --encfs-config default
expect "1 listed item (1)"
$GENCFS -l

expect "succeeding edit with a custom EncFS5 config file (1)"
mv $TENV/e1/.encfs5 $TENV/e1_encfs5
$GENCFS -e $TENV/m1 --password p1 --epath $TENV/e1 --mpoint $TENV/m1 --proceed n --amount n --encfs-config $TENV/e1_encfs5
expect "1 listed item (1)"
$GENCFS -l

expect "succeeding remove (1)"
$GENCFS -r $TENV/m1
mv $TENV/e1_encfs5 $TENV/e1/.encfs5
expect "0 items"
$GENCFS -l

# test EncFS config file custom location (encfs6.xml)
expect "succeeding add with a custom EncFS6 config file (1)"
mv $TENV/e2/.encfs6.xml $TENV/e2_encfs6.xml
$GENCFS -a $TENV/e2 $TENV/m2 --password p2 --proceed n --amount n --encfs-config $TENV/e2_encfs6.xml
expect "1 listed item (2)"
$GENCFS -l

expect "1 succeeding mounts (2)"
$GENCFS -m $TENV/e2
expect "1 mounted paths (2)"
mount | grep "/tenv/m[0-9]" | sed -e "s/user=\w\+//"

for MPOINT in $TENV/m2* ; do
        fusermount -u $MPOINT 2>&1
done
expect "no mounted paths - all unmounted"
mount | grep "/tenv/m[0-9]"

expect "succeeding edit to set back EncFS6 config file to its default location (2)"
mv $TENV/e2_encfs6.xml $TENV/e2/.encfs6.xml
$GENCFS -e $TENV/m2 --password p2 --epath $TENV/e2 --mpoint $TENV/m2 --proceed n --amount n --encfs-config default
expect "1 listed item (2)"
$GENCFS -l

expect "succeeding edit with a custom EncFS6 config file (2)"
mv $TENV/e2/.encfs6.xml $TENV/e2_encfs6.xml
$GENCFS -e $TENV/m2 --password p2 --epath $TENV/e2 --mpoint $TENV/m2 --proceed n --amount n --encfs-config $TENV/e2_encfs6.xml
expect "1 listed item (2)"
$GENCFS -l

expect "succeeding remove (2)"
$GENCFS -r $TENV/m2
mv $TENV/e2_encfs6.xml $TENV/e2/.encfs6.xml
expect "0 items"
$GENCFS -l

# clean up keyring
$GENCFS -l | grep "mount point" | grep "/tenv/m[0-9]" | awk {'print $4'} | \
    while read MP ; do $GENCFS -r $MP ; done

expect "no listed items"
$GENCFS -l
expect "autostart off"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"

