@tool
extends Node2D

#Item details for editor window
@export var item_name: String
@export var item_texture: Texture
@export var item_effect: String
const scene_path: String = "res://Scenes/inventory_item.tscn"

@onready var icon_sprite: Sprite2D = $Sprite2D

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	# Set texture to reflect in the game
	if not Engine.is_editor_hint():
		icon_sprite.texture = item_texture
		
@rpc("authority", "call_local")
func pickup_item(body: Node2D) -> void:
	var item: Dictionary = {
		"quantity" : 1,
		"name" : item_name,
		"texture" : item_texture,
		"texture_path" : item_texture.resource_path,
		"effect" : item_effect,
		"scene_path" : scene_path,
	}
	if body is CharacterBody2D and body.is_multiplayer_authority():
		if body.add_item(item):
			disappear.rpc()

@rpc("any_peer", "call_local")
func disappear() -> void:
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority() and body.INFO.isHosting:
		print("Joueur %s entré dans %s" % [body.name, item_name])
		body.set_interactable_item(self)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority() and body.INFO.isHosting:
		print("Joueur %s sortit de %s" % [body.name, item_name])
		body.set_interactable_item(null)

#Sets the item's dictionnary data
func set_item_data(data: Dictionary) -> void:
	item_name = data["name"]
	item_effect = data["effect"]
	if data.has("texture_path"):
		item_texture = load(data["texture_path"])
	elif data.has("texture") and typeof(data["texture"]) == TYPE_STRING:
		item_texture = load(data["texture"])
	elif data.has("texture"):
		item_texture = data["texture"]
		
func _process(_delta: float) -> void:
	#Set texture to reflect in the editor
	if Engine.is_editor_hint():
		icon_sprite.texture = item_texture
