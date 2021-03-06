
require('aurita/controller')

Aurita::Main.import_model :hierarchy
Aurita::Main.import_model :hierarchy_entry
Aurita::Main.import_model :hierarchy_category
Aurita.import_module :gui, :hierarchy
Aurita.import_module :gui, :accordion_box

Aurita::Main.import_controller :hierarchy_entry

module Aurita
module Main

  class Hierarchy_Controller < App_Controller

    guard(:CUD) { Aurita.user.may(:edit_hierarchies) }

    def form_groups
      [
        Hierarchy.header, 
        Hierarchy.category, 
        Category.category_id, 
        Hierarchy.interface
      ]
    end

    def update
      form = update_form
      form[Hierarchy.category].hidden = true
      category = Category_Selection_List_Field.new()
      category.value = load_instance.category_ids
      if !Aurita.user.is_admin? then
        form[Hierarchy.interface.to_s].hide!
      end
      form.add(category)
      render_form(form)
    end

    def delete
      form = delete_form
      form[Hierarchy.category.to_s].hide! 
      form[Hierarchy.interface.to_s].hide! 
      render_form(form)
    end

    def perform_add
      instance = super()
      Hierarchy_Category.create_for(instance, param(:category_id))
      after_modification(instance)
    end

    def perform_update
      return unless param(:hierarchy_id)
      return unless Aurita.user.is_admin? 
      super()
      instance = load_instance()
      Hierarchy_Category.update_for(instance, param(:category_id))
      after_modification(Hierarchy.load(:hierarchy_id => param(:hierarchy_id)))
    end

    def perform_delete
      return unless param(:hierarchy_id)
      return unless Aurita.user.may(:delete_hierarchies)
      hierarchy = load_instance()
      Hierarchy_Entry.delete { |he|
        he.where(he.hierarchy_id == param(:hierarchy_id))
      }
      after_modification(hierarchy)
      super()
    end

    def after_modification(hierarchy)
      category = hierarchy.category
      if category == 'GENERAL' then
        exec_js("Aurita.load({ element: 'app_left_column', action: 'App_General/left/' })")
      elsif category == 'MY_PLACE' then
        exec_js("Aurita.load({ element: 'app_left_column', action: 'App_My_Place/left/' })")
      end
    end


    def list(params={})
      params[:perspective] = 'GENERAL' unless params[:perspective]
      hierarchy_boxes(params[:perspective])
    end

    def hierarchy_boxes(params={})

      category   = params[:section]
      category ||= 'GENERAL'
      filter     = params[:filter]
      filter   ||= (Hierarchy.category == category)
      
      hierarchy_list = []
      count = 0
      Hierarchy.all_with(filter & (Hierarchy.accessible)).each { |h|
        entries = Hierarchy_Entry.all_with(Hierarchy_Entry.hierarchy_id == h.hierarchy_id)
        map = Hierarchy_Map.new(entries)
        dec = Hierarchy_Entries_Default_Decorator.new(map)
        if dec.string || Aurita.user.is_registered? then
          box = Accordion_Box.new(:type   => :hierarchy, 
                                  :class  => :topic, 
                                  :id     => "hierarchy_#{h.hierarchy_id}", 
                                  :params => { :hierarchy_id => h.hierarchy_id } )
          box.header = Context_Menu_Element.new(h) { h.header }
          box.body   = dec.string
          hierarchy_list << box 
        end
        count += 1
      }
      hierarchy_list 
    end

    def perform_reorder
      hid = param(:hierarchy_id)
      position_tree = []
      position_tree = param("hierarchy_sortable_list_#{hid}")
      position_tree = parse_position_tree(position_tree)
      position_tree.each { |entry|
        Hierarchy_Entry.update { |e|
          e.where(e.hierarchy_entry_id == entry[0]) 
          e.set(:hierarchy_entry_id_parent => entry[1], 
                :sortpos => entry[2])
        }
      }
    end

  private 

    def parse_position_tree(mapping, last_parent_entry_id=0, tree=[])
      position = 0
      while mapping[position.to_s] && mapping[position.to_s]['id'] do 
        entry_id = mapping[position.to_s]['id']
        tree << [ entry_id, last_parent_entry_id, position ]
        tree = parse_position_tree(mapping[position.to_s], entry_id, tree)
        position += 1
      end
      return tree
    end

  public

    def list_model(hierarchy_id=nil)
      hierarchy_id = param(:hierarchy_id) unless hierarchy_id
      entries = Hierarchy_Entry.all_with(Hierarchy_Entry.hierarchy_id == hierarchy_id).sort_by(:sortpos, :asc).entities
      entry_map = Hash.new
      for entry in entries do 
        pid = entry.hierarchy_entry_id_parent
        entry_map[pid] = Array.new unless entry_map[pid]
        entry_map[pid] << entry
      end
      return entry_map
    end

    def add
      form = add_form()
      form.add(Hidden_Field.new(:name  => Hierarchy.category.to_s, 
                                :value => param(:category)))
      form.add(GUI::Category_Selection_List_Field.new())
      if !Aurita.user.is_admin? then
      #  form[Hierarchy.interface.to_s].hide!
      end
      form = render_form(form)

      return form unless param(:element) == 'app_main_content'
      return Page.new(:header => tl(:add_hierarchy)) { form } 
    end

    def delete
      form = delete_form()
      instance = load_instance()
      form.add(Hidden_Field.new(:name  => Hierarchy.category.to_s, 
                                :value => param(:category)))
      render_form(form)
      form.add(Hidden_Field.new(:name  => Hierarchy.category.to_s, 
                                :value => instance.category))
    end

    def sort
      h = Hierarchy.load(:hierarchy_id => param(:hierarchy_id))
      return unless h
      
      h_id = h.hierarchy_id
      map = Hierarchy_Map.new(Hierarchy_Entry.all_with(Hierarchy_Entry.hierarchy_id == h.hierarchy_id).entities)
      dec = Hierarchy_Sortable_Decorator.new(map)
      dec.dom_id = "hierarchy_sortable_list_#{h_id}"
      dec
    end

    def body
      return unless param(:hierarchy_id)
      h_id = param(:hierarchy_id)
      map = Hierarchy_Map.new(Hierarchy_Entry.all_with(Hierarchy_Entry.hierarchy_id == h_id).entities)
      dec = Hierarchy_Entries_Default_Decorator.new(map)
      puts dec.string
    end

  end # class
  
end # module
end # module

