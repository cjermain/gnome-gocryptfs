gnome-gocryptfs
===============

*gnome-gocryptfs* integrates [gocryptfs][cfs] folders into the GNOME desktop by storing
their passwords in the [keyring][gkr] and optionally mounting them at login
using GNOME's autostart mechanism. This package is a fork of the [gnome-encfs][gef]
project.

*gnome-gocryptfs* allows you to use strong passwords for gocryptfs folders while still
mounting them painlessly (i.e. no password prompt).  This is an advantage over
automount solutions like *pam-encfs* and *pam-mount* which require to use the
same password for gocryptfs folders as for your local user account. This is bad
because local account passwords usually are weaker than those one should use
for encrypting online stored data, e.g. in a [Dropbox][dbx].

Download
--------

Checkout the source:

    $ git clone https://github.com/cjermain/gnome-gocryptfs

Installation
------------

    $ cd /path/to/gnome-gocryptfs
    $ install gnome-gocryptfs /usr/local/bin

**Note:** You can run *gnome-gocryptfs* right from the extracted package but to
make use of the automount feature at GNOME login, it must be placed somewhere
in *PATH* (as configured during a login to GNOME). Using the install command
above ensures this requirement is fulfilled.

Usage
-----

### Add a gocryptfs folder

Suppose you have a gocryptfs folder at `~/.Private.encrypted` which should get
mounted to `~/Private`. Make it known to *gnome-gocryptfs*:

    $ gnome-gocryptfs -a ~/.Private.encrypted ~/Private
    gocryptfs config file [-]: <optional custom gocryptfs.conf location>
    gocryptfs password: <enter gocryptfs password>
    Mount at login [Y/n]: <say 'y' or 'n'>

This adds the gocryptfs path, its mount location and password to the GNOME keyring
and sets up a GNOME autostart entry to mount it at GNOME login (if enabled).

### Mount a gocryptfs folder

If you said *y* above to the login mount question, the gocryptfs folder gets
mounted automatically at GNOME login. If you prefer to mount on demand, you do
that with

     $ gnome-gocryptfs -m ~/Private

which looks up the password in the keyring and does the mounting without
the need to enter the password manually.

Unmount as usual, using *fusermount*:

    $ fusermount -u ~/Private

### Other tasks

You can also  show, edit and remove gocryptfs folders handled by *gnome-gocryptfs*:

    $ gnome-gocryptfs -h

    Usage: gnome-gocryptfs --list
           gnome-gocryptfs --mount [GOCRYPTFS-PATH-or-MOUNT-POINT]
           gnome-gocryptfs --add GOCRYPTFS-PATH MOUNT-POINT
           gnome-gocryptfs --edit MOUNT-POINT
           gnome-gocryptfs --remove MOUNT-POINT

    Painlessly mount and manage gocryptfs folders using GNOME's keyring.

    Options:
      --version            show program's version number and exit
      -h, --help           show this help message and exit
      -l, --list           list all gocryptfs items stored in keyring
      -m, --mount          mount all or selected gocryptfs paths stored in keyring
      -a, --add            add a new gocryptfs item to keyring
      -e, --edit           edit an gocryptfs item in keyring
      -r, --remove         remove an gocryptfs item from keyring
    ...

Usage should be straight forward - otherwise [submit an issue][itr].

### Automatically unmount gocryptfs folders on logout

Unfortunately there's no equivalent to GNOME's autostart scripts which could be
used to automatically unmount your gocryptfs folders on logout (without shutting
down). However, there's a manual solution using a [GDM hook script][gdm]:
`/etc/gdm/PostSession/Default`. Open this file in an editor (requires *root*
privileges) and add these lines:

    mount -t fuse.gocryptfs | grep "user=$USER" | awk '{print $3}' | while read MPOINT ; do
        sudo -u $USER fusermount -u "$MPOINT"
    done

This script is executed whenever you logout from GNOME. With this line, it
looks for mounted gocryptfs folders of the user currently logging out. Then it
unmounts each, using the `fusermount` command (note that this command is
executed as *root*, that's why there is a `sudo -u $USER` before the
`fusermount` command).

This works independent of *gnome-gocryptfs*, i.e. it unmounts **any** gocryptfs folder
of the user logging out.

License
-------

*gnome-gocryptfs* is licensed as [GPL][gpl].

[gef]: https://hg.sr.ht/~obensonne/gnome-encfs
[dbx]: http://dropbox.com
[cfs]: https://nuetzlich.net/gocryptfs/
[gdm]: http://library.gnome.org/admin/gdm/stable/configuration.html
[gkr]: http://live.gnome.org/GnomeKeyring
[gpl]: http://www.gnu.org/licenses/gpl.html
[itr]: https://github.com/cjermain/gnome-gocryptfs/issues

