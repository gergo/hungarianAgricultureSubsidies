#!/bin/bash

FROM_ENCODING="ISO-8859-2"
TO_ENCODING="UTF-8"

CONVERT=" iconv -f $FROM_ENCODING -t $TO_ENCODING"

for file in *.csv; do
    $CONVERT "$file" > "${file}.utf8"
done
exit 0
