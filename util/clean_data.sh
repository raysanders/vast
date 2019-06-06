#!/usr/bin/env bash

#
# This script will remove all files created by a previous VaST run.
#
# Note, from this version on the command line parameter "all" is no longer needed.
#

echo -n "Checking write permissions for the current directory ( $PWD ) ...  "

touch testfile$$.tmp
if [ $? -eq 0 ];then
 rm -f testfile$$.tmp
 echo "Ok"
else
 echo "ERROR: please make sure you have write permissions for the current directory.

Maybe you need something like:
sudo chown -R $USER $PWD"
 exit 1
fi

## Clean the silly *.chk files produced by astcheck
rm -f -- *.chk

rm -f test.cat CPCS.cat  
echo "deleting ALL data files"
# lib/fast_clean_data exists only if the source code is compiled
if [ -x lib/fast_clean_data ];then
 lib/fast_clean_data # This will quickly remove out*dat files
fi
# Remember! We are removing WCS-calibrated images too!
for i in out*dat* aavso_out*.dat* out*.dat_hjd wcs_* *.chk image*.cat* image*.log ;do
 rm -f $i
done
# Remove possible leftovers from WCS calibration process
for i in out*.xyls  server_reply*.html ;do
 rm -f $i
done
# Remove flag images
for i in image*.flag ;do
 rm -f $i
done
# Remove weight images
for i in image*.weight ;do
 rm -f $i
done
for i in data* candidates.lst pgplot.ps pgplot.gif nohup.out test.cat *~ util/*~ lib/*~ util/photo/*~ util/examples/*~ src/*~ src/pgfv/*~ DEADJOE BLS/*~ periodFilter/*~ tmp.cat src/ccd/*~ src/diferential/*~ src/astrometry/*~ ;do
 if [ -f "$i" ];then
  rm -f "$i"
 fi
done
for i in candidates-*.err candidates-*.txt candidates-*.lst m_sigma_bin.tmp match.txt calib.txt manually_selected_comparison_stars.lst ;do
 if [ -f "$i" ];then
  rm -f "$i"
 fi
done
if [ -d selected ];then
 rm -rf selected/
fi
for i in vast*.log vast_list_of_all_stars.ds9 vast_list_of_all_stars.ds9.reg wcs.fit m_sigma_bin.tmp sysrem_input_star_list.lst ref_frame_sextractor.cat util/convert/*~ bright_star_blend_check_*.sex ;do
 if [ -f "$i" ];then
  rm -f "$i"
 fi
done
if [ -d vast_magnitude_calibration_details_log ];then
 rm -rf vast_magnitude_calibration_details_log/
fi
for i in calib.txt_backup *.calib_param *.calib *.struct octave-core out.wcs out.xyls *.bak util/*.bak lib/*.bak src/*.bak src/pgfv/*.bak BLS/*.bak periodFilter/*.bak src/ccd/*.bak src/diferential/*.bak ;do
 if [ -f "$i" ];then
  rm -f "$i"
 fi
done
for i in coadd.* check.fits test.mpc curr_unc curlhack.html server_reply.html wcsmag.cat psfex_*cat test.psf psfex.xml psfex_?????.param psfex_????.param psfex_???.param psfex_input_*.cat autodetect_aper_*.cat psfex.found *.cat.vizquery Aladin.script candidates-transients.tmp_1 ;do
 if [ -f "$i" ];then
  rm -f "$i"
 fi
done
# Remove saved VaST source code snapshots that could be loaded together with loghtcurves
for i in vast_src_* ;do
 if [ -d "$i" ];then
  rm -rf "$i"
 fi
done
for i in search_databases_with_vizquery_USNOB_ID_OK.tmp vizquerry_*.input vizquerry_*.output vizquery_*.input vizquery_*.output ;do
 if [ -f "$i" ];then
  rm -f "$i"
 fi
done
# Remove Astrometry.net residuals
for i in out*.axy out*.corr out*.match out*.rdls out*.solved out*.wcs ;do
 if [ -f "$i" ];then
  rm -f "$i"
 fi
done
# Remove symlinks to images
# THIS CANNOT BE HERE
#rm -rf symlinks_to_images/
