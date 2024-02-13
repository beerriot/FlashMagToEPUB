#!/bin/bash

# Import images and metadata from the files in a magazine issue
# directory. These are pre-arranged for use in EPUB generation.
#
#
# Creates
#   ./issues/<issue id>/EPUB
#   .../issue.opf
#   .../images/page_N.jpeg
#   .../pages/page_N.xhtml
#   .../pages/about.xhtml
#
# The other OCF container files will be added at site build time.

if (( $# < 1 )); then
    echo "Usage: $0 <original magazine issue directory>";
    exit -1;
fi

if [[ -e $1/index.html ]]; then
    echo  "Converting issue from $1/index.html";
else
    echo "Cannot find issue file at $1/index.html";
    exit -1;
fi

TITLE=`grep "<title>" $1/index.html | cut -d ">" -f 2 | cut -d "<" -f 1`
if [[ -z $TITLE ]]; then
    echo "No title found!"
    exit -1
fi

VOLUMEDIR=$1/${TITLE// /_}
if [[ ! -d $VOLUMEDIR ]]; then
    echo "Cannot find issue data directory $VOLUMEDIR";
    exit -1;
fi

DOCXML=`ls $VOLUMEDIR/*/document.xml`
if [[ -z DOCXML ]]; then
    echo "Issue document not found at $VOLUMEDIR/*/document.xml"
    exit -1;
fi
TOTALPAGES=`grep pagenum $DOCXML | tail -1 | sed -r -e "s/.*pagenum=\"([0-9]+)\".*/\1/"`
SOURCEID=`grep docid $DOCXML | cut -d ">" -f 2 | cut -d "<" -f 1`

ISSUEDATADIR=$(dirname $DOCXML)
echo "Extracting data from issue directory $ISSUEDATADIR"

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

ISSUEID=${YEAR}_0${ISSUE}
if [[ -z $ISSUEID ]]; then
    echo "Empty issue id."
    exit -1
fi

OUTDIR=issues/$ISSUEID/EPUB
mkdir -p $OUTDIR
if [[ ! -d $OUTDIR ]]; then
    echo "Failed to create output directory $OUTDIR";
    exit -1;
else
    echo "Writing files to $OUTDIR"
fi

IMGSUB=images
IMGDIR=$OUTDIR/$IMGSUB
mkdir $IMGDIR

XHTMLSUB=xhtml
XHTMLDIR=$OUTDIR/$XHTMLSUB
mkdir $XHTMLDIR

ISSUEOPF=$OUTDIR/issue.opf
echo "---
layout: epub_opf
issue_title: $TITLE
issue_id: $ISSUEID
source_id: $SOURCEID
files:" > $ISSUEOPF

TOC=$XHTMLDIR/toc.xhtml
echo "---
layout: epub_toc
issue_title: $TITLE
date: $YEAR-$MONTH_NUM-01 09:00:00Z
pages:" > $TOC

echo "  - id: toc
    href: xhtml/$(basename $TOC)
    type: application/xhtml+xml" >> $ISSUEOPF

## TODO actual table-of-contents items

DOCTEXTXML=`ls $ISSUEDATADIR/DocumentText.xml`
if [[ ! -e $DOCTEXTXML ]]; then
    echo "Warning: Text extraction document not found at $ISSUEDATADIR/DocumentText.xml. No alt-text will be included."
fi

## Page Images

IMGPREFIX=page_
IMGSUFFIX=.jpeg

for PAGE in $(seq 1 $TOTALPAGES); do
    SWFFILE=$ISSUEDATADIR/Zoom_Page_$PAGE.swf
    IMGFILE=$IMGDIR/$IMGPREFIX$PAGE$IMGSUFFIX

    swfextract -j 3 -o $IMGFILE $SWFFILE
    if [[ $? -ne 0 ]]; then
        echo "Error extracting JPEG from $SWFFile";
    fi
    echo "  - id: i${PAGE}
    href: $IMGSUB/$(basename $IMGFILE)
    type: image/jpeg" >> $ISSUEOPF

    XHTMLFILE=$XHTMLDIR/page_$PAGE.xhtml
    echo "---
layout: epub_page
number: $PAGE
image: ../$IMGSUB/$(basename $IMGFILE)" > $XHTMLFILE
    if [[ -e $DOCTEXTXML ]]; then
        PAGETEXT=`sed -n -e "/<page p=\"$PAGE\"/,/page>/p" $DOCTEXTXML | sed -e "s/\<.*page.*\>//" -e "s/^[ ]*/  /"`
        echo "text: |2
$PAGETEXT" >> $XHTMLFILE
    fi
    echo "---" >> $XHTMLFILE

    echo "  - number: $PAGE
    href: $(basename $XHTMLFILE)" >> $TOC

    echo "  - id: p$PAGE
    href: $XHTMLSUB/$(basename $XHTMLFILE)
    type: application/xhtml+xml
    role: page" >> $ISSUEOPF
done

echo "---" >> $TOC
echo "---" >> $ISSUEOPF

IMPORT_DATE=`date`
echo "---
layout: epub_about
orig_path: $1
import_date: $IMPORT_DATE
---" > $XHTMLDIR/about.xhtml
