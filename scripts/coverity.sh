#!/bin/bash

# Trigger coverity report generation.
#
# Required environment variables:
# ${MAKE_CMD}
# ${NEOVIM_REPO}
# ${NEOVIM_BRANCH}
# ${NEOVIM_DIR}

cd ${NEOVIM_DIR}

wget -q -O - https://scan.coverity.com/scripts/travisci_build_coverity_scan.sh |
  TRAVIS_BRANCH="${NEOVIM_BRANCH}" \
  COVERITY_SCAN_PROJECT_NAME="${NEOVIM_REPO}" \
  COVERITY_SCAN_NOTIFICATION_EMAIL="coverity@aktau.be" \
  COVERITY_SCAN_BRANCH_PATTERN="${NEOVIM_BRANCH}" \
  COVERITY_SCAN_BUILD_COMMAND_PREPEND="${MAKE_CMD} deps" \
  COVERITY_SCAN_BUILD_COMMAND="${MAKE_CMD} nvim" \
  bash

exit 0
