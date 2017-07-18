#!/bin/bash

# # # # #
#
# This script is responsible of updating the NeoVim url and sha256 inside
# formula file. For that, it checks current version from CMakeLists.txt file at
# neovim repository, compute sha256 and updates formula at homebrew-neovim
# temporary repository.
#
#


echo "Updating NeoVim version based on CMakeLists.txt from repository...";


TMP_DIR=/tmp

#
# Clone or update a temporary neovim repository
#
function clone_or_update ()
{
    if [ -d "$TMP_DIR/$1" ]; then

        echo "Found temporary $1 repository.";
        pushd "$TMP_DIR/$1";
            echo "Updating repository with remote"
           git pull origin master;
           git remote update;
        popd;
    else
        echo "Cloning $1 repository to temporary directory:"
        pushd $TMP_DIR;
            git clone $2;
        popd;
    fi;
}


#
# Gets the current version from CMakeLists.txt
#
function find_version ()
{

    if [ ! -f "CMakeLists.txt" ]; then
        echo "CMakeLists.txt not found. Aborting.";
        exit 1;
    fi;

    grep "set($1" CMakeLists.txt | cut -d " " -f 2 | tr -d ")";
}



clone_or_update "neovim" "git@github.com:neovim/neovim.git"

echo "Finding nvim current version..."
pushd "$TMP_DIR/neovim";
    MAJOR=$(find_version NVIM_VERSION_MAJOR);
    MINOR=$(find_version NVIM_VERSION_MINOR);
    PATCH=$(find_version NVIM_VERSION_PATCH);
popd

VERSION="$MAJOR.$MINOR.$PATCH";
echo "Current version: $MAJOR.$MINOR.$PATCH";



#
# Verifies if current Formula needs to be updated
#

clone_or_update "homebrew-neovim" "git@github.com:neovim/homebrew-neovim.git"

echo "Checking if Formula is up to date...";
pushd "$TMP_DIR/homebrew-neovim"
    FORMULA="Formula/neovim.rb";

    # Extracts current sha256 from Formula file
    nvim_line=$(cat $FORMULA | grep -n "neovim/archive" | cut -d ":" -f 1);
    nvim_line=$(( nvim_line + 1 ));
    CURR_SHA256=$(head -$nvim_line $FORMULA| tail -1 | grep 'sha256' | awk '{print $2}' | tr -d '"');
popd



#
# Calculates sha256 from tarball if exists. Otherwise downloads it and recalculate
#
if [ -f "$TMP_DIR/v$VERSION.tar.gz" ]; then
    SHA256=$(shasum --algorithm 256 "$TMP_DIR/v$VERSION.tar.gz" | cut -d " " -f 1);
else
    NVIM_URL="https://github.com/neovim/neovim/archive/v$VERSION.tar.gz"
    wget $NVIM_URL -O "$TMP_DIR/v$VERSION.tar.gz";
    if [ $? -ne 0 ]; then
        echo "Tarball from current version $VERSION not found. Have you build it and uploaded to $NVIM_URL";
        exit 1;
    fi;
    SHA256=$(shasum --algorithm 256 "$TMP_DIR/v$VERSION.tar.gz" | cut -d " " -f 1);
fi;



#
# Compare hashes and updates Formula file if necessary
#
if [ "$CURR_SHA256" == "$SHA256" ]; then
    echo
    echo "Version already up to date. Nothing to do.";
    exit 0;
else
    pushd "$TMP_DIR/homebrew-neovim"
        echo "Updating NeoVim tarball url..."
        CURR_ARQ=$(grep -n "neovim/archive" $FORMULA | cut -d "/" -f 7 | tr -d '"');
        sed -i "s/$CURR_ARQ/v$VERSION.tar.gz/" $FORMULA;

        echo "Updating NeoVim tarball sha256...";
        sed -i "s/$CURR_SHA256/$SHA256/" $FORMULA;

        git diff $FORMULA;

        echo
        echo "Formula updated successfully : )";
        echo "Commit changes at $TMP_DIR/homebrew-neovim";
    popd
fi;
