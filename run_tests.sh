#!/bin/bash -el

echo "Starting tests..."

# BEGIN TIMEOUT #
if [ "$TRAVIS" == "true" ] ; then
  echo "Travis-CI detected."
  TIMEOUT=300 # 2640 # 44 minutes
else
  TIMEOUT=5400 # 90 minutes
fi

BOSSPID=$$
(
  sleep $TIMEOUT
  echo
  echo "Test timed out after $TIMEOUT seconds."
  echo
  kill -SIGINT $BOSSPID
  echo
  echo Emulator log:
  echo
  cat adb_logcat.log
  echo
  echo "Test timed out after $TIMEOUT seconds."
  sleep 60 # Allow the main process to kill us
  echo KILL THE BOSS!
  kill -9 $BOSSPID # Kill the main process and signal failure.
)&
TIMERPID=$!
echo "PIDs: Boss: $BOSSPID, Timer: $TIMERPID"

trap "echo 'Got timeout signal' ; exit" SIGINT
trap "echo 'Kill timer.' ; kill -9 $TIMERPID" EXIT
# END TIMEOUT #

if [ ! $(command -v ant) ] ; then
  if [ -e /etc/profile.d/ant.sh ] ; then
    . /etc/profile.d/ant.sh
  else
    echo Apache ANT is missing!
    exit 2
  fi
fi
ant -version

if [ "$RUBY_IMPL" != "" ] ; then
  if [ -e /etc/profile.d/rvm.sh ] ; then
    . /etc/profile.d/rvm.sh
  fi
  if [ ! $(command -v rvm) ] ; then
    echo RVM is missing!
    exit 2
  fi
  rvm --version
  unset JRUBY_HOME
  rvm install $RUBY_IMPL
  rvm use $RUBY_IMPL
  echo -n
fi

export NOEXEC_DISABLE=1
rake clean
set +e
rake test $*
TEST_RC=$?
set -e

echo Tests exited with code $TEST_RC

if [ "$TEST_RC" != "0" ] ; then
  echo
  echo Emulator log:
  echo
  cat adb_logcat.log
  echo
  echo Tests failed with exit code $TEST_RC
fi

exit $TEST_RC
