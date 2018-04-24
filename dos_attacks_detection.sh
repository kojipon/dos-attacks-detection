#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0);pwd)
ACCESSLOG_PATH="/var/log/httpd/access_log"
TMPLOG_PATH="$SCRIPT_DIR/access_log.tmp"
WHITELIST_PATH="$SCRIPT_DIR/while_list.txt"
BLACKLIST_PATH="$SCRIPT_DIR/black_list.txt"
ACCESS_COUNT_THRESHOLD=100
AN_HOURS_AGO=$(/bin/env LANG=en_US.UTF-8 /bin/date +'%d/%b/%Y:%H:' -d '-1 hours')

/bin/grep "$AN_HOURS_AGO" $ACCESSLOG_PATH | /usr/bin/cut -d ' ' -f 1 > $TMPLOG_PATH
/bin/cat $TMPLOG_PATH | /bin/sort | /usr/bin/uniq -c | /bin/sort -nr | /usr/bin/head -n 1000 > $TMPLOG_PATH

echo -n > $BLACKLIST_PATH

while read line; do
    ACCESS_COUNT=$(echo $line|/usr/bin/cut -d ' ' -f 1|/bin/sed -e 's/^[ \t]*//')
    ACCESS_IPADDR=$(echo $line|/usr/bin/cut -d ' ' -f 2|/bin/sed -e 's/^[ \t]*//')

    /bin/grep "$ACCESS_IPADDR" $WHITELIST_PATH > /dev/null && continue     
    if [ $ACCESS_COUNT -gt $ACCESS_COUNT_THRESHOLD ] ; then
        echo -e "${ACCESS_COUNT} ${ACCESS_IPADDR}" >> $BLACKLIST_PATH
    fi
done < $TMPLOG_PATH

if [ -s $BLACKLIST_PATH ]; then
    MAIL_TO="channel@workspace.slack.com"
    MAIL_TITLE="DoS attacks detection on ${HOSTNAME}"
    SUB_TITLE="These IP addresses were accessed ${HOSTNAME} more than ${ACCESS_COUNT_THRESHOLD} times per hour on ${AN_HOURS_AGO}??."
    /bin/sed -i "1i${SUB_TITLE}" $BLACKLIST_PATH
    /bin/cat $BLACKLIST_PATH | /bin/mail -s "${MAIL_TITLE}" "${MAIL_TO}"
fi

exit 0
