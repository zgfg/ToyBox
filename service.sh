#!/system/bin/sh

# Magisk Module: ToyBox-Ext v1.0.7
# Copyright (c) zgfg @ xda, 2022-
# GitHub source: https://github.com/zgfg/ToyBox-Ext

# toDo: Debugging - remove
LogFile="/data/local/tmp/service.log"
MODDIR=${0%/*}
echo ${MODDIR:18} >> $LogFile

# Wait to finish booting
until [ "$(getprop sys.boot_completed)" = 1 ]
do
  sleep 1
done

# Module's own path (local path)
MODDIR=${0%/*}
cd $MODDIR

# Current time
DLTIME=$(date +"%s")

# Source the original toybox binary type and last download time
TBSCRIPT='./tbtype.sh'
if [ -f $TBSCRIPT ]
then
  . $TBSCRIPT
fi

# Passed time since the last download
PASSEDTIME=$(($DLTIME - $LASTDLTIME))

# Waiting time between downloads (15 days)
WAITTIME=$((15 * 24 * 3600))
WAITTIME=$((10 * 1)) # toDo: remove

# If waiting time passed, download the latest binary again
if [ ! -z $TBTYPE ] && [ $PASSEDTIME -gt $WAITTIME ]
then
  sleep 5
  rm -f $TBTYPE
  /data/adb/magisk/busybox wget -c -T 10 "http://landley.net/toybox/bin/$TBTYPE"
fi

ls -l $TBTYPE >> $LogFile  # toDo: Debugging - remove

# Test the download 
if [ ! -z $TBTYPE ] && [ -f $TBTYPE ]
then
  # Compare checksums for the old and new binary
  MD5Old=($(md5sum toybox-ext))
echo "Old MD5 $MD5Old" >> $LogFile  # toDo: Debugging - remove
  MD5New=($(md5sum "$TBTYPE"))
echo "New MD5 $MD5New" >> $LogFile  # toDo: Debugging - remove
  if [ "$MD5New" = "$MD5Old" ]
  then
    # Delete, same as old binary
echo 'Delete download' >> $LogFile  # toDo: Debugging - remove
    rm -f $TBTYPE
  else
    # Test downloaded binary
echo 'Test download' >> $LogFile  # toDo: Debugging - remove
    chmod 755 $TBTYPE
    Applets=$(./$TBTYPE)
echo "Downloaded $Applets" >> $LogFile  # toDo: Debugging - remove
    if [ -z "$Applets" ]
    then
      # Delete, not working
      rm -f $TBTYPE
    else
echo 'Keep download' >> $LogFile  # toDo: Debugging - remove
      # Save the binary type and installation time
      echo "TBTYPE=$TBTYPE" > $TBSCRIPT
      echo "LASTDLTIME=$DLTIME" >> $TBSCRIPT

      # Notify user to reboot
echo 'Notify user' >> $LogFile  # toDo: Debugging - remove
      su -lp 2000 -c "cmd notification post -S bigtext -t 'ToyBox-Ext Module' 'Tag' 'Reboot to update ToyBox binary'" 1> /dev/null
    fi
  fi
fi
