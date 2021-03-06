
require('aurita/controller')

module Aurita
module Main

  class User_Role_Controller < App_Controller

    guard_interface(:list, :perform_add, :perform_delete, :perform_update) { Aurita.user.is_admin? }

    def perform_add
      param[:role_id] = param(:role_id_select) unless param(:role_id)
      super()
    end

    def list
      puts list_string(param(:user_group_id))
    end

    def list_string(user_group_id)
      user = User_Group.load(:user_group_id => user_group_id)
      view_string(:admin_user_role_list, :user => user)
    end

    def perform_delete
      User_Role.delete { |r|
        r.where((User_Role.user_group_id == param(:user_group_id)) & 
                (User_Role.role_id == param(:role_id)))
      }
    end

  end

end
end
