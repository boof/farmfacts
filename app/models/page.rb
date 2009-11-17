class Page < ActiveRecord::Base
  include Localization
  include Authoring
  include Vizard

  attr_reader :page_id
  attr_writer :html_file, :page_id

  validates_presence_of :path

  def relative_href
    "#{ path }.#{ locale }.html"
  end
  def absolute_href
    "/#{ relative_href }"
  end
  alias_method :href, :absolute_href

  protected

    def read_external_html
      if page = Page.find_by_id(@page_id.to_i)
        self.html = page.html
      elsif @html_file
        self.html = @html_file.read
      end
    end
    before_validation :read_external_html

    def remove_prefix
      path.slice! 0 if path[0, 1] == '/'
    end
    before_validation :remove_prefix

    def create_navigation_node
      title_node = document.root.at 'title'
      # p title_node.content
      #navigation.insert title, href
      #navigation.write visitor, "updated link to #{ page.href }"
    end
    after_create :create_navigation_node

    # Parses HTML and returns a hash of git-dirs pointing to their branches.
    def observables
      {}
    end

    # Registers as observer for branch at each observed storage.
    def register_as_git_observer
      observables.each do |git_dir, branch|
        V.git :git_dir => git_dir do |observable|
          observable.observer :register, git, branch
        end
      end
    end
    after_save :register_as_git_observer

    def unregister_as_git_observer
      observables.each do |git_dir, branch|
        V.git :git_dir => git_dir do |observable|
          observable.observer :register, git, branch
        end
      end
    end
    after_destroy :unregister_as_git_observer

end
