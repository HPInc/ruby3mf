#!/bin/bash

MATCH=$1
echo "Test Suite: filter:${MATCH}"

GOOD_FILES=../3mf-test-suite/Positive/${MATCH}*.3mf
BAD_FILES=../3mf-test-suite/Negative/${MATCH}*.3mf

echo;echo;echo "Positive Files -------------"
echo "Positive Files -------------" >> suite_test.txt
for filename in ${GOOD_FILES}; do
  echo "  Validating ${filename}"
  result=$(( ~/src/ruby3mf/bin/cli.rb ${filename} ) 2>&1)
  if [ $? -ne 0 ]; then
      echo "    Failed!"
      echo $result >> suite_test.txt
  fi
done

echo;echo;echo "Negative Files -------------"
echo;echo;echo "Negative Files -------------" >> suite.txt
for filename in ${BAD_FILES}; do
  echo "  Validating ${filename}"
  result=$(( ~/src/ruby3mf/bin/cli.rb ${filename} ) 2>&1)
  if [ $? -eq 0 ]; then
      echo "    Passed!"
      echo "${filename} - No Errors found!" >> suite_test.txt
  fi
done

echo "All Done."
