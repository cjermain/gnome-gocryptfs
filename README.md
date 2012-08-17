gnome-encfs
===========

*gnome-encfs* integrates [EncFS][efs] folders into the GNOME desktop by storing
their passwords in the [keyring][gkr] and optionally mounting them at login
using GNOME's autostart mechanism.

*gnome-encfs* allows you to use strong passwords for EncFS folders while still
mounting them painlessly (i.e. no password prompt).  This is an advantage over
automount solutions like *pam-encfs* and *pam-mount* which require to use the
same password for EncFS folders as for your local user account. This is bad
because local account passwords usually are weaker than those one should use
for encrypting online stored data, e.g. in a [Dropbox][dbx]. In this case, you
can also move your EncFs config files (.encfs5 or .encfs6.xml) outside their
EncFS folders to increase security so they are not stored online (See below).

[![Flattr this][flattr-img]][flattr-url]

[flattr-url]: http://flattr.com/thing/142770/gnome-encfs
[flattr-img]: http://api.flattr.com/button/flattr-badge-large.png "Flattr this"

Download
--------

Download the [package][dlp] *or* checkout the source:

    $ hg clone http://bitbucket.org/obensonne/gnome-encfs

Installation
------------

    $ cd /path/to/gnome-encfs
    $ install gnome-encfs /usr/local/bin

**Note:** You can run *gnome-encfs* right from the extracted package but to
make use of the automount feature at GNOME login, it must be placed somewhere
in *PATH* (as configured during a login to GNOME). Using the install command
above ensures this requirement is fulfilled.

Usage
-----

### Add an EncFS folder

Suppose you have an EncFS folder at `~/.Private.encrypted` which should get
mounted to `~/Private`. Make it known to *gnome-encfs*:

    $ gnome-encfs -a ~/.Private.encrypted ~/Private
    EncFS password: <enter encfs password>
    Mount at login [Y/n]: <say 'y' or 'n'>

This adds the EncFS path, its mount location and password to the GNOME keyring
and sets up a GNOME autostart entry to mount it at GNOME login (if enabled).

### Add an EncFS folder with a custom location EncFs config file

Suppose you have an EncFS folder at `~/.Private.encrypted` which should get
mounted to `~/Private`.

And suppose you move the EncFS config file (.encfs5 or .encfs6.xml), from 
`~/.Private.encrypted/.encfs6.xml` to `~/Private_encfs6.xml`.

Make it known to *gnome-encfs*:

    $ gnome-encfs -a ~/.Private.encrypted ~/Private
    Custom EncFS config file path [**Default location**]: ~/Private_encfs6.xml
    EncFS password: <enter encfs password>
    Mount at login [Y/n]: <say 'y' or 'n'>

This adds the EncFS path, its mount location, the location of its EncFS config
file and password to the GNOME keyring and sets up a GNOME autostart entry to
mount it at GNOME login (if enabled).

### Mount an EncFS folder

If you said *y* above to the login mount question, the EncFS folder gets
mounted automatically at GNOME login. If you prefer to mount on demand, you do
that with

     $ gnome-encfs -m ~/Private

which looks up the password in the keyring and does the mounting without
the need to enter the password manually.

Unmount as usual, using *fusermount*:

    $ fusermount -u ~/Private

### Other tasks

You can also  show, edit and remove EncFS folders handled by *gnome-enfs*:

    $ gnome-encfs -h

    Usage: gnome-encfs --list
           gnome-encfs --mount [ENCFS-PATH-or-MOUNT-POINT]
           gnome-encfs --add ENCFS-PATH MOUNT-POINT
           gnome-encfs --edit MOUNT-POINT
           gnome-encfs --remove MOUNT-POINT

    Painlessly mount and manage EncFS folders using GNOME's keyring.

    Options:
      --version            show program's version number and exit
      -h, --help           show this help message and exit
      -l, --list           list all EncFS items stored in keyring
      -m, --mount          mount all or selected EncFS paths stored in keyring
      -a, --add            add a new EncFS item to keyring
      -e, --edit           edit an EncFS item in keyring
      -r, --remove         remove an EncFS item from keyring
    ...

Usage should be straight forward - otherwise [submit an issue][itr].

### Automatically unmount EncFS folders on logout

Unfortunately there's no equivalent to GNOME's autostart scripts which could be
used to automatically unmount your EncFS folders on logout (without shutting
down). However, there's a manual solution using a [GDM hook script][gdm]:
`/etc/gdm/PostSession/Default`. Open this file in an editor (requires *root*
privileges) and add these lines:

    mount -t fuse.encfs | grep "user=$USER" | awk '{print $3}' | while read MPOINT ; do
        sudo -u $USER fusermount -u "$MPOINT"
    done

This script is executed whenever you logout from GNOME. With this line, it
looks for mounted EncFS folders of the user currently logging out. Then it
unmounts each, using the `fusermount` command (note that this command is
executed as *root*, that's why there is a `sudo -u $USER` before the
`fusermount` command).

This works independent of *gnome-encfs*, i.e. it unmounts **any** EncFS folder
of the user logging out.

License
-------

*gnome-encfs* is licensed as [GPL][gpl].

[dbx]: http://dropbox.com
[dlp]: http://bitbucket.org/obensonne/gnome-encfs/get/tip.tar.gz
[efs]: http://www.arg0.net/encfs
[gdm]: http://library.gnome.org/admin/gdm/stable/configuration.html
[gkr]: http://live.gnome.org/GnomeKeyring
[gpl]: http://www.gnu.org/licenses/gpl.html
[itr]: http://bitbucket.org/obensonne/gnome-encfs/issues/?status=new&status=open

