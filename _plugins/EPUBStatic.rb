require 'jekyll'

module Jekyll

  # Dynamically create a static file for each file in the
  # _epub_static/ tree for each issue directory.
  #
  # The import script could have copied these files to each source
  # directory instead, but it made development iteration easier to be
  # able to re-render without always needing to re-import in some
  # cases.
  class EPUBStatic < Jekyll::Generator
    def generate(site)
      # Find each file, and record its path and mtime
      statics = `find _epub_static -type f`.split("\n")
                .map{ |s| {'path'=>s.sub("_epub_static/", ""),
                           'mtime'=>File.mtime(s)} }

      # Find each issue by locating its OPF
      opfs = site.pages.filter { |page| page.name == 'issue.opf' }

      # Make copies
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

      # The source path is always the same, but the destination path
      # is relative to each issue.
      @path = "_epub_static/"+s['path']
      @url = File.dirname(File.dirname(opf.path))+'/'+s['path']

      @mtime = s['mtime']
    end
  end
end
