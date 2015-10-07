require 'redhat_access_lib'
#require_relative  '../../../services/telemetry_api'
module RedhatAccessCfme

  class PortalClient < RedHatSupportLib::TelemetryApi::Client

    def initialize(upload_url,api_url, creds, context, optional)
      super(upload_url,api_url, creds, optional)
      @context = context
    end

    def get_machines
      #return ['9186bf73-93c1-4855-9e04-2ce3c9f13125','286ef64a-5d9f-49cb-a321-a0b88307d87d'].sort
      list = @context.get_machine_ids.values.sort
      if list.empty?
         list = ['NULL_SET']
       end
      list
    end

    # Returns the branch id of the current org/account
    def get_branch_id
      return "ZOMGTESTFROMCFME"
    end

    def get_auth_opts creds
      @context.get_auth_opts
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

    include RedhatAccessCfme::Telemetry::SmartState

    STRATA_URL = "https://cert-api.access.redhat.com/r/insights"

    def get_branch_info
      #user, pass = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
      #Rails.logger.error "TEST #{user}"
      render status: 200, json: {branch_id: "ZOMGTESTFROMCFME"}
    end

    def get_machine_id
      #0d64ee48-61eb-11e5-a3fa-001a4ad54000
      guid = params[:guid]
      machine_id = get_vm_machine_id(guid)
      if machine_id
        render status: 200, json: {machine_id: machine_id}
      else
        render status: 404, json: {error: "machine_id not found for requested system"}
      end
    end

    def get_machine_ids
      users_machine_ids = get_users_machine_ids(current_user.userid)
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

      client = PortalClient.new("#{STRATA_URL}",
                                "#{STRATA_URL}",
                                {},
                                self,
                                { :logger =>TestLogger.new(Rails.logger),
                                  RedHatSupportLib::TelemetryApi::SUBSET_LIST_TYPE_KEY => RedHatSupportLib::TelemetryApi::SUBSET_LIST_TYPE_MACHINE_ID })

      res = client.call_tapi(original_method,  URI.escape(resource), original_params, original_payload, nil)
      render status: res[:code] , json: res[:data]
    end

    # The method that "proxies" tapi requests over to Strata
    def proxy
      original_method  = request.method
      original_params  = request.query_parameters
      original_payload = request.request_parameters[:telemetry_api]
      resource         = params[:path] == nil ?  "/" : params[:path]
      if params[:filedata]
        original_payload = get_file_data(params)
      end
      client = PortalClient.new("#{STRATA_URL}/r/insights", "#{STRATA_URL}", {}, self, { logger: TestLogger.new(Rails.logger) })
      res = client.call_tapi(original_method,  URI.escape(resource), original_params, original_payload, nil)
      Rails.logger.error(res)
      render status: res[:code] , json: res[:data]
    end


    def get_auth_opts
      return {
        user: "XXXXXXXX",
        password: "XXXXXXX",
        verify_ssl: OpenSSL::SSL::VERIFY_NONE
      }
    end

  end
end
