#!/bin/bash 
. /kb/deployment/user-env.sh

python ./scripts/prepare_deploy_cfg.py ./deploy.cfg ./work/config.properties

if [ -z $KB_AUTH_TOKEN ] ; then 
  export KB_AUTH_TOKEN=$(cat /kb/module/work/token)
fi
export KB_AUTH_USER_ID=$(PYTHONPATH=/kb/module/lib ./scripts/get_user.py)


# Helper function to start ARAST backend
start_backend () {
    echo "Starting local instance of ARAST backend services (mongo, rabitmq, ARAST)"
    mkdir /tmp/db
    mongod --smallfiles --fork --logpath=/tmp/mongo.log --dbpath=/tmp/db > /tmp/mongo-start.log 2>&1

    # Start Rabbit (works as non-root)
    RQ=/tmp/rabbitmq
    mkdir $RQ
    export RABBITMQ_BASE=$RQ
    export RABBITMQ_MNESIA_BASE=$RQ
    export RABBITMQ_LOG_BASE=$RQ
    HOME=$RQ /usr/lib/rabbitmq/bin/rabbitmq-server > /tmp/rabbit.log 2>&1 &

    # Fix up ARAST configs and start server
    ADIR=/kb/assembly/lib/assembly
    SHOCK=$(grep endpoint deploy.cfg|sed 's/.*= *//')/shock-api
    sleep 2
    $ADIR/arastd.py  -c $ADIR/arast.conf \
		--shock-url $SHOCK \
		--logfile /tmp/arastd.log > /tmp/arastd-start.log 2>&1 &

    # Start up compute service
    PERL5LIB=$PERL5LIB:/kb/runtime/assembly/a5/bin/SSPACE/dotlib/
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/kb/runtime/assembly/masurca/lib/
    mkdir /kb/module/work/worker/
    sleep 1
    ./create.py || exit 1
    sleep 5
    HOME=/tmp python $ADIR/ar_computed.py -s localhost \
		-d /kb/module/work/worker/ \
		-c $ADIR/ar_compute.conf \
		-b /kb/runtime/assembly/ &
    AC=$!
    sleep 5
    if [ ! -e /proc/$AC ] ; then 
      echo "Compute backend failed to start"
      exit 1
    fi
}

if [ $# -eq 0 ] ; then
  start_backend
  sh ./scripts/start_server.sh
elif [ "${1}" = "test" ] ; then
  echo "Run Tests"
  start_backend
  make test || (cat /tmp/arastd.log )
elif [ "${1}" = "async" ] ; then
  start_backend
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
