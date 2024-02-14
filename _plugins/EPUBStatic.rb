require 'jekyll'

module Jekyll

  # Dynamically create a static file for each file in the
  # _epub_static/ tree for each issue directory
  class EPUBStatic < Jekyll::Generator
    def generate(site)
      statics = `find _epub_static -type f`.split("\n")
                .map{ |s| {'path'=>s.sub("_epub_static/", ""),
                           'mtime'=>File.mtime(s)} }
      opfs = site.pages.filter { |page| page.name == 'issue.opf' }
      opfs.each { |opf|
        statics.each { |s|
          site.static_files << EPUBStaticFile.new(site, opf, s)
        }
      }
    end
  end

  class EPUBStaticFile < Jekyll::StaticFile
    def initialize(site, opf, s)
      @site = site

      @ext = File.extname(s['path'])
      @name = File.basename(s['path'])
      @basename = File.basename(s['path'], @ext)

      @path = "_epub_static/"+s['path']
      @url = File.dirname(File.dirname(opf.path))+'/'+s['path']

      @mtime = s['mtime']
    end
  end
end
