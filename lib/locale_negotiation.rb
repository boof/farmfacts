class LocaleNegotiation
  AVAILABLE_LOCALES = I18n.available_locales.map { |sym| sym.to_s }

  def self.filter(ctrl)
    instance = new ctrl.request

    begin
      instance.negotiate
      yield
    ensure
      instance.restore_locale
    end
  end

  def initialize(request)
    @request          = request
    @default_locale   = I18n.locale
  end
  def negotiate
    best = accepted_locales.
        find { |locale| AVAILABLE_LOCALES.include? locale }

    I18n.locale = best if best
  end
  def restore_locale
    I18n.locale = I18n.default_locale
  end

  protected
    delegate :accept_language, :params, :to => :@request

    # << 'de-de,de;q=0.8,en-us;q=0.5,en;q=0.3'
    def accepted_languages
      @accepted_languages ||= begin
        sorted = [ params.values_at('language') ]

        "#{ accept_language }".split(',').each do |lang|
          lang, q = lang.split ';', 2
          q = Integer 10 * (q ? Float(q[2, 3]) : 1)

          sorted[ q ] ||= []
          sorted[ q ] << lang.strip
        end
        sorted.flatten!
        sorted.compact!

        sorted
      end
    end
    # >> ['de-de', 'de', 'en-us', 'en']

    # << ['de-de', 'de', 'en-us', 'en']
    def accepted_locales
      @accepted_locales ||= accept_language.
          map { |language| language[0, 2] }.
          uniq
    end
    # >> ['de', 'en']

end
