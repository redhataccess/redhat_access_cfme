require 'redhat_access_lib'
module RedhatAccessCfme
  module Telemetry
    class PortalClient < RedHatSupportLib::TelemetryApi::Client
      include RedhatAccessCfme::Telemetry::MiqApi

      def initialize(upload_url, api_url, creds, context, optional)
        super(upload_url, api_url, creds, optional)
        $log.debug("#{self.class} : API url #{api_url}")
        $log.debug("#{self.class} : UPLOAD url #{upload_url}")
        @context = context
      end

      def get_machines
        list = @context.get_machine_ids.sort
        if list.empty?
          list = ['NULL_SET']
        end
        list
      end

      # Returns the branch id of the current appliance
      def get_branch_id
        current_server_guid
      end

      def get_auth_opts(_creds)
        @context.get_auth_opts
      end
    end
  end
end
