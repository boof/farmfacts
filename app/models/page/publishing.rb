module Page::Publishing

  def self.included(base)
    base.class_eval do
      after_destroy :depublish
      define_callbacks :before_publish, :after_publish
      define_callbacks :before_depublish, :after_depublish
    end
  end

  def public_path
    Rails.root.join 'public', relative_path
  end
  # Creates or modifies tag and writes public html file.
  def publish
    return false if callback(:before_publish) == false

    public_path.dirname.mkpath unless public_path.dirname.directory?

#    storage.git.tag 'published', @version,
#        :force      => true,
#        :annotated  => true,
#        :message    => "#{ author.name } published #{ href }."

    result = public_path.open('w') { |file| file << clean_html }

    callback(:after_publish)

    result
  end
  # Removes tag and public html file.
  def depublish
    return false if callback(:before_depublish) == false

    git.tag 'published', :delete => true
    result = public_path.unlink

    callback(:after_depublish)

    result
  end

end
