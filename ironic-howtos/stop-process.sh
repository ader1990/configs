set -e

if [ $# -ne 1 ]; then
    echo "Usage: stop-process.sh <process-regexp>"
    exit 1
fi

PROCESS_REGEXP=$1

PID=`ps -ef | grep $PROCESS_REGEXP | grep -v grep | awk '{print $2}'`

if [ $PID ]; then
    echo "Killing process with PID:$PID"
    kill -9 $PID
else
    echo "Process not found for regexp: $PROCESS_REGEXP"
fi


