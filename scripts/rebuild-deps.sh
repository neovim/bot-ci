#!/bin/bash -e

# Build dependencies for Neovim and push generated output to a
# "deps" Git repository.
#
# Required environment variables:
# ${MAKE_CMD}
# ${BUILD_DIR}
# ${NEOVIM_REPO}
# ${NEOVIM_BRANCH}
# ${NEOVIM_DIR}

DEPS_REPO=${DEPS_REPO:-neovim/deps}
DEPS_BRANCH=${DEPS_BRANCH:-master}
DEPS_DIR=${BUILD_DIR}/build/deps

# Helper function for building dependencies
# ${1}:   Path where built dependencies should be copied to
# ${2}:   Path to dependency build dir
# ${3}:   Additional CMake flags (optional)
rebuild_deps() {
  local repo_dir="${1}"
  local build_dir="${2}"

  # Build dependencies
  cd ${NEOVIM_DIR}
  make distclean
  make deps DEPS_CMAKE_FLAGS="-DDEPS_DIR=${build_dir} ${3}"

  # Update content of deps repo
  rm -rf ${repo_dir}/usr
  mkdir -p ${repo_dir}
  mv ${build_dir}/usr/ ${repo_dir}

  # Copy busted output script "color_terminal.lua" to deps repo
  cp ${BUILD_DIR}/assets/color_terminal.lua ${repo_dir}/usr/share/lua/*/busted/output
}

# Clone deps repo
# Skip if directory already present for local builds
[[ ${LOCAL_BUILD} != true || ! -d ${DEPS_DIR} ]] \
  && git clone --branch ${DEPS_BRANCH} --depth 1 git://github.com/${DEPS_REPO} ${DEPS_DIR}

# Create /opt/neovim-deps dir to use as build output
sudo rm -rf /opt/neovim-deps
sudo mkdir -p /opt/neovim-deps
sudo chmod 777 /opt/neovim-deps

echo "Building dependencies (x86_64)."
rebuild_deps ${DEPS_DIR} /opt/neovim-deps

echo "Building dependencies (i386)."

if [[ ${LOCAL_BUILD} != true ]]; then
  echo "Installing GCC multilib."

  sudo apt-get update -qq
  sudo apt-get install gcc-multilib g++-multilib -q
else
  echo "Local build, not installing GCC multilib."
fi

rebuild_deps ${DEPS_DIR}/32 /opt/neovim-deps/32 \
  "-DCMAKE_TOOLCHAIN_FILE=${NEOVIM_DIR}/cmake/i386-linux-gnu.toolchain.cmake"

# Exit early if not built on Travis to simplify
# local test runs of this script
if [[ ${LOCAL_BUILD} == true ]]; then
  echo "Local build, exiting early..."
  exit 1
fi

# Commit the updated dependencies
cd ${DEPS_DIR}
git add --all .
git commit -m "Dependencies: Automatic update."
git push --force https://${GH_TOKEN}@github.com/${DEPS_REPO} ${DEPS_BRANCH}
