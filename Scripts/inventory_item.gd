@tool
extends Node2D

#Item details for editor window
@export var item_name = ""
@export var item_texture: Texture
@export var item_effect = ""
var scene_path: String = "res://Scenes/inventory_item.tscn"

#Scene-Tree Node references
@onready var icon_sprite = $Sprite2D

func _enter_tree():
	set_multiplayer_authority(int(str(name))) # Authority = player ID

func _ready():
	# Set texture to reflect in the game
	if not Engine.is_editor_hint():
		icon_sprite.texture = item_texture
		
func pickup_item(body):
	var item = {
		"quantity" : 1,
		"name" : item_name,
		"texture" : item_texture,
		"effect" : item_effect,
		"scene_path" : scene_path,
	}
	print("test1")
	if body is CharacterBody2D and body.is_multiplayer_authority():
		print("test2")
		if body.add_item(item):
			queue_free()

func _on_area_2d_body_entered(body):
	if body is CharacterBody2D and body.is_multiplayer_authority():
		print("Le joueur ", body.name, " est entré dans la zone de collision de ", self)
		body.set_interactable_item(self)

func _on_area_2d_body_exited(body):
	if body is CharacterBody2D and body.is_multiplayer_authority():
		print("Le joueur ", body.name, " est sortit dans la zone de collision de ", self)
		body.set_interactable_item(null)

#Sets the item's dictionnary data
func set_item_data(data):
	item_name = data["name"]
	item_effect = data["effect"]
	item_texture = data["texture"]
		
func _process(delta):
	#Set texture to reflect in the editor
	if Engine.is_editor_hint():
		icon_sprite.texture = item_texture
