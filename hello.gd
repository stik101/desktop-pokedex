extends Control

@onready var sprite: Sprite2D = $Sprite2D

var dragging := false
var drag_offset := Vector2.ZERO # The initial position of mouse while clicked on sprite


func _ready() -> void:
	sprite.visible = true
	set_passthrough()


func set_passthrough() -> void:
	# 1. trying to set the polygon
	var window_size := DisplayServer.window_get_size()

	var rect := sprite.get_rect()
	var top_left := sprite.to_global(rect.position)
	var bottom_right := sprite.to_global(rect.end)

	var viewport_size := get_viewport_rect().size

	var scale := Vector2(
		float(window_size.x) / viewport_size.x,
		float(window_size.y) / viewport_size.y
	)

	top_left *= scale
	bottom_right *= scale

	var polygon := PackedVector2Array([
		top_left,
		Vector2(bottom_right.x, top_left.y),
		bottom_right,
		Vector2(top_left.x, bottom_right.y)
	])
	DisplayServer.window_set_mouse_passthrough(polygon)


# THIS IS FOR DRAGGIN SPRITE, WORKS LIKE NORMAL DRAGGING BTW
func _input(event: InputEvent) -> void:
	# Mouse button pressed/released
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check whether the click is on the sprite.
				var local_mouse := sprite.to_local(event.position) # position of mouse wrt sprite
				# checks if the point is in the sprite area
				if sprite.get_rect().has_point(local_mouse):
					dragging = true
					# DRAG OFFSET ASSIGNED HERE
					drag_offset = sprite.position - event.position
					# Disable passthrough while dragging.
					# EMPYTY PACKEDVECOTR ARRAY DISABLES PASSTHROUGH
					DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
					get_viewport().set_input_as_handled()
			else:
				# DISABLES DRAGGING IF NOT BEING PRESSED
				if dragging:
					dragging = false
					# Put click-through back.
					set_passthrough()

	# Mouse movement while dragging
	elif event is InputEventMouseMotion:
		if dragging:
			sprite.position = event.position + drag_offset


func _on_button_pressed() -> void:
	print("pressed!")
