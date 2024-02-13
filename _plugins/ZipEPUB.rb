require 'fileutils'

Jekyll::Hooks.register :site, :post_write do |site|
  puts "Adding static files and zipping epubs"
  opfs = site.pages.filter { |page| page.name == 'issue.opf' }
  opfs.each { |opf|
    FileUtils.cp_r('_epub_static/.', site.dest + File.dirname(opf.dir))
    Dir.chdir("#{site.dest}#{File.dirname(opf.dir)}") {
      system("zip -r ../#{File.basename(File.dirname(opf.dir))}.epub .")
    }
  }
end
