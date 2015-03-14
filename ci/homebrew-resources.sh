#!/usr/bin/env bash
set -e

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd ${BUILD_DIR}/homebrew-resources
bundle
bundle exec ruby ./homebrew-resources.rb
