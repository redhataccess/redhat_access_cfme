# require_dependency "redhat_access_cfme/configuration"
module RedhatAccessCfme
  module Telemetry
    module MiqApi
      MACHINE_ID_FILE_NAME = '/etc/redhat-access-insights/machine-id'
      DEFAULT_INSIGHTS_SVC_URL = 'https://cert-api.access.redhat.com/r/insights'
      SM_CERT_FILE = '/etc/pki/consumer/cert.pem'
      SM_KEY_FILE = '/etc/pki/consumer/key.pem'
      SAT6_CA_FILE = '/etc/rhsm/ca/katello-server-ca.pem'
      SAT5_CA_FILE = '/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT'
      RHAI_PINNED_CA = "#{RedhatAccessCfme::Engine.root}/ca/rh_cert-api_chain.pem"

      RegistrationConfig = Struct.new(
        :userid,
        :password,
        :registration_server,
        :registration_type,
        :registration_http_proxy,
        :registration_http_proxy_username,
        :registration_http_proxy_password
      )

      class  ConfigError < StandardError; end

      ##########################################################################
      # Given a cfme guid, return a machine_id.
      # Nil if not found
      ##########################################################################
      def get_vm_machine_id(guid)
        machine_id = nil
        begin
          machine_id = Vm.find_by_guid(guid).filesystems.find_by_name(MACHINE_ID_FILE_NAME).contents
        rescue Exception => e
          # Rails.logger.error("No machine_id found for GUID #{guid}")
        end
        machine_id
      end

      ##########################################################################
      # Given a userid, return a hash of cfme guid=>machine_id.
      # Empty hash if none found
      ##########################################################################
      def get_users_machine_ids(userid)
        # Rails.logger.error("Looking up vms for #{userid}")
        current_user_vms = Rbac.filtered(Vm.all, :userid => userid)
        # Rails.logger.error("VMS are #{current_user_vms}")
        machine_id_guid_hash = {}
        current_user_vms.each do |vm|
          machine_id = get_vm_machine_id(vm.guid)
          if machine_id
            machine_id_guid_hash[vm.guid] = machine_id
          end
        end
        machine_id_guid_hash
      end

      def  rh_config
        db = MiqDatabase.first
        RegistrationConfig.new(
          db.authentication_userid(:registration),
          MiqPassword.try_decrypt(db.authentication_password(:registration)),
          db.registration_server,
          db.registration_type,
          db.registration_http_proxy_server,
          db.authentication_userid(:registration_http_proxy),
          MiqPassword.try_decrypt(db.authentication_password(:registration_http_proxy))
        )
      end

      def  rhai_service_url
        case server_rh_registration_type
        when "sm_hosted"
          return DEFAULT_INSIGHTS_SVC_URL
        when "rhn_satellite6"
          return "https://#{rh_config.registration_server}/redhat_access/r/insights"
        when "rhn_satellite"
          return "https://#{rh_config.registration_server.delete!('XMLPRC')}/redhat_access/r/insights"
        else
          return DEFAULT_INSIGHTS_SVC_URL
        end
      end

      def rhai_service_proxy
        proxy = nil
        if rh_config.registration_http_proxy
          proxy_config = rh_config.registration_http_proxy
          proxy_config = "http://#{proxy_config}" unless proxy_config.start_with?('http')
          uri = URI.parse(proxy_config)
          uri = URI.parse("http://#{proxy_config}") if uri.scheme.nil?
          uri.user = rh_config.registration_http_proxy_username
          uri.password = rh_config.registration_http_proxy_password
          proxy = uri.to_s
        end
        proxy
      end

      def rhai_service_auth_opts
        case server_rh_registration_type
        when "sm_hosted"
          if use_rhai_basic_auth?
            return rhai_basic_auth_opts(RHAI_PINNED_CA)
          end
          Rails.logger.debug("#{self.class} : Using hosted SM cert auth options...")
          rhai_cert_auth_opts_sm(RHAI_PINNED_CA)
        when "rhn_satellite6"
          if use_rhai_basic_auth?
            return rhai_basic_auth_opts(SAT6_CA_FILE)
          end
          Rails.logger.debug("#{self.class} : Using Sat 6 cert auth options...")
          rhai_cert_auth_opts_sm(SAT6_CA_FILE)
        when "rhn_satellite"
          Rails.logger.debug("#{self.class} : Using Sat5 auth options...")
          rhai_basic_auth_opts(SAT5_CA_FILE)
        else
          return rhai_basic_auth_opts(RHAI_PINNED_CA) if use_rhai_basic_auth?
          rhai_cert_auth_opts_sm(RHAI_PINNED_CA)
        end
      end

      def rhai_basic_auth_opts(ca_file)
        Rails.logger.debug("#{self.class} Using basic auth options...")
        raise(ConfigError, "Cant read file #{ca_file}") unless File.readable?(ca_file)
        {
          :user       => rh_config.userid,
          :password   => rh_config.password,
          :verify_ssl => rhai_verify_ssl,
          :ca_file    => ca_file
        }
      end

      def rhai_cert_auth_opts_sm(ca_file)
        [SM_CERT_FILE, SM_KEY_FILE, ca_file].each do |f|
          raise(ConfigError, "Cant read file #{f}") unless File.readable?(f)
        end
        Rails.logger.debug("#{self.class} All cert keys readable")
        {
          :ssl_client_cert => OpenSSL::X509::Certificate.new(File.read(SM_CERT_FILE)),
          :ssl_client_key  => OpenSSL::PKey::RSA.new(File.read(SM_KEY_FILE)),
          :verify_ssl      => rhai_verify_ssl,
          :ssl_ca_file     => ca_file
        }
      end

      def current_server_guid
        MiqServer.my_server.guid
      end

      def current_server_registered?
        MiqServer.my_server.rh_registered?
      end

      def server_rh_registration_type
        MiqDatabase.first.registration_type
      end

      def rhai_service_connection_configured?
        if !current_server_registered? && require_appliance_registration
          return false
        end
      end

      #
      # Move the following methods to our config class so we can read them in
      #
      def use_rhai_basic_auth?
        basic_auth = REDHAT_ACCESS_CONFIG[:use_basic_auth] ? true : false
        Rails.logger.debug("#{self.class} : basic auth config: #{basic_auth}")
        basic_auth
      end

      def rhai_verify_ssl
        verify_peer = REDHAT_ACCESS_CONFIG[:ssl_verify_peer] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
        Rails.logger.debug("#{self.class} : SSL verify peer config : #{verify_peer}")
        verify_peer
      end

      def require_appliance_registration?
        require_reg = REDHAT_ACCESS_CONFIG[:require_appliance_registration] ? true : false
        Rails.logger.debug("#{self.class} : Require registration config: #{require_reg}")
        require_reg
      end
    end
  end
end
