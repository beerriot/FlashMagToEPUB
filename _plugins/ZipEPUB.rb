require 'fileutils'

# This zips each issue's files into an EPUB after all files have been
# written. If incremental builds are enabled (`--incremental`), it
# will skip rezipping if mtimes show nothing has changed.
Jekyll::Hooks.register :site, :post_write do |site|
  cache_disabled = site.safe || site.config['disable_disk_cache']
  if !cache_disabled && !File.exists?(site.in_cache_dir("epubs"))
    FileUtils.mkdir_p(site.in_cache_dir("epubs"))
  end

  opfs = site.pages.filter { |page| page.name == 'issue.opf' }
  opfs.each { |opf|
    epub_name = "#{File.basename(File.dirname(opf.dir))}.epub"
    cache_epub = site.in_cache_dir("epubs/#{epub_name}")
    epub_files_dir = site.in_dest_dir(File.dirname(opf.dir))

    issue_mtime = `find #{epub_files_dir} -type f`.split("\n")
                  .map{ |file| File.mtime(file) }
                  .sort().reverse().first()

    if (!cache_disabled &&
        File.exists?(cache_epub) &&
        File.mtime(cache_epub) >= issue_mtime)
      # TODO: also if list of included paths match?
      FileUtils.cp(cache_epub, File.dirname(epub_files_dir)+"/"+epub_name)
    else
      Dir.chdir(epub_files_dir) {
        system("zip -0X ../#{epub_name} mimetype > /dev/null")
        system("zip -r ../#{epub_name} META-INF EPUB > /dev/null")

        if !cache_disabled
          FileUtils.cp("../#{epub_name}", cache_epub)
        end
      }
    end
  }
end
