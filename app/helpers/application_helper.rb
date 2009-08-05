module ApplicationHelper

  def icon(name)
    %Q'<span class="ui-icon ui-icon-#{ name }" style="left: .5em; margin: -8px 5px 0 0; position: absolute; top:50%;"></span>'
  end

end
