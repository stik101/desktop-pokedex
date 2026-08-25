extends Control

'''
ID 
Name
IMAGES
TYPE
BASE STATS [HP, Attack, Defense, Special Attack, Special Defense, and Speed]
MOVES
ATTACKS
DESCRIPTION
'''

# ALL HTTPREQUEST NODES GO HERE
@onready var api:HTTPRequest = $PokeAPI/APIName
@onready var api_image: HTTPRequest = $PokeAPI/APIImage
@onready var api_cry: HTTPRequest = $PokeAPI/APICry
@onready var api_entry: HTTPRequest = $PokeAPI/APIEntry

# SEARCH BAR STUFF GO HERE
@export var search_bar:LineEdit
@export var search_button:Button
@onready var output: Label = $Output
@onready var poke_cry: AudioStreamPlayer = $PokeCry

# MINI DEX STUFF GO HERE
var mouse_offset = Vector2.ZERO
@export var draggable_area:Sprite2D
@export var dex:Node2D
@export var dex_anim:AnimationPlayer
@export var search_bar_anim:AnimationPlayer
@onready var dex_sprites:Node2D = $DemoDex/DexSprites
@export var poke_image: TextureRect
@export var search_toggle:TextureButton
var is_open:bool = false
@export var closed_sprite:Sprite2D
@export var open_sprite:Sprite2D
var current_sprite:Sprite2D
var is_hovering:bool = false
var is_waiting:bool = true
var is_dragging:bool = false
var is_search_bar_open:bool = true
var is_mouse_on_search_toggle:bool = false
@export var entry_text_label:Label

# Pokemon Cry SFX
var cry_audio:AudioStreamOggVorbis = AudioStreamOggVorbis.new()

# NOTE: POKE ID IS REQUIRED FOR A LOTA STUFF, SO ITS DECLARED EARLIER HERE
var p_id:int

# API LINKS GO HERE
var api_link:String = "https://pokeapi.co/api/v2/pokemon/"
var image_link:String = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/'
var cry_link:String = 'https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/latest/'
var cry_link_legacy:String = 'https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/legacy/'
var entry_link:String = "https://pokeapi.co/api/v2/pokemon-species/"

# Connect a lota signals (mostly of APIs)
func _ready() -> void:
	entry_text_label.modulate = Color("ffeb0000")
	current_sprite = closed_sprite
	api.request_completed.connect(_on_request_pokedata)
	search_button.pressed.connect(search)
	api_image.request_completed.connect(_on_request_pokeimage)
	api_cry.request_completed.connect(_on_request_pokecry)
	api_entry.request_completed.connect(_on_request_pokeentry)

# For search bar field
func search() -> void:
	var text:String = search_bar.text.to_lower()
	print("FETCHING DATA (Where's my farfetch'd?)")
	var error = api.request(api_link + text)
	
	if error != OK:
		print("Oops, there's an error when data was recieved!", str(error))
	
# NOTE: ALL OTHER API FUNCTION CALLS ARE DONE AT THE END OF THS FUNC TOO
func _on_request_pokedata(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray):
	print("Request done! Status: ", response_code)
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	
	if error != OK:
		print("OOPS! There's an error in parsing json")
		return
	
	var data:Dictionary = json.data
	
	# COLLECTING ALL DATAS OF POKEMON HERE ON
	#Name
	var p_name:String = data["name"]
	
	#ID
	p_id = data["id"]
	
	# HEIGHT
	var p_height:float = data["height"]
	
	# WEIGHT
	var p_weight:float = data['weight']
	
	# TYPES
	var p_type:Array[String] = []
	for t in data['types']:
		p_type.append(t['type']['name'])
	
	# MOVES
	var p_moves:Array[String] = []
	for m in data["moves"]:
		p_moves.append(m["move"]["name"])
	
	# ABILITIES
	var p_abilities:Array[String] = []
	for a in data["abilities"]:
		p_abilities.append(a["ability"]["name"])
	
	# BASE STATS!!!
	var p_hp:float = data["stats"][0]['base_stat'] # HP
	var p_attack:float = data["stats"][1]['base_stat'] # ATTACK
	var p_defence:float = data["stats"][2]['base_stat'] # DEFENCE
	var p_sattack:float = data["stats"][3]['base_stat'] # SPECIAL ATTACK
	var p_sdefence:float = data["stats"][4]['base_stat'] # SPECIAL DEFENCE
	var p_speed:float = data["stats"][5]['base_stat'] # SPEED
	
	output.text = str(int(data["id"])) + ". " + str(data["name"]).to_upper()
	print(int(data["id"]),'. ', data["name"])
	print("Height: ", str(p_height), " Weight: ", str(p_weight))
	print("Type: ", p_type)
	print("Moves: ", p_moves)
	print("\nAbilities: ", p_abilities)
	print("\nBASE STATS\n")
	print("HP: ", p_hp)
	print("Atk: ", p_attack)
	print("DEF: ", p_defence)
	print("S. ATK: ", p_sattack)
	print("S. DEF: ", p_sdefence)
	print("SPD: ", p_speed)
	
	search_image() # since now weve id, we can search the pokemon image
	search_cry()
	search_entry()

func search_image() -> void:
	var error = api_image.request(image_link + str(p_id) + '.png')

func search_cry() -> void:
	var error
	if not (p_id == 25 or p_id == 133):
		error = api_cry.request(cry_link + str(p_id) + '.ogg')
	else:
		error = api_cry.request(cry_link_legacy + str(p_id) + '.ogg')
	if error != OK:
		print("Oops, there's an error when data was recieved!", str(error))

func search_entry() -> void:
	var error = api_entry.request(entry_link + str(p_id))

func _on_request_pokeimage(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray):
	if response_code != 200:
		print("Failed to download image for ID: ", p_id)
		return

	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	
	if error == OK:
		poke_image.texture = ImageTexture.create_from_image(image)
		print("Pokemon image loaded successfully! ")

func _on_request_pokecry(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray):
	if response_code != 200:
		print("Failed to download cry for ID: ", p_id)
		return
	
	
	cry_audio = AudioStreamOggVorbis.load_from_buffer(body)
	poke_cry.stream = cry_audio

func _on_request_pokeentry(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray):
	print("\nDESCRIPTION RECIEVED SUCCESFULLY")
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	
	if error != OK:
		print("OOPS! There's an error in parsing json")
		return
	
	var data:Dictionary = json.data
	
	var p_entry:String = ""
	
	for e in data["flavor_text_entries"]:
		if p_entry == '':
			if SettingsGlobal.language == "en":
				if e["language"]["name"] == 'en':
					p_entry = e["flavor_text"]
	
	p_entry = p_entry.replace("\n", " ").replace("\f", " ")
	entry_text_label.text = p_entry
	
	print("\n", JSON.stringify(p_entry))
func _process(delta: float) -> void:
	if is_dragging:
		dex.global_position = get_global_mouse_position() + mouse_offset
	# HANDLES THE HOVER POKEDEX FEATURE
	if not is_open:
		if closed_sprite.get_rect().has_point(closed_sprite.to_local(get_global_mouse_position())):
			dex_sprites.modulate = Color("e4e4e4")
		else:
			dex_sprites.modulate = Color("ffffff")
	else:
		if entry_text_label.text != '':
			# HANDLES THE MARQUEE EFFECT IN ENTRLY LABEL
			var x_limit = entry_text_label.size.x
			var scroll_speed = 1
			# Start of effect
			if is_waiting:
				await get_tree().create_timer(1).timeout 
				await get_tree().create_tween().tween_property(entry_text_label, "modulate:a", 1.0, 0.5).finished
				await get_tree().create_timer(1).timeout
				is_waiting = false
			else:
				if entry_text_label.position.x >= -x_limit:
					entry_text_label.position.x -= scroll_speed
				else:
					is_waiting = true
					entry_text_label.position.x = 5
					entry_text_label.modulate.a = 0.0
		
# To flip open the pokedex
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if search_toggle.get_global_rect().has_point(event.position):
				return
		if event.pressed:
			if draggable_area.get_rect().has_point(draggable_area.to_local(event.position)):
				search_bar_anim.play("popdown")
				is_search_bar_open = true
				mouse_offset = dex.global_position - get_global_mouse_position()
				is_dragging = true
				return
		else:
			if is_dragging:
				is_dragging = false
				return
			if current_sprite.get_rect().has_point(current_sprite.to_local(event.position)):
				get_viewport().set_input_as_handled()

				if not is_open:
					if not is_mouse_on_search_toggle:
						current_sprite = closed_sprite
						dex_anim.play("open")
						is_open = true



func _on_cry_button_pressed() -> void:
	poke_cry.play()


func _on_close_button_pressed() -> void:
	current_sprite = open_sprite
	dex_anim.play("closed")
	is_open = false




func search_bar_toggle() -> void:
	is_search_bar_open = !is_search_bar_open
	if is_search_bar_open:
		search_bar_anim.play("popdown")
	else:
		search_bar_anim.play("popup")


func _on_search_button_mouse_entered() -> void:
	is_mouse_on_search_toggle = true


func _on_search_button_mouse_exited() -> void:
	is_mouse_on_search_toggle = false
