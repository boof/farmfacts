class PagesController < ApplicationController

  def not_implemented
    render :text => '501 Not Implemented', :status => '501 Not Implemented'
  end

  alias_method :index, :not_implemented
  alias_method :show, :not_implemented

end
