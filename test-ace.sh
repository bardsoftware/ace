# /bin/bash
# Usage: no arguments to run all tests;
#        test path relative to "lib/" as an argument to run specific test
#        "-W" to show all warnings (no warnings by default)
for ARG in "$@"
do
    if [ "$ARG" = "-W" ]; then
        WARN="-W"
    else
        TEST_PATH=$ARG
    fi
done;

ROOT=$(dirname $0)
export NODE_PATH=$ROOT/lib;

if [ -z "$TEST_PATH" ]; then
    if [ -z "$WARN" ]; then
        node $ROOT/lib/ace/test/all_no_warnings.js
    else
        node $ROOT/lib/ace/test/all.js
    fi
else
    node $ROOT/lib/ace/test/only.js $WARN $TEST_PATH
fi
