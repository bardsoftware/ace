# /bin/bash
# Usage: no arguments to run all tests;
#        test path relative to "lib/" as an argument to run specific test
#        "-W" to show all warnings (no warnings by default)
for i in "$@"
do
    if [ "$i" = "-W" ]; then
        WARN="-W";
    else
        TEST_PATH=$i;
    fi
done;

ROOT=`dirname $0`;
export NODE_PATH=$ROOT/lib;

if [ "$TEST_PATH" = "" ]; then
    if [ "$WARN" = "" ]; then
        node $ROOT/lib/ace/test/all_no_warnings.js
    else
        node $ROOT/lib/ace/test/all.js
    fi
else
    node $ROOT/lib/ace/test/only.js $WARN $TEST_PATH
fi
