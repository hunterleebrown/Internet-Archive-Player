#!/bin/sh

if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
  TESTFLIGHT_DIR_PATH=../TestFlight
  mkdir $TESTFLIGHT_DIR_PATH
  git fetch --deepen 3 && git log --no-merges --pretty=format:"%s" latest_build..HEAD > $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  git push --delete https://${GIT_AUTH}@github.com/hunterleebrown/Internet-Archive-Player.git latest_build
  git tag -d latest_build
  git tag latest_build
  git push --tags https://${GIT_AUTH}@github.com/hunterleebrown/Internet-Archive-Player.git
fi
