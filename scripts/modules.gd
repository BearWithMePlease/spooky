extends HBoxContainer

class_name Modules

var module_button := preload("res://prefab/module_button.tscn")

@export var color_valid_spot: Color
@export var color_invalid_spot: Color
@export var color_hover_spot: Color
@export var color_invalid_hover_spot: Color
@export var animation_duration: float = 0.5
@export var entry_position: Vector2 = Vector2(3,3)
@export var message_place_modules: String = "Place all rooms to start"
@export var message_connect_path: String = "Connect all modules to start"
@export var message_need_deselect: String = "You can edit/place with left-click and delete with right-click"


var grid: Dictionary = {}

@onready var mover = %Module_Mover # Unique Name
@onready var confirm_build_button: Button = $"../Confirm_Button"
@onready var help_label: Label = $"../Help_Label"
var moving = false
var grid_position: Vector2
var type: Module.ModuleType = Module.ModuleType.NONE
var mouse_over_gui = false
var force_update = false
var all_connected = false
var module_buttons = {}

var animation_running = false
var animation_old_position: Vector2 = Vector2.ZERO
var animation_new_position: Vector2 = Vector2.ZERO
var animation_weight: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mover.visible = false
	
	if len(Module.ModuleType.keys()) != len(Module.scales.keys()) or len(Module.ModuleType.keys()) != len(Module.connections.keys()):
		push_error("Module.ModuleType, module_scales or connections length does not match")
		return
	
	# Instantiate available modules (gui module button)
	for type in Module.ModuleType.values():
		if type == Module.ModuleType.NONE or type == Module.ModuleType.ENTRY:
			continue
		
		var button = module_button.instantiate()
		button.module_type = type
		module_buttons[type] = button
		self.add_child(button)
		
	# Add Entry
	on_module_type_select(Module.ModuleType.ENTRY)
	grid_position = Module.GRID_SIZE * entry_position
	on_build_module()
	check_finished_building(0.01)
	$"../../AudioStreamPlayer".stream.loop = true
	$"../../AudioStreamPlayer".play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var old_grid_position = grid_position
	grid_position = get_grid_position(mover.get_global_mouse_position())
	
	# move module to cursor with animation
	move_to_cursor(delta) 
	
	# only process if grid_position has changed or click action
	if grid_position == old_grid_position and not Input.is_action_just_pressed("click") and not Input.is_action_just_pressed("right_click") and not force_update:
		return
	
	force_update = false
	
	if moving:
		if grid_position != old_grid_position and can_build_module(old_grid_position, true):
			# Remove module direction
			adjust_surroundings(old_grid_position, true)
	
		# set color highlighting & on click -> build function
		if can_build_module(grid_position):
			# Valid build spot
			mover.sprite.modulate = color_valid_spot
			Input.set_default_cursor_shape(Input.CURSOR_MOVE)
			
			var new_mover_direction = adjust_surroundings(grid_position)
			mover.set_direction(new_mover_direction & Module.ModuleDirection.H, new_mover_direction & Module.ModuleVerticalDirection.V)
			
			if Input.is_action_just_pressed("click"):
				on_build_module()
			elif Input.is_action_just_pressed("right_click"):
				# Remove mover module
				adjust_surroundings(grid_position, true)
				
				var module_button = module_buttons.get(self.type) as ModuleButton
				if module_button != null:
					module_button.add_to_placeable_count(+1)
				
				# Cleanup
				self.type = Module.ModuleType.NONE
				moving = false
				force_update = true
				mover.sprite.texture = null
		else:
			# Invalid build spot
			mover.sprite.modulate = color_invalid_spot
			mover.set_direction(Module.ModuleDirection.N)
			Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN)
			
			if Input.is_action_just_pressed("right_click"):
				var module_button = module_buttons.get(self.type) as ModuleButton
				if module_button != null:
					module_button.add_to_placeable_count(+1)
				
				# Remove mover module
				self.type = Module.ModuleType.NONE
				moving = false
				force_update = true
				mover.sprite.texture = null
	else:
		# Cleanup old position
		var old_module = grid.get(get_grid_id(old_grid_position)) as GridModule
		if old_module != null:
			old_module.node.modulate = Color.WHITE if old_module.node.connected else color_invalid_spot
		
		# Not moving any module - can edit placed modules
		var module = grid.get(get_grid_id(grid_position)) as GridModule
		if module == null:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			return
		
		# Highlight hovered modules
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		
		module.node.modulate = color_hover_spot if module.node.connected else color_invalid_hover_spot
		
		if Input.is_action_just_pressed("click"):
			on_undo_build_module(true)
		elif Input.is_action_just_pressed("right_click"):
			on_undo_build_module(false) # Will undo but not grab item
			
			var module_button = module_buttons.get(self.type) as ModuleButton
			if module_button != null:
				module_button.add_to_placeable_count(+1)
	
	# Might be checked a few more times then necessary, but it works!
	check_finished_building()


func mouse_gui_status(mouse_over_gui:bool):
	if self.mouse_over_gui == mouse_over_gui:
		return
	
	adjust_surroundings(grid_position, mouse_over_gui)
	
	self.mouse_over_gui = mouse_over_gui
	self.force_update = true
	mover.visible = not mouse_over_gui

static func get_icon_path(type: Module.ModuleType):
	var type_str = Module.ModuleType.find_key(type).to_lower()
	return Module.MODULE_PATH + type_str + "/icon.png"
	
# hash grid position. NEEDS to be int due to shift operation
static func get_grid_id(pos:Vector2i):
	return (pos.x << Module.HASH_SHIFT) + pos.y

func move_to_cursor(delta: float):
	if animation_running:
		animation_weight = clamp(animation_weight + delta / animation_duration, 0, 1)
		mover.position = lerp(animation_old_position, animation_new_position, animation_weight)
		
		if animation_weight == 1.0:
			animation_running = false

	if grid_position != animation_new_position:
		# starting new animation
		animation_running = true
		animation_old_position = mover.position
		animation_new_position = grid_position
		animation_weight = 0

func on_module_type_select(type: Module.ModuleType, new_position = null):
	if moving:
		# Deselect module. Increase placable count
		var module_button = module_buttons.get(self.type) as ModuleButton
		if module_button != null:
			module_button.add_to_placeable_count(+1)
	
	self.type = type
	moving = true
	
	var module_button = module_buttons.get(self.type) as ModuleButton
	if new_position == null:
		animation_new_position = grid_position
		mover.init(grid_position, type, Module.ModuleDirection.N)
		mover.position.y -= Module.GRID_SIZE
		force_update = true
		if module_button != null:
			module_button.add_to_placeable_count(-1)
	else:
		animation_new_position = new_position
		mover.init(new_position, type, Module.ModuleDirection.N)

func remove_mover():
	moving = false
	mover.sprite.texture = null

# Gets mouse to grid position. Only works for positive coords
func get_grid_position(pos: Vector2) -> Vector2:
	var posI: Vector2i = Vector2i(floori(pos.x + Module.GRID_SIZE * 0.5), floori(pos.y + Module.GRID_SIZE * 0.5))
	var x: int = int(posI.x / Module.GRID_SIZE) if (posI.x >= 0) else int((posI.x + 1) / Module.GRID_SIZE) - 1
	var y: int = int(posI.y / Module.GRID_SIZE) if (posI.y >= 0) else int((posI.y + 1) / Module.GRID_SIZE) - 1
	return Vector2(x * Module.GRID_SIZE, y * Module.GRID_SIZE)

func get_surroundings(grid_position: Vector2, type: Module.ModuleType) -> Dictionary:
	if len(Module.connections[type]) == 0:
		return {}
		
	var connection_slot_first = grid_position + Module.GRID_SIZE * (Module.connections[type][0]-Vector2.ONE)
	var connection_slot_last = grid_position + Module.GRID_SIZE * (Module.connections[type][len(Module.connections[type])-1]-Vector2.ONE)
	
	return {
		Module.ModuleDirection.L: connection_slot_first + Vector2(-Module.GRID_SIZE, 0), 		# left
		Module.ModuleDirection.R: connection_slot_last + Vector2(Module.GRID_SIZE, 0),			# right
		Module.ModuleVerticalDirection.U: connection_slot_first + Vector2(0, -Module.GRID_SIZE),	# up
		Module.ModuleVerticalDirection.D: connection_slot_last + Vector2(0, Module.GRID_SIZE)	# down
	}

# Check if there is already a module in that position (on grid)
func can_build_module(grid_position: Vector2, ignore_gui: bool = false):
	if mouse_over_gui and not ignore_gui: return false
	
	# check if all grid slots are empty
	for x in range(Module.scales[type].x):
		for y in range(Module.scales[type].y):
			var new_pos = grid_position + Module.GRID_SIZE * Vector2(x,-y)
			if grid.has(get_grid_id(new_pos)):
				return false
	
	# only allow connected modules to be buildable
	#var surrounding_check = adjust_surroundings(grid_position, false, true)
	#if surrounding_check & (ModuleDirection.H | ModuleVerticalDirection.V) == 0:
		# module not connected with anything
		#return false
	
	return true

func adjust_surroundings(pos: Vector2, removing = false, read_only = false) -> int:
	var surroundings = get_surroundings(pos, type)
	var mover_direction: int = 0b0000 # combination of ModuleDirection & ModuleVerticalDirection
	
	for direction in surroundings.keys():
		var grid_module = grid.get(get_grid_id(surroundings[direction])) as GridModule

		if grid_module == null or not Module.connections[grid_module.node.type].has(grid_module.scale_index):
			continue

		# Vertical direction only allowed for corridor
		if direction & Module.ModuleVerticalDirection.V != 0 and (grid_module.node.type != Module.ModuleType.CORRIDOR or type != Module.ModuleType.CORRIDOR):
			continue
			

		# update surrounding (inverse direction L->R; U->D; N->N)
		var opposite_direction = Module.ModuleDirection.H & (~(direction | Module.ModuleVerticalDirection.V))
		var opposite_vertical_direction = Module.ModuleVerticalDirection.V & (~(direction | Module.ModuleDirection.H))
		
		# None stays None
		if direction & Module.ModuleDirection.H == 0: opposite_direction = Module.ModuleDirection.N
		if direction & Module.ModuleVerticalDirection.V == 0: opposite_vertical_direction = Module.ModuleVerticalDirection.N
		
		if not read_only:
			grid_module.node.adjust_direction(opposite_direction, opposite_vertical_direction, removing)
		
		# update mover
		mover_direction |= direction

	return mover_direction


var firstBuilding = true

func on_build_module():
	# Instantiate module prefab
	var node = Globals.module_prefabs[type].instantiate() as Module
	node.init(grid_position, type, mover.direction, mover.vertical_direction)
	mover.get_parent().add_child(node)
	
	# Add module to each grid slot it occupies
	for x in range(Module.scales[type].x):
		for y in range(Module.scales[type].y):
			var module = GridModule.new(node, Vector2(x+1,y+1))
			var slot_position = grid_position + Module.GRID_SIZE * Vector2(x,-y)
			grid[get_grid_id(slot_position)] = module
	
	check_all_connected()
	
	if self.type != Module.ModuleType.CORRIDOR or module_buttons.get(Module.ModuleType.CORRIDOR)._placeable_count == 0:
		# Clean up
		moving = false
		mover.sprite.texture = null
		type = Module.ModuleType.NONE
		grid_position = Vector2(-1, -1)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	else:
		# Grab second corridor and move it to lower grid spot
		on_module_type_select(Module.ModuleType.CORRIDOR)
		mover.position.y += 2 * Module.GRID_SIZE
		
		var module_button = module_buttons.get(self.type) as ModuleButton
		if module_button != null:
			module_button.add_to_placeable_count(-1)
	
	
	if !firstBuilding:
		$"../../AudioStreamPlayer2".play()
	firstBuilding = false

func on_undo_build_module(grab_item:bool):
	# Instantiate module prefab
	var current_module = grid.get(get_grid_id(grid_position)) as GridModule
	if current_module == null:
		print("Undo module: Module not found")
		return
	
	if current_module.node.type == Module.ModuleType.ENTRY:
		return
	
	# find scale_index (1,1), bottom left corner
	var bottom_left_slot = grid_position - (current_module.scale_index - Vector2.ONE) * Module.GRID_SIZE * Vector2(1,-1)
	current_module = grid.get(get_grid_id(bottom_left_slot)) as GridModule
	if current_module == null:
		print("Undo module: Bottom left module not found")
		return
	
	# Remove all grid slots of module
	type = current_module.node.type
	var current_node = current_module.node
	var current_position = current_module.node.position
	for x in range(Module.scales[type].x):
		for y in range(Module.scales[type].y):
			var slot_position = current_position + Module.GRID_SIZE * Vector2(x,-y)
			var slot_id = get_grid_id(slot_position)
			var slot_module = grid.get(slot_id) as GridModule
			if slot_module == null:
				print("Undo module: Could not erase a slot")

			grid.erase(slot_id)
			slot_module.free()

	# Free node
	current_node.free()
	
	if grab_item:
		on_module_type_select(type, current_position)
	
	if grid_position != current_position or not grab_item:
		# Move to cursor grid slot
		adjust_surroundings(current_position, true)
		grid_position = current_position
		
	check_all_connected()
	force_update = true
	$"../../AudioStreamPlayer3".play()

func check_all_connected():
	# Set all grid nodes to not connected
	var total_nodes_count = {}
	for grid_module:GridModule in self.grid.values():
		if not total_nodes_count.has(grid_module.node):
			total_nodes_count[grid_module.node.get_instance_id()] = true
			grid_module.node.connected = false
			grid_module.node.modulate = color_invalid_spot
			
	
	var root_node = grid.get(get_grid_id(Module.GRID_SIZE * entry_position)) as GridModule
	root_node.node.connected = true
	root_node.node.modulate = Color.WHITE
	var search_nodes: Array[GridModule] = [root_node]
	var connected_node_count = 1
	
	while len(search_nodes) != 0:
		var next_search: Array[GridModule] = []
		for search in search_nodes:
			# check surrounding of search node
			var surroundings = get_surroundings(search.node.position, search.node.type)
			for direction in surroundings.keys():
				if direction & (search.node.direction | search.node.vertical_direction) == 0:
					# node has no connection in this direction
					continue
				
				# check single direction of search node
				var next_module = grid.get(get_grid_id(surroundings[direction])) as GridModule
				if next_module != null and not next_module.node.connected:
					# new connection found - add to new search cycle
					next_module.node.connected = true
					next_module.node.modulate = Color.WHITE
					connected_node_count += 1
					
					next_search.append(next_module)

		search_nodes = next_search
	
	self.all_connected = len(total_nodes_count.values()) == connected_node_count

func check_finished_building(timing:float = 0.5):
	var placed_all_rooms: bool = true
	for module_button:ModuleButton in module_buttons.values():
		if module_button.module_type != Module.ModuleType.CORRIDOR and module_button._placeable_count != 0:
			placed_all_rooms = false
			break

	self.help_label.text = ""
	if not placed_all_rooms:
		self.help_label.text = self.message_place_modules
	elif not self.all_connected:
		self.help_label.text = self.message_connect_path
	elif self.moving:
		self.help_label.text = self.message_need_deselect

	# Can not click button if: not connected or not all rooms placed (except Corridor) or moving module
	var can_finish = not self.all_connected or not placed_all_rooms or self.moving
	if can_finish == self.confirm_build_button.disabled:
		return
	
	self.confirm_build_button.disabled = can_finish # TODO: replace to can_finish

	var new_position: Vector2
	if self.confirm_build_button.disabled:
		# Can not build bunker
		new_position = Vector2(self.confirm_build_button.position.x, -self.confirm_build_button.size.y) # Move outside screen
	else:
		# Can build bunker
		new_position = Vector2(self.confirm_build_button.position.x, 10)
	
	var tween = get_tree().create_tween()
	tween.tween_property(self.confirm_build_button, "position", new_position, timing).set_trans(Tween.TRANS_LINEAR)
	
func on_confirm_build():
	check_finished_building()
	if self.confirm_build_button.disabled:
		return
	
	var nodes_dict = {}
	for grid_module:GridModule in grid.values():
		nodes_dict[grid_module.node.get_instance_id()] = grid_module.node
	var nodes = nodes_dict.values() as Array[Module]
	
	Globals.switch_scene(Globals.SceneType.BUNKER_BUILD, Globals.SceneType.MAIN_SCENE, nodes)
