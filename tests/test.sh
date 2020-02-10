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
$GGOCRYPTFS list | grep "^MOUNT " | grep "/tenv/m[0-9]" | awk {'print $3'} | \
    while read MP ; do $GGOCRYPTFS remove $MP ; done

# start tests

expect "no listed items"
$GGOCRYPTFS list

expect "succeeding add (1)"
$GGOCRYPTFS add $TENV/e1 $TENV/m1 --config "-" --password p1 --proceed n --auto-mount y
expect "1 listed item (1)"
$GGOCRYPTFS list

expect "failing add - mount point in use"
$GGOCRYPTFS add $TENV/e1 $TENV/m1 --config "-" --password p1 --proceed n --auto-mount y
expect "1 listed item (1)"
$GGOCRYPTFS list

expect "succeeding add (2)"
$GGOCRYPTFS add $TENV/e2 $TENV/m2 --config "-" --password p2 --proceed n --auto-mount y
expect "2 listed items (1,2)"
$GGOCRYPTFS list

expect "succeeding add (3a)"
$GGOCRYPTFS add $TENV/e3 $TENV/m3a --config "-" --password p3 --proceed n --auto-mount y
expect "3 listed items (1,2,3a)"
$GGOCRYPTFS list

expect "succeeding add (3b)"
$GGOCRYPTFS add $TENV/e3 $TENV/m3b --config "-" --password p3 --proceed n --auto-mount y
expect "4 listed items (1,2,3a,3b)"
$GGOCRYPTFS list

expect "2 succeeding mounts (3a,3b)"
$GGOCRYPTFS mount $TENV/e3
expect "2 mounted paths (3a,3b)"
mounts

expect "2 succeding unmounts (3a,3b)"
$GGOCRYPTFS unmount $TENV/e3
expect "no mounted paths - all unmounted"
mounts

expect "4 succeeding mounts (1,2,3a,3b)"
$GGOCRYPTFS mount
expect "4 mounted paths (1,2,3a,3b)"
mounts

expect "4 failing mounts - already mounted"
$GGOCRYPTFS mount

expect "4 succeeding unmounts (1,2,3a,3b)"
$GGOCRYPTFS unmount
expect "no mounted paths - all unmounted"
mounts

$GGOCRYPTFS remove $TENV/m3a
expect "3 items (1,2,3b)"
$GGOCRYPTFS list

$GGOCRYPTFS edit $TENV/m3b --config "-" --password p3 --path $TENV/e3 --mount $TENV/m3a --auto-mount y
expect "3 items (1,2,3a)"
$GGOCRYPTFS list

$GGOCRYPTFS edit $TENV/m3a --config "-" --password px --path $TENV/e3 --mount $TENV/m3a --auto-mount y
expect "3 items (1,2,3a)"
$GGOCRYPTFS list

expect "1 failing mount (3a) - wrong password"
$GGOCRYPTFS mount $TENV/m3a
expect "no mounted paths"
mounts

$GGOCRYPTFS edit $TENV/m3a --config "-" --password p3 --path $TENV/e3 --mount $TENV/m3b --auto-mount y
expect "3 items (1,2,3b)"
$GGOCRYPTFS list

expect "1 succeeding mount (3b)"
$GGOCRYPTFS mount $TENV/m3b
expect "1 mounted path (3b)"
mounts

expect "1 succeeding unmount (3b)"
$GGOCRYPTFS unmount $TENV/m3b

expect "no mounted paths - all unmounted"
mounts

expect "failing edit (3b->2) - mount point in use"
$GGOCRYPTFS edit $TENV/m3b --config "-" --password p3 --path $TENV/e3 --mount $TENV/m2 --proceed n --auto-mount y
expect "3 items (1,2,3b)"
$GGOCRYPTFS list
expect "autostart on"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"
expect "2 succeeding edits"
$GGOCRYPTFS edit $TENV/m1 --config "-" --password p1 --path $TENV/e1 --mount $TENV/m1 --proceed n --auto-mount n
$GGOCRYPTFS edit $TENV/m2 --config "-" --password p2 --path $TENV/e2 --mount $TENV/m2 --proceed n --auto-mount n
expect "autostart on"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"
expect "autostart content"
cat autostart.desktop | sort -d # Ensure that the order does not matter
expect "1 succeeding edits"
$GGOCRYPTFS edit $TENV/m3b --config "-" --password p3 --path $TENV/e3 --mount $TENV/m3b --proceed n --auto-mount n
expect "autostart off"
test -e autostart.desktop && echo "autostart on" ||  echo "autostart off"

# clean up keyring

$GGOCRYPTFS list | grep "^MOUNT " | grep "/tenv/m[0-9]" | awk {'print $3'} | \
    while read MP ; do $GGOCRYPTFS remove $MP ; done

# test custom gocryptfs config file location

expect "succeeding add (1) with custom config file location"
mv $TENV/e1/gocryptfs.conf $TENV/e1_gocryptfs.conf
$GGOCRYPTFS add $TENV/e1 $TENV/m1 --config $TENV/e1_gocryptfs.conf --password p1 --proceed n --auto-mount n
expect "1 listed item (1)"
$GGOCRYPTFS list

expect "1 succeeding mounts (1)"
$GGOCRYPTFS mount $TENV/e1
expect "1 mounted paths (1)"
mounts

expect "1 succeeding unmount (1)"
$GGOCRYPTFS unmount $TENV/m1
expect "no mounted paths - all unmounted"
mounts

expect "succeeding edit (1) reset config file location"
mv $TENV/e1_gocryptfs.conf $TENV/e1/gocryptfs.conf
$GGOCRYPTFS edit $TENV/m1 --config "-" --password p1 --path $TENV/e1 --mount $TENV/m1 --proceed n --auto-mount n
expect "1 listed item (1)"
$GGOCRYPTFS list

expect "succeeding edit (1) with custom config file location"
mv $TENV/e1/gocryptfs.conf $TENV/e1_gocryptfs.conf
$GGOCRYPTFS edit $TENV/m1 --config $TENV/e1_gocryptfs.conf --password p1 --path $TENV/e1 --mount $TENV/m1 --proceed n --auto-mount n
expect "1 listed item (1)"
$GGOCRYPTFS list

expect "succeeding remove (1)"
$GGOCRYPTFS remove $TENV/m1
mv $TENV/e1_gocryptfs.conf $TENV/e1/gocryptfs.conf
expect "0 items"
$GGOCRYPTFS list

# clean up keyring
$GGOCRYPTFS list | grep "^MOUNT " | grep "/tenv/m[0-9]" | awk {'print $3'} | \
    while read MP ; do $GGOCRYPTFS remove $MP ; done

expect "no listed items"
$GGOCRYPTFS list
expect "autostart off"
test -e autostart.desktop && echo "autostart on" || echo "autostart off"

