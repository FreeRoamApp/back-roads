#!/bin/sh
[ -z "$VERBOSE" ] && export VERBOSE=0
[ -z "$LINT" ] && export LINT=1
[ -z "$COVERAGE" ] && export COVERAGE=1
export NODE_ENV=test

node_modules/gulp/bin/gulp.js test
