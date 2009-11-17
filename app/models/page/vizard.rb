module Page::Vizard
  include TidyFFI

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      include Publishing

      delegate :href, :relative_path, :absolute_path, :git, :to => :storage

      before_save :remove_firebug!
      after_save :inject_vizard!
      after_save :commit_document

      before_publish :remove_vizard!, :valid_html?
    end
  end

  def storage
    @storage ||= Page::Storage.new path, locale
  end

  def title
    document.root.at('title').content
  end
  def title=(title)
    document.root.at('title').content = title
  end

  attr_writer :version
  def version
    @version ||= git.head.name
  end

  def commit_document
    storage.store document

    message = "#{ author.username } has updated the page.\n"
    message << changed_attributes.
    map { |name, origin| " * changed #{ name }" } * "\n"

    storage.commit author, message
  end

  def html=(html)
    @html = html

    # store outer html as formatted string
    document = Nokogiri.HTML html
    document.root.inner_html = '%s'
    self.outer_html = document.to_s
  end

  def html
    @html ||= begin
      blob = git.commits.find { |c| p c.name, version; c.name == version }.tree / relative_path
      blob.content
    end
  end

  def document
    @document ||= Nokogiri.HTML html
  end

  def inner_html=(inner_html)
    attribute_will_change! :html
    @html = outer_html % inner_html
  end

  protected

  def inject_vizard!
    script_include = Nokogiri::XML::Node.new 'script', document
    script_include['id']      = '_vizardInjector'
    script_include['src']      = 'javascripts/jquery-vizard.js'
    script_include['type']     = 'text/javascript'
    script_include['charset']  = 'utf-8'

    document.root.at('head').add_child script_include
  end

  def remove_vizard!
    document.root.instance_eval do
      xpath('vizard_elements(.)', Finder.new).each { |n| n.try :unlink }
      xpath('vizard_classes(.)', Finder.new).each do |node|
        node['class'] = node['class'].split(' ') \
        .reject { |css_class| Finder.vizard_class? css_class }.join ' '
      end
    end

    self.html = document.to_s
  end

  def remove_firebug!
    document.root.at('script#_firebugCommandLineInjector').try :unlink
    self.html = document.to_s
  end

  def valid_html?
    Tidy.new(html, :output_xml => true) { |t| t.errors.empty? }
  end

  module ClassMethods
    TEMPLATE = Rails.root.join('lib', 'vizard.html').read

    def vizard(author, attributes = {})
      attributes = {} unless Hash === attributes
      attributes = {
        'author'      => author,
        'html'        => TEMPLATE,
        'locale'      => I18n.locale
      } \
      .update attributes
      sanitize_path! attributes['path']

      new attributes
    end
    def sanitize_path!(path)
      if String === path
        path.slice! 0 if path[0, 1] == '/'
        path.gsub!(/\.[a-z-]+$/i, '')
      end
    end
  end

  class Finder
    const_set :VIZARD_XPATHS, [
      '//script[@id=\'_vizardInjector\'',
      '//div[@id=\'_vizardOverlay\''
    ]
    const_set :VIZARD_CLASSES,
    'isMutable' => nil,
    'mutableRoot' => nil,
    'mutableContainer' => nil,
    'mutableText' => nil

    def vizard_elements(node_set)
      node_set.xpath VIZARD_XPATHS.join(' | ')
    end
    def vizard_class?(css_class)
      VIZARD_CLASSES.member? css_class
    end
    def vizard_classes(node_set)
      node_set.find_all { |node|
        node['class'] =~ Regexp.new("(?:#{ VIZARD_CLASSES.keys * '|' })")
      }
    end
  end

end
