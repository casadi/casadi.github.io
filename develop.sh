#!/bin/bash

echo "=========== DEVELOP STARTED ============"

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
gulp watch & # run watch-task of gulp to constantly sync

echo "------------- SERVE PAGES --------------"

cd ../..
hugo server --disableFastRender -b http://localhost:1313 --bind=0.0.0.0 # serve pages

echo "=========== DEVELOP FINISHED ==========="
