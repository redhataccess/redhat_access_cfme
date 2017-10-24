module RedhatAccessCfme
  class Engine < ::Rails::Engine
    isolate_namespace RedhatAccessCfme
    
    initializer "redhat_access.mount_engine", :after => :build_middleware_stack do |app|
      app.config.assets.paths << "#{RedhatAccessCfme::Engine.root}/vendor/assets/images"
      app.config.assets.paths << "#{RedhatAccessCfme::Engine.root}/vendor/assets/stylesheets"
      app.config.assets.paths << "#{RedhatAccessCfme::Engine.root}/vendor/assets/fonts"
    end
    assets_to_precompile = [
      'redhat_access_cfme/application.js',
      'redhat_access_cfme/application.css'
    ]
    initializer 'redhat_access.assets.precompile' do |app|
      app.config.assets.precompile += assets_to_precompile
    end

  end
end
