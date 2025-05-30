class_name Item
extends Node2D

@onready var INFO: Dictionary[StringName, Variant] = {
	name = "MISSING ITEM",
	texture = "res://Sprites/missingTexture.png",
	description = "MISSING DESCRIPTION",
	scale = Vector2(1.0, 1.0),
	scenePath = "res://Scenes/inventory/item.tscn"
}

@onready var sprite: Sprite2D = $Sprite2D

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func initialize() -> void:
	sprite.texture = INFO.texture
	sprite.scale = INFO.scale

func _ready() -> void:
	# Set texture to reflect in the game
	if not Engine.is_editor_hint():
		sprite.texture = INFO.texture

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Body and body.is_multiplayer_authority():
		body.set_interactable_item(self)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Body and body.is_multiplayer_authority():
		body.set_interactable_item(null)
		
@rpc("authority", "call_local")
func pickup_item(body: Body) -> void:
	var item = {
		"quantity" : 1,
		"name" : INFO.name,
		"texture" : INFO.texture,
		"texture_path" : INFO.texture.resource_path,
		"description" : INFO.description,
		"scenePath" : INFO.scenePath,
	}
	if body.is_multiplayer_authority():
		if body.add_item(item):
			disappear.rpc()
			
# Suppression de l'item
@rpc("any_peer", "call_local")
func disappear() -> void:
	self.queue_free()

# Mettre les données de l'item sur l'item
func set_item_data(data: Dictionary) -> void:
	INFO.name = data["name"]
	INFO.description = data["description"]
	if data.has("texture_path"):
		INFO.texture = load(data["texture_path"])
	elif data.has("texture") and typeof(data["texture"]) == TYPE_STRING:
		INFO.texture = load(data["texture"])
	elif data.has("texture"):
		INFO.texture = data["texture"]
