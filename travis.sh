#!/bin/bash -e

# Travis wrapper, delegate to build scripts in ./scripts/
# based on ${TRAVIS_BUILD_TYPE}.

# Set up Git credentials
git config --global user.name "${GIT_NAME}"
git config --global user.email ${GIT_EMAIL}

# Clone neovim repo
git clone --branch ${NEOVIM_BRANCH} --depth 1 git://github.com/${NEOVIM_REPO} ${NEOVIM_DIR}

if [[ -x ./scripts/${TRAVIS_BUILD_TYPE}.sh ]]; then
  exec ./scripts/${TRAVIS_BUILD_TYPE}.sh
else
  echo "Invalid build type: ${TRAVIS_BUILD_TYPE}"
  exit 1
fi
