Rails.application.routes.draw do
  
  mount Blacklight::Engine => '/'
  #Blacklight::Marc.add_routes(self)
  root to: "catalog#index"
    concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  devise_for :users
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  mount Riiif::Engine => '/image-service', as: 'riiif'

  #to refactor: MVC name not exactly corrent, rather than 'print_scan' do something more semantic
  get 'print/scan/:scan' => 'print_scan#show'
  get 'print/object/:object' => 'print_scan#object'
  get 'edit/document' => 'print_scan#edit'
  post 'edit/confirm' => 'print_scan#confirm'
  post 'edit/submit' => 'print_scan#submit'
  get 'edit/solr_lookup' => 'print_scan#solr_lookup'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
