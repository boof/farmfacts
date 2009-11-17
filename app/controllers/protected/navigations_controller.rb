class Protected::NavigationsController < Protected::Base

  before_filter :authorized?, :except => :index
  before_filter :set_title

  layout 'protected'

  def index
    @navigation = Navigation.localized
    @pages = Hash.new { |pages, path| pages[path] = [] }
    Page.all(:order => 'locale').each { |page| @pages[page.path] << page }
  end

  def create type = param(:type), parent_id = param(:parent_id)
    navigation = Navigation.localized
    @pages = Hash.new { |pages, path| pages[path] = [] }

    parent = navigation[parent_id]
    case type
    when 'bookmark'
      title = generate_title parent.bookmarks, type
      @node = parent.add_bookmark title, '/'
    when 'folder'
      title = generate_title parent.folders, type
      @node = parent.add_folder title
    when 'link'
      @node = parent.add_alias parent.bookmarks.first
    when 'separator'
      @node = parent.add_separator
    end
    parent.child.add_previous_sibling @node.unlink

    navigation.write visitor, "added #{ type } to #{ parent_id }"

    @parent_id, @type = parent_id, type
  end

  def update
    (attribute, id), value = param(:id).split('-', 2), param(:value)

    navigation = Navigation.localized
    navigation[id].send :"#{ attribute }=", value
    navigation.write visitor, "changed #{ attribute } to #{ value }"

    render :text => value
  end

  def destroy
    navigation = Navigation.localized
    navigation[id].unlink
    navigation.write visitor, "removed #{ id }"

    render :js => "$('entry-#{ id }').remove();"
  end

  protected

    def generate_title(set, type)
      unless set.at(%Q'./#{ type }[title="#{ t "xbel.nodes.#{ type }" }"]')
        translate "xbel.nodes.#{ type }"
      else
        n = 0
        n += 1 while set.at(%Q'./#{ type }[title="#{ t "xbel.nodes.#{ type }_n", :n => n }"]')
        translate "xbel.nodes.#{ type }_n", :n => n
      end
    end

    def set_title
      super 'navigations'
    end

    def authorized?
      visitor.is? 'Author'
    end

end
