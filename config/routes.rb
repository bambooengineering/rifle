Rifle::Application.routes.draw do

  constraints :format => :json do
    post 'store/:urn', to: 'searches#store'
    get 'search', to: 'searches#search'
  end

end