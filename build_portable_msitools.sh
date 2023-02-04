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
LIBGSF="https://github.com/GNOME/libgsf.git"
MSITOOLS="https://github.com/GNOME/msitools.git"

# Create array from git link for later use
GITLINKS=($GLIB $LIBGSF $MSITOOLS)

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
        if [[ ! -d "$INSTALLDIR/$GITDIR" ]]; then
            echo "We use Meson"
            cd $GITDIR
            meson setup --wipe
            meson setup builddir --prefix=/ --default-library=static -Db_pie=true
            cd builddir
            meson compile
            meson test
            DESTDIR=$INSTALLDIR/$GITDIR meson install
        fi
    else
        if [[ ! -d "$INSTALLDIR/$GITDIR" ]]; then
            echo "We use Autotools"
            cd $GITDIR
            ./autogen.sh
            ./configure --prefix=$INSTALLDIR/$GITDIR --enable-static --disable-shared
            make
            make install
        fi
    fi

    


}

for i in "${GITLINKS[@]}"
do
   GITDIR=$(basename "$i" .git)
   build
done

ldd $INSTALLDIR/msitools/bin/msiextract




