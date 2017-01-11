#!/bin/bash

NAME=$1
echo "input: ${NAME}"
echo "Starting test on: ${NAME}"
echo "Starting test on: ${NAME}" >> ${NAME}_test.json

for filename in ${NAME}/*.3mf; do
  echo "Validating ${filename}"
  ~/src/ruby3mf/bin/cli.rb ${filename} >> ${NAME}_test.json
done

echo "All Done."
