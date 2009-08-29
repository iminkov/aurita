
require('aurita/controller')

module Aurita
module Main

  class User_Login_Data_Controller < App_Controller
    
    guard_interface(:perform_lock, :perform_unlock, :perform_delete, :perform_add) { 
      Aurita.user.is_admin?
    }
    
    def perform_add
      instance = super()
      cat = Category.create(:category_name => instance.user_group_name)
    end
    
    def form_groups
      [
       User_Group.user_group_name, 
       User_Login_Data.login, 
       User_Login_Data.pass
      ]
    end
    
    def update
      return unless Aurita.user.is_admin? 

      user = User_Profile.load(:user_group_id => param(:user_group_id))
       
      form = view_string(:admin_edit_user, 
                         :user_categories => User_Category_Controller.category_list(user.user_group_id),
                         :user_roles => User_Role_Controller.list_string(user.user_group_id),
                         :user => user)
      page = Page.new(:header => tl(:edit_user)) { form }
      page.add_css_class(:form_section) 
      page
    end
    
    def show
      render_controller(User_Group_Controller, :show)
    end

    # To be called as admin user only
    def perform_update
      return unless Aurita.user.is_admin? 

      instance = load_instance
    
      login = param(:login).gsub("\s",'')
      pass  = param(:pass)
      raise ::Exception.new(tl(:no_login_specified)) if login.to_s == ''

      login_md5 = Digest::MD5.hexdigest(login) if param(:login).to_s.gsub(/\s/,'') != ''
      login_md5 = instance.login unless login_md5
      pass_md5 = Digest::MD5.hexdigest(pass) if param(:pass).to_s.gsub(/\s/,'') != ''
      pass_md5 = instance.pass unless pass_md5

      # Check if selected login is still available
      check = User_Group.find(1).with((User_Group.user_group_name.ilike(login)) & 
                                      (User_Group.user_group_id <=> param(:user_group_id))).entity
      raise ::Exception.new(tl(:login_already_used)) if check

      @params[:pass] = pass_md5
      @params[:login] = login_md5
      @params[:user_group_name] = login

      user = User_Profile.load(:user_group_id => instance.user_group_id)
      user.forename = param(:forename)
      user.surname = param(:surname)
      user.division = param(:division)
      user.tags = param(:tags)
      user.commit

      super()
      exec_js("Aurita.load({ element: 'admin_users_box_body', action: 'User_Profile/admin_box_body/' }); 
               Aurita.load({ element: 'app_main_content', action: 'App_Main/blank/' }); ")
    end

    def perform_lock
      instance = load_instance
      instance['locked'] = true
      instance.commit
      exec_js("Aurita.load({ action: 'User_Login_Data/update/user_group_id=#{instance.user_group_id}' }); ")
    end
    def perform_unlock
      instance = load_instance
      instance['locked'] = false
      instance.commit
      exec_js("Aurita.load({ action: 'User_Login_Data/update/user_group_id=#{instance.user_group_id}' }); ")
    end

    def delete
      puts HTML.h2.critical { tl(:delete_user) }
      form = delete_form
      form.fields = [ User_Group.user_group_name ]
      render_form(form)
    end
    
    def perform_delete
      instance = load_instance
      instance.locked  = true; 
      instance.deleted = true; 
      instance.hidden  = true; 
      instance.commit
      exec_js("Aurita.load({ element: 'app_left_column', action: 'App_Admin/left/' }); 
               Aurita.load({ element: 'app_main_content', action: 'App_Main/blank/' }); ")
    end

  end

end
end
