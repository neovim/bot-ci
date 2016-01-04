#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${BUILD_DIR}/ci/common/common.sh
source ${BUILD_DIR}/ci/common/doc.sh

DOC_INDEX_PAGE_URL=${DOC_INDEX_PAGE_URL:-https://neovim.io/doc_index}

generate_doc_index() {
  echo "Updating index.html from ${DOC_INDEX_PAGE_URL}."
  curl --tlsv1 ${DOC_INDEX_PAGE_URL} > ${DOC_DIR}/index.html
}

DOC_SUBTREE="/index.html"
clone_doc

curl --tlsv1 ${DOC_INDEX_PAGE_URL}

generate_doc_index
commit_doc
