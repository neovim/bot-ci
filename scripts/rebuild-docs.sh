#!/bin/bash -e

# Build documentation & reports for Neovim and
# push generated HTML to a "doc" Git repository.
# This script is based on http://philipuren.com/serendipity/index.php?/archives/21-Using-Travis-to-automatically-publish-documentation.html
#
# Required environment variables:
# ${MAKE_CMD}
# ${BUILD_DIR}
# ${NEOVIM_REPO}
# ${NEOVIM_BRANCH}
# ${NEOVIM_DIR}

DOC_REPO=${DOC_REPO:-neovim/doc}
DOC_BRANCH=${DOC_BRANCH:-gh-pages}
DOC_DIR=${BUILD_DIR}/build/doc
INDEX_PAGE_URL=http://neovim.org/doc_index
REPORTS=(${REPORTS:-"doxygen clang-report translation-report"})

# Helper function for report generation
# ${1}:   Report title
# ${2}:   Report body
# ${3}:   Path to HTML output file
# Output: None
generate_report() {
  report_title="${1}" \
  report_body="${2}" \
  report_date=$(date -u) \
  report_commit="${NEOVIM_COMMIT}" \
  report_short_commit="${NEOVIM_COMMIT:0:7}" \
  report_repo="${NEOVIM_REPO}" \
  report_header=$(<${BUILD_DIR}/templates/${REPORT}/head.html) \
  envsubst < "${BUILD_DIR}/templates/report.sh.html" > "${3}"
}

# Install dependencies
source ${BUILD_DIR}/scripts/install-travis-dependencies.sh
if [[ ${LOCAL_BUILD} != true ]]; then
  install_deps
else
  echo "Local build, not installing dependencies."
fi

# Clone doc repo
# Skip if directory already present for local builds
[[ ${LOCAL_BUILD} != true || ! -d ${DOC_DIR} ]] && git clone --branch ${DOC_BRANCH} --depth 1 git://github.com/${DOC_REPO} ${DOC_DIR}
NEOVIM_COMMIT=$(git --git-dir=${NEOVIM_DIR}/.git rev-parse HEAD)

# Generate documentation & reports
for REPORT in ${REPORTS[@]}; do
  echo "Generating ${REPORT//-/ }."
  source ${BUILD_DIR}/scripts/generate-${REPORT}.sh
  generate_${REPORT//-/_}
done

# Update the index page
echo "Updating index.html from ${INDEX_PAGE_URL}."
wget -q ${INDEX_PAGE_URL} -O ${DOC_DIR}/index.html

# Exit early if not built on Travis to simplify
# local test runs of this script
if [[ ${LOCAL_BUILD} == true ]]; then
  echo "Local build, exiting early..."
  exit 1
fi

# Commit the updated docs
cd ${DOC_DIR}
git add --all .
git commit -m "Documentation: Automatic update."
git push --force https://${GH_TOKEN}@github.com/${DOC_REPO} ${DOC_BRANCH}
