#!/bin/bash

. /kb/deployment/user-env.sh

python ./scripts/prepare_deploy_cfg.py ./deploy.cfg ./work/config.properties


RQ=/tmp/rabbitmq
mkdir $RQ
mkdir /tmp/db
export RABBITMQ_BASE=$RQ
export RABBITMQ_MNESIA_BASE=$RQ
export RABBITMQ_LOG_BASE=$RQ

sed -i 's|http://kbase.us/services/assembly|http://localhost:8000|' /kb/assembly/lib/assembly/config.py

export ARAST_URL=http://localhost:8000/
export KB_AUTH_TOKEN=$(cat work/token)

ADIR=/kb/assembly/lib/assembly
# Fix up shock url
sed -i  "s|140.221.67.235:7445|$(grep endpoint deploy.cfg|sed 's/.*= *//')/shock-api|"  /kb/assembly/lib/assembly/arast.conf 

if [ $# -eq 0 ] ; then
  sh ./scripts/start_server.sh
elif [ "${1}" = "test" ] ; then
  echo "Run Tests"
  mongod --smallfiles --fork --logpath=/tmp/mongo.log --dbpath=/tmp/db
  HOME=$RQ /usr/lib/rabbitmq/bin/rabbitmq-server > /tmp/rabbit.log 2>&1 &
  sleep 5
  python $ADIR/arastd.py  -c $ADIR/arast.conf --logfile /tmp/arastd.log &
  # We need to start the consumer after a job has been submitted so the queue actually exist
  mkdir /kb/module/work/worker/
  (sleep 10;HOME=$RQ python $ADIR/ar_computed.py -s localhost -d /kb/module/work/worker/ -c $ADIR/ar_compute.conf  -b /kb/runtime/assembly/ )&
  make test || (cat /tmp/arastd.log )
elif [ "${1}" = "async" ] ; then
  mongod --smallfiles --fork --logpath=/tmp/mongo.log --dbpath=/tmp/db
  HOME=/tmp/rabbitmq /usr/lib/rabbitmq/bin/rabbitmq-server &
  sleep 5
  python $ADIR/arastd.py  -c $ADIR/arast.conf --logfile /tmp/arastd.log &
  # We need to start the consumer after a job has been submitted so the queue actually exist
  mkdir /kb/module/work/worker/
  (sleep 10;HOME=$RQ python $ADIR/ar_computed.py -s localhost -d /kb/module/work/worker/ -c $ADIR/ar_compute.conf  -b /kb/runtime/assembly/ )&
  sh ./scripts/run_async.sh
elif [ "${1}" = "init" ] ; then
  echo "Initialize module"
elif [ "${1}" = "bash" ] ; then
  bash
elif [ "${1}" = "report" ] ; then
  export KB_SDK_COMPILE_REPORT_FILE=./work/compile_report.json
  make compile
else
  echo Unknown
fi
