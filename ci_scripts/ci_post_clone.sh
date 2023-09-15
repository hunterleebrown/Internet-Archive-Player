#!/bin/sh

#  ci_post_clone.sh
#  Internet Archive Player
#
#  Created by Hunter Lee Brown on 9/15/23.
#  
if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
    git fetch origin tag latest_build -f
fi
