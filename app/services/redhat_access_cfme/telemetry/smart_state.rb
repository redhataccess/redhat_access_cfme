module RedhatAccessCfme
  module Telemetry
    module SmartState

      ##########################################################################
      # Given a cfme guid, return a machine_id. 
      # Nil if not found
      ##########################################################################
      def get_vm_machine_id guid
        machine_id_file = ['/etc/redhat-access-insights/machine-id']
        machine_id = nil
        begin
          machine_id = Vm.find_by_guid(guid).filesystems.find_by_name(machine_id_file).contents
        rescue Exception => e
          Rails.logger.warn('No machine_id found for ' + guid)
        end
        return machine_id
      end

      ##########################################################################
      # Given a userid, return a hash of cfme guid=>machine_id. 
      # Empty hash if none found
      ##########################################################################
      def get_users_machine_ids userid
        current_user_vms = Rbac.filtered(Vm.all, {:userid => userid})
        machine_id_guid_hash = Hash.new()
        current_user_vms.each do |vm|
          machine_id = get_vm_machine_id(vm.guid)
          if machine_id
            machine_id_guid_hash[vm.guid] = machine_id
          end
        end
        return machine_id_guid_hash
      end

    end
  end
end
