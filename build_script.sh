#!/bin/bash
echo "tesst" > test.txt
git add .
git commit -a -m "test"
echo "da"
git push --set-upstream origin master
