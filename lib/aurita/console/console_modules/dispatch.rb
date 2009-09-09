
require('aurita')

module Aurita
module Console

  # Console module that simulates complete dispatch 
  # run on a CGI request and prints output. 
  #
  # Usage: 
  #
  #    aurita <project name> dispatch [ <Controller> <method> [ param=value param2=value ] ]
  #
  # Default is 
  #
  #    controller: App_Main
  #    method: start
  #
  # Example: 
  #
  #   dispatch Wiki::Article show article_id=123 user_group_id=1
  #
  class Dispatch

    def initialize(argv)
      # Fake a request
      
      params = {}
      params['mode']       = 'default'
      params['controller'] = 'App_Main'
      params['action']     = 'start'
      params['controller'] = argv[0].to_s if argv[0]
      params['action']     = argv[1].to_s if argv[1]

      Aurita.import('handler/dispatcher')

      arg_c = 0
      while argv[2+arg_c] do 
        param = argv[2+arg_c].split('=')
        value = nil
        if param[1] then
          param[1].strip!
          param[0].strip!
          value = [ param[1] ]
          if /\[([^\]])+?\]/.match(param[1]) then
            value = param[1].sub('[','').sub(']','')
            value = value.squeeze(' ').split(',')
          end
        end
        params[param[0]] = value
        arg_c += 1
      end

      puts '============================================================='
      puts 'Dispatching with request parameters: '
      pp params
      puts '============================================================='

      user_group_id   = params['user_group_id'].first if params['user_group_id']

      @old_session_user   = Aurita.session.user
      Aurita.session.user = User_Profile.load(:user_group_id => user_group_id) if user_group_id

      @dispatcher = Aurita::Dispatcher.new()
    end

    def run
      @dispatcher.dispatch(request)
      Aurita.session.user = @old_session_user
    end

    def usage
      "Usage: 
      
          aurita.dispatch [ <Controller> <method> [ param=value param2=value ] ]
      
       Default is 
      
          controller: App_Main
          method: start
      
       Example: 
      
         dispatch Wiki::Article show article_id=123 user_group_id=1
      "
    end

  end

end
end
