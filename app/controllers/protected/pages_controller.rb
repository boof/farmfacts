class Protected::PagesController < Protected::Base

  before_filter :authorized?, :except => [:index, :show]
  before_filter :set_title

  layout 'protected', :except => [:edit, :update]

  def show id = param(:id), version = param(:version, 'HEAD'),
      page = Page.find(id).tap { |page| page.version = version }

    @page = page
    return :show
  end

  def publish id = param(:id), version = param(:version, 'HEAD'),
      page = Page.find(id).tap { |page| page.version = version }

    if page.publish
      redirect_to protected_page_path(page)
    else
      render show(id, version, page)
    end
  end

  def new attributes = param(:page, {}),
      page = Page.vizard(visitor, attributes)

    @page, @pages = page, Page.all(:order => 'path, locale')
    return :new
  end
  def create attributes = param(:page),
      page = Page.new(attributes)

    page.author = visitor

    if page.save
      redirect_to edit_protected_page_path(page, :locale => page.locale)
    else
      render new(attributes, page)
    end
  end

  def edit id = param(:id), version = param(:version, nil)
      page = Page.find(id).tap { |page| page.version = version }

    @page = page
    return :edit
  end
  def update id = param(:id), attributes = param(:page),
      page = Page.find(id).tap { |page| page.attributes = attributes }

    page.author = visitor

    if page.save
      redirect_to protected_pages_path
    else
      render edit(id, page)
    end
  end

  def destroy id = param(:id),
      page = find_and_set(id)

    page.destroy
    redirect_to protected_page_path(id)
  end

  protected

    def set_title
      super 'pages'
    end
    def authorized?
      visitor.is? 'Author'
    end

end
