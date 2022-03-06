#!/bin/sh

potentionally_empty_dir="$1"

while [ ${#potentionally_empty_dir} -ne 0 ]
do
  echo "${potentionally_empty_dir}"
  rm --dir --force --verbose "${potentionally_empty_dir}"
  potentionally_empty_dir="${potentionally_empty_dir%/*}"
done

