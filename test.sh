#!/bin/sh -ue
cleanup() {
    kill $process
    echo
    echo "Output from server:"
    cat test-log
}

strace ./echo >test-log 2>&1 &
process=$!
trap cleanup EXIT

sleep 0.5 # Wait for the server to start.
url='http://127.0.0.1:20480'

curl $url

