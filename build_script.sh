#!/bin/bash
echo "tesst" > test.txt
git add .
git commit -a -m "test"
git push --set-upstream origin master
