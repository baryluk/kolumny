#!/bin/sh

FAIL=0
PASS=0

ALL=$(pwd)
for t in $(ls -d */)
do
  cd $ALL
  cd $t
  if [ ! -f command ]; then
    echo "ERROR $t - Test broken. command file missing."
    FAIL=$((FAIL+1))
    continue
  fi
  if [ ! -f expected ]; then
    echo "ERROR $t - Test broken. expected file missing."
    FAIL=$((FAIL+1))
    continue
  fi
  KOLUMNY=../../kolumny sh command 2>&1 | sed -E -e 's|File "([^"]+kolumny)", line [0-9]+, in|File "\1", line xxx, in|' > actual
  if ! diff -Nu expected actual >/dev/null 2>/dev/null; then
    echo "FAIL $t"
    echo
    echo "Test command:"
    cat command
    echo
    echo "Differences detected:"
    diff -Nu expected actual
    echo "--------------------------------------------------------------------------------"
    FAIL=$((FAIL+1))
  else
    echo "PASS $t"
    PASS=$((PASS+1))
  fi
done

echo "${PASS} tests passed!"
echo "${FAIL} tests failed!"
if [ "x${FAIL}" != "x0" ]; then
  exit 1
fi

exit 0
