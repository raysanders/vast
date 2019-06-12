#!/usr/bin/env bash

if [ -z "$1" ];then
 echo "Usage: $0 out01234.dat"
 exit 1
fi

INPUT_VAST_LIGHTCURVE="$1"

if [ ! -f "$INPUT_VAST_LIGHTCURVE" ];then
 echo "ERROR: cannot find the lightcurve file $INPUT_VAST_LIGHTCURVE"
 exit 1
fi
if [ ! -s "$INPUT_VAST_LIGHTCURVE" ];then
 echo "ERROR: the lightcurve file $INPUT_VAST_LIGHTCURVE is empty"
 exit 1
fi
# Check that the lightcurve is readable
util/cute_lc "$INPUT_VAST_LIGHTCURVE" > /dev/null
if [ $? -ne 0 ];then
 echo "ERROR: parsing the lightcurve file $INPUT_VAST_LIGHTCURVE"
 exit 1
fi

# Check that the magnitudes are reasonable
if [ 1 -ne `util/cute_lc "$INPUT_VAST_LIGHTCURVE" | awk '{print $2}' | util/colstat 2>/dev/null | grep 'MEAN=' | awk '{if ( $2 > 5 ) print 1 ;else print 0 }'` ];then
 echo "The magnitudes seem too small! Are you forgetting to convert the instrumental magnitudes to the absolute scale?"
 exit 1
fi
# Check that the magnitudes are reasonable
if [ 1 -ne `util/cute_lc "$INPUT_VAST_LIGHTCURVE" | awk '{print $2}' | util/colstat 2>/dev/null | grep 'MEAN=' | awk '{if ( $2 < 25 ) print 1 ;else print 0 }'` ];then
 echo "The magnitudes seem too large!"
 exit 1
fi

# Check that the time system is UTC
if [ ! -s vast_summary.log ];then
 echo "ERROR: cannot find vast_summary.log to determine the JD time system"
 exit 1
fi
grep --quiet 'JD time system (TT/UTC/UNKNOWN): UTC' vast_summary.log
if [ $? -ne 0 ];then
 echo "ERROR: cannot confirm that the JD time system is UTC from vast_summary.log"
 exit 1
fi
SOFTWARE_VERSION=`grep 'Software: ' vast_summary.log  | awk '{print $2" "$3}'`

# Get the observing date for the header
JD_FIRST_OBS=`util/cute_lc "$INPUT_VAST_LIGHTCURVE" | head -n1 | awk '{print $1}'`
JD_LAST_OBS=`util/cute_lc "$INPUT_VAST_LIGHTCURVE" | tail -n1 | awk '{print $1}'`
UNIXTIME_FIRST_OBS=`util/get_image_date "$JD_FIRST_OBS" 2>/dev/null | grep 'Unix Time' | awk '{print $3}'`
DATE_FOR_AAVSO_HEADER_FIRST_OBS=`LANG=C date -d @"$UNIXTIME_FIRST_OBS" +"%d%b%Y"`
DATE_FOR_AAVSO_MESSAGE_SUBJECT_FIRST_OBS=`LANG=C date -d @"$UNIXTIME_FIRST_OBS" +"%d %B %Y"`

# Get the exposure time for the header
if [ -s vast_image_details.log ];then
 MEDIAN_EXPOSURE_TIME_SEC=`cat vast_image_details.log | awk '{print $2}' FS='exp=' | awk '{print $1}' | util/colstat 2> /dev/null | grep 'MEDIAN=' | awk '{printf "%.0f\n", $2}'`
else
 echo "WARNING: cannot get the exposure time from vast_image_details.log"
fi

VARIABLE_STAR_NAME="XX Xxx"
FILTER="X"
if [ -s CBA_previously_used_header.txt ];then
 echo "Importing the variable star info from CBA_previously_used_header.txt" >> /dev/stderr
 VARIABLE_STAR_NAME=`cat CBA_previously_used_header.txt | grep '# Variable: ' | awk '{print $2}' FS='# Variable: '`
 FILTER=`cat CBA_previously_used_header.txt | grep '# Filter: ' | awk '{print $2}' FS='# Filter: '`
fi

if [ ! -s AAVSO_previously_used_header.txt ];then
 echo "#TYPE=EXTENDED
#OBSCODE=SKA
#SOFTWARE=$SOFTWARE_VERSION
#DELIM=,
#DATE=JD
#NAME,DATE,MAG,MERR,FILT,TRANS,MTYPE,CNAME,CMAG,KNAME,KMAG,AMASS,GROUP,CHART,NOTES" > AAVSO_previously_used_header.txt
fi
cp AAVSO_previously_used_header.txt AAVSO_report.txt
util/cute_lc "$INPUT_VAST_LIGHTCURVE" | while read JD MAG ERR ;do
      ##NAME,DATE,MAG,MERR,FILT,TRANS,MTYPE,CNAME,CMAG,KNAME,KMAG,AMASS,GROUP,CHART,NOTES
      #SS CYG,2450702.1234,11.235,0.003,B,NO,STD,ENSEMBLE,na,105,10.593,1.561,1,X16382L,na
 echo "$VARIABLE_STAR_NAME,$JD,$MAG,$ERR,$FILTER,NO,STD,ENSEMBLE,na,na,na,na,1,na,na"
done >> AAVSO_report.txt
if [ $? -ne 0 ];then
 echo "Something went WRONG with the lightcurve conversion!"
 exit 1
fi

 echo "The stub report is written to AAVSO_report.txt
You may need to edit the header before submitting the file to the AAVSO!"

# Manually edit the report
if [ ! -z "$EDITOR" ];then
 $EDITOR AAVSO_report.txt
fi

#VARIABLE_STAR_NAME=`head AAVSO_report.txt | grep 'Variable: ' | awk '{print $2}' FS='Variable: '`
if [ -z "$VARIABLE_STAR_NAME" ];then
 echo "ERROR in AAVSO_report.txt : cannot find the variable star name"
 exit 1
fi
VARIABLE_STAR_NAME_NO_WHITESPACES="${VARIABLE_STAR_NAME//' '/'_'}"


FINAL_OUTPUT_FILENAME=AAVSO_"$VARIABLE_STAR_NAME_NO_WHITESPACES""$DATE_FOR_AAVSO_HEADER_FIRST_OBS"_measurements.txt
echo "Renaming the final report file:"
cp -v AAVSO_report.txt "$FINAL_OUTPUT_FILENAME"
grep '# ' AAVSO_report.txt > AAVSO_previously_used_header.txt

