#!/bin/bash

# Copy the page images from a magazine issue.
# Copies the thumbnails to $THUMBNAILDIR/Thumbnail_$PAGE.jpg
# Extracts full-resolution JPEG form Zoom_Page SWF, and copies it to
# $FULLPAGEDIR/Page_$PAGE.jpg

. config

if (( $# < 3 )); then
    echo "Usage: $0 <in:source dir> <out:thumbs dir> <out:full-res dir>"
    exit -1;
fi

if [[ ! -d $1 ]]; then
    echo "Source directory does not exist: $1"
    exit -1;
fi

if [[ ! -d $2 ]]; then
    echo "Thumbs directory does not exist: $2"
    exit -1;
fi

if [[ ! -d $3 ]]; then
    echo "Full-resolution directory does not exist: $3"
    exit -1;
fi

THUMBCOUNT=0
for Thumb in $1/Thumbnail_*.jpg; do
    BASENAME=$(basename $Thumb)
    Outfile=${BASENAME/Thumbnail_/${THUMBNAIL_PREFIX}}
    Outfile=$2/${Outfile/.jpg/${THUMBNAIL_SUFFIX}}

    cp $Thumb $Outfile
    ((THUMBCOUNT++));
done
echo "Copied $THUMBCOUNT thumbnails."

PAGECOUNT=0
for SWFFile in $1/Zoom_Page_*.swf; do
    BASENAME=$(basename $SWFFile)
    OutFile=${BASENAME/Zoom_Page_/$IMAGE_PREFIX}
    OutFile=$3/${OutFile/.swf/$IMAGE_SUFFIX}

    swfextract -j 3 -o $OutFile $SWFFile

    if [[ $? -eq 0 ]]; then
        ((PAGECOUNT++));
    else
        echo "Error extracting JPEG from $SWFFile";
    fi
done

if [[ $PAGECOUNT -eq $THUMBCOUNT ]]; then
    echo "Also extracted $PAGECOUNT full-resolution pages";
else
    echo "Warning: only extracted $PAGECOUNT pages (expected $THUMBCOUNT)";
    exit -1
fi
