require 'rubygems'
require 'activesupport'
require 'nokogiri'
require 'date'

class XBEL < Nokogiri::XML::Document

  # TODO: How do I set this?
  DOCTYPE = '<!DOCTYPE xbel PUBLIC "+//IDN python.org//DTD XML Bookmark Exchange Language 1.0//EN//XML" "http://www.python.org/topics/xml/dtds/xbel-1.0.dtd">'

  delegate :title, :title=, :to => :root
  delegate :desc, :desc=, :to => :root

  def initialize(*args)
    super
    decorators(Nokogiri::XML::Node) << Nokogiri::Decorators::XBEL
    decorate!

    self.root = '<xbel version="1.0"></xbel>'
  end

  def version
    root.attribute 'version'
  end

end

module Nokogiri::Decorators::XBEL

  def self.extended(base)
    case base.name
    when 'xbel'
      base.extend Folder
    when 'title'
    when 'desc'
    when 'folder'
      base.extend Folder
    when 'bookmark'
      base.extend Bookmark
    when 'alias'
      base.extend Alias
    when 'separator'
    end
  end

  module Separator
    def to_s
      ''
    end
  end

  module Alias
    def ref
      attribute('ref').content
    end
    def ref=(value)
      set_attribute 'ref', value.to_s
    end
    alias_method :reference, :ref
    alias_method :reference=, :ref=

    def entry
      at %Q'//*[@id="#{ ref }"]'
    end

    delegate :description, :title, :to_s, :to => :entry
    delegate :id, :added, :to => :entry

    def alias?
      true
    end
    delegate :bookmark?, :folder?, :to => :entry
  end

  module Entry
    def desc
      if node = at('./desc') then node.content end
    end
    def desc=(value)
      node = at './desc'
      node ||= add_child Nokogiri::XML::Node.new('desc', document)

      node.content = value
    end
    alias_method :description, :desc
    alias_method :description=, :desc=

    def title
      if node = at('./title') then node.content end
    end
    def title=(value)
      node = at './title'
      node ||= add_child Nokogiri::XML::Node.new('title', document)

      node.content = value
    end
    alias_method :to_s, :title

    def id
      if id = attribute('id') then id.content end
    end
    def id=(value)
      set_attribute 'id', value.to_s
    end

    def added
      if value = attribute('added') then Date.parse value.content end
    end
    def added=(value)
      set_attribute 'added', value.to_s
    end

    def alias?; end
    def bookmark?; end
    def folder?; end
  end

  module Folder
    include Entry
    def entries
      xpath './alias', './bookmark', './folder', './separator'
    end
    def aliases
      xpath './alias'
    end
    def bookmarks
      xpath './bookmark'
    end
    def folders
      xpath './folder'
    end

    def folder?
      true
    end

    def add_child(node)
      node.added = Date.today if node.is_a? Entry
      super
    end

    def build_bookmark(attributes = {}, &block)
      node = Nokogiri::XML::Node.new('bookmark', document)
      assign_to node, attributes

      add_child node
    end
    def build_folder(attributes = {}, &block)
      node = Nokogiri::XML::Node.new('folder', document)
      assign_to node, attributes

      add_child node
    end
    def build_alias(ref)
      node = Nokogiri::XML::Node.new('alias', document)
      node.ref = (Entry === ref) ? ref.id : ref.to_s

      add_child node
    end
    def add_seperator
      add_child Nokogiri::XML::Node.new('separator', document)
    end

    protected
    def assign_to(node, attributes)
      attributes.each do |key, value|
        node.send "#{ key }=", value
      end
      yield node if block_given?
    end
  end

  module Bookmark
    include Entry
    def modified
      if value = attribute('modified') then Date.parse value.content end
    end
    def modified=(value)
      set_attribute 'modified', value.to_s
    end
    def visited
      if value = attribute('visited') then Date.parse value.content end
    end
    def visited=(value)
      set_attribute 'visited', value.to_s
    end
    def visit
      self.visited = Date.today
    end
    def href
      if value = attribute('href') then value.content end
    end
    def href=(value)
      self.modified = Date.today
      set_attribute 'href', value
    end
    def bookmark?
      true
    end
  end

end

class Navigation < XBEL
end

#navigation = Navigation.parse DATA
navigation = Navigation.new
p navigation
# navigation

__END__
<?xml version="1.0" encoding="utf-8"?>

<!DOCTYPE xbel
  PUBLIC "+//IDN python.org//DTD XML Bookmark Exchange Language 1.0//EN//XML"
         "http://www.python.org/topics/xml/dtds/xbel-1.0.dtd">
<xbel version="1.0">
  <title>Elbphilharmonie Hauptnavigation</title>
  <desc>
    Deutschen Version der Elbphilharmonie Hauptnavigation.
  </desc>
  <folder id="f0" added="2007-11-10">
    <title>Elbphilharmonie Hamburg</title>
    <desc></desc>
    <bookmark href="http://wikimediafoundation.org/"
              id="b0"
              added="2007-11-11"
              modified="2007-11-14"
              visited="2007-11-14">
      <title>Wikimedia Foundation</title>
    </bookmark>
    <bookmark href="http://de.wikipedia.org/"
              id="b1"
              added="2007-11-11"
              modified="2007-11-14"
              visited="2007-12-27">
      <title>Wikipedia</title>
    </bookmark>
  </folder>
  <separator />
  <alias ref="b1" />
</xbel>
