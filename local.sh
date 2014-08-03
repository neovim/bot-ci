#!/bin/bash -e

export BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper function to output script usage.
print_usage() {
  echo "Usage:"
  echo "${BASH_SOURCE[0]} <build type>"
  echo ""
  echo "Available build types:"
  for build_type in $(find ${BUILD_DIR}/scripts/*.sh -executable -type f); do
    filename=$(basename ${build_type})
    echo "  ${filename%.sh}"
  done
  exit 1
}

if [[ ${#} -ne 1 ]]; then
  print_usage
fi

LOCAL_BUILD_TYPE="${1}"
export LOCAL_BUILD=true
export NEOVIM_REPO=${NEOVIM_REPO:-neovim/neovim}
export NEOVIM_BRANCH=${NEOVIM_BRANCH:-master}
export NEOVIM_DIR=${BUILD_DIR}/build/neovim
export MAKE_CMD=${MAKE_CMD:-make}

# Clone neovim repo
# Skip if directory already present for local builds
[[ ! -d ${NEOVIM_DIR} ]] && git clone --branch ${NEOVIM_BRANCH} --depth 1 git://github.com/${NEOVIM_REPO} ${NEOVIM_DIR}

if [[ -x ${BUILD_DIR}/scripts/${LOCAL_BUILD_TYPE}.sh ]]; then
  exec ${BUILD_DIR}/scripts/${LOCAL_BUILD_TYPE}.sh
else
  print_usage
fi
