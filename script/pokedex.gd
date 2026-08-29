extends Control


# ALL HTTPREQUEST NODES GO HERE
@onready var api:HTTPRequest = $PokeAPI/APIName
@onready var api_image_front: HTTPRequest = $PokeAPI/APIImageFront
@onready var api_image_back: HTTPRequest = $PokeAPI/APIImageBack
@onready var api_cry: HTTPRequest = $PokeAPI/APICry
@onready var api_entry: HTTPRequest = $PokeAPI/APIEntry

# SEARCH BAR STUFF GO HERE
@export var search_bar:LineEdit
@export var search_button:Button
@onready var poke_cry: AudioStreamPlayer = $PokeCry

# MINI DEX STUFF GO HERE
var mouse_offset = Vector2.ZERO
@export var draggable_area:Sprite2D
@export var dex:Node2D
@export var dex_anim:AnimationPlayer
@export var search_bar_anim:AnimationPlayer
@onready var dex_sprites:Node2D = $DemoDex/DexSprites
@export var name_id_label:Label
@export var poke_image: TextureRect
var image_front:Texture2D
var image_back:Texture2D
@export var search_toggle:TextureButton
var is_open:bool = false
@export var closed_sprite:Sprite2D
@export var open_sprite:Sprite2D
@export var icon_1:TextureRect
@export var icon_2:TextureRect
@export var nav_right:TextureButton
@export var nav_left:TextureButton
@export var genera_label:Label
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
var p_name:String
var p_id:int
var p_genera:String
var p_height:float
var p_weight:float
var p_type:Array[String]
var p_moves:Array[String]
var p_abilities:Array[String]
var p_hp:int
var p_speed:int
var p_attack:int
var p_defence:int
var p_sattack:int
var p_sdefence:int
var p_entry:String

# FOR THE ENTRY TEXT SPLITTING

const CHAR_LIMIT:int = 88

var entry_pages:Array[String] = []
var current_page:int = 0


# API LINKS GO HERE
var api_link:String = "https://pokeapi.co/api/v2/pokemon/"
var image_front_link:String = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/'
var image_back_link:String = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/back/'
var cry_link:String = 'https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/latest/'
var cry_link_legacy:String = 'https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/legacy/'
var species_link:String = "https://pokeapi.co/api/v2/pokemon-species/"
var type_url:String = "res://type_icons/"

# Connect a lota signals (mostly of APIs)
func _ready() -> void:
	current_sprite = closed_sprite
	api.request_completed.connect(_on_request_pokedata)
	search_button.pressed.connect(search)
	api_image_front.request_completed.connect(_on_request_pokeimage_front)
	api_image_back.request_completed.connect(_on_request_pokeimage_back)
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
	p_name = data["name"]
	
	#ID
	p_id = data["id"]
	
	# HEIGHT
	p_height = data["height"]
	
	# WEIGHT
	p_weight = data['weight']
	
	# TYPES
	p_type = []
	for t in data['types']:
		p_type.append(t['type']['name'])
	
	# MOVES
	p_moves = []
	for m in data["moves"]:
		p_moves.append(m["move"]["name"])
	
	# ABILITIES
	p_abilities = []
	for a in data["abilities"]:
		p_abilities.append(a["ability"]["name"])
	
	# BASE STATS!!!
	p_hp = data["stats"][0]['base_stat'] # HP
	p_attack = data["stats"][1]['base_stat'] # ATTACK
	p_defence = data["stats"][2]['base_stat'] # DEFENCE
	p_sattack = data["stats"][3]['base_stat'] # SPECIAL ATTACK
	p_sdefence = data["stats"][4]['base_stat'] # SPECIAL DEFENCE
	p_speed = data["stats"][5]['base_stat'] # SPEED
	
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
	
	name_id_label.text = str(p_id) + '. ' + str(p_name
	)
	set_type()
	search_image() # since now weve id, we can search the pokemon image
	search_cry()
	search_entry()

func set_type():
	if len(p_type) == 1:
		icon_1.texture = load(type_url+ p_type[0] + '.svg')
		icon_2.texture = null
		icon_1.tooltip_text = p_type[0].capitalize()
	elif len(p_type) == 2:
		icon_1.texture = load(type_url+ p_type[0] + '.svg')
		icon_2.texture = load(type_url+ p_type[1] + '.svg')
		icon_1.tooltip_text = p_type[0].capitalize()
		icon_2.tooltip_text = p_type[1].capitalize()
	else:
		icon_1.texture = null
		icon_2.texture = null

func search_image() -> void:
	var error = api_image_front.request(image_front_link + str(p_id) + '.png')
	error = api_image_back.request(image_back_link + str(p_id) + '.png')

func search_cry() -> void:
	var error
	if not (p_id == 25 or p_id == 133):
		error = api_cry.request(cry_link + str(p_id) + '.ogg')
	else:
		error = api_cry.request(cry_link_legacy + str(p_id) + '.ogg')
	if error != OK:
		print("Oops, there's an error when data was recieved!", str(error))

func search_entry() -> void:
	var error = api_entry.request(species_link + str(p_id))

func _on_request_pokeimage_front(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray):
	if response_code != 200:
		print("Failed to download image for ID: ", p_id)
		return

	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	
	if error == OK:
		image_front = ImageTexture.create_from_image(image)
		poke_image.texture = image_front
		print("Pokemon image loaded successfully! ")

func _on_request_pokeimage_back(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray):
	if response_code != 200:
		print("Failed to download image for ID: ", p_id)
		return

	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error == OK:
		image_back = ImageTexture.create_from_image(image)
		print("Pokemon's back sprite is succesfully loaded")


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
	
	# GENERA OF POKEMON
	
	for g in data["genera"]:
		if g["language"]["name"] == SettingsGlobal.language:
			p_genera = g["genus"]
	
	genera_label.text = p_genera
	
	# ENTRY FLAVOR TEXT
	p_entry = ""
	
	for e in data["flavor_text_entries"]:
		if p_entry == '':
			if SettingsGlobal.language == "en":
				if e["language"]["name"] == 'en':
					p_entry = e["flavor_text"]
	

	p_entry = p_entry.replace("\n", " ").replace("\f", " ")
	
	entry_pages.clear()
	
	while p_entry.length() > CHAR_LIMIT:
		var split_at:int = p_entry.rfind(" ", CHAR_LIMIT)
		
		if split_at == -1:
			split_at = CHAR_LIMIT
		
		entry_pages.append(p_entry.substr(0, split_at))
		p_entry = p_entry.substr(split_at + 1)
		
	if p_entry.length() > 0:
		entry_pages.append(p_entry)
	
	if entry_pages.size() > 0:
		entry_text_label.text = entry_pages[0]
		
	entry_text_label.text = entry_pages[current_page]


func _process(delta: float) -> void:
	if is_dragging:
		dex.global_position = get_global_mouse_position() + mouse_offset
	# HANDLES THE HOVER POKEDEX FEATURE
	if not is_open:
		if closed_sprite.get_rect().has_point(closed_sprite.to_local(get_global_mouse_position())):
			dex_sprites.modulate = Color("e4e4e4")
		else:
			dex_sprites.modulate = Color("ffffff")

# To flip open the pokedex
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if search_toggle.get_global_rect().has_point(event.position):
				return
		if event.pressed:
			if draggable_area.get_rect().has_point(draggable_area.to_local(event.position)):
				Input.set_default_cursor_shape(Input.CURSOR_DRAG)
				mouse_offset = dex.global_position - get_global_mouse_position()
				is_dragging = true
				return
		else:
			if is_dragging:
				is_dragging = false
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)
				return
			if current_sprite.get_rect().has_point(current_sprite.to_local(event.position)):

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

# THESE ARE FOR NAVIGATION BUTTONS FOR TEXT ENTRIES

func _on_right_button_pressed() -> void:
	if current_page + 1 < entry_pages.size():
		current_page += 1
		entry_text_label.text = entry_pages[current_page]

func _on_left_button_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		entry_text_label.text = entry_pages[current_page]


func _on_flip_pressed() -> void:
	print("SPRITE FLIPPED")
	if poke_image.texture == image_front:
		poke_image.texture = image_back
	else:
		poke_image.texture = image_front
