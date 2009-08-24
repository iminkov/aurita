
require('lore')
require('aurita/base/exceptions')
Aurita.import_module :gui, :form_generator

module Aurita

  module Base_Controller_Methods

    HTTP_STATUS_CODES = { 302 => 'REDIRECT', 
                          200 => 'FOUND', 
                          400 => 'NOT_FOUND' }

    @@form_generator = Aurita::GUI::Form_Generator
    
    public

    # Wrapper for this controller's Aurita::Attributes 
    # instance 
    # Returns value for given request parameter name. 
    # 
    # Example: 
    # Request is 
    #
    #   [public.article.article_id] = 123
    #   [viewmode] = 'table'
    #
    #   param(:viewmode)     --> 'table'
    #   param(:article_id)   --> '123'
    #
    def param(key)
      @params[key]
    end

    def load(klass_name) # :nodoc:
    # {{{
      namespaces = klass_name.to_s.split('::')
      @klass = Aurita.const_get(namespaces[0])
      namespaces[1..-1].each { |ns|
        @klass = @klass.const_get(ns)
      }
    end # def }}}

    protected

    # Raise an Aurita::User_Runtime_Error. 
    # Expects a language key to be translated for 
    # user interfaces. 
    #
    # Example: 
    #
    #    runtime_error(:username_already_exists)
    #
    # raises Exception with message
    #
    #    'This user name already exists. Please choose another one.'
    #
    def runtime_error(tag)
      raise Aurita::User_Runtime_Error.new(tag)
    end
    
    # Raise an Aurita::User_Runtime_Error. 
    # Expects a language key to be translated for 
    # user interfaces. 
    #
    # Usage: 
    #
    #   validation_error(User_Group.user_group_name => tl(:must_be_longer_than_3_characters), 
    #                    User_Login_Data.pass => tl(:must_contain_numbers))
    #
    # Example: 
    #
    #    runtime_error(:username_already_exists)
    #
    # raises Exception with message
    #
    #    'This user name already exists. Please choose another one.'
    #
    def validation_error(params={})
      klass = params[:model]
      klass = @klass unless klass
      params.each_pair { |clause,message|
        errors[clause.table_name] = Invalid_Parameters.new(clause.field_name => message)
      }
      raise Lore::Exception::Invalid_Klass_Parameters.new(klass, errors)
    end

    # Raise an Aurita::Type_Validation_Error. 
    # Expects a language key to be translated for 
    # user interfaces. 
    #
    # Usage: 
    #
    #   type_error(Content.created => tl(:must_be_timestamp), 
    #              Content.user_group_id => tl(:expected_integer))
    #
    def type_error(params)
      klass = params[:model]
      klass = @klass unless klass
      params.each_pair { |clause,message|
        # Resolve expected type by looking it up in model
        expected_type = klass.get_types[clause.to_s] 
        errors[clause.table_name] = Invalid_Types.new(clause.field_name => expected_type)
      }
      raise Lore::Exception::Invalid_Klass_Parameters.new(klass, errors)
    end

    # Load model instance identified by primary key attribute 
    # values in request parameters (@params). 
    #
    # Example: 
    # Request is
    #
    #   [controller] Wiki::Article
    #   [article_id] 123
    #
    # If there is only one primary key defined in the model klass, 
    # attribute 'id' can be used in request, too. This is needed 
    # for REST protocol: 
    #
    #   [controller] Wiki::Article
    #   [id] 123
    #
    # load_instance would look up instance like: 
    #
    #   Wiki::Article.load(:article_id => 123)
    #
    # This is very useful, as this method also works for 
    # polymorphic controller methods. It is thus recommended to 
    # use load_instance instead of loading model instances 
    # manually. 
    # 
    # Example: 
    #
    #   class Article_Controller < Aurita::Plugin_Controller
    #     def perform_commit_version
    #       article = load_instance
    #       # Modify aricle
    #     end
    #   end
    #  
    #   class Memo_Article_Controller < Article_Controller
    #     # no need to overload perform_commit_version as 
    #     # it automatically operates on model Memo_Article
    #   end
    #   
    #
    def load_instance(klass=nil) 
    # {{{
      klass = @klass if klass.nil?
      instance = klass.load(@params)
      raise ::Exception.new('Unable to load instance') unless instance
      return instance
    end # def }}}
    
    # Updates attributes of model instance with values 
    # in request parameters (@params). 
    # Either a model instance to be updated is passed, 
    # or it is resolved using #load_instance. 
    #
    def update_instance(inst=nil)
    # {{{
      inst         ||= load_instance
      instance_attr  = inst.class.get_fields_flat
      ignored_params = [:action, :mode, :controller, :_session, :_request]
      log('Known attributes: ' << instance_attr.inspect)
      @params.each_pair { |param_name, param_value| 
        if param_name.to_s != '' && !(ignored_params.include?(param_name.to_sym)) then
          param_name = param_name.to_sym
          # only update attributes (that is: Skip primary keys)
          if instance_attr.include?(param_name)  then
            inst[param_name] = param_value
            log('Setting ' << param_name.to_s << ' : ' << param_value.to_s)
          elsif(instance_attr.include?(param_name.to_s.split('.').last)) then
            log('Setting ' << param_name.to_s << ' : ' << param_value.to_s)
            inst.set_attribute_value(param_name, param_value)
          end
        end
      }
      return inst
    end # }}}

    public

    # Default implementation of creation routine on a 
    # business object. 
    #
    # If not overloaded, this method implements the following 
    # procedure: 
    #
    #   - Load model klass for this controller
    #   - Create a new instance of this model klass using 
    #     given request parameters (@params)
    #
    # As controller methods are invoced via App_Controller.call_guarded, 
    # errors are handled there. 
    #
    def perform_add() 
    # {{{
      if !@klass then
        model_klass_name = self.to_s.gsub('_Controller','')
        model_klass = eval(model_klass_name)
        @klass = model_klass 
      end
      log('perform_add -->')
      @klass_instance = @klass.create(@params)
      log(@params.inspect)
      log('perform_add <--')
      return @klass_instance
    end # def }}}
    
    # Default implementation of update routine on a 
    # business object. 
    #
    # If not overloaded, this method implements the following 
    # procedure: 
    #
    #   - Load model klass for this controller
    #   - Load instance from model klass, identified by primary 
    #     key attribute values in request parameters (@params). 
    #   - Update this instance using given request parameters (@params)
    #
    # As controller methods are invoced via App_Controller.call_guarded, 
    # errors are handled there. 
    #
    def perform_update() 
    # {{{
      @klass_instance = load_instance() 
      @klass_instance = update_instance(@klass_instance)
      @klass_instance.commit()
    end # def }}}

    # Default implementation of deletion routine on a 
    # business object. 
    #
    # If not overloaded, this method implements the following 
    # procedure: 
    #
    #   - Load model klass for this controller
    #   - Load instance from model klass, identified by primary 
    #     key attribute values in request parameters (@params). 
    #   - Call this instance's delete method. 
    #
    # As controller methods are invoced via App_Controller.call_guarded, 
    # errors are handled there. 
    #
    def perform_delete() 
    # {{{
      @klass_instance = load_instance()
      @klass_instance.delete()
      @klass_instance = nil
    end # def }}}

    def invalidate_cache() # :nodoc:
      @klass.invalidate_all()
    end

    protected

    # Set HTTP response header entries. 
    # Example: 
    #
    #   set_http_header('type' => 'application/x-pdf')
    #
    def set_http_header(args={})
      @response[:http_header] = {} unless @response[:http_header]
      @response[:http_header].update(args)
    end

    # Set an HTTP status code. 
    # Example: 
    #
    #   set_http_status(400)
    #
    #   set_http_status(302, 'Location' => 'http://somewhere.com')
    #
    # Note: Use method redirect_to for latter case. 
    #
    def set_http_status(status_code, params={})
      status_code = HTTP_STATUS_CODES[status_code]
      set_http_header('status' => status_code)
      set_http_header(params)
    end

    # Set HTTP response header entry for content type. 
    # Example: 
    #
    #   set_content_type('application/x-pdf')
    #
    def set_content_type(type)
      set_http_header('type' => type)
    end

    # Ajax redirect. 
    #
    #
    def redirect_to(params={})
      params[:controller] = controller_name() unless params[:controller]
      params[:action]     = :show unless params[:action]

      url = "#{params[:controller]}/#{params[:action]}/"
      target   = params[:target]
      target ||= params[:element]
      params.delete(:controller)
      params.delete(:action)
      params.delete(:target)
      params.delete(:element)
      
      if params.size > 0 then
        get_params = []
        params.each_pair { |k,v|
          get_params << "#{k}=#{v}"
        }
      end
      if target then
        url << get_params.join('&') if get_params
        exec_js("Aurita.load({ action: '#{url}', element: '#{target}' });")
      else
        url << get_params.join('--') if get_params
        exec_js("Aurita.set_hashcode('#{url}');")
      end
    end


    # Redirect to controller method or URL using an HTTP 302 
    # status code. 
    #
    # Examples: 
    #
    #   http_redirect_to('http://somewhere.com')
    #
    #   http_redirect_to(:controller => 'Wiki::Article', :action => :show, :id => 123)
    #
    # If no controller is given, this controller is assumed. 
    # So within Wiki::Article_Controller, you can also use: 
    #
    #   http_redirect_to(:action => :show, :id => 123)
    #
    # All result in an HTTP header entry like: 
    #
    #   HTTP/1.1 302 Found
    #   Location: http://yourserver.com/aurita/Wiki::Article/show/id=123
    #
    # In case you redirect to a method in this controller without 
    # passing any params, it's sufficient to only name the method 
    # (as Symbol): 
    #
    #   redirect_to(:list)
    #
    def http_redirect_to(target)
    # {{{
      url = ''
      if target.is_a?(Hash) then
        get_args = '' 
        target.each_pair { |k,v| 
          get_args << "#{k}=#{v}&" unless [ :controller, :action ].include?(k)
        }
        # Inherit decorator from original call
        target[:mode]       = param(:mode) unless target[:mode]
        target[:controller] = short_model_name unless target[:controller]
        url = "/aurita/#{target[:controller]}/#{target[:action]}/#{get_args}"
      elsif target.is_a?(String) then
        url = target
      elsif target.is_a?(Symbol) then
        url = "/aurita/#{short_model_name}/#{target}/"
      end
      set_http_status(302, { 'Location' => url })
    end # }}}

    # Upload a file from CGI multipart request. 
    # Example (file form field has name 'file_to_upload'): 
    #
    #   upload_file(:form_file_tag_name => :file_to_upload, 
    #               :relative_path      => :uploads, 
    #               :server_filename    => 'document')
    #
    # File would be uploaded to <project dir>/public/assets/tmp/uploads/document
    #
    def upload_file(params)
    # {{{
      
      form_file_tag_name = params[:form_file_tag_name]
      relative_path      = params[:relative_path]
      server_filename    = params[:server_filename]

      info = Hash.new

      begin

        tmpfile = @request.params[form_file_tag_name.to_s].first
        server_filename    = sanitize_filename(tmpfile.original_filename) unless server_filename        
        if server_filename.to_s == '' then 
          filename = sanitize_filename(tmpfile.original_filename)
        else
          filename = server_filename
        end
        filetype  = tmpfile.content_type
        
        if tmpfile.instance_of? Tempfile then
        # Fix permissions of tempfile in CGI's tmp/ directory: 
          File.chmod(0777, tmpfile.local_path)
        end
        path_to = Aurita.project_path + '/public/assets/tmp/'
        path_to   += relative_path+'/' if relative_path
        path_to   += filename

        path_to.gsub!('//','/')

        if tmpfile.instance_of?(StringIO) then
          local_path        = nil # not existing, not needed
          original_filename = tmpfile.original_filename
        elsif tmpfile.instance_of?(Tempfile) then
          local_path        = tmpfile.local_path
          original_filename = tmpfile.original_filename
        end
        Aurita.log 'UPLOAD: tmpfile ' << tmpfile.inspect
        Aurita.log 'UPLOAD: path_to ' << path_to.inspect
        Aurita.log 'UPLOAD: original_filename ' << original_filename.inspect
        Aurita.log 'UPLOAD: local_path ' << local_path.inspect
        Aurita.log 'UPLOAD: filetype ' << filetype.inspect
        Aurita.log 'UPLOAD: info ' << info.inspect
        
        info[:type] = filetype.gsub("\r",'').gsub("\n",'').gsub(' ','')
        info[:original_filename] = sanitize_filename(tmpfile.original_filename)
        info[:server_filename] = relative_path.to_s + '/' + filename
        info[:server_filepath] = path_to.to_s
        Aurita.log 'UPLOAD: info ' << info.inspect

        if tmpfile.instance_of? Tempfile then
          FileUtils.copy(local_path, path_to)
        else 
          File.open(path_to.untaint, 'w') { |file| 
            File.chmod(0777, path_to)
            file << tmpfile.string
          }
        end
        GC.enable
        GC.start
        GC.disable
        info[:filesize] = File.size(path_to.to_s)
      
        return info

      rescue => excep
        GC.enable
        GC.start
        GC.disable
        raise excep
      end
    end # }}} 

    private

    def sanitize_filename(str) # :nodoc:
      return str.split('/')[-1].split('\\')[-1].downcase.gsub(/(\s)+/,'_')
    end

    public

    # Renders GUI::Form instance into HTML part of response 
    # using method Base_Controller.form_string. 
    # Example: 
    #
    #   form = add_form
    #   render_form(form, :template => :special_template)
    #
    def render_form(form, params={})

      @response[:html] << GUI::Async_Form_Decorator.new(form)
      return

    # WAS: 
      @response[:html] << form_string(form, params)
    end

    def decorate_form(form)
      GUI::Async_Form_Decorator.new(form)
    end

    # Set custom form generator klass. 
    #
    def use_form_generator(fg_klass)
      @@form_generator = fg_klass
    end

    # DEPRECATED! Should be replaced by just returning 
    # a form instance wherever found! 
    #
    # Renders form instance to a string using method 
    # Base_Controller.view_string. 
    def form_string(form, params={})
    # {{{
      template   = params[:template] 
      template ||= :form_section if params[:title]
      template ||= :form 
      params[:form] = form
      view_string(template, params)
    end # }}}

    # Helper method for form generator (default: Aurita::GUI::Form_Generator, 
    # set in Aurita::Main::Base_Controller). 
    #
    # Generates a form for this controller's  model klass, derived from 
    # controller name (Foo_Controller -> model Foo). 
    #
    # Parmeters are: 
    #
    # - :model
    #   The model klass to generate the form for, in case it 
    #   differs from the default one. 
    # - :action
    #   Controller action to invoke (e.g. :perform_update). 
    # - :instance 
    #   The model instance used to populate form fields. 
    #
    # Example: 
    #
    #   form = model_form(:instance => inst, :action => :move)
    #
    # Returns configured instance of Aurita::GUI::Form. 
    # You might want to adjust this instance after generation for your 
    # specific purposes. 
    #
    def model_form(params={})
    # {{{
      method     = params[:action]
      instance   = params[:instance]
      klass      = params[:model]
      klass    ||= @klass

      custom_elements = {}
      log { "Custom Form Elements: #{custom_form_elements.inspect}" }
      custom_form_elements.each_pair { |clause, value|
        clause_parts = clause.to_s.split('.')
        table  = clause_parts[0..1].join('.')
        attrib = clause_parts[2]
        custom_elements[table] = Hash.new unless custom_elements[table]
        custom_elements[table][attrib.to_sym] = value
      }
      view = @@form_generator.new(klass)
      view.labels = Lang[plugin_name]
      view.custom_elements = custom_elements
      form = view.form

      form.add(GUI::Hidden_Field.new(:name => :action, :value => method.to_s, :required => true)) if method
      form.add(GUI::Hidden_Field.new(:name => :controller, :value => klass.model_name.to_s, :required => true))
      
      form_values = {}
      default_form_values.each_pair { |attrib, value|
        form_values[attrib.to_s] = value
      }

      if instance then
        instance.attribute_values.each { |table, args| 
          args.each { |name, value|
            form_values["#{table}.#{name}"] = value
          }
        }
        klass.get_primary_keys.each { |table, keys|
          keys.each { |key|
            pkey_field_name = "#{table}.#{key}"
            form.add(GUI::Hidden_Field.new(:name     => pkey_field_name, 
                                           :value    => instance.attribute_values[table][key], 
                                           :required => true))
          }
        }
      end
      
      if(defined? form_groups) then
        form.fields = form_groups.flatten
      end

      form.set_values(form_values)
      title_key  = (klass.table_name).gsub('.','--')+'--add'
      form.title = (Lang[plugin_name][title_key]) unless Lang[plugin_name][title_key] == title_key
      klassname  = @klass.to_s.gsub('Aurita::','').gsub('Main::','').gsub('Plugins::','').gsub('::','__').downcase
      form.name  = klassname + '_' << method.to_s + '_form'
      form.id    = klassname + '_' << method.to_s + '_form'

      log('Update form fields: ' << form.fields.inspect)
      log('Update form elements: ' << form.element_map.keys.inspect)
      return form
    end # def }}}

    # Returns plain form object for a model instance identified by 
    # controller request parameters. 
    # Almost the same as #update_form() but does not set any 
    # dispatcher attributes (like 'controller' and 'method'). 
    #
    # This is useful for non-CRUD operations: 
    #
    #    form = instance_form(:model => Article)
    #    form.add(Hidden_Field.new(:name => 'controller', :value => 'Article_Version'))
    #    form.add(Hidden_Field.new(:name => 'method',     :value => 'perform_add'))
    #
    #
    def instance_form(params={})
    # {{{
      klass = params[:model]
      klass ||= @klass
      params[:instance] = load_instance(klass) unless params[:instance]
      model_form(params)
    end # }}}

    # Returns a preconfigured form for adding a 
    # instance of the model klass associated to this controller. 
    # 
    # For working with form objects, see Aurita::GUI::Form. 
    #
    def add_form(klass=nil) 
    # {{{
      form = model_form(:model => klass, :action => :perform_add)
      return form
    end # def }}}

    # Returns a preconfigured form for updating a 
    # instance of the model klass associated to this controller. 
    # 
    # For working with form objects, see Aurita::GUI::Form. 
    #
    def update_form(klass=nil) 
    # {{{
      form = model_form(:model => klass, :action => :perform_update, :instance => load_instance(klass))
      return form
    end # def }}}

    # Returns a preconfigured form for deleting a 
    # instance of the model klass associated to this controller. 
    # 
    # For working with form objects, see Aurita::GUI::Form. 
    #
    def delete_form(klass=nil) 
    # {{{
      form = model_form(:model => klass, :action => :perform_delete, :instance => load_instance(klass))
      form.readonly! 
      return form
    end # def }}}

    def show(klass=nil) 
    # {{{
      form = model_form(:model => klass, :instance => load_instance(klass))
      form.readonly! 
      puts form.string
    end # def }}}

    # Default method for adding a model instance. 
    # Renders Aurita::GUI::Form instance returned by #add_form(). 
    def add(klass=nil) 
    # {{{
      klass     = @klass if klass.nil?
      form      = model_form(:klass => @klass, :action => :perform_add)
      render_form(form)
    end # def }}}

    # Default method for updating a model instance. 
    # Renders Aurita::GUI::Form instance returned by #update_form(). 
    def update(klass=nil) 
    # {{{
      klass     = @klass if klass.nil?
      instance  = load_instance(klass)
      form      = model_form(:klass => @klass, :instance => instance, :action => :perform_update)
      render_form(form)
    end # def }}}

    # Default method for deleting a model instance. 
    # Renders Aurita::GUI::Form instance returned by #delete_form(). 
    def delete(klass=nil) 
    # {{{
      klass     = @klass if klass.nil?
      instance  = load_instance(klass)
      form      = model_form(:klass => @klass, :instance => instance, :action => :perform_delete)
      form.readonly! 
      render_form(form)
    end # def }}}

  end # class

end # module

