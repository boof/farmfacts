class Regexp

  PREDEFINED = {
    :'ISO 639-1' => /^\w{2}$/i,
    :'ISO 3166-1' => /^\w{2}$/i
  }

  def self.[](name) PREDEFINED.fetch name.to_sym end

end
