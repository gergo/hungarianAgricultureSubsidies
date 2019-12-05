#!/bin/bash

FROM_ENCODING="ISO-8859-2//IGNORE"
TO_ENCODING="UTF-8"

CONVERT=" iconv -f $FROM_ENCODING -t $TO_ENCODING"
cd `pwd`/../input/csv/

for file in ????.csv; do
    echo converting "$file"
    $CONVERT "$file" > "utf8_${file}"
done
exit 0
