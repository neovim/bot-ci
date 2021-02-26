#!/usr/bin/env bash

# Automated pull requests

set -e
# set -x

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/dependencies.sh
source ${BUILD_DIR}/ci/common/neovim.sh

require_environment_variable NEOVIM_DIR "${BASH_SOURCE[0]}" ${LINENO}

# Fork of neovim/neovim (upstream) to which the PR will be pushed.
NEOVIM_FORK="${NEOVIM_FORK:-marvim}"

# Updates documentation generation via dxoygen in the Nvim source tree.
# Commits the changes to branch "bot-ci-vimdoc-update".
# Configures "$NEOVIM_FORK/neovim" as a remote.
# Pushes the changes.
update_vimdoc() {
  local branch="bot-ci-vimdoc-update"

  if is_ci_build --silent ; then
    require_environment_variable GIT_NAME "${BASH_SOURCE[0]}" ${LINENO}
    require_environment_variable GIT_EMAIL "${BASH_SOURCE[0]}" ${LINENO}
  fi

  (
    cd "$NEOVIM_DIR"
    git checkout master
    git pull --rebase
    2>/dev/null git branch -D "$branch" || true
    git checkout -b "$branch"

    # Clone the Vim repo.
    log_info 'run: python scripts/gen_vimdoc.py'
    python scripts/gen_vimdoc.py

    if test -z "$(git diff)" ; then
      log_info 'update_vimdoc: no changes to documentation'
      return 1
    fi

    # Commit and push the changes.
    if prompt_key_local "commit and push to $NEOVIM_FORK:${branch} ?" ; then
      if is_ci_build --silent ; then
        git config --local user.name "${GIT_NAME}"
        git config --local user.email "${GIT_EMAIL}"
      fi
      git add --all
      git commit -m "$(printf 'vimdoc: update [ci skip]')"
      if ! has_gh_token ; then
        return "$(can_fail_without_private)"
      fi
      git remote add "$NEOVIM_FORK" "https://github.com/$NEOVIM_FORK/neovim.git" || true
      git push --force --set-upstream "$NEOVIM_FORK" HEAD:$branch
    fi
  )
}

main() {
  install_nvim_appimage
  install_hub
  clone_neovim

  if update_vimdoc ; then
    (
      cd "$NEOVIM_DIR"
      # Note: update_vimdoc configures marvim/neovim as a remote.
      create_pullrequest neovim:master "${NEOVIM_FORK}:bot-ci-vimdoc-update"
    )
  fi
}

main
