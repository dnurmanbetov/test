#!/bin/bash
echo "tesst" > test.txt
git add .
git commit -a -m "test"
echo "da 312"
git push --set-upstream origin master
