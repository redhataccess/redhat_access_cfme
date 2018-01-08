require 'redhat_access_lib'
require_dependency 'redhat_access_cfme/version'

module RedhatAccessCfme
  class InsightsController < RedhatAccessCfme::ApplicationController
    include RedhatAccessCfme::Telemetry::MiqApi

    SUBSET_LIST_TYPE_KEY = RedHatSupportLib::TelemetryApi::SUBSET_LIST_TYPE_KEY
    SUBSET_LIST_TYPE = RedHatSupportLib::TelemetryApi::SUBSET_LIST_TYPE_MACHINE_ID

    def index
      client = rest_client
      res = client.call_tapi('GET', 'me', nil, nil, nil)
      Rails.logger.debug(res[:data])
      if res[:code] != 200
        redirect_to "/redhat_access/insights/configure"
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
        file: params[:file],
        filename: params[:file].original_filename
      }
    end

    def me; end

    # The method that "proxies" tapi requests over to Strata
    def proxy
      original_method  = request.method
      original_params  = request.query_parameters
      resource         = params[:path].nil? ? '/' : params[:path]
      original_params  = add_branch_to_params(original_params, resource)
      original_payload = request.request_parameters[controller_name]
      if request.post? && request.raw_post
        original_payload = request.raw_post.clone
      end
      original_payload = get_file_data(params) if params[:filedata]
      client = rest_client
      begin
        res = client.call_tapi(original_method, URI.escape(resource), original_params, original_payload, nil)
        # 401 errors means our proxy is not configured right.
        # Change it to 502 to distinguish with local applications 401/403 errors
        resp_data = res[:data]
        if res[:code] == 401 || res[:code] == 403 
          res[:code] = 502
        end
        if resp_data.respond_to?(:headers)
          if resp_data.headers[:content_disposition]
            send_data resp_data, disposition: resp_data.headers[:content_disposition], type: resp_data.headers[:content_type]
            return
          end
          if resp_data.headers[:x_resource_count]
            response.headers['x-resource-count'] = resp_data.headers[:x_resource_count]
          end
          render status: res[:code], json: resp_data
        else
          render status: res[:code], json: resp_data
        end
      rescue Exception => e
        render status: 500, json: { error: e }
      end
    end

    def add_branch_to_params(params, resource)
      params = {} if params.nil?
      if resource && resource.start_with?('acks')
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

    def rest_client
      RedhatAccessCfme::Telemetry::PortalClient.new(nil,
                                                nil,
                                                {},
                                                self,
                                                :logger              => $log,
                                                :user_agent          => http_user_agent,
                                                :user_headers        => { 'content-type' => 'application/json', 'accept' => 'application/json' },
                                                :http_proxy          => rhai_service_proxy,
                                                SUBSET_LIST_TYPE_KEY => SUBSET_LIST_TYPE)
    end
  end
end
