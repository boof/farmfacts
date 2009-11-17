module Page::Authoring

  def self.included(base)
    base.class_eval do
      has_many :shares do
        def touch(author) by_author(author).each { |share| share.touch } end
      end
      has_many :authors, :through => :shares, :source => :login
    end
  end

  def author
    authors.last
  end
  def author=(author)
    if authors.include? author
      shares.touch author
    else
      authors << author
    end
  end

end
