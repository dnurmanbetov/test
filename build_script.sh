#!/bin/bash
git config --global user.email "dnurmanbetov@sxope.com"
git config --global user.name "dnurmanbetov"

echo "tesst" > test.txt
git add .
git commit -a -m "test"
echo "da 312 3"


git push --set-upstream origin master
