## force mount ourselves
Vmdb::Application.routes.draw do
  mount RedhatAccessCfme::Engine, at: "/redhat_access"
end

RedhatAccessCfme::Engine.routes.draw do

  scope '/r/insights' do
    get   '/branch_info',    to: 'telemetry_api#get_branch_info'
    get   '/v1/branch_info', to: 'telemetry_api#get_branch_info'
    post  '/uploads/:id',    to: 'telemetry_api#proxy_upload'
    match '/client_api',     to: 'telemetry_api#proxy' , via: [:all]
    match '/:path',          to: 'telemetry_api#proxy', :constraints => {:path => /.*/}, via: [:all]
  end

  scope '/r/cfme' do
    get   '/system',    to: 'telemetry_api#get_machine_ids'
    get   '/system/:guid',    to: 'telemetry_api#get_machine_id'
  end

  get '/insights(/*path)', to: 'insights#index'
  
end
