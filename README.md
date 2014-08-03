Marvim Bot CI
=============

[![Build Status](https://travis-ci.org/neovim/bot-ci.svg?branch=master)](https://travis-ci.org/neovim/bot-ci)

This is the part of Marvim's planet sized brain that runs on TravisCI.
However, you won't find the "Genuine People Personalities" technology here.

Generated Content
=================

```
neovim.org
  doc
    dev
    user [todo]
    build-reports
      clang
      translations
```

Building Locally
----------------

The `./local.sh` script can be used to perform local test runs. For example, execute the following to rebuild the static analysis report from a custom repository:

```
REPORTS=clang-report \
NEOVIM_REPO=custom/neovim \
NEOVIM_BRANCH=custom-branch \
./local.sh rebuild-docs
```
