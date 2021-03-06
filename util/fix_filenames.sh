#!/usr/bin/env bash
echo "Fixing filenames in the current directory."
echo -n "Renaming files which contain coma in the name... "
for TEST in *","* ;do
 if [ -f "$TEST" ];then
  OUT=`echo ${TEST//","/.}` # Remove this stupid coma
  mv "$TEST" "$OUT"
 fi
done && echo "OK"
echo -n "Renaming files which contain white space in the name... "
for TEST in *" "* ;do
 if [ -f "$TEST" ];then
  OUT=`echo ${TEST//" "/_}` # Remove this stupid white space
  mv "$TEST" "$OUT"
 fi
done && echo "OK"
echo "All done. :)"
