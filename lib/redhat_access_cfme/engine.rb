module RedhatAccessCfme
  class Engine < ::Rails::Engine
    isolate_namespace RedhatAccessCfme

    assets_to_precompile = [
      'redhat_access_cfme/application.js',
      'redhat_access_cfme/application.css'
    ]
    initializer 'redhat_access.assets.precompile' do |app|
      app.config.assets.precompile += assets_to_precompile
    end

  end
end
