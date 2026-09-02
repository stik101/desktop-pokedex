extends Node2D

# The pokedex itself, for cordinates and stuff
@export var dex:Node2D
@export var main:Node

# The hitbox Polygons go here
@export var h_closed:Polygon2D
@export var h_closed_search:Polygon2D
@export var h_opened:Polygon2D
@export var h_opened_search:Polygon2D
@export var h_settings:Polygon2D
@export var h_closed_anim:Polygon2D
@export var h_opened_anim:Polygon2D
@export var is_open_close_anim_playing:bool = false
@export var is_search_bar_open:bool = false
var is_settings_toggled:bool = false
var is_option_menu_open:bool = false
@export var is_open:bool = false
var is_dragging:bool = false
var was_dragging:bool = false

enum DexState{
	CLOSED,
	CLOSED_SEARCH,
	CLOSED_ANIM,
	OPENED,
	OPENEED_SEARCH,
	OPENED_ANIM,
	SETTINGS
}

var dex_state:DexState = DexState.CLOSED

func _process(_delta: float) -> void:
	
	if main.is_settings_toggled:
		is_settings_toggled = true
	else:
		is_settings_toggled = false
	
	is_option_menu_open = main.is_option_button_opened
	
	if main.is_dragging:
		if not was_dragging:
			# Drag just started
			DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
			was_dragging = true
		
		return

	else:
		if was_dragging:
			# Drag just ended
			was_dragging = false
			set_passthrough()
	
	# UPDATE THE STATES OVER HERE!!!
	if not is_option_menu_open:
		if is_settings_toggled:
			dex_state = DexState.SETTINGS
		elif is_open_close_anim_playing:
			if is_open:
				dex_state = DexState.OPENED_ANIM
			else:
				dex_state = DexState.CLOSED_ANIM
		else:
			if is_open:
				if is_search_bar_open:
					dex_state = DexState.OPENEED_SEARCH
				else:
					dex_state = DexState.OPENED
			else:
				if is_search_bar_open:
					dex_state = DexState.CLOSED_SEARCH
				else:
					dex_state = DexState.CLOSED
		set_passthrough()
	else:
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
	

func set_passthrough() -> void:
	var hitbox:Polygon2D
	
	match dex_state:
		DexState.CLOSED:
			hitbox = h_closed
		DexState.CLOSED_SEARCH:
			hitbox = h_closed_search
		DexState.OPENED:
			hitbox = h_opened
		DexState.OPENEED_SEARCH:
			hitbox = h_opened_search
		DexState.SETTINGS:
			hitbox = h_settings
		DexState.CLOSED_ANIM:
			hitbox = h_closed_anim
		DexState.OPENED_ANIM:
			hitbox = h_opened_anim
	
	if hitbox == null:
		return
	if hitbox.polygon.is_empty():
		return
		
	var window_polygon = null
	if dex_state != DexState.SETTINGS:	
		window_polygon = convert_to_window_space(hitbox)
	else:
		window_polygon = convert_settings_to_window_space(h_settings)
	
	DisplayServer.window_set_mouse_passthrough(window_polygon)

func convert_to_window_space(hitbox: Polygon2D) -> PackedVector2Array:
	var result := PackedVector2Array()

	var viewport_size := get_viewport_rect().size
	var window_size := DisplayServer.window_get_size()

	var scale := Vector2(
		window_size.x / viewport_size.x,
		window_size.y / viewport_size.y
	)

	for point in hitbox.polygon:
		var global_point := dex.to_global(point)

		var window_point := global_point * scale

		result.append(window_point)

	return result


func convert_settings_to_window_space(hitbox: Polygon2D) -> PackedVector2Array:
	var result := PackedVector2Array()

	var viewport_size := get_viewport_rect().size
	var window_size := DisplayServer.window_get_size()

	var scale := Vector2(
		window_size.x / viewport_size.x,
		window_size.y / viewport_size.y
	)

	for point in hitbox.polygon:
		result.append(point * scale)

	return result
