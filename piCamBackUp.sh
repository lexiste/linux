#!/bin/bash

# Create a logfile and filelist
TIMESTAMP=`date +%d%b%Y.%H`
FILELIST="/tmp/motion_filelist.$TIMESTAMP.txt"
LOGFILE="/tmp/motion.backup.$TIMESTAMP.txt"

date +"%c - Starting Backup Job" | tee -a $LOGFILE

date +"%c - Removing backup log files older than 7 days" | tee -a $LOGFILE
find /tmp -name "motion_backup*.txt" -mtime +7 -exec rm {} \; -print | tee -a $LOGFILE

date +"%c - Remove filelist files older than 7 days" | tee -a $LOGFILE
find /tmp -name "motion_filelist*.txt" -mtime +7 -exec rm {} \; -print | tee -a $LOGFILE

# Mount the cifs share of our home NAS ... check if mounted first
date +"%c - Checking if //catnas/public/piCam is already mounted to /mnt/picam" | tee -a $LOGFILE
MOUNTED=`grep "//catnas/public/piCam" /etc/mtab`
if [ "$MOUNTED" = "" ]
then
   date +"%c - Mounting //catnas/public/piCam to /mnt/picam" | tee -a $LOGFILE
   mount -t cifs -o username=todd,password="YourPasswordHere" //catnas/public/piCam /mnt/picam/
else
   date +"%c - Skipping, share is already mounted to //catnas/public/piCam" | tee -a $LOGFILE
fi

# Now that we have verified the mount, let's move the files avi and jpg files over
date +"%c - Starting the actual backup job" | tee -a $LOGFILE
find /tmp/motion -type f -mmin -480 -exec ls -1d {} \; > /tmp/t.$$

date +"%c - Found total of `cat /tmp/t.$$ | wc -l` files to move" | tee -a $LOGFILE

cat /tmp/t.$$ |
while
   read LINE
do
   sshpass -p "RemoteHostPassword" scp -r -p $LINE "user@hostname:~/www/piCam/" | tee -a $LOGFILE
   rsync -a --no-owner --no-group --remove-source-files $LINE /mnt/picam | tee -a $LOGFILE
done > $FILELIST

date +"%c - Files rsync'd from /tmp/motion to /mnt/picam" | tee -a $LOGFILE
date +"%c - Files scp'd from /tmp/motion to fencl0ne@fencl.net:~/www/piCam/" | tee -a $LOGFILE
date +"%c - Backup Job Completed, moving $LOGFILE and exiting" | tee -a $LOGFILE

# Move the backup log file as well
rsync -a --no-owner --no-group --remove-source-files  $LOGFILE /mnt/picam

# Remove temp file created
rm -rf /tmp/t.$$

# We are done, let's unmount and slide out
umount /mnt/picam
exit 0
