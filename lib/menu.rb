class Menu

  def initialize
  end

  class Node

    def initialize(attributes = {}, &block)
      @views = {}

      attributes = { :parent => self }.merge attributes
      initialize_attributes attributes

      yield self if block_given?
    end
    def to_s
      ''
    end
    def view
      @views[ Thread.current ] || ( @parent != self ) && @parent.view
    end
    delegate :content_tag, :link_to, :to => :view

    protected

      def with_view(current_view)
        @views[ Thread.current ] = current_view if current_view
        yield
      ensure
        @views.delete Thread.current
      end
      def initialize_attributes(attributes)
        attributes.each { |k, v| instance_variable_set :"@#{ k }", v }
      end

  end
  class Divider < Node

    def to_s
      '<hr />'
    end

  end
  class Collection < Node

    def <<(node)
      node.parent = @parent
      @nodes << node
    end
    def new(type, attributes = {}, &block)
      attributes.update :parent => self
      @nodes << ::Menu.const_get(type).new(attributes, &block)
    end
    def to_s(&block)
      block ||= proc { |str, n| "#{ str }#{ n }" }
      @nodes.inject('', &block)
    end
    def [](variable_name)
      instance_variable_get variable_name.to_sym
    end

    protected

      def initialize_attributes(attributes)
        attributes = { :nodes => [] }.merge attributes
        super attributes
      end

  end
  class Item < Node

    def to_s
      link_to "#{ icon }#{ @caption }", href
    end

    protected

      def initialize_attributes(attributes)
        href = "##{ attributes[:name] }"
        attributes = { :href => href }.merge attributes
        super
      end
      def icon
        content_tag :span, '', :class => "ui-icon ui-icon-#{ @icon }" if @icon
      end

  end
  class Label < Item

    protected

      def initialize_attributes(attributes)
        attributes = { :href => '' }.merge attributes
        super attributes
      end

  end
  class Menu < Collection

    def to_s
      nodes_str = super { |str, n| "#{ str }#{ wrap n }" }
      nodes_str = content_tag :ul, nodes_str

      content_tag(:li, @label.to_s) +
      content_tag(:li, nodes_str, :class => 'hidden')
    end

    protected

      def wrap(node)
        content_tag :li, node.to_s, :class => node[:class]
      end
      def initialize_attributes(attributes)
        super :label => Label.new(attributes)
      end

  end

end

__END__
def set_titlebar
  home    = MenuItem.new :name => 'system', :icon => 'home', :caption => t('titles.default')
  current = Label.new :caption => title
  groups  = MenuItem.new :name => 'groups', :caption => t('menu.base.groups.index')
  login   = MenuItem.new :name => 'logins', :caption => t('menu.base.login.index')

  if visitor.admin?
    groups.add_menuitem :caption => t('menu.admin.groups.new'), :href => new_admin_group_path
    login.add_menuitem :caption => t('menu.admin.logins.index'), :href => admin_logins_path
  end

  home.add_menuitem :caption => t('menu.base.frontpage'), :href => dashboard_index_path
  for group in Group.find :all
    groups.add_menuitem :caption => group.name, :href => group_path(group)
  end
  login.add_menuitem :caption => t('menu.base.login.edit'), :href => login_path(visitor)
  login.add_menuitem :caption => t('menu.base.login.forget', :name => visitor.name), :href => forget_login_path

  @titlebar = [ home, current, groups, login ]
end

class Label
  attr_accessor :caption, :name, :icon, :parent
  def initialize(attributes)
    @views, @parent = {}, self
    attributes.each { |k, v| send "#{ k }=", v }
  end
  def render(current_view = nil)
    with_view current_view do
      block_given?? render_item + yield : render_item
    end
  end

  def view
    @views[ Thread.current ] || @parent.view
  end
  delegate :content_tag, :link_to, :to => :view

  protected

  def render_icon
    #content_tag :span, '', :style => 'float: left; margin-right: .5em;', :class => "ui-icon ui-icon-#{ @icon }" if @icon
  end
  def href
    ''
  end
  def render_anchor
    link_to "#{ render_icon }#{ @caption }", href
  end
  def classes
    'ui-tabs-selected ui-state-active'
  end
  def render_item
    content_tag :li, render_anchor#, :class => classes
  end

  def with_view(current_view)
    @views[ Thread.current ] = current_view if current_view
    yield
  ensure
    @views.delete Thread.current
  end

end

class MenuItem < Label
  attr_accessor :caption
  attr_writer :href
  def initialize(attributes)
    super
    @children = Children.new self
  end
  def has_children?
    not @children.empty?
  end
  def render(current_view = nil)
    super { @children.render }
  end
  def href
    @href || "##{ @name }"
  end
  def classes
    "ui-state-default #{ 'fg-button' if has_children? }" if @parent == self
  end

  def add_label(attributes)
    label = Label.new(attributes)
    @children << label
    label
  end
  def add_menuitem(attributes)
    menuitem = MenuItem.new(attributes)
    @children << menuitem
    menuitem
  end

  class Children
    def initialize(parent)
      @parent, @children = parent, []
    end
    def <<(item)
      item.parent = @parent
      @children << item
    end
    def view
      @parent.view
    end
    delegate :content_tag, :to => :view
    delegate :each, :empty?, :to => :@children

    def render
      return '' if empty?

      html = content_tag :ul, @children.map { |c| c.render }.to_s
      content_tag :li, html, :id => @parent.name#, :class => 'hidden'
    end
  end
end
