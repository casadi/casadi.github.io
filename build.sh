#!/bin/bash

echo "============ BUILD STARTED ============="

# checking dependencies
declare -a dep=("hugo" "npm")
for i in "${dep[@]}"
do
  {
    command -v $i > /dev/null 2>&1 && true
  } || {
    echo >&2 "  .. couldn't find $i, aborting."
    exit 1
  }
done
printf "node @ $(node --version)\n"
printf "npm @ $(npm --version)\n"
printf "gulp @\n$(gulp -v)\n"

echo "-------------- GULP THEME --------------"

cd themes/casadi-theme/ # goto theme folder and run npm/gulp
npm update # get/update npm packages
gulp scss # run gulp to build static files and collect them for deploying

echo "------------- BUILD PAGES --------------"

cd ../.. && rm -rf public
hugo # run hugo

echo "============ BUILD FINISHED ============"
