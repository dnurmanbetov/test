#!/bin/bash
git config --global user.email "dnurmanbetov@sxope.com"
git config --global user.name "dnurmanbetov"

git remote -v

git remote set-url origin git@github.com:dnurmanbetov/test.git
git remote -v

echo "tesst" > test.txt
git add .
git commit -a -m "test"
echo "da 312 3"


git push --set-upstream origin master
