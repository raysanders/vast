#!/usr/bin/env bash

# This script will update the copies of VSX and ASASSN-V catalogs for offline use

# By default, do not download VSX and astorb.dat ifthey were not downloaded earlier
DOWNLOAD_EVERYTHING=0
if [ ! -z "$1" ];then
 DOWNLOAD_EVERYTHING=1
fi

if [ ! -d lib/catalogs ];then
 echo "ERROR locating lib/catalogs" >> /dev/stderr
 exit 1
fi

# Get current date from the system clock
CURRENT_DATE_UNIXSEC=`date +%s`

for FILE_TO_UPDATE in astorb.dat lib/catalogs/vsx.dat lib/catalogs/asassnv.csv ;do
 NEED_TO_UPDATE_THE_FILE=0

 # check if the file is there at all
 if [ ! -s "$FILE_TO_UPDATE" ];then
  echo "There is no file $FILE_TO_UPDATE or it is empty" >> /dev/stderr
  # Always update only lib/catalogs/asassnv.csv
  if [ "$FILE_TO_UPDATE" == "lib/catalogs/asassnv.csv" ] || [ $DOWNLOAD_EVERYTHING -eq 1 ] ;then
   NEED_TO_UPDATE_THE_FILE=1
  else
   continue
  fi
 else
  # First try Linux-style stat
  FILE_MODIFICATION_DATE=`stat -c "%Y" "$FILE_TO_UPDATE" 2>/dev/null`
  if [ $? -ne 0 ];then
   FILE_MODIFICATION_DATE=`stat -f "%m" "$FILE_TO_UPDATE" 2>/dev/null`
   if [ $? -ne 0 ];then
    echo "ERROR cannot get modification time for $FILE_TO_UPDATE" >> /dev/stderr
    exit 1
   fi
  fi
  # Check that FILE_MODIFICATION_DATE actually contains Unix seconds
  re='^[0-9]+$'
  if ! [[ $FILE_MODIFICATION_DATE =~ $re ]] ; then
   echo "ERROR inappropriate content of FILE_MODIFICATION_DATE=$FILE_MODIFICATION_DATE" >> /dev/stderr
   exit 1
  fi
 fi

 if [ $NEED_TO_UPDATE_THE_FILE -eq 0 ];then 
  # 2592000 is 30 days
  if [ $[$CURRENT_DATE_UNIXSEC-$FILE_MODIFICATION_DATE] -gt 2592000 ];then
   NEED_TO_UPDATE_THE_FILE=1
  fi
 fi
 
 # TEST !!!
 #NEED_TO_UPDATE_THE_FILE=1

 # Update the file if needed
 if [ $NEED_TO_UPDATE_THE_FILE -eq 1 ];then
  echo "######### Updating $FILE_TO_UPDATE #########" >> /dev/stderr
  WGET_COMMAND=""
  WGET_LOCAL_COMMAND=""
  UNPACK_COMMAND=""
  TMP_OUTPUT=""
  if [ "$FILE_TO_UPDATE" == "astorb.dat" ];then
   TMP_OUTPUT="astorb.dat.new"
   WGET_COMMAND="wget -O $TMP_OUTPUT.gz --timeout=120 --tries=2 ftp://ftp.lowell.edu/pub/elgb/astorb.dat.gz"
   WGET_LOCAL_COMMAND="wget -O $TMP_OUTPUT.gz --timeout=120 --tries=2 http://scan.sai.msu.ru/~kirx/catalogs/compressed/astorb.dat.gz"
   UNPACK_COMMAND="gunzip $TMP_OUTPUT.gz"
  fi
  if [ "$FILE_TO_UPDATE" == "lib/catalogs/vsx.dat" ];then
   TMP_OUTPUT="vsx.dat"
   WGET_COMMAND="wget -O $TMP_OUTPUT.gz --timeout=120 --tries=2 ftp://cdsarc.u-strasbg.fr/pub/cats/B/vsx/vsx.dat.gz"
   WGET_LOCAL_COMMAND="wget -O $TMP_OUTPUT.gz --timeout=120 --tries=2 http://scan.sai.msu.ru/~kirx/catalogs/compressed/vsx.dat.gz"
   UNPACK_COMMAND="gunzip $TMP_OUTPUT.gz"
  fi
  if [ "$FILE_TO_UPDATE" == "lib/catalogs/asassnv.csv" ];then
   TMP_OUTPUT="asassnv.csv"
   WGET_COMMAND="wget -O $TMP_OUTPUT --timeout=120 --tries=2 --no-check-certificate https://asas-sn.osu.edu/variables/catalog.csv"
   WGET_LOCAL_COMMAND="wget -O $TMP_OUTPUT --timeout=120 --tries=2 http://scan.sai.msu.ru/~kirx/catalogs/asassnv.csv"
   UNPACK_COMMAND=""
  fi
  if [ -z "$WGET_COMMAND" ];then
   echo "ERROR WGET_COMMAND is not set" >> /dev/stderr
   exit 1
  fi
  if [ -z "$WGET_LOCAL_COMMAND" ];then
   echo "ERROR WGET_LOCAL_COMMAND is not set" >> /dev/stderr
   exit 1
  fi
  if [ -z "$TMP_OUTPUT" ];then
   echo "ERROR TMP_OUTPUT is not set" >> /dev/stderr
   exit 1
  fi
  
  
  # First try to download a catalog from the mirror
  echo "$WGET_LOCAL_COMMAND" >> /dev/stderr
  $WGET_LOCAL_COMMAND
  if [ $? -ne 0 ];then
   # if that failed, try to download the catalog from the original link
   echo "$WGET_COMMAND" >> /dev/stderr
   $WGET_COMMAND  
   if [ $? -ne 0 ];then
    echo "ERROR running wget" >> /dev/stderr
    if [ -f "$TMP_OUTPUT" ];then
     rm -f "$TMP_OUTPUT"
    fi
    exit 1
   fi
   #
  fi # if that failed
  # If we are still here, we downloaded the catalog, one way or the other
  if [ ! -z "$UNPACK_COMMAND" ];then
   $UNPACK_COMMAND
   if [ $? -ne 0 ];then
    echo "ERROR running $UNPACK_COMMAND" >> /dev/stderr
    if [ -f "$TMP_OUTPUT" ];then
     rm -f "$TMP_OUTPUT"
    fi
    exit 1
   fi
  fi
  if [ ! -s "$TMP_OUTPUT" ];then
   echo "ERROR: $TMP_OUTPUT is EMPTY!"  >> /dev/stderr
   if [ -f "$TMP_OUTPUT" ];then
    rm -f "$TMP_OUTPUT"
   fi
   exit 1
  fi
  mv -v "$TMP_OUTPUT" "$FILE_TO_UPDATE" && touch "$FILE_TO_UPDATE"
  echo "Successfully updated $FILE_TO_UPDATE"
 #else
 # echo "No need to update $FILE_TO_UPDATE" >> /dev/stderr
 fi

done