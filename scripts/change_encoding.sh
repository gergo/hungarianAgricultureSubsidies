#!/bin/bash

FROM_ENCODING="ISO-8859-2"
TO_ENCODING="UTF-8"

CONVERT=" iconv -f $FROM_ENCODING -t $TO_ENCODING"

for file in ../input/csv/*.csv; do
    $CONVERT "$file" > "utf8_${file}"
done
exit 0
