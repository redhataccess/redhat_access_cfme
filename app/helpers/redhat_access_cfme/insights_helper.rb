module RedhatAccessCfme
  module InsightsHelper
    include RedhatAccessCfme::Telemetry::MiqApi
    def rhai_prereqs_met?
      current_server_registered? || Rails.env.development?
    end
  end
end
