require 'rest_client'

module RedhatAccessCfme
  module Telemetry
    SUBSETTED_RESOURCES = {
      "reports" => true,
      "systems" => true,
      "systems/status" => true
    }

    class Client

      RestClient.log =
      Object.new.tap do |proxy|
        def proxy.<<(message)
          Rails.logger.debug message
        end
      end

      def initialize upload_url, api_url, creds, optional
        @creds      = creds
        @upload_url = upload_url
        @api_url    = api_url
        @subset_url = "#{@api_url}/subsets"
        @subset_leaf_type = "machine_ids"

        if optional
          @logger = optional[:logger]
          @http_proxy = optional[:http_proxy] if optional[:http_proxy]
          @user_agent = optional[:user_agent] if optional[:user_agent]
        end
        ldebug ("HTTP proxy is set to #{@http_proxy}")
      end

      def post_upload original_params, original_payload
        call_tapi 'POST', '/', original_params, original_payload, { do_upload: true }
      end

      def call_tapi_no_subset original_method, resource, original_params, original_payload, extra
        ldebug ("Called no subset proxy")
        call_tapi original_method, resource, original_params, original_payload, extra, true
      end

      def call_tapi original_method, resource, original_params, original_payload, extra, no_subset = false
        begin
          if SUBSETTED_RESOURCES.has_key?(resource) and not no_subset
            ldebug "Doing subset call to #{resource}"
            response = do_subset_call(resource, { params: original_params, method: original_method, payload: original_payload })
            return { data: response, code: response.code }
          else
            if extra and extra[:do_upload]
              url = @upload_url
            else
              url = "#{@api_url}/#{resource}"
            end

            ldebug "Doing non subset call--- to #{url}"
            client = default_rest_client(url, { params: original_params, method: original_method, payload: original_payload })
            response = client.execute
            return { data: response, code: response.code }
          end
        rescue RestClient::ExceptionWithResponse => e
          lerror nil, "Caught HTTP error when proxying call to tapi: #{e}"
          return { data: e.response, error: e, code: e.response.code }
        rescue Exception => e
          lerror e, "Caught unexpected error when proxying call to tapi: #{e}"
          return { data: e, error: e, code: 500 }
        end
      end

      private

      def ldebug message
        if @logger
          @logger.debug "#{self.class.name}: #{message}"
        end
      end

      def lerror e, message
        if @logger
          @logger.error "#{self.class.name}: #{message}"
          if e
            @logger.error e.backtrace.join("\n")
          end
        end
      end

      def do_subset_call resource, conf
        ldebug "Doing subset call"
        # Try subset
        begin
          url = build_subset_url(resource)
          ldebug "url: #{url}"
          client = default_rest_client url, conf
          response = client.execute
          ldebug "First subset call passed, CACHE_HIT"
          return response
        rescue RestClient::ExceptionWithResponse => e

          if  e.response && e.response.code == 412
            create_subset

            # retry the original request
            ldebug "Subset creation passed calling newly created subset"
            response = client.execute
            return response
          else
            raise e
          end
        end
      end

      def create_subset
        ldebug "First subset call failed, CACHE_MISS"
        subset_client = default_rest_client @subset_url, {
          :method => :post,
          payload: {
            hash: get_hash(get_machines),
            branch_id: get_branch_id,
            @subset_leaf_type => get_machines
          }.to_json
        }
        response = subset_client.execute
      end

      # Transforms the URL that the user requested into the subsetted URL
      def build_subset_url url
        url = "#{@subset_url}/#{get_hash(get_machines)}/#{url}"
        ldebug "build_subset_url #{url}"
        return url
      end

      # Returns an array of the machine IDs that this user has access to
      # def get_machines
      #  raise NotImplementedError
      # end

      # Returns the UUID for this branch
      # def get_branch_id
      #  raise NotImplementedError
      # end

      # Returns the machines hash used for /subset/$hash/
      def get_hash(machines)
        branch = get_branch_id
        hash   = Digest::SHA1.hexdigest(machines.join)
        return "#{branch}__#{hash}"
      end

      def default_rest_client(url, override_options)

        opts = {
          :method   => :get,
          :url      => url,
        }
        opts[:proxy] = @http_proxy unless @http_proxy.nil? || @http_proxy == ""
        opts = opts.merge(get_auth_opts(@creds))
        opts = opts.merge(override_options)
        if override_options[:params]
          opts[:url] = "#{url}?#{override_options[:params].to_query}"
          override_options.delete(:params)
        end
        if override_options[:method] == :post and override_options[:payload]
          opts[:headers] = ensure_content_type(opts)
        end
        if not opts[:headers]
          opts[:headers] = {}
        end
        if @user_agent
          opts[:headers] = opts[:headers].merge({:user_agent => @user_agent})
        end
        RestClient::Request.new(opts)
      end


      def ensure_content_type(opts)
        # TODO we should probably not force here.
        # I would rather throw an exception if nothing is provided
        # Or even just let it POST w/o anything and have upstream fail
        if not opts[:headers]
          return opts[:headers] = {'content-type' => 'application/json', 'accept' => 'application/json'}
        end
      end
    end

  end
end
