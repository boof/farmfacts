ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  map.namespace :protected do |protect|
    protect.resources :logins
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

  map.with_options :conditions => { :method => :get } do |get|
    get.pages '/pages', :controller => 'pages', :action => 'index'
    get.with_options :controller => 'pages', :action => 'show' do |pages|
      pages.root :p => []
      pages.connect '*p'
    end
  end

end
