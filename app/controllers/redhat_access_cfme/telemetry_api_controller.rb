require 'redhat_access_lib'
require_dependency "redhat_access_cfme/version"

module RedhatAccessCfme
  class TelemetryApiController < RedhatAccessCfme::ApplicationController
    include RedhatAccessCfme::Telemetry::MiqApi

    SUBSET_LIST_TYPE_KEY =   RedHatSupportLib::TelemetryApi::SUBSET_LIST_TYPE_KEY
    SUBSET_LIST_TYPE = RedHatSupportLib::TelemetryApi::SUBSET_LIST_TYPE_MACHINE_ID

    def get_branch_info
      render :status => 200, :json => {:branch_id => current_server_guid}
    end

    def get_machine_id
      # 0d64ee48-61eb-11e5-a3fa-001a4ad54000
      guid = params[:guid]
      machine_id = get_vm_machine_id(guid)
      if machine_id
        render :status => 200, :json => {:machine_id => machine_id}
      else
        render :status => 404, :json => {:error => "machine_id not found for requested system"}
      end
    end

    def get_machine_ids
      if Rails.env.development?
        if REDHAT_ACCESS_CONFIG[:use_test_vms]
           $log.debug("#{self.class} ids are #{INSIGHTS_TEST_VMS}")
           return INSIGHTS_TEST_VMS[:ids]
        end
      end
      users_machine_ids = get_users_machine_ids(current_user.userid).values
    end

    def get_file_data(params)
      {
        :file     => params[:file],
        :filename => params[:file].original_filename
      }
    end

    def proxy_upload
      request.query_parameters[:branch_id] = current_server_guid
      original_method  = request.method
      original_params  = request.query_parameters
      original_payload = request.request_parameters[controller_name]
      resource         = "uploads/#{params[:id]}"
      if params[:file]
        original_payload = get_file_data(params)
      end

      client = RedhatAccessCfme::Telemetry::PortalClient.new(rhai_service_url,
                                                             rhai_service_url,
                                                             {},
                                                             self,
                                                             :logger              => $log,
                                                             :user_agent          => http_user_agent,
                                                             :headers             => {'content-type' => 'application/json', 'accept' => 'application/json'},
                                                             :http_proxy          => rhai_service_proxy,
                                                             SUBSET_LIST_TYPE_KEY => SUBSET_LIST_TYPE)

      res = client.call_tapi(original_method,  URI.escape(resource), original_params, original_payload, nil)
      render :status => res[:code], :json => res[:data]
    end

    # The method that "proxies" tapi requests over to Strata
    def proxy
      original_method  = request.method
      original_params  = request.query_parameters
      resource         = params[:path].nil? ? "/" : params[:path]
      original_params  = add_branch_to_params(original_params, resource)
      original_payload = request.request_parameters[controller_name]
      if request.post? && request.raw_post
        original_payload = request.raw_post.clone
      end
      if params[:filedata]
        original_payload = get_file_data(params)
      end
      client = RedhatAccessCfme::Telemetry::PortalClient.new(rhai_service_url,
                                                             rhai_service_url,
                                                             {},
                                                             self,
                                                             :logger              => $log,
                                                             :user_agent          => http_user_agent,
                                                             :user_headers        => {'content-type' => 'application/json', 'accept' => 'application/json'},
                                                             :http_proxy          => rhai_service_proxy,
                                                             SUBSET_LIST_TYPE_KEY => SUBSET_LIST_TYPE)

      res = client.call_tapi(original_method, URI.escape(resource), original_params, original_payload, nil)
      # 401 errors means our proxy is not configured right.
      # Change it to 502 to distinguish with local applications 401 errors
      resp_data = res[:data]
      if (res[:code] == 401)
        res[:code] = 502
        resp_data = {
          :message => 'Authentication to the Insights service failed.'
        }
      end
      render :status => res[:code], :json => resp_data
    end

    def add_branch_to_params(params, resource)
      if params.nil?
        params = {}
      end
      if resource and resource.start_with?('acks')
        params[:branch_id] = current_server_guid
      end
      params
    end

    def get_auth_opts
      rhai_service_auth_opts
    end

    def http_user_agent
      "redhat_access_cfme/#{RedhatAccessCfme::VERSION}"
    end
  end
end
