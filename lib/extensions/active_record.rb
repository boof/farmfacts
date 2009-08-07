module Extensions::ActiveRecord

  def self.split(path)
    return File.dirname(path), File.basename(path, '.rb')
  end
  def self.each_extension(base)
    dirname, basename = split base::Source
    offset = "#{ Rails.root }/app/models".length

    Dir[ File.join(dirname, basename, '**', '*.rb') ].each do |path|
      yield path[ offset, path.length - offset - 3 ].camelize.constantize
    end
  end
  def self.include_extension(base, extension)
    base.class_eval { include extension }
  end
  def self.included(base)
    each_extension(base) { |extension| include_extension base, extension }
  end

end
