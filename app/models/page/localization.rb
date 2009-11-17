module Page::Localization

  def self.included(base)
    base.class_eval do
      validates_format_of :language_code, :with => Regexp[:'ISO 639-1']
      validates_format_of :country_code, :with => Regexp[:'ISO 3166-1']
    end
  end

  def language_code
    locale.split('-', 2).first
  end
  def country_code
    locale.split('-', 2).reverse.find { |code| code }
  end

end
