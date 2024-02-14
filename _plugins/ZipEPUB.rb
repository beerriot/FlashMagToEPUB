require 'fileutils'

# TODO: do not re-copy and rezip each epub, if not necessary.  See
# stash "try to use mtime to prevent recopy & rezip epub" - checking
# mtimes here doesn't work because jekyll has removed the zip before
# we get here, so there is no mtime to check.

Jekyll::Hooks.register :site, :post_write do |site|
  puts "Zipping epubs"
  opfs = site.pages.filter { |page| page.name == 'issue.opf' }
  opfs.each { |opf|
    Dir.chdir("#{site.dest}#{File.dirname(opf.dir)}") {
      system("zip -0X ../#{File.basename(File.dirname(opf.dir))}.epub mimetype > /dev/null")
      system("zip -r ../#{File.basename(File.dirname(opf.dir))}.epub META-INF EPUB > /dev/null")
    }
  }
end
