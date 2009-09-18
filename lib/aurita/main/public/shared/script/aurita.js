
var Aurita = {
  last_username: '', 
  username_input_element: '0'
}; 

Aurita.check_if_internet_explorer = function() {
  var nAgt = navigator.userAgent;
  if (nAgt.indexOf("MSIE") != -1) {
    return 1;
  }
  else {
    return 0;
  }
};


Aurita.random = function(length) {
  if(!length) length = 4; 
  return Math.round(Math.random() * Math.exp(10,length)); 
}; 

Aurita.element = function(dom_id) { 
  try { 
    elem = $(dom_id); 
  } catch(e) { 
    elem = false; 
  }
  return elem; 
}; 

Aurita.get_remote_string = function(action, response_fun) { 
  var xml_conn = new XHConn; 
  xml_conn.get_string('/aurita/'+action+'&mode=none', response_fun);
}; 

Aurita.check_username_available = function(result) { 
  if(result.match('true')) { 
      Element.setStyle(Aurita.username_input_element, { 'border-color': '#00ff00' });
  } else { 
      Element.setStyle(Aurita.username_input_element, { 'border-color': '#ff0000' });
  }
};

Aurita.username_available = function(input_element) { 
  if(input_element.value == Aurita.last_username) { return; }
  Aurita.username_input_element = input_element; 
  Aurita.last_username = input_element.value; 
  Aurita.get_remote_string('User_Group/username_available/user_group_name='+input_element.value, 
                           Aurita.check_username_available);
};

Aurita.async_form_submit = function(form_element, params) { 
  context_menu_autoclose = true; 
  target_url   = '/aurita/dispatch'; 
  postVars     = Form.serialize(form_element);

  postVars    += '&mode=async'; 
  // postVarsHash = Form.serialize(form_element, true); 
  
  var xml_conn = new XHConn; 
  element = Aurita.element('dispatcher'); 
  if(params) { onload = params['onload']; }
  xml_conn.connect(target_url, 'POST', Aurita.update_element, element, postVars, onload); 
};

Aurita.handle_form_error = function() { 
  for (var i=0; i < arguments.length; i++) {
    info = arguments[i];
    try { 
      // Get input element by attribute 'name' that is 
      // known from exception: 
      elm  = $$('input[name="' + info.field + '"]').first();
      // Get wrapper by DOM id, which is the same as 
      // the input field's id with '_wrap' appended: 
      wrapper = $(elm.id + '_wrap'); 
      Element.addClassName(wrapper, 'error'); 
      Element.removeClassName(warpper, 'invalid'); 
    } catch(e) { } 
  }
  if(Aurita.context_menu_opened()) { 
    Element.setOpacity('context_menu', 1.0); 
  }
};

Aurita.cancel_form = function(form) { 
  save_all_editors(); 
  if(Aurita.context_menu.is_opened()) { 
    Element.hide('context_menu'); 
    Aurita.context_menu_close(); 
  } 
  else { 
    history.back(); 
  }
  return true; 
}; 

Aurita.submit_form = function(form, params) { 
  save_all_editors(); 
  Aurita.async_form_submit(form, params); 
};

Aurita.waiting_for_file_upload = false; 
Aurita.submit_upload_form = function(form_id) { 
  if(Aurita.waiting_for_file_upload) { 
    alert('Ein anderer Upload ist noch aktiv');
    return false;
  }

  if($('public_media_asset_title') && $('autocomplete_tags') && 
     ($('public_media_asset_title').value == '' || $('autocomplete_tags').value == '')) 
  { 
    alert('Bitte machen Sie alle erforderlichen Angaben'); 
    return false; 
  }
  Aurita.waiting_for_file_upload = true; 

  save_all_editors(); 
  Element.toggle(form_id); 
  
  Element.hide('context_menu'); 
  setTimeout('Aurita.context_menu_close()', 2000); 

  $(form_id).submit(); 
  // Delay closing context menu so form values 
  // remain intact at the moment of submit: 
  Aurita.close_info_badge(); 
  new Effect.SlideDown('file_upload_indicator'); 
  if(!Aurita.context_menu_opened()) { 
    setTimeout('Aurita.after_submit_upload_form()', 2000); 
  }
  return false; 
}; 

Aurita.after_submit_upload_form = function() { 
  Aurita.load({ action: 'Wiki::Media_Asset/after_add' }); 
}; 

Aurita.after_file_upload = function() { 
  if(Aurita.waiting_for_file_upload) {
    new Effect.SlideUp('file_upload_indicator'); 
    Aurita.waiting_for_file_upload = false; 
    Aurita.open_info_badge('Wiki::Media_Asset.after_file_upload');
  }
};

Aurita.info_badge_opened = false; 
Aurita.open_info_badge = function(action) { 
  Aurita.close_info_badge(); 
  Aurita.load({ element: 'info_badge', 
                action: action, 
                onload: function() { new Effect.SlideDown('info_badge'); Aurita.info_badge_opened = true; } });
} 
Aurita.close_info_badge = function() { 
  if(Aurita.info_badge_opened) { 
    new Effect.SlideUp('info_badge');
    Aurita.info_badge_opened = false; 
  }
}

Aurita.form_field_onfocus = function(element_id) { 
  Element.addClassName(element_id+'_wrap', 'focussed' ); 
  Element.addClassName(element_id, 'focussed' );
  return true; 
};

Aurita.form_field_onblur = function(element_id) { 
  Element.removeClassName(element_id+'_wrap', 'focussed' ); 
  Element.removeClassName(element_id, 'focussed' );
  return true; 
};

Aurita.handle_invalid_field = function(element) { 
  Element.addClassName(element, 'invalid');
  Element.addClassName(element.id+'_wrap', 'invalid');
}; 

Aurita.validate_form_field_value = function(element, data_type, required) { 
  if(required && (!element.value || element.value == '')) { 
    Aurita.handle_invalid_field(element); 
    return false; 
  }
  switch(data_type) { 
    // Varchar
    case 1043: break; // every input matches varchar
    case 1015: break; // every input matches varchar[]
  }
  // All tests passed, set to valid state again if 
  // failed before: 
  Element.removeClassName(element, 'invalid');
  Element.removeClassName(element.id+'_wrap', 'invalid');
  Element.removeClassName(element.id+'_wrap', 'error');
  return true; 
};


Aurita.flash = function(mesg) { 
  alert(mesg); 
}

Aurita.hierarchy_node_select_onchange = function(field, attribute_name, level) { 
  Aurita.load({ element: attribute_name + '_' + level + '_next', 
                action : 'Wiki::Media_Asset_Folder/hierarchy_node_select_level/media_folder_id__parent='+field.value+'&level='+(level+1) }); 
  $(attribute_name).value = field.value; 
}


///// XHR ///////////////////////////////

Aurita.update_targets            = {}; 
Aurita.current_interface_calls   = {}; 
Aurita.completed_interface_calls = {}; 
Aurita.last_hashvalue            = ''; 
Aurita.wait_for_iframe_sync      = '0'; 

Aurita.set_ie_history_fix_iframe_src = function(url) 
{ 
  return; // IE REACT
  if(Aurita.wait_for_iframe_sync == '1') { 
    Aurita.wait_for_iframe_sync = '0'; 
  } else { 
    Aurita.wait_for_iframe_sync = '1'; 
  }
  Aurita.ie_history_fix_iframe = parent.ie_fix_history_frame; 
  Aurita.ie_history_fix_iframe.location.href = url; 
};
Aurita.set_hashcode = function(code) 
{
  if(Aurita.check_if_internet_explorer() == 1)
  {
    Aurita.set_ie_history_fix_iframe_src('/aurita/get_code.fcgi?code='+code);
  }
  Aurita.force_load = true; 
  document.location.href = '#'+code;
  Aurita.check_hashvalue(); 
}; 
Aurita.append_hashcode = function(code) { 
    Aurita.force_load = true; 
    document.location.href += '--' + code;
    Aurita.check_hashvalue(); 
}; 


Aurita.after_update_element = function(element) {
  init_all_editors(); 
}; 

Aurita.on_successful_submit = function() { 
  context_menu_close(); 
}; 

Aurita.convert_response = function(xml_conn)
{
  response_text = xml_conn.responseText; 
  response = { error: false, script: false, html: response_text }; 

  response_script = false; 
  if(response_text.substr(0, 6) == '{ html')
  { 
    json_response   = eval('(' + response_text + ')'); 
    response_html   = json_response.html.replace('\"','"'); 
    response_script = json_response.script.replace('\"','"'); 
    response_error  = json_response.error; 
    if(response_error) { 
      response_error = json_response.error.replace('\"','"'); 
    }
  } 
  else if(response_text.substr(0,8) == '{ script' ) 
  {
    json_response   = eval('(' + response_text + ')'); 
    response_html   = ''
    response_error  = false; 
    response_script = json_response.script.replace('\"','"'); 
  } 
  else if(response_text.substr(0,7) == '{ error' ) 
  {
    json_response   = eval('(' + response_text + ')'); 
    response_text   = ''
    response_html   = false; 
    response_script = false; 
    Aurita.update_targets = { }; // Break dispatch chain on error, 
                                 // prohibit further actions in interface
    response_error = json_response.error.replace('\"','"'); 
  } 
  else if(response_text.replace(/\s/g,'') == '') { 
    Aurita.on_successful_submit(); 
  }

  response_debug  = json_response.debug; 
  return { html: response_html, error: response_error, script: response_script, debug: response_debug };
};

Aurita.update_element_silently = function(xml_conn, element, request_method, onload_fun)
{
    if(element) { log_debug('Aurita.update_element_silently ' + element.id); }
    else        { log_debug('Aurita.update_element_silently: Target element undefined!'); }

    response_script = false; 
    response_error = false; 
    if(element) 
    {
      response = Aurita.convert_response(xml_conn); 
      response_html   = response['html']; 
      response_script = response['script']; 
      response_error  = response['error']; 
      response_debug  = response['debug'];
      if(response_debug) { log_debug(response_debug); }

    // When to close context menu (no error and no html response, or target element
    // is not context menu)
      if(!response_error && (!element || !response_html))
      {
        context_menu_close(); 
      } 
      if(response_html) { 
        element.innerHTML = response_html; 
      }
    }
    if(response_script) { eval(response_script); }
    if(response_error)  { eval(response_error);  }

    if(onload_fun) { onload_fun(); }
}; 

Aurita.update_element = function(xml_conn, element, request_method, onload_fun)
{
    if(element) { log_debug('Aurita.update_element ' + element.id); }
    else        { log_debug('Aurita.update_element: No target element'); }

    response = Aurita.convert_response(xml_conn); 
    response_html   = response['html']; 
    response_script = response['script']; 
    response_error  = response['error']; 
    response_debug  = response['debug'];
    // See Cuba::Controller.render_view
    if(element) 
    {
      try { Element.setOpacity(element, 1.0); } catch(e) { }

      if(response_debug) { log_debug(response_debug); }

      // When to close context menu (no error and no html response, or target element
      // is not context menu)
      if(!response_error && (!element || !response_html))
      {
        Aurita.context_menu_close(); 
      } 
      if(response_error) // aurita wants to tell us something
      {
        eval(response_error); 
      }
      element.innerHTML = response_html; 
    }
    if(onload_fun) { 
      onload_fun(element); 
    }
    if(response_script) { eval(response_script); }

    if(Aurita.update_targets) {
      for(var target in Aurita.update_targets) {
        if(Aurita.update_targets[target]) { 
          url = Aurita.update_targets[target].replace('.','/');
          url += '&randseed='+Math.round(Math.random()*100000);
          Aurita.load({ element: target, action: url }); 
        }
      }
      // Reset targets so they will be set in next load/remote_submit call: 
      Aurita.update_targets = null; 
    }
    Aurita.after_update_element(element); 
}; 

Aurita.before_load_url = function(element) { 
  try { Element.setOpacity(element, 0.5); } catch(e) { } 
  try { save_all_editors(); } catch(e) { } 
}

Aurita.current_request = false; 
Aurita.load_url = function(params)
{
  target_id = params['element']; 
  if(!target_id) { target_id = 'app_main_content'; }

  element = Aurita.element(target_id); 

  if(!params['silently']) { 
    log_debug('Before load');
    Aurita.before_load_url(element); 
  }

  if(params['action']) { 
    action_url = params['action'];
    action_url.replace('/aurita/',''); 
    call_arr  = action_url.replace(/([^\/]+)\/([^\/]+)[\/&]?(.+)?/,'$1.$2').replace('/','');
    model     = call_arr.split('.')[0]; 
    method    = call_arr.split('.')[1]; 
    postVars  = 'controller=' + model; 
    postVars += '&action=' + method; 
    if(!params['mode']) { 
      params['mode'] = 'async';
    }
    postVars += ('&mode=' + params['mode'] + '&');
    postVars += action_url.replace(/([^\/]+)\/([^\/]+)[\/&]?(.+)?/,'$3').replace('/',''); 
    interface_url = '/aurita/dispatch'; 
  } 
  else if(params['url']) { 
    interface_url = params['url'];
    postVars      = '';
  }
  if(params['silently']) { 
    update_fun = Aurita.update_element_silently; 
  } 
  else { 
  log_debug('LOAD URL'); 
    update_fun = Aurita.update_element; 
  }

  log_debug("Dispatch interface "+interface_url);
  
  Aurita.update_targets = params['targets']; 
/*
  if(Aurita.current_request) { 
    if(!Aurita.current_request.bComplete) { 
      // Already requesting this URL
      log_debug("Testing request for " + Aurita.current_request.req_url()); 
      if(Aurita.current_request.req_url() == interface_url) { 
// TODO: Verify / test this! 
//      Aurita.current_request.abort(); 
        log_debug("Cancelled request for " + interface_url); 
      }
    }
  }
*/
  var xml_conn = new XHConn; 
//  Aurita.current_request = xml_conn; 
  
  xml_conn.connect(interface_url, 'POST', update_fun, element, postVars, params['onload']); 
}; 

Aurita.load = function(params) {
  try { 
    Aurita.load_url(params); 
  } catch(e) { 
    log_debug(e); 
  } 
  return false; 
}; 

Aurita.load_silently = function(params) {
  try { 
    if(!$(params['element'])) { 
      log_debug('Target for Aurita.load_silently does not exist: '+params['target']+', using default'); 
    }
    params['targets']  = params['redirect_after']; 
    params['silently'] = true; 
    Aurita.load_url(params); 
    return false; 
  } catch(e) { 
    log_debug(e); 
    return false; 
  } 
}; 

Aurita.call = function(url_req) { 
  if(url_req['action']) { 
    url_req['element'] = 'dispatcher';
    Aurita.load(url_req); 
  }
  else {
    Aurita.load({ action: url_req, element: 'dispatcher' }); 
  }
}; 

Aurita.get_ie_history_fix_iframe_code = function() 
{ 

}; 

Aurita.check_hashvalue = function() 
{
    current_hashvalue = document.location.hash.replace('#',''); 

    if(current_hashvalue.match(/(.+)?_anchor/)) { return;  } 

    if(Aurita.check_if_internet_explorer() == 1) { // IE REACT
      iframe_hashvalue = Aurita.get_ie_history_fix_iframe_code(); 
      if(iframe_hashvalue != 'no_code' && iframe_hashvalue != current_hashvalue && !Aurita.force_load && iframe_hashvalue != '' && !iframe_hashvalue.match('about:')) { 
        current_hashvalue = iframe_hashvalue; 
      }
      if(document.location.hash != '#'+current_hashvalue) { document.location.hash = current_hashvalue; }
    }

    if(Aurita.force_load || current_hashvalue != Aurita.last_hashvalue && current_hashvalue != '') 
    { 
      window.scrollTo(0,0);

      Aurita.force_load = false; 
      log_debug("loading interface for "+current_hashvalue); 
      Aurita.last_hashvalue = current_hashvalue;
      action = current_hashvalue.replace(/--/g,'/').replace(/-/,'=');

      Aurita.load({ element: 'app_main_content', 
                    action: action }); 
    } 
}; 

Aurita.last_feedback = { }; 
Aurita.handle_feedback = function(response) 
{
  if(!response) return; 
  feedback = eval('('+response+')'); 

  if(feedback.unread_mail && Aurita.last_feedback.unread_mail != feedback.unread_mail) { 
    log_debug('-- unread_mail: '+feedback.unread_mail); 
    if(feedback.unread_mail == 0) {
      feedback.unread_mail = ''; 
      $('mailbox_icon').src = '/aurita/images/icons/mailbox.gif'; 
      Element.hide('mail_notifier'); 
    }
    else { 
      feedback.unread_mail = '(' + feedback.unread_mail + ')'; 
      $('mailbox_icon').src = '/aurita/images/icons/mailbox_alert.gif'; 
      $('mail_notifier').innerHTML = feedback.unread_mail; 
      Element.show('mail_notifier'); 
    }
  }
  Aurita.last_feedback = feedback; 
}; 

Aurita.poll_feedback = function()
{
  Aurita.get_remote_string('Async_Feedback/get/x=1', Aurita.handle_feedback); 
}; 

Aurita.confirmed_interface = ''; 
Aurita.unconfirmed_action =  '';  
Aurita.message_box = undefined; 
Aurita.on_confirm_action = false; 

Aurita.after_confirmed_action = function(xml_conn, element) 
{
  // do nothing
}; 

// Usage: 
// <span onclick="Aurita.confirmable({ action: 'Community::Forum_Post/delete/forum_post_id=123', 
//                                     message: 'Really delete post?', 
//                                     onconfirm: function() { alert('Post deleted'); }
//                                  });" >
//   delete post
// </span>
Aurita.confirmable = function(params) {
  interface_url = params['action']; 
  message       = params['message']; 
  Aurita.message_box = new MessageBox({ action: 'App_Main/confirmation_box/message='+message }); 
  Aurita.unconfirmed_action = interface_url; 
  if(params['onconfirm']) { 
    Aurita.on_confirm_action = params['onconfirm']; 
  } 
  else { 
    Aurita.on_confirm_action = false; 
  }
  Aurita.message_box.open();
}; 
Aurita.confirm_action = function() { 
  Aurita.call({ action: Aurita.unconfirmed_action, 
                onupdate: Aurita.after_confirmed_action });
  if(Aurita.on_confirm_action) { Aurita.on_confirm_action(); }
  Aurita.message_box.close(); 
}; 
Aurita.cancel_action = function() { 
  Aurita.message_box.close(); 
}; 

Aurita.tabs = {}; 
Aurita.register_tab_group = function(tab_params) { 
  Aurita.tabs[tab_params.tab_group_id] = tab_params; 
}

var active_messaging_button = false;
Aurita.tab_click = function(tab_group_id, tab_id, tab_name)
{
  tab_params = Aurita.tab_register[tab_group_id]; 
  tabs = tab_params.tabs; 
  
  for(t in tabs) { 
    Element.removeClassName(t, 'active');
  }
  Element.addClassName(tab_id, 'active');

  action_url = tab_params.actions[tab_id]; 

  Aurita.load({ element: tab_content_id, action: action_url }); 
}
