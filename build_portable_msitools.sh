#!/bin/bash

#sudo apt-get install build-essential manpages-dev python3 python3-pip python3-setuptools python3-wheel ninja-build valac meson cmake* git libgsf* libgcab* gobject* libperl-dev libgtk* -y

# Downloading prerequsites
dwPrerequisites () {
    declare -A osInfo;
    osInfo[/etc/debian_version]="sudo apt-get install -y build-essential manpages-dev python3 python3-pip python3-setuptools python3-wheel ninja-build valac meson cmake* git libgsf* libgcab* gobject* libperl-dev libgtk*"
    osInfo[/etc/alpine-release]="sudo apk --update add build-base manpages-dev python3 python3-pip python3-setuptools python3-wheel ninja-build valac meson cmake* git libgsf* libgcab* gobject* libperl-dev libgtk*"
    osInfo[/etc/centos-release]="sudo yum install -y groupinstall \"Development Tools\" manpages-dev python3 python3-pip python3-setuptools python3-wheel ninja-build valac meson cmake* git libgsf* libgcab* gobject* libperl-dev libgtk*"
    osInfo[/etc/fedora-release]="sudo dnf install -y groupinstall \"Development Tools\" manpages-dev python3 python3-pip python3-setuptools python3-wheel ninja-build valac meson cmake* git libgsf* libgcab* gobject* libperl-dev libgtk*"

    for f in ${!osInfo[@]}
    do
        if [[ -f $f ]];then
            ${osInfo[$f]}
        fi
    done
}
#dwPrerequisites


WORKDIR=$HOME/workdir
SOURCESDIR=$WORKDIR/sources
INSTALLDIR=$WORKDIR/install

# Creating working directories
if [[ ! -d "$WORKDIR" ]]
then
    mkdir -p $WORKDIR
fi

if [[ ! -d "$SOURCESDIR" ]]
then
    mkdir -p $SOURCESDIR
fi

if [[ ! -d "$INSTALLDIR" ]]
then
    mkdir -p $INSTALLDIR
fi

# Creating vars containing git links
GLIB="https://github.com/GNOME/glib.git"
LIBXML="https://github.com/GNOME/libxml2.git"
LIBGSF="https://github.com/GNOME/libgsf.git"

# We keep MSITOOLS on last position -> see below
MSITOOLS="https://github.com/GNOME/msitools.git"

# Create array from git link for later use
## MSITOOLS Should always be the last as it depends on the
## other tools required by the libmsi and msitools executables
GITLINKS=($GLIB $LIBXML $LIBGSF $MSITOOLS)

useMeson () {
    echo "We use Meson"
    cd $GITDIR
    meson setup --wipe
    meson setup builddir --prefix=/ --default-library=static -Db_pie=true
    cd builddir
    meson compile
    meson test
    if [[ ! "$GITDIR" = "msitools" ]]; then
        DESTDIR=$INSTALLDIR/msitools meson install
    else
        DESTDIR=$INSTALLDIR/$GITDIR meson install
        echo $DESTDIR
    fi
}

useAutotools () {
    echo "We use Autotools"
    cd $GITDIR
    ./autogen.sh
    INSTALLPATH=$INSTALLDIR/msitools/lib/x86_64-linux-gnu
    if [ "$GITDIR" = "libxml2" ]; then
        ./configure --prefix=$INSTALLPATH --libdir=$INSTALLPATH --enable-static --disable-shared
    else
        #./configure --prefix=$INSTALLPATH --libdir=$INSTALLPATH --enable-static --disable-shared LDFLAGS=$INSTALLPATH LIBS=$INSTALLPATH
        #./configure --prefix=$INSTALLPATH --libdir=$INSTALLPATH --enable-static --disable-shared --enable-default-pie
        ./configure --prefix=$INSTALLPATH --libdir=$INSTALLPATH --enable-static --disable-shared
    fi
    make
    make install
}

build () {
    cd $SOURCESDIR
    if [[ ! -d "$SOURCESDIR/$GITDIR" ]]
    then
        git clone --recursive $i
    fi

    if [[ -d "$SOURCESDIR/$GITDIR/.git" ]]
    then
        rm -rf $SOURCESDIR/$GITDIR/.git
    fi

    if [ "$GITDIR" = "msitools" ]; then
        VERSION=$(grep -Eo "v.*" -m1 $SOURCESDIR/$GITDIR/NEWS)
        sed -i 's/version: run.*/version: '"'"'gxgl.standalone.msitools-'$VERSION''"'"',/' $SOURCESDIR/$GITDIR/meson.build
        sed -i 's/libmsi = shared_library/libmsi = library/' $SOURCESDIR/$GITDIR/libmsi/meson.build
    fi
    if [ "$GITDIR" = "glib" ] || [ "$GITDIR" = "msitools" ]; then
        if [ "$GITDIR" = "glib" ] && [[ ! -f "$INSTALLDIR/msitools/lib/x86_64-linux-gnu/libglib-2.0.a" ]]; then
            useMeson
        fi
        if [ "$GITDIR" = "msitools" ] && [[ ! -f "$INSTALLDIR/msitools/lib/x86_64-linux-gnu/libmsi.a" ]]; then
            useMeson
        fi
    else
        if [ "$GITDIR" = "libxml2" ] && [[ ! -f "$INSTALLDIR/msitools/lib/x86_64-linux-gnu/libxml2.a" ]]; then
            useAutotools
        fi
        if [ "$GITDIR" = "libgsf" ] && [[ ! -f "$INSTALLDIR/msitools/lib/x86_64-linux-gnu/lib/libgsf-1.a" ]]; then
            useAutotools
        fi
    fi

    


}

for i in "${GITLINKS[@]}"
do
   GITDIR=$(basename "$i" .git)
   build
done

ldd $INSTALLDIR/msitools/bin/msiextract




