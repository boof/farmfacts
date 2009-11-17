module ApplicationHelper

  def flag(locale, html_options = {})
    language_code, country_code = locale.split '-', 2
    country_code ||= language_code

    html_options = {} unless Hash === html_options
    html_options = {:alt => locale, :size => '16x11'}.update html_options

    image_tag "flags/#{ country_code }.png", html_options
  end
  def icon(name)
    %Q'<span class="ui-icon ui-icon-#{ name }"></span>'
  end

  def image_icon(basename, size = 16, *classes)
    image_tag "icons/#{ basename }.gif",
        :size => "#{ size }x#{ size }",
        :class => classes * ' '
  end
  def create_navigation_link(type, options)
    basename = case type
    when :bookmark; :page_add
    when :folder; :folder_add
    when :link; :link_add
    when :separator; :separator_add
    else
      return
    end

    id = (parent = options[:in]) ? parent.id : 0
    path = "/protected/navigations/#{ id }.#{ I18n.locale }?type=#{ type }"

    link_to image_icon(basename, 16, *options[:classes]), path,
        :class => :loadsScript
  end

end
