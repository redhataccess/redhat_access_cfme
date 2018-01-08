## force mount ourselves
Vmdb::Application.routes.draw do
  mount RedhatAccessCfme::Engine, at: "/redhat_access"
end

RedhatAccessCfme::Engine.routes.draw do

  scope '/r/insights' do
    match '/:path',          to: 'insights#proxy', :constraints => {:path => /.*/}, via: [:all]
  end
  get '/insights/configure', to: 'insights#configure'
  get '/insights/help', to: 'insights#help'
  get '/insights(/*path)', to: 'insights#index'
  
end
