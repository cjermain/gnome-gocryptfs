# Changes

## gnome-gocryptfs v0.3 (?)

* Replaced deprecated `optparse` with `argparse`
* Restructured CLI into sub-commands
* Added `unmount` command for unmounting all or specific managed folders
* Refactoring work to simplify code

## gnome-gocryptfs v0.2 (2019-01-23)

* Initial fork of [gnome-encfs][gef] v0.1 (ported from Mercurial VCS)
* Ported to support `gocryptfs` instead of `encfs`
* Ported to Python 3, by replacing deprecated `python-gnomekeyring` with `python3-gi`
* Introduced `KeyRing` object for interacting with GNOME keyring through `libsecret`
* Added CI for running tests

[gef]: https://hg.sr.ht/~obensonne/gnome-encfs
