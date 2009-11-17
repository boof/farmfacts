class Navigation < XBEL

  attr_reader :path, :xbel, :locale, :href

  ROOT = Rails.root.join 'db', 'navigations'
  ROOT.directory? or ROOT.mkdir

  REPO = V.git :work_tree => ROOT
  REPO.init unless ROOT.join('.git').directory?

  module Writer
    def initialize_writer(locale, path)
      @locale, @path = locale, path
      @relative_path = @path.relative_path_from ROOT
    end

    def set_href(href)
      @href = href
    end

    def insert(title, path)
    end
    def update(xpath, attributes)
    end
    def delete(xpath)
    end

    def write(author, *changes)
      @path.open('w') { |file| file << @xbel }

      message = "#{ author.name } updated #{ @relative_path }.\n"
      message << changes.map { |c| " * #{ c }" }.join("\n")

      # TODO: write git commit hooks to support observers
      # TODO: write git observers <remote> <branch> operation
      # TODO: write git observers -r <remote>

      REPO.add @relative_path
      REPO.commit message, :author => "#{ author.name } <#{ author.email }>"
    end
  end

  def self.localized
    path = ROOT.join "#{ I18n.locale }.xbel"

    instance = open path, I18n.locale
    instance.extend Writer
    instance.initialize_writer I18n.locale, path

    instance
  end

  def self.open(path, locale)
    super path
  rescue Errno::ENOENT
    path.dirname.mkpath unless path.dirname.directory?
    xbel = XBEL.new :div_id_er => '-',
        :id => path.basename('.xbel'),
        :title => path.basename('.xbel')
    path.open('w') { |file| file << xbel }
    REPO.add relative_path(path)
    REPO.commit "Created navigation for #{ locale }."
    retry
  end

  class Filter
    def matches(nodes, pattern)
      pattern_re = Regexp.new pattern
      nodes.each { |node| nodes.delete node if node.content =~ pattern_re }
    end
  end

  def self.filter
    Filter.new
  end

end
