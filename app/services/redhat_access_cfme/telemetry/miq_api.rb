module RedhatAccessCfme
  module Telemetry
    module MiqApi

      MACHINE_ID_FILE_NAME = '/etc/redhat-access-insights/machine-id'
      RegistrationConfig = Struct.new(:userid,
                                      :password,
                                      :registration_server,
                                      :registration_type,
                                      :registration_http_proxy,
                                      :registration_http_proxy_username,
                                      :registration_http_proxy_password)

      ##########################################################################
      # Given a cfme guid, return a machine_id.
      # Nil if not found
      ##########################################################################
      def get_vm_machine_id(guid)
        machine_id = nil
        begin
          machine_id = Vm.find_by_guid(guid).filesystems.find_by_name(MACHINE_ID_FILE_NAME).contents
        rescue Exception => e
          Rails.logger.error("No machine_id found for GUID #{guid}")
        end
        return machine_id
      end

      ##########################################################################
      # Given a userid, return a hash of cfme guid=>machine_id.
      # Empty hash if none found
      ##########################################################################
      def get_users_machine_ids(userid)
        Rails.logger.error("Looking up vms for #{userid}")
        current_user_vms = Rbac.filtered(Vm.all, {:userid => userid})
        #Rails.logger.error("VMS are #{current_user_vms}")
        machine_id_guid_hash = Hash.new()
        current_user_vms.each do |vm|
          machine_id = get_vm_machine_id(vm.guid)
          if machine_id
            machine_id_guid_hash[vm.guid] = machine_id
          end
        end
        return machine_id_guid_hash
      end



      def  rh_config
        db = MiqDatabase.first
        return RegistrationConfig.new(
          db.authentication_userid(:registration),
          MiqPassword.try_decrypt(db.authentication_password(:registration)),
          db.registration_server,
          db.registration_type,
          db.registration_http_proxy_server,
          db.authentication_userid(:registration_http_proxy),
          MiqPassword.try_decrypt(db.authentication_password(:registration_http_proxy))
        )
      end

      def current_server_guid
        MiqServer.my_server.guid
      end


      def current_server_registered?
        MiqServer.my_server.rh_registered?
      end

      def server_rh_registration_type
        MiqDatabase.first.registration_type
      end


    end
  end
end
