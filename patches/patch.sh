#!/usr/bin/env bash

# 1. make patch
# 2. download coq and apply patch

set -e # http://www.clear-code.com/blog/2012/10/11.html

scriptname="patch.sh"
prefix="coq-" # Don't edit
suffix="+actor"

cd `dirname $0`

original=${prefix}${2}
patched=${prefix}${2}${suffix}
patch_file=${2}.patch

function version_specify() {
    if [ "$1" = "" ]; then
        echo "Please specify the Coq version"
        echo "e.g., ./${scriptname} <command> 8.4pl5"
        exit 0
    fi
}

function remove_original() {
    if [ -d ${original} ]; then
        echo -n "${original} exists. It will be replaced to clean Coq. OK? [y/N]: "
        read replace_ok
        if [ "$replace_ok" = "y" ] || [ "$replace_ok" = "Y" ]; then
            rm -rf ${original}
        else
            echo "aborted."
            exit 0
        fi
    fi
}

function remove_patched() {
    if [ -d ${patched} ]; then
        echo -n "${patched} exists. It will be replaced to patched Coq. OK? [y/N]: "
        read replace_ok
        if [ "$replace_ok" = "y" ] || [ "$replace_ok" = "Y" ]; then
            rm -rf ${patched}
        else
            echo "aborted."
            exit 0
        fi
    fi
}

case "$1" in
    "make")
        version_specify "$2"
        if [ -d ${original} ] && [ -d ${patched} ]; then
            diff -u -N -r ${original} ${patched} > ${patch_file}
        else
            echo "${original} and ${patched} are required"
        fi
        ;;
    "apply")
        version_specify "$2"
        if [ -d ${original} ] && [ -f ${patch_file} ]; then
            remove_patched
            cp -r ${original} ${patched}
            patch -u -p1 -d ${patched} < ${patch_file}
        else
            echo "${original} and ${patch_file} are required"
        fi
        ;;
    "auto")
        version_specify "$2"
        if [ -f ${patch_file} ]; then
            remove_original
            tarball=coq-${2}.tar.gz
            wget https://coq.inria.fr/distrib/V${2}/files/${tarball}
            tar xf ${tarball}
            rm ${tarball}
            patch -u -p1 -d ${original} < ${patch_file}
            cd ${original}
            echo -n "Please input configure option (e.g., -prefix ../): "
            read option
            ./configure ${option}
            make world
            echo "Preparations for installing custom Coq are complete."
            echo -n "Do you want to install? [y/N]: "
            read install_ok
            if [ "$install_ok" = "y" ] || [ "$install_ok" = "Y" ]; then
                echo "sudo? [y/N]: "
                read sudo_ok
                if [ "$sudo_ok" = "y" ] || [ "$sudo_ok" = "Y" ]; then
                    sudo make install
                else
                    make install
                fi
            else
                echo "install is aborted. To install, 'cd ${original}' and 'make install' (or 'sudo make install')"
            fi
        else
            echo "${patch_file} is required"
        fi
        ;;
    "setup")
        version_specify "$2"
        remove_original
        tarball=coq-${2}.tar.gz
        wget https://coq.inria.fr/distrib/V${2}/files/${tarball}
        tar xf ${tarball}
        rm ${tarball}
        remove_patched
        cp -r ${original} ${patched}
        if [ -f ${patch_file} ]; then
            patch -u -p1 -d ${patched} < ${patch_file}
        fi
        ;;
    "clean")
        version_specify "$2"
        rm -rf bin etc lib share || true
        cd ${patched}
        make distclean
        find . -type f -name "*.cmt" | xargs rm -f
        find . -type f -name "*.cmti" | xargs rm -f
        rm -rf bin || true
        rm -f ide/coqide_main_opt.ml || true
        ;;
    *)
        echo "Usage: ${scriptname} <command> <args>"
        echo ""
        echo "Commands:"
        echo "  make  <version>    - make patch file"
        echo "  apply <version>    - apply patch to Coq"
        echo "  auto  <version>    - auto (but some interactive) download, apply patch, build, install"
        echo "  setup <version>    - setup for development"
        echo "  clean <version>    - clean for development"
        ;;
esac