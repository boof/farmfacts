class LanguageNegotiation

  module Extension
    def self.included(base)
      base.around_filter LanguageNegotiation
    end
    # expose methods to controller
  end

  def self.filter(ctrl)
    instance = new ctrl.request

    begin
      instance.negotiate ctrl.send(:locales) || %w[en]
      yield
    ensure
      instance.restore_locale
    end
  end

  def initialize(request)
    @request = request
  end
  def negotiate(locales)
    locales = locales.map { |locale| locale.to_s.downcase }
    languages = locales.map { |locale| locale[0, 2] }.uniq

    accepted_locales.find { |locale|
      if locale.length == 2 and languages.include? locale or locales.include? locale
        I18n.locale = locale
      elsif languages.include? locale[0, 2]
        I18n.locale = locale[0, 2]
      end
    }
  end
  def restore_locale
    I18n.locale = I18n.default_locale
  end

  protected
    delegate :accept_language, :params, :to => :@request

    # << 'de-de,de;q=0.8,en-us;q=0.5,en;q=0.3'
    # german germany
    # german any
    # english us
    # english any
    def accepted_locales
      @accepted_locales ||= begin
        locales = []

        accept_language.to_s.split(',').each do |lang|
          lang, q = lang.split ';', 2
          q = Integer 10 * (q ? Float(q[2, 3]) : 1)

          locales[ q ] ||= []
          locales[ q ] << lang.strip
        end
        locales.flatten!
        locales.compact!
        locales.reverse!

        locale = params['locale'] and
        locales.unshift locales.delete(locale.downcase)

        locales
      end
    end
    # >> ['de-de', 'de', 'en-us', 'en']

end
