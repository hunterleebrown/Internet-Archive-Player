#!/bin/sh

#        git fetch --deepen 3 && git log main..HEAD --pretty=format:"%s" > WhatToTest.$locale.txt

if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
  TESTFLIGHT_DIR_PATH=../TestFlight
  mkdir $TESTFLIGHT_DIR_PATH
  git fetch --deepen 3 && git log latest_build..HEAD --pretty=format:"%s" > $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  git tag -d latest_build && git tag latest_build
  git push --tags https://${GIT_AUTH}@github.com/hunterleebrown/Internet-Archive-Player.git
#  git push origin latest_build -f
fi
