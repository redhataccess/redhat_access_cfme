module RedhatAccessCfme
  module InsightsHelper
    include RedhatAccessCfme::Telemetry::MiqApi
    def rhai_prereqs_met?
      true
    end
  end
end
