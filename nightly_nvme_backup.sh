#!/bin/bash
#back up critical information from the NVME drive on a regular basis so that
#it can be protected with snapraid
SERVERNAME=`hostname | sed "s/-server.lan//g"`
BACKUPLOCATION="/data/hydrogen/backups/backups-from-server"
TODAY=`date +%F`
CRYPTOVAULT="/data/encrypted_vault.img"
CONTAINERS="/data/container-storage"
BACKUPLOG="/home/snapraid/automation/backup.log"
#How many of each interval to keep; note that due to how -mtime works and 
#the never-delete newest safety, the actual number left can be higher by 1-2
DAILYCOUNT=7
WEEKLYCOUNT=4
MONTHLYCOUNT=12

echo "-----Starting backups from server $TODAY-----" >> $BACKUPLOG

#back up the cryptovault file
NOWTIME=`date`
echo "Starting backup of cryptovault file at $NOWTIME" >> $BACKUPLOG
echo "Closing vault"
bash /home/snapraid/automation/close_vault.sh >> $BACKUPLOG
tar -czf $BACKUPLOCATION/$SERVERNAME-encrypted-vault-daily-$TODAY.tar.gz $CRYPTOVAULT
NOWTIME=`date`
echo "Cryptovault file backup created at $NOWTIME" >> $BACKUPLOG

#back up the container persistent storage folder

#tell minecraft server to 'save off' so we get a consistent world state
podman exec hermitcraft6 rcon-cli save-off
podman exec creative-server rcon-cli save-off

sleep 10

NOWTIME=`date`
echo "Starting backup of container persistence at $NOWTIME" >> $BACKUPLOG
cd $CONTAINERS
for dir in */
do
	base=$(basename "$dir")
	tar -czf $BACKUPLOCATION/$SERVERNAME-$base-daily-$TODAY.tar.gz $dir
done
NOWTIME=`date`
echo "Container persistence backup created at $NOWTIME" >> $BACKUPLOG

sleep 10

podman exec hermitcraft6 rcon-cli save-on
podman exec creative-server rcon-cli save-on

#generate weekly snapshot files
NIGHTLY_ARRAY=(`find $BACKUPLOCATION -name "*daily*tar.gz" -type f -exec basename {} \; | sed "s/$SERVERNAME-//g" | sed "s/-daily-.*tar.gz//g" | sort | uniq`)

for t in ${NIGHTLY_ARRAY[@]}; do
    #mtime has to be 1 day less if you want it to be 7 days apart
    if [[ $(find $BACKUPLOCATION -name "$SERVERNAME-$t-weekly-*tar.gz" -type f -mtime -6 -exec basename {} \; | wc -l) -le 0 ]]; then
        #create weekly from most recent daily available
		NEWEST_SNAPSHOT=`find $BACKUPLOCATION -name "$SERVERNAME-$t-daily*tar.gz" -type f -exec stat -c '%X %n' {} \; | sort -nr | head -1 | cut -d " " -f 2`
		WEEKLY_SNAPSHOT="${NEWEST_SNAPSHOT/daily/weekly}"
		#echo $WEEKLY_SNAPSHOT
		cp $NEWEST_SNAPSHOT $WEEKLY_SNAPSHOT
    fi
	#remove dailies older than X days, but never the newest
	STALE_LIST=(`find $BACKUPLOCATION -name "$SERVERNAME-$t-daily*tar.gz" -mtime +$DAILYCOUNT -type f -exec stat -c '%X %n' {} \; | sort -n | head -n -1 | cut -d " " -f 2`)
	for stale in ${STALE_LIST[@]}; do
		rm $stale
	done

	#create monthlies
	if [[ $(find $BACKUPLOCATION -name "$SERVERNAME-$t-monthly-*tar.gz" -type f -mtime -29 -exec basename {} \; | wc -l) -le 0 ]]; then
        #create weekly from most recent daily available
        NEWEST_SNAPSHOT=`find $BACKUPLOCATION -name "$SERVERNAME-$t-daily*tar.gz" -type f -exec stat -c '%X %n' {} \; | sort -nr | head -1 | cut -d " " -f 2`
        MONTHLY_SNAPSHOT="${NEWEST_SNAPSHOT/daily/monthly}"
        #echo $MONTHLY_SNAPSHOT
        cp $NEWEST_SNAPSHOT $MONTHLY_SNAPSHOT
    fi
    #remove weeklies older than X days, but never the newest
    STALE_LIST=(`find $BACKUPLOCATION -name "$SERVERNAME-$t-weekly*tar.gz" -mtime +$(( $WEEKLYCOUNT*7 )) -type f -exec stat -c '%X %n' {} \; | sort -n | head -n -1 | cut -d " " -f 2`)
    for stale in ${STALE_LIST[@]}; do
        rm $stale
    done

	#create yearlies
	if [[ $(find $BACKUPLOCATION -name "$SERVERNAME-$t-yearly-*tar.gz" -type f -mtime -364 -exec basename {} \; | wc -l) -le 0 ]]; then
        #create weekly from most recent daily available
        NEWEST_SNAPSHOT=`find $BACKUPLOCATION -name "$SERVERNAME-$t-daily*tar.gz" -type f -exec stat -c '%X %n' {} \; | sort -nr | head -1 | cut -d " " -f 2`
        YEARLY_SNAPSHOT="${NEWEST_SNAPSHOT/daily/yearly}"
        #echo $MONTHLY_SNAPSHOT
        cp $NEWEST_SNAPSHOT $YEARLY_SNAPSHOT
    fi
    #remove monthlies older than X days, but never the newest
    STALE_LIST=(`find $BACKUPLOCATION -name "$SERVERNAME-$t-monthly*tar.gz" -mtime +$(( $MONTHLYCOUNT*30 )) -type f -exec stat -c '%X %n' {} \; | sort -n | head -n -1 | cut -d " " -f 2`)
    for stale in ${STALE_LIST[@]}; do
        rm $stale
    done

done

#ensure snapraid owns the relavent files
chown snapraid:snapraid $BACKUPLOCATION/*

#prevent too many files till we get weekly/monthly/yearly rotate figured out
#find $BACKUPLOCATION -name "*daily*tar.gz" -type f -mtime +30 -exec rm -f {} \;

