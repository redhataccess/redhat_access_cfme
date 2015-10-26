
if File.exists? ("#{RedhatAccessCfme::Engine.root}/config/config.yml")
  REDHAT_ACCESS_CONFIG = YAML.load_file("#{RedhatAccessCfme::Engine.root}/config/config.yml")
else
  REDHAT_ACCESS_CONFIG = {}
end
