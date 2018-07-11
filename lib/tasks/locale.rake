namespace :locale do
  desc "Extract strings from various yaml files and store them in a ruby file for gettext:find"
  task :extract_rh_insights_yaml_strings do
    def update_output(string, file, output)
      return if string.nil? || string.empty?
      if output.key?(string)
        output[string].append(file)
      else
        output[string] = [file]
      end
    end

    def parse_object(object, keys, file, output)
      if object.kind_of?(Hash)
        object.keys.each do |key|
          if keys.include?(key) || keys.include?(key.to_s)
            if object[key].kind_of?(Array)
              object[key].each { |i| update_output(i, file, output) }
            else
              update_output(object[key], file, output)
            end
          end
          parse_object(object[key], keys, file, output)
        end
      elsif object.kind_of?(Array)
        object.each do |item|
          parse_object(item, keys, file, output)
        end
      end
    end

    engine_root = RedhatAccessCfme::Engine.root.to_s
    yamls = {
      "deploy/menubar/*.yml"              => %w(name),
      "deploy/miq_product_features/*.yml" => %w(name description),
      "deploy/miq_shortcuts/*.yml"        => %w(description)
    }
    output = {}

    yamls.keys.each do |yaml_glob|
      Dir.glob("#{engine_root}/#{yaml_glob}").each do |file|
        yml = YAML.load_file(file)
        parse_object(yml, yamls[yaml_glob], file.gsub("#{engine_root}/", ""), output)
      end
    end

    File.open("#{engine_root}/config/rh_insights_yaml_strings.rb", "w+") do |f|
      f.puts "# This is automatically generated file (rake locale:extract_rh_insights_yaml_strings)."
      f.puts "# The file contains strings extracted from various yaml files for gettext to find."
      output.keys.each do |key|
        output[key].sort.uniq.each do |file|
          f.puts "# TRANSLATORS: file: #{file}"
        end
        f.puts 'N_("%s")' % key
      end
    end
  end
end
