require 'fileutils'

# This zips each issue's files into an EPUB after all files have been
# written. If incremental builds are enabled (`--incremental`), it
# will skip rezipping if mtimes show nothing has changed.
Jekyll::Hooks.register :site, :post_write do |site|

  # Set up the cache, if it hasn't been disabled
  cache_disabled = site.safe || site.config['disable_disk_cache']
  if !cache_disabled && !File.exists?(site.in_cache_dir("epubs"))
    FileUtils.mkdir_p(site.in_cache_dir("epubs"))
  end

  # Find individual issues by locating their OPF files
  opfs = site.pages.filter { |page| page.name == 'issue.opf' }
  opfs.each { |opf|
    # the filename of the output EPUB
    epub_name = "#{File.basename(File.dirname(opf.dir))}.epub"

    # the path to the cached version of the EPUB
    cache_epub = site.in_cache_dir("epubs/#{epub_name}")

    # the directory that will be zipped to make the EPUB
    epub_files_dir = site.in_dest_dir(File.dirname(opf.dir))

    # the latest mtime of any file in the rendered issue
    issue_mtime = `find #{epub_files_dir} -type f`.split("\n")
                  .map{ |file| File.mtime(file) }
                  .sort().reverse().first()

    if (!cache_disabled &&
        File.exists?(cache_epub) &&
        File.mtime(cache_epub) >= issue_mtime)
      # TODO: also if list of included paths match?

      # We have a cached copy that is new enough - just use it
      FileUtils.cp(cache_epub, File.dirname(epub_files_dir)+"/"+epub_name)

    else
      # We have to rezip the epub

      # Zip includes the relative file path, so it's easiest to change
      # to the rendered directory and execute from there.
      Dir.chdir(epub_files_dir) {

        # mimetype must be the first file in the EPUB, and it must be
        # uncompressed (as per EPUB spec)
        system("zip -0X ../#{epub_name} mimetype > /dev/null")

        # Everything else must be in either META-INF/ or EPUB/
        system("zip -r ../#{epub_name} META-INF EPUB > /dev/null")

        # Jekyll will remove the EPUB when it resets before
        # rebuilding, because there is no source .epub file. In order
        # to have it around to compared against the unzipped-render,
        # we have to copy it to the cache.
        if !cache_disabled
          FileUtils.cp("../#{epub_name}", cache_epub)
        end
      }
    end
  }
end
