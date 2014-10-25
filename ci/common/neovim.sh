# Helper functions & environment variable defaults for builds using the neovim repository.

require_environment_variable BUILD_DIR "${BASH_SOURCE[0]}" ${LINENO}

NEOVIM_DIR=${NEOVIM_DIR:-${BUILD_DIR}/build/neovim}
NEOVIM_REPO=${NEOVIM_REPO:-neovim/neovim}
NEOVIM_BRANCH=${NEOVIM_BRANCH:-master}

clone_neovim() {
  rm -rf ${NEOVIM_DIR}

  if [[ -n "${NEOVIM_COMMIT}" ]]; then
    # Fetch specific revision.
    git clone --branch ${NEOVIM_BRANCH} --depth 50 git://github.com/${NEOVIM_REPO} ${NEOVIM_DIR}
    git --git-dir=${NEOVIM_DIR}/.git reset --hard ${NEOVIM_COMMIT}
  else
    # Fetch latest revision of branch.
    git clone --branch ${NEOVIM_BRANCH} --depth 1 git://github.com/${NEOVIM_REPO} ${NEOVIM_DIR}
    NEOVIM_COMMIT=$(git --git-dir=${NEOVIM_DIR}/.git rev-parse HEAD)
  fi
}
