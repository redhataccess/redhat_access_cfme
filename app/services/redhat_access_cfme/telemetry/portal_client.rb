module RedhatAccessCfme
  module Telemetry
    class PortalClient < RedhatAccessCfme::Telemetry::Client
      def get_machines
        return (1..9).collect {|i| "CFME_MACHINE_#{i}"}
      end

      # Returns the branch id of the current org/account
      def get_branch_id
        return "ZOMGTESTFROMCFME"
      end

      def get_auth_opts creds
        return { user: "xxxxx", password: "xxxx" }
      end
    end
  end
end
