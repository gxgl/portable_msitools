#!/bin/bash

echo "Current working directory is \"$(pwd)\""

init() {
    if [ ! -d "AppDir" ]; then
        mkdir AppDir
    fi
}

clone() {
    if [ ! -d "msitools" ]; then
        # Clonning msitools repo...
        git clone --recursive https://github.com/GNOME/msitools.git
    fi
}

build() {
    if [ ! -d "msitools/builddir" ]; then
        # Building msitools...
        cd msitools
        meson setup builddir
        cd builddir
        meson compile
        meson test
        DESTDIR=../../AppDir meson install
        cd ../..
    fi
}

cpres() {
    # Copy the icon into AppDir...
    if [ ! -d "AppDir/usr/local/share/icons" ]; then
        mkdir -p AppDir/usr/local/share/icons
    fi
    if [ ! -f "AppDir/usr/local/share/icons/msitools/png" ]; then
        cp -R msitools.png AppDir/usr/local/share/icons
    fi
    # Copy .desktop files
    if [ -d "AppDir" ]; then
        cp -R *.desktop AppDir
    fi
}

init
clone
build

folder="AppDir/usr/local/bin"
if [ -d "$folder" ]; then
    # Building executables array...
    for file in "$folder"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            echo $filename
            # Creating recipe
            recipeEnd="_recipe.yml"
            recipe=$filename$recipeEnd
            echo $recipe
            if [ ! -f "$recipe" ]; then
                # Generate app template
                echo "version: 1" >$recipe
                echo "AppDir:" >>$recipe
                echo "  path: $(pwd)/AppDir" >>$recipe
                if [ "$filename" == "msidiff" ] || [ "$filename" == "msidump" ]; then
                    echo "  app_info:" >>$recipe
                    echo "    id: $filename" >>$recipe
                    echo "    name: $filename" >>$recipe
                    echo "    icon: msitools" >>$recipe
                    echo "    version: latest" >>$recipe
                    echo "    exec: bin/bash" >>$recipe
                    echo "    exec_args: \$APPDIR/usr/local/bin/$filename \$@" >>$recipe
                else
                    echo "  app_info:" >>$recipe
                    echo "    id: $filename" >>$recipe
                    echo "    name: $filename" >>$recipe
                    echo "    icon: msitools" >>$recipe
                    echo "    version: latest" >>$recipe
                    echo "    exec: usr/local/bin/$filename" >>$recipe
                    echo "    exec_args: \$@" >>$recipe
                fi
                echo "  apt:" >>$recipe
                echo "    arch:" >>$recipe
                echo "    - amd64" >>$recipe
                echo "    allow_unauthenticated: true" >>$recipe
                echo "    sources:" >>$recipe
                echo "    - sourceline: deb https://mirrors.hostico.ro/linuxmint/packages vera main upstream import backport" >>$recipe
                echo "    - sourceline: deb http://mirrors.pidginhost.com/ubuntu jammy main restricted universe multiverse" >>$recipe
                echo "    - sourceline: deb http://mirrors.pidginhost.com/ubuntu jammy-updates main restricted universe multiverse" >>$recipe
                echo "    - sourceline: deb http://mirrors.pidginhost.com/ubuntu jammy-backports main restricted universe multiverse" >>$recipe
                echo "    - sourceline: deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse" >>$recipe

                if [ "$filename" == "msidiff" ] || [ "$filename" == "msidump" ]; then
                    echo "    include:" >>$recipe
                    echo "    - bash:amd64" >>$recipe
                    echo "    - coreutils:amd64" >>$recipe
                    echo "    - libc6:amd64" >>$recipe
                    echo "    - libbz2-1.0:amd64" >>$recipe
                    echo "    - libgcc-s1:amd64" >>$recipe
                    echo "    - liblzma5:amd64" >>$recipe
                    echo "    - libpcre3:amd64" >>$recipe
                    echo "    - libselinux1:amd64" >>$recipe
                    echo "    - libtinfo6:amd64" >>$recipe
                    echo "    - zlib1g:amd64" >>$recipe
                else
                    echo "    include:" >>$recipe
                    echo "    - libbz2-1.0:amd64" >>$recipe
                    echo "    - libgcc-s1:amd64" >>$recipe
                    echo "    - liblzma5:amd64" >>$recipe
                    echo "    - libpcre3:amd64" >>$recipe
                    echo "    - libselinux1:amd64" >>$recipe
                    echo "    - libtinfo6:amd64" >>$recipe
                    echo "    - zlib1g:amd64" >>$recipe
                fi
                echo "  files:" >>$recipe
                echo "    include:" >>$recipe
                echo "    - /lib/x86_64-linux-gnu/libgcab-1.0.so.0" >>$recipe
                echo "    - /lib/x86_64-linux-gnu/libgsf-1.so.114" >>$recipe
                echo "    exclude:" >>$recipe
                echo "    - usr/share/man" >>$recipe
                echo "    - usr/share/doc/*/README.*" >>$recipe
                echo "    - usr/share/doc/*/changelog.*" >>$recipe
                echo "    - usr/share/doc/*/NEWS.*" >>$recipe
                echo "    - usr/share/doc/*/TODO.*" >>$recipe
                for otherfile in "$folder"/*; do
                    if [ "$otherfile" != "$file" ] && [ -f "$otherfile" ]; then
                        otherfilename=$(basename "$otherfile")
                        echo "    - usr/local/bin/$otherfilename" >>$recipe
                        echo "    - $otherfilename.desktop" >>$recipe
                    fi
                done
                echo "AppImage:" >>$recipe
                echo "  arch: x86_64" >>$recipe
                echo "  update-information: none" >>$recipe
            fi
            # Crearing .desktop files
            desktopEnd=".desktop"
            desktop=$filename$desktopEnd
            if [ ! -f "$desktop" ]; then
                echo "[Desktop Entry]">$desktop
                echo "X-AppImage-Arch=x86_64">>$desktop
                echo "X-AppImage-Version=latest">>$desktop
                echo "X-AppImage-Name=$filename">>$desktop
                echo "Version=1.0">>$desktop
                echo "Type=Application">>$desktop
                echo "Name=$filename">>$desktop
                echo "Comment=Command line tools to manipulate msi packages on linux">>$desktop
                echo "TryExec=$filename">>$desktop
                echo "Exec=$filename">>$desktop
                echo "Icon=msitools">>$desktop
                echo "MimeType=image/x-foo;">>$desktop
                echo "Categories=Utility;">>$desktop
            fi
        fi
    done
    cpres
fi

for recipe in *_recipe.yml
do
    if [ -f "$recipe" ]
    then
        filename="${recipe%_recipe.yml}"
        if [ -f "$folder/$filename" ]
        then
            echo "$filename"
            # File exists, run the code
            echo ""
            echo "appimage-builder --recipe $recipe"
            appimage-builder --recipe $recipe
            echo ""
        else
            echo "No $filename"
            # File does not exist, rebuild
            if [ -d "AppDir" ]
            then
                rm -rf AppDir
            fi
            if [ -d "appimage-build" ]
            then
                rm -rf appimage-build
            fi
            if [ -d "msitools/builddir" ]
            then
                rm -rf msitools/builddir
            fi
            init
            build
            cpres
            echo "Rebuilding $filename"
            echo ""
            echo "appimage-builder --recipe $recipe"
            appimage-builder --recipe $recipe
            echo ""
        fi
    fi
done

if [ ! -d "dist" ]; then
    mkdir -p dist/msitools
fi
for file in *-latest*.AppImage; do
    mv "$file" "dist/msitools/${file%-latest*}"
done
cd dist/ 
tar -czvf msitools-$LATEST_VERSION-portable.tar.gz msitools/* 
cd ..