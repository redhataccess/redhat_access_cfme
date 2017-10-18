
if File.exists? ("#{RedhatAccessCfme::Engine.root}/config/config.yml")
  REDHAT_ACCESS_CONFIG = YAML.load_file("#{RedhatAccessCfme::Engine.root}/config/config.yml")
else
  REDHAT_ACCESS_CONFIG = {}
end

if File.exists? ("#{RedhatAccessCfme::Engine.root}/config/test_vm_ids.yml")
    INSIGHTS_TEST_VMS = YAML.load_file("#{RedhatAccessCfme::Engine.root}/config/test_vm_ids.yml")
else
    INSIGHTS_TEST_VMS = {:ids =>[]}
end