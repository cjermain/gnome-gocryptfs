export GNOME_GOCRYPTFS_TEST=""

expect() {
	echo "# EXPECT: $1"
}

mounts() {
    mount | grep "/tenv/m[0-9]" | sed -r -e "s/ \([^ ]+\)//"
}

if [ ! -e ./tenv.tar ] ; then
    echo "Abort. Not in testing environment."
    exit 1
fi

GGOCRYPTFS="$PWD/../gnome-gocryptfs"
TENV="$PWD/tenv"

# clean up mounts
for MPOINT in $TENV/m* /dev/null ; do
    fusermount -u $MPOINT > /dev/null 2>&1
done

# recreate test environment
rm -rf $TENV
tar xf tenv.tar

# clean up keyring
$GGOCRYPTFS -l | grep "mount point" | grep "/tenv/m[0-9]" | awk {'print $4'} | \
    while read MP ; do $GGOCRYPTFS -r $MP ; done

# start tests

expect "no listed items"
$GGOCRYPTFS -l

expect "succeeding add (1)"
$GGOCRYPTFS -a $TENV/e1 $TENV/m1 --econfig "-" --password p1 --proceed n --amount y
expect "1 listed item (1)"
$GGOCRYPTFS -l

expect "failing add - mount point in use"
$GGOCRYPTFS -a $TENV/e1 $TENV/m1 --econfig "-" --password p1 --proceed n --amount y
expect "1 listed item (1)"
$GGOCRYPTFS -l

expect "succeeding add (2)"
$GGOCRYPTFS -a $TENV/e2 $TENV/m2 --econfig "-" --password p2 --proceed n --amount y
expect "2 listed items (1,2)"
$GGOCRYPTFS -l

expect "succeeding add (3a)"
$GGOCRYPTFS -a $TENV/e3 $TENV/m3a --econfig "-" --password p3 --proceed n --amount y
expect "3 listed items (1,2,3a)"
$GGOCRYPTFS -l

expect "succeeding add (3b)"
$GGOCRYPTFS -a $TENV/e3 $TENV/m3b --econfig "-" --password p3 --proceed n --amount y
expect "4 listed items (1,2,3a,3b)"
$GGOCRYPTFS -l

expect "2 succeeding mounts (3a,3b)"
$GGOCRYPTFS -m $TENV/e3
expect "2 mounted paths (3a,3b)"
mounts

for MPOINT in $TENV/m3* ; do
    fusermount -u $MPOINT 2>&1
done
expect "no mounted paths - all unmounted"
mounts

expect "4 succeeding mounts (1,2,3a,3b)"
$GGOCRYPTFS -m
expect "4 mounted paths (1,2,3a,3b)"
mounts

expect "4 failing mounts - already mounted"
$GGOCRYPTFS -m

for MPOINT in $TENV/m* ; do
	fusermount -u $MPOINT 2>&1
done
expect "no mounted paths - all unmounted"
mounts

$GGOCRYPTFS -r $TENV/m3a
expect "3 items (1,2,3b)"
$GGOCRYPTFS -l

$GGOCRYPTFS -e $TENV/m3b --econfig "-" --password p3 --epath $TENV/e3 --mpoint $TENV/m3a --amount y
expect "3 items (1,2,3a)"
$GGOCRYPTFS -l

$GGOCRYPTFS -e $TENV/m3a --econfig "-" --password px --epath $TENV/e3 --mpoint $TENV/m3a --amount y
expect "3 items (1,2,3a)"
$GGOCRYPTFS -l

expect "1 failing mount (3a) - wrong password"
$GGOCRYPTFS -m $TENV/m3a
expect "no mounted paths"
mounts

$GGOCRYPTFS -e $TENV/m3a --econfig "-" --password p3 --epath $TENV/e3 --mpoint $TENV/m3b --amount y
expect "3 items (1,2,3b)"
$GGOCRYPTFS -l

expect "1 succeeding mount (3b)"
$GGOCRYPTFS -m $TENV/m3b
expect "1 mounted path (3b)"
mounts

fusermount -u $TENV/m3b 2>&1

expect "no mounted paths - all unmounted"
mounts

expect "failing edit (3b->2) - mount point in use"
$GGOCRYPTFS -e $TENV/m3b --econfig "-" --password p3 --epath $TENV/e3 --mpoint $TENV/m2 --proceed n --amount y
expect "3 items (1,2,3b)"
$GGOCRYPTFS -l
expect "autostart on"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"
expect "2 succeeding edits"
$GGOCRYPTFS -e $TENV/m1 --econfig "-" --password p1 --epath $TENV/e1 --mpoint $TENV/m1 --proceed n --amount n
$GGOCRYPTFS -e $TENV/m2 --econfig "-" --password p2 --epath $TENV/e2 --mpoint $TENV/m2 --proceed n --amount n
expect "autostart on"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"
expect "autostart content"
cat autostart.desktop | sort -d # Ensure that the order does not matter
expect "1 succeeding edits"
$GGOCRYPTFS -e $TENV/m3b --econfig "-" --password p3 --epath $TENV/e3 --mpoint $TENV/m3b --proceed n --amount n
expect "autostart off"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"

# clean up keyring

$GGOCRYPTFS -l | grep "mount point" | grep "/tenv/m[0-9]" | awk {'print $4'} | \
    while read MP ; do $GGOCRYPTFS -r $MP ; done

# test custom gocryptfs config file location

expect "succeeding add (1) with custom config file location"
mv $TENV/e1/gocryptfs.conf $TENV/e1_gocryptfs.conf
$GGOCRYPTFS -a $TENV/e1 $TENV/m1 --econfig $TENV/e1_gocryptfs.conf --password p1 --proceed n --amount n
expect "1 listed item (1)"
$GGOCRYPTFS -l

expect "1 succeeding mounts (1)"
$GGOCRYPTFS -m $TENV/e1
expect "1 mounted paths (1)"
mounts

for MPOINT in $TENV/m1* ; do
        fusermount -u $MPOINT 2>&1
done
expect "no mounted paths - all unmounted"
mounts

expect "succeeding edit (1) reset config file location"
mv $TENV/e1_gocryptfs.conf $TENV/e1/gocryptfs.conf
$GGOCRYPTFS -e $TENV/m1 --econfig "-" --password p1 --epath $TENV/e1 --mpoint $TENV/m1 --proceed n --amount n
expect "1 listed item (1)"
$GGOCRYPTFS -l

expect "succeeding edit (1) with custom config file location"
mv $TENV/e1/gocryptfs.conf $TENV/e1_gocryptfs.conf
$GGOCRYPTFS -e $TENV/m1 --econfig $TENV/e1_gocryptfs.conf --password p1 --epath $TENV/e1 --mpoint $TENV/m1 --proceed n --amount n
expect "1 listed item (1)"
$GGOCRYPTFS -l

expect "succeeding remove (1)"
$GGOCRYPTFS -r $TENV/m1
mv $TENV/e1_gocryptfs.conf $TENV/e1/gocryptfs.conf
expect "0 items"
$GGOCRYPTFS -l

# clean up keyring
$GGOCRYPTFS -l | grep "mount point" | grep "/tenv/m[0-9]" | awk {'print $4'} | \
    while read MP ; do $GGOCRYPTFS -r $MP ; done

expect "no listed items"
$GGOCRYPTFS -l
expect "autostart off"
test -e autostart.desktop && echo "autostart on" || echo "autostart off"

