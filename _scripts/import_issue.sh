#!/bin/bash

# Import images and metadata from the files in a magazine issue
# directory. These are pre-arranged for use in EPUB generation.
#
# Creates
#   ./issues/<issue id>/EPUB
#   ./issues/<issue id>/EPUB/issue.opf
#                        .../images/page_N.jpeg
#                        .../xhtml/page_N.xhtml
#                        .../xhtml/about.xhtml
#                        .../xhtml/toc.xhtml
#
# The other OCF container files will be added at site build time.

if (( $# < 1 )); then
    echo "Usage: $0 <original magazine issue directory>";
    exit -1;
fi

# The files in the top-level issue directory don't contain the
# information we need. But the offlineparams.xml file contains
# pointers to the directory that does.
if [[ -e "$1/offlineparams.xml" ]]; then
    REPOSITORY=`xq -r '.offline.param[]|select(.["@pname"] == "repository")|.["#text"]' "$1/offlineparams.xml"`
    DOCID=`xq -r '.offline.param[]|select(.["@pname"] == "documents")|.param["#text"]' "$1/offlineparams.xml"`
    ISSUEDATADIR="$1/$REPOSITORY$DOCID";
else
    # Fallback to assuming that the directory we wouldn't have deduced
    # from offlineparams.xml is the one that was actually passed as
    # our argument.
    ISSUEDATADIR="$1"
fi

# This is the file with almost all of the metadata about the issue. If
# we don't have this, we can't continue.
DOCXML=$ISSUEDATADIR/document.xml
if [[ ! -e "$DOCXML" ]]; then
    echo "Error: document.xml not found in issue data directory $ISSUEDATADIR"
    exit -1
fi

echo "Extracting data from issue directory $ISSUEDATADIR"

# My tools say lots of these issues contain invalid XML in
# document.xml. This step attempts to clean them up before further
# processing.
TMPDOCXML=`mktemp -t import_doc_xml`
if [[ $? == 0 ]]; then
    # American Woodworker sometimes...
    #    ... uses ampersand without escaping it (& -> &amp;)
    #    ... or embeds a comment within a comment (<!--<!----> -> <!--)
    sed -e 's/& /\&amp; /g' \
        -e 's/<!--<!---->/<!--/' \
        "$DOCXML" > $TMPDOCXML
else
    # If we can't do the substitution, try to keep going, in case we
    # didn't need to do it anyway
    TMPDOCXML=$DOCXML
fi

# If we didn't get DOCID from offlineparams.xml, get it now from
# document.xml.
if [[ -z DOCID ]]; then
    DOCID=`xq -r '.DigitalFlipDoc.docid["#text"]' "$TMPDOCXML"`
fi

ISSUETITLE=`xq -r '.DigitalFlipDoc.title["#text"]' "$TMPDOCXML"`
if [[ -z $ISSUETITLE ]]; then
    echo "No title found!"
    exit -1
fi

# Issue title has the form "Vol 1 No 1 March 1985"
# splitting by spaces:      1   2 3  4 5     6
YEAR=`echo $ISSUETITLE | cut -d " " -f 6`
MONTH=`echo $ISSUETITLE | cut -d " " -f 5`
ISSUE=`echo $ISSUETITLE | cut -d " " -f 4`

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

    (Spring) MONTH_NUM=03;;
    (Summer) MONTH_NUM=06;;
    (Fall) MONTH_NUM=09;;
    (Winter) MONTH_NUM=12;;

    (*) MONTH_NUM=UU;; # This is somewhat easy to find later
esac

if [[ -z $YEAR || -z $ISSUE ]]; then
    echo "Unable to extract YEAR and/or ISSUE from issue title $ISSUETITLE"
    exit -1
fi
ISSUEID=${YEAR}_${ISSUE}

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
issue_title: $ISSUETITLE
issue_id: $ISSUEID
source_id: $DOCID
files:" > $ISSUEOPF
# the list of files is added by ">> $ISSUEOPF" commands below

TOC=$XHTMLDIR/toc.xhtml
echo "---
layout: epub_toc
issue_title: $ISSUETITLE
date: $YEAR-$MONTH_NUM-01 09:00:00Z
pages:" > $TOC
# the list of pages is added by ">> $TOC" commands below

echo "  - id: toc
    properties: nav
    href: xhtml/$(basename $TOC)
    type: application/xhtml+xml" >> $ISSUEOPF

DOCTEXTXML=$ISSUEDATADIR/DocumentText.xml
if [[ ! -e "$DOCTEXTXML" ]]; then
    echo "Warning: Text extraction document not found at $ISSUEDATADIR/DocumentText.xml. No alt-text will be included."
fi

TOTALPAGES=`xq -r '.DigitalFlipDoc.pages.page|length' "$TMPDOCXML"`
for PAGE in $(seq 1 $TOTALPAGES); do
    # Where we extract the image from
    SWFFILE=$ISSUEDATADIR/Zoom_Page_$PAGE.swf

    # Where we save the image to
    IMGFILE=$IMGDIR/page_$PAGE.jpeg

    # The image is always ID 3 in the American Woodworker files
    swfextract -j 3 -o $IMGFILE "$SWFFILE"
    if [[ $? -ne 0 ]]; then
        echo "Error extracting JPEG from $SWFFile";
    fi
    echo "  - id: i${PAGE}
    href: $IMGSUB/$(basename $IMGFILE)
    type: image/jpeg" >> $ISSUEOPF

    # This tells reader apps to show page 1 in their shelf/thumbnail view
    if [[ $PAGE == 1 ]]; then
        echo "    properties: cover-image" >> $ISSUEOPF
    fi

    # So far all American Woodworker images have been the same size,
    # but this is an easy assurance
    IMGSIZE=`identify -format "width=%w, height=%h\n" $IMGFILE`

    # Create the XHTML page that displays the image
    XHTMLFILE=$XHTMLDIR/page_$PAGE.xhtml
    echo "---
layout: epub_page
number: $PAGE
image: ../$IMGSUB/$(basename $IMGFILE)
image_size: $IMGSIZE" > $XHTMLFILE

    if [[ -e "$DOCTEXTXML" ]]; then
        # could replace the query with an index like
        #    ".doc.page[$((PAGE - 1))][\"#text\"]"
        # but it seems to not make a time difference, and this seems less fragile, in case pages without text are omitted?
        PAGETEXT=`xq -r ".doc.page[]|select(.[\"@p\"] == \"$PAGE\")|.[\"#text\"]" "$DOCTEXTXML" | sed -e "s/^[ ]*/  /"`
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

# Add all table-of-contents items
echo "toc:" >> $TOC
xq -r '.DigitalFlipDoc.customtoc.content[]|"  - label: \(.["@label"])\n    page: \(.["@gotopage"])"' "$TMPDOCXML" >> $TOC

# done adding items to TOC and OPF
echo "---" >> $TOC
echo "---" >> $ISSUEOPF

# Just a small page at the end to record where this EPUB came from
IMPORT_DATE=`date`
echo "---
layout: epub_about
orig_path: $1
import_date: $IMPORT_DATE
---" > $XHTMLDIR/about.xhtml

# Not strictly necessary, but clean up temp files, if possible
if [[ "$TMPDOCXML" != "$DOCXML" ]]; then
    rm $TMPDOCXML
fi
