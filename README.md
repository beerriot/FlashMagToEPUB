# Build EPUB Magazines From Page Scans

This is a tool I built to convert an old DVD archive of the American
Woodworker magazine back catalog from its Flash-player viewer to EPUB
documents. I can't (legally) share that catalog's content with you,
but I can share this tool to help you regain access to that content if
you own a copy but, like the rest of us, no longer have a Flash player
installed. See the [[ExtractingAmericanWoodworkerDVDs]] section for
instructions.

Other people who might find this repo interesting are:

* People with DVDs holding other magazine back catalogs. See
  [[FlashContentStructure]].
* People curious about EPUB creation or Jekyll site building. See
  [[EPUBAndJekyl]].

## Extracting American Woodworker DVDs

To directly use the code in this repo as written, you will need:

* A copy of "American Woodworker, 25 Years of Issues: Vol.1, No.1,
  March 1985 through #146, Feb/March 2010", ISBN 978-0-615-39003-1
* A computer with MacOS or Linux installed. This tool may also work on
  a Windows machine with the Windows Subsystem for Linux (WSL)
  installed, but I haven't tried it.
* The Git version control system (technically optional)
* The Ruby programming language runtime, as well as the Ruby Gems
  and Bundler package systems.
* The Jekyll static site builder.
* The xq XML parsing tool.
* The swftools package (for extracting data from Flash files).
* The ImageMagik suite of graphics tools.
* The zip compression utility.

Once you have those, follow these steps to extract and build your
first issue:

1. Copy this repository to your computer.

`git clone https://github.com/beerriot/TODO`

2. Change into the repo's root directory.

`cd TODO`

3. Run the import script to extract information from the Flash content
   and prepare it for further processing. On my Mac, the DVD shows up
   at `/Volumes/American\ Woodworker\ -\ Disc1`, and the path under
   that to the first issue (March 1985) under that is
   `disc1/issues/1985/1985_01`. So the full command looks like this:

`_scripts/import_issue.sh /Volumes/American\ Woodworker\ -\ Disc1/disc1/issues/1985/1985_01/`

4. All information and page images are now in the `issues/1985_1`
   folder under your current directory. Feel free to stop here, and
   just look through the images you'll find in
   `issues/1985_1/EPUB/images/`. If you don't need EPUBs, just repeat
   step 3 with each issue directory on the DVD. Images for the other
   issues will be plaed in `issues/[YEAR]_[INDEX]` directories here.

5. To generate EPUBs for use with electronic readers and apps, run the
   jekyll build process.

`bundle exec jekyll build --disable-disk-cache`

6. An EPUB for each magazine issue you imported is now available in
   the `_site/issues/` directory. Navigate to that directory in your
   file browser and drag them all to your reader app to load them.

If you know you want to create EPUBs for every issue on both DVDs,
some advice and warnings:

1. Warning: you will need approximately 14GB of free space to import
   and generate all issues at once.
2. Advice: if you don't import and generate all issues at once, delete
   the imported issue data *after* you have copied the EPUBs to your
   reader app, *before* importing and generating more issue EPUBs (run
   `rm -r issues`). If you don't, past issues will be regenerated
   again along with the new issue generation (not consuming any
   additional disk space, but wasting time).

To import all issues at once, the following `bash` snippet will work:

```
for i in /Volumes/American\ Woodworker\ -\ Disc1/disc1/issues/*/*; do
  _scripts/import_issue.sh $i;
done
```

To import just one year's issues, replace the second to last asterisk
with the year. For example, to import all issues from 1997:

```
for i in /Volumes/American\ Woodworker\ -\ Disc1/disc1/issues/1997/*; do
  _scripts/import_issue.sh $i;
done
```

## Flash Content Structure

I'm curious if other magazines have used the same tooling to produce
back catalog collections. Strings that look like names of tools are
"New Track Media, LLC" (who is listed as copyright owner) and
"InHouseDigitalPublishing" (who is listed as "publisher"). If you
bought a DVD back catalog from a magazine publisher that has one or
both of these strings hiding in its files, the rest of this
information may or may not help you recover the content.

I've never used these DVDs as intended, so some of my assumptions
about what different files are for might be wrong. But what I've found
is that each issue has its own directory containing all of its content
(including a full copy of the viewer app?). The path to each issue,
from the DVD root is of the form
`disc{1,2}/issues/$YEAR/$YEAR_$INDEX`. For example,
`disc1/issues/1985/1985_01` is the first issue.

In an issue's directory there are three XML files, plus one SWF per
page that the `_scripts/import_issue.sh` script in this repo uses:

```
  .../$YEAR_$INDEX/offlineparams.xml
  .../$YEAR_$INDEX/$REPOSITORY/$DOCID/document.xml
  .../$YEAR_$INDEX/$REPOSITORY/$DOCID/DocumentText.xml
  .../$YEAR_$INDEX/$REPOSITORY/$DOCID/Zoom_Page_*.swf
```

### `offlineparams.xml`

The `offlineparams.xml` file is the simplest, but it gives us the
names of the two subdirectories in which to find the other
files. (There are many others that we don't need to look in.)

Basically, it looks like this:

```
<offline>
  <param pname="documents">
    <param pname="docid" isdefault="1">[hex characters - a hash?]</param>
  </param>
  <param pname="repository">[something like "Vol_v_No_n_Month_Year/"]</param>
</offline>
```

Concatenating the first param ("docid" - a senseless string of
characters) onto the second ("repository" - a string that looks like
the basic issue title with underscores in place of spaces) gives us
the subdirectory to look for everything else in.

### document.xml

The `document.xml` file is where all of the metadata about the issue
lives. From this we get:

1. The title of the issue (from which we derive the year and month of
   publishing).
2. The number of pages in the issue.
3. The items for the table of contents

There are a lot more items to peruse in there, but these are the ones
we care about:

```
<DigitalFlipDoc>
  <title pname="title">Vol 1 No 1 March 1985</title>
  <pages pname="pages" imgtype="jpg">
    <page>...</page>
    <page>...</page>
    ...
  </pages>
  <customtoc pname="customtoc">
    <content pname="content" label="Requests" gotopage="4"/>
    ...
  </customtoc>
</DigitalFlipDoc>
```

### DocumentText.xml

The `DocumentText.xml` file contatins what looks like OCR (optical
character recognition) output of each page. It's honestly not great
(many character errors, spaces in the middle of words, column
confusion, and lack of placement information), but using the built-in
text extraction on MacOS didn't do much better. So, in an effort to
provide *some* searchability, the text from this file is imported.

Its structure:

```
<doc>
  <page p="1">The text that
was on page
number 1</page>
  <page p="2">...
  ...</page>
  ...
</doc>
```

### `Zoom_Page_*.swf`

The `Zoom_Page` files are where the images we came after actually
live. If you have one of these DVDs, and you list one of these
directories, you'll find that there are already `Page_*.jpg` JPEG
image files available. Open one and you'll find its 750x1027
pixels. It's not unreadable, but on today's high-resolution screens,
the pixels are evident.

List the contents of one of these `Zoom_Page_*.swf` Flash files, and
you'll find another JPEG image inside. That image is 1498x2054
pixels. That's only a tiny bit smaller than the number of pixels on an
iPad screen. Much more appropriate.

Luckily, the SWFTools package provides tools to extract items from
Flash files, and it seems that every `Zoom_Page` has exactly one JPEG,
at id 3.

```
% swfextract Vol_1_No_1_March_1985/1a222c8d671141e4a0867f568dacee3c/Zoom_Page_61.swf
Objects in file Vol_1_No_1_March_1985/1a222c8d671141e4a0867f568dacee3c/Zoom_Page_61.swf:
 [-i] 3 Shapes: ID(s) 1, 2, 4
 [-j] 1 JPEG: ID(s) 3
 [-f] 1 Frame: ID(s) 0
```

## EPUB And Jekyll

EPUB files, compatibile with many digital readers, seemed like the
best way to make this content accessible in a modern way. EPUB isn't
dissimilar from a static website - pages are encoded in XHTML, and
then organized with some XML. As such, I created a system for building
these EPUBs with a tool that I use for several of my other websites:
Jekyll.

The import script creates a `YEAR_INDEX/` directory in the `issues/`
directory of this repo, and prepares the issue data for the EPUB
templates in there.

Files it creates:

```
EPUB/issue.opf - the Open Package Format descriptor of what this
                 bundle is (name, id, list of files)
EPUB/xhtml/toc.xhtml - the list of pages, and the table of contents
EPUB/xhtml/about.xhtml - basic export/generation notes
EPUB/xhtml/page_*.xhtml - a basic page wrapper to display the page
                          image (and hold the OCR text as alternate
                          description)
EPUB/images/page_*.jpeg - the actual page image
```

The opf and xhtml files hold the imported information in YAML
format. It is converted to XML/XHTML by the Jekyll rendering
process. At the top of each of those files is a line that starts with
the string `layout:`. The name after that refers to a file in the
`_layouts/` directory. The data in the issue file is templated into
the layout file, and the result is written into the `_site/`
subdirectory at an equivalent path
(e.g. `issues/1985_1/EPUB/issue.opf` is templated with
`_layouts/epub_opf.xhtml` and written to
`_sites/issues/1985_1/EPUB/issue.opf`).

### Static files

Three additional files are necessary to complete the EPUB contents,
but they are the same for every issue - no templating is needed. These
are the three files in the `_epub_static/` tree.

Jekyll doesn't provide a built-in way to say, "Copy these files into
each of these other directories." The `_plugins/EPUBStatic.rb` script
does this instead. It does this by injecting `Jekyll::StaticFile`
entries at site-build time, causing Jekyll to do the copying, and
getting the benefits of cleanup and caching in the process.

### Zipping

Jekyll also doesn't provide a builtin way to zip files
together. Another script, `_plugins/ZipEPUB.rb` adds a hook to the
post-write phase of site generation to handle this. The output is
`_site/issues/YEAR_INDEX.epub` for each issue.

### Disk Space and Incremental Builds

This generation process is where the disk space required to generate
all issues balloons. Importing the images creates one copy of all of
them in `issues/YEAR_INDEX/EPUB/images/`. Jekyll copies all of them to
`_site/issues/...`. The zipping script copies them into
`YEAR_INDEX.epub`. That's three copies of every image!

To speed up incremental builds, the zipping script also copies each
`YEAR_INDEX.epub` into the Jekyll cache directory, so that it can be
copied back if nothing has changed, instead of spending time
re-zipping. That's a fourth copy, but Jekyll will also copy everything
into a `.jekyll-metadata` file when using `--incremental`, so that's
five total copies!

Five copies of every image. Each issue has around 30MB of
images. There are about 150 issues. 30MB * 150 * 5 = 22.5GB. This is
why the build instructions in the first section of this readme suggest
*not* using `--incremental` and also specifying
`--disable-disk-cache`. That brings the total back down to "only"
three copies, at and estimated 13.5GB.


## Other Back Catalogs

If I hear about other magazine back catalogs that this is tool is
compatible with, I will list them here. If you're importing
information from some other magazine, there is one other change you
will want to make. The name of the magazine is a pre-configured item
in the `_config.yaml` file (as `magazine_title`). That name was not
easily accessible on the American Woodworker DVDs, so the import
script does not automatically populate it.