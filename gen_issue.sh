#!/bin/bash

# Create a Jekyll post given information about a magazine issue.
# Output will be a file like:
#
# ---
# title: Vol 1 No 1 March 1985
# date: 1985-03-01 09:00:00Z
# cover: /covers/1985_01.jpeg
# pages:
#   - number: 1
#     thumbnail: /thumbnails/1985_01/Page1.jpeg
#     image: /fullpages/1985_01/Page1.jpeg
#     text: "yadda yadda yadda"
#   - number: 2
#     ...
# ---
#
# Input: <issue directory> <posts directory>

. config

if (( $# < 2 )); then
    echo "Usage: $0 <issue directory> <posts directory>";
    exit -1
fi

if [[ -e $1/index.html ]]; then
    echo "Converting issue from $1/index.html";
else
    echo "Cannot find issue file at $1/index.html";
    exit -1;
fi

TITLE=`grep "<title>" $1/index.html | cut -d ">" -f 2 | cut -d "<" -f 1`

YEAR=`echo $TITLE | cut -d " " -f 6`
MONTH=`echo $TITLE | cut -d " " -f 5`
ISSUE=`echo $TITLE | cut -d " " -f 4`

case $MONTH in
    (January) MONTH_NUM=01;;
    (Feburary) MONTH_NUM=02;;
    (March) MONTH_NUM=03;;
    (April) MONTH_NUM=04;;
    (May) MONTH_NUM=05;;
    (June) MONTH_NUM=06;;
    (July) MONTH_NUM=07;;
    (August) MONTH_NUM=08;;
    (September) MONTH_NUM=09;;
    (October) MONTH_NUM=10;;
    (November) MONTH_NUM=11;;
    (December) MONTH_NUM=12;;
    (*) MONTH_NUM=UU;;
esac

OUTFILENAME="$2/$YEAR-$MONTH_NUM-01-${TITLE// /-}.html"

if [[ -d $2 ]]; then
    echo "Creating $OUTFILENAME";
else
    echo "Output directory $2 does not exist;"
    exit -1;
fi

ISSUEID=${YEAR}_0${ISSUE}

echo "---
title: $TITLE
date: $YEAR-$MONTH_NUM-01 09:00:00Z
cover: /covers/${ISSUEID}.jpg
pages: " > $OUTFILENAME

VOLDATADIR=$1/${TITLE// /_}
DOCXML=`ls $VOLDATADIR/*/document.xml`
DOCTEXTXML=`ls $VOLDATADIR/*/DocumentText.xml`

if [[ -e $DOCTEXTXML ]]; then
    TOTALPAGES=`grep pagenum $DOCXML | tail -1 | sed -r -e "s/.*pagenum=\"([0-9]+)\".*/\1/"`
    echo "Extracting text from $TOTALPAGES pages";

    for PAGE in $(seq 1 $TOTALPAGES); do
        PAGETEXT=`sed -n -e "/<page p=\"$PAGE\"/,/page>/p" $DOCTEXTXML | sed -e "s/\<.*page.*\>//" -e "s/^[ ]*/      /"`
        echo "  - number: $PAGE
    thumbnail: ${THUMBNAIL_BASE_DIR}${ISSUEID}/${THUMBNAIL_PREFIX}${PAGE}${THUMBNAIL_SUFFIX}
    image: ${IMAGE_BASE_DIR}${ISSUEID}/${IMAGE_PREFIX}${PAGE}${IMAGE_SUFFIX}
    text: |2
$PAGETEXT" >> $OUTFILENAME
    done

else
    echo "Cannot find $DOCTEXTXML for text extraction";
fi

echo "---" >> $OUTFILENAME

echo "Created $OUTFILENAME"
