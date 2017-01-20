#!/bin/bash

MATCH=$1
OUTFILE=suite_test.txt
GOOD_FILES=../3mf-test-suite/Positive/${MATCH}*.3mf
BAD_FILES=../3mf-test-suite/Negative/${MATCH}*.3mf

echo "Test Suite: filter: ${MATCH}"
printf "\n\nTest Suite: filter: ${MATCH} - $(date)\n" >> ${OUTFILE}

echo "Positive Files -------------"
printf "\nPositive Files -------------\n" >> ${OUTFILE}
for filename in ${GOOD_FILES}; do
  if [ -f ${filename} ]; then
    echo "  Validating ${filename}"
    result=$(( ~/src/ruby3mf/bin/cli.rb ${filename} ) 2>&1)
    if [ $? -ne 0 ]; then
      echo "    Failed!"
      printf "  ${filename}\n    $result\n" >> ${OUTFILE}
    fi
  fi
done

echo "Negative Files -------------"
printf "\nNegative Files -------------\n" >> suite_test.txt
for filename in ${BAD_FILES}; do
  if [ -f ${filename} ]; then
    echo "  Validating ${filename}"
    result=$(( ~/src/ruby3mf/bin/cli.rb ${filename} ) 2>&1)
    if [ $? -eq 0 ]; then
      echo "    Passed!"
      printf "  ${filename} - No Errors found!\n" >> ${OUTFILE}
    fi
  fi
done

echo "All Done."
printf "Completed -- $(date)\n\n" >> ${OUTFILE}

