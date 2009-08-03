class Protected::Base < ApplicationController

  anonymous do |ctrl|
    ctrl.instance_eval do
      return_uri = request.request_uri unless request.post?
      redirect_to new_login_path(:return_uri => return_uri)
    end
  end
  layout 'protected'

end
