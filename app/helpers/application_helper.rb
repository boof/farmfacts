module ApplicationHelper

  def icon(name)
    %Q'<span class="ui-icon ui-icon-#{ name }"></span>'
  end

end
