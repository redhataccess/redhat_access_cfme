module RedhatAccessCfme
  module InsightsHelper
    include RedhatAccessCfme::Telemetry::MiqApi
    def rhai_prereqs_met?
      $log.debug("#{self.class} : Checking Insights prerequisites - registration type: #{server_rh_registration_type}")
      (current_server_registered? && (server_rh_registration_type != "rhn_satellite")) || Rails.env.development?
    end
  end
end
