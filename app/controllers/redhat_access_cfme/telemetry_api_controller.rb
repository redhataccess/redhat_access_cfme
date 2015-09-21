#require 'redhat_access_lib'
#require_relative  '../../../services/telemetry_api'

module RedhatAccessCfme

  class PortalClient < RedhatAccessCfme::Telemetry::Client
    def get_machines
      #return (0..9).collect {|i| "cfme-client#{i}"}
      return ['9186bf73-93c1-4855-9e04-2ce3c9f13125','286ef64a-5d9f-49cb-a321-a0b88307d87d']
    end

    # Returns the branch id of the current org/account
    def get_branch_id
      return "ZOMGTESTFROMCFME"
    end

    def get_auth_opts creds
      return {
        user: "XXXX",
        password: "XXXXX",
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }
    end
  end

  class TestLogger
    def initialize logger
      @logger = logger
    end
    def error msg
      @logger.error msg
    end
    def debug msg
      @logger.info msg
    end
  end

  class TelemetryApiController < RedhatAccessCfme::ApplicationController

    STRATA_URL = "https://cert-api.access.redhat.com/r/insights"

    def get_branch_info
      user, pass = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
      Rails.logger.error "TEST #{user}"
      render status: 200, json: { "remote_branch" => "ZOMGTESTFROMCFME", "remote_leaf" => user }
    end

    def get_file_data params
      return {
        :file => params[:file],
        :filename => params[:file].original_filename
      }
    end

    def proxy_upload
      request.query_parameters[:branch_id] = "ZOMGTESTFROMCFME"
      original_method  = request.method
      original_params  = request.query_parameters
      original_payload = request.request_parameters[controller_name]
      resource         = "uploads/#{params[:id]}"

      if params[:file]
        original_payload = get_file_data(params)
      end

      client = PortalClient.new("#{STRATA_URL}", "#{STRATA_URL}", {}, { logger: TestLogger.new(Rails.logger) })

      res = client.call_tapi(original_method,  URI.escape(resource), original_params, original_payload, nil)
      render status: res[:code] , json: res[:data]
    end

    # The method that "proxies" tapi requests over to Strata
    def proxy
      original_method  = request.method
      original_params  = request.query_parameters
      Rails.logger.info(
      "Original parameters are #{original_params}")
      if original_params
       # original_params["group"] = 21
      end
      original_payload = request.request_parameters[:telemetry_api]
      resource         = params[:path] == nil ?  "/" : params[:path]

      if params[:filedata]
        original_payload = get_file_data(params)
      end

      client = PortalClient.new("#{STRATA_URL}/r/insights", "#{STRATA_URL}", {}, { logger: TestLogger.new(Rails.logger) })

      # original_params[:account_number] = "000006"
      res = client.call_tapi_no_subset(original_method,  URI.escape(resource), original_params, original_payload, nil)

      Rails.logger.error res
      print_vms
      render status: res[:code] , json: res[:data]
    end


    def print_vms
      #vms = Vm.all
      rhai_files = ['/etc/redhat-access-insights/machine-id']
      vms = Vm.joins(:filesystems).where(:filesystems => {:name => rhai_files})
      options = {
        :userid         => @auth_user,
      }
      myVms = Rbac.filtered(vms, options)

      myVms.each do |a|
        a.filesystems.each do |fs|
          if (fs.name .eql? "/etc/redhat-access-insights/machine-id")
            Rails.logger.info(fs.contents)
          end
        end
      end
      myVms.each { |a| Rails.logger.info(a.name) }
    end


    def print_hosts
      #rhai_files = ['/etc/redhat-access-insights/machine-id']
      #hosts = Host.joins(:filesystems).where(:filesystems => {:name => rhai_files})
      hosts = Host.all
      hosts = Rbac.filtered(hosts, :class => Host, :userid => @auth_user)
      Rails.logger.error(hosts);
      hosts.each do |host|
        host.filesystems.each do |fs|
          Rails.logger.error(fs.name)
        end
      end
    end

  end
end
