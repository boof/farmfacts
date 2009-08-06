module ApplicationHelper

  def icon(name, state = :default)
    %Q'<span class=".ui-state-#{ state }">%s</span>' %
    %Q'<span class="ui-icon ui-icon-#{ name }"></span>'
  end

end
