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
        #['9186bf73-93c1-4855-9e04-2ce3c9f13125', '286ef64a-5d9f-49cb-a321-a0b88307d87d', 'e388e982-d4ee-43d3-9670-56051b23155b'].sort
        list = @context.get_machine_ids.values.sort
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
