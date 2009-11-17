ActionController::Routing::Routes.draw do |map|

  # insert your routes here...

  map.namespace :protected do |protect|
    protect.resources :logins do |logins|
      logins.with_options :controller => 'roles', :path_prefix => '/protected/logins/:login_id/role' do |login_role|
        login_role.role ':action/:group_id', :group_id => nil
      end
    end

    #protect.resources :navigations, :except => [:index, :new, :edit]
    # protected_navigation_path(folder.id, :locale => I18n.locale, :return_uri => current_uri)
    # protected_navigation_url failed to generate from {:controller=>"protected/navigations", :locale=>"de", :return_uri=>"%2Fprotected%2Fpages", :action=>"show", :id=>"1.2"}, expected: {:controller=>"protected/navigations", :action=>"show"}, diff: {:locale=>"de", :return_uri=>"%2Fprotected%2Fpages", :id=>"1.2"}

    protect.with_options :controller => 'navigations' do |navigations|
      navigations.navigation 'navigations/:id.:locale', :action => 'show', :conditions => {:method => :get}
      navigations.connect 'navigations/:parent_id.:locale', :action => 'create', :conditions => {:method => :post}
      navigations.connect 'navigations.:locale', :action => 'update', :conditions => {:method => :put}
      navigations.connect 'navigations/:id.:locale', :action => 'destroy', :conditions => {:method => :delete}
      navigations.navigations 'pages.:locale', :action => 'index'
    end
    protect.resources :pages, :except => :index

    protect.resources :groups do |groups|
      groups.resources :roles
      groups.resources :logins
    end

    protect.with_options :controller => 'setup' do |setup|
      setup.connect '/setup',
          :action => :new_user, :conditions => { :method => :get }
      setup.connect '/setup',
          :action => :create_user, :conditions => { :method => :post }
    end
  end

  map.resource :login, :member => { :destroy => :get }

end
