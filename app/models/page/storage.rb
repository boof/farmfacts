class Page::Storage

  WORK_TREE = Rails.root.join('db', 'pages')
  WORK_TREE.mkpath unless WORK_TREE.directory?

  GIT = V.git :work_tree => WORK_TREE
  GIT.init unless WORK_TREE.join('.git').directory?

  def initialize(path, locale)
    @path, @locale = "#{ path }", locale
    @path.slice! 0 if @path[0, 1] == '/'
  end

  def git
    GIT
  end

  def relative_path
    "#{ @path }.#{ @locale }.html".gsub '/', File::SEPARATOR
  end
  def absolute_path
    WORK_TREE.join relative_path
  end
  alias_method :path, :absolute_path

  def store(document)
    absolute_path.dirname.mkpath unless absolute_path.dirname.directory?
    absolute_path.open('w') { |file| file << document }
  end

  # Commits changes to navigation.
  def commit(author, message)
    GIT.add relative_path
    GIT.commit message, :author => "#{ author.name } <#{ author.email }>"
  end

end
