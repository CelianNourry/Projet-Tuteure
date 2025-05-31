class_name Item
extends Node2D

#region Nodes
@onready var sprite: Sprite2D = $Sprite2D
#endregion

#region Informations
@onready var itemName: String = "MISSING ITEM"
@onready var itemTexture: Texture2D = preload("res://Sprites/missingTexture.png")
@onready var itemDescription: String = "MISSING DESCRIPTION"
@onready var itemScale: Vector2 = Vector2(1.00, 1.00)
@onready var itemScenePath: String = "res://Scenes/inventory/item.tscn"
#endregion

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func initialize() -> void:
	sprite.texture = itemTexture
	sprite.scale = itemScale

func _ready() -> void:
	# Set texture to reflect in the game
	if not Engine.is_editor_hint():
		sprite.texture = itemTexture

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Body and body.is_multiplayer_authority():
		body.set_interactable_item(self)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Body and body.is_multiplayer_authority():
		body.set_interactable_item(null)
		
@rpc("authority", "call_local")
func pickup_item(body: Body) -> void:
	var item: Dictionary[String, Variant] = {
		"quantity" : 1,
		"name" : itemName,
		"texture" : itemTexture,
		"texture_path" : itemTexture.resource_path,
		"description" : itemDescription,
		"scenePath" : itemScenePath,
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
	name = data["name"]
	itemDescription = data["description"]
	if data.has("texture_path"):
		itemTexture = load(data["texture_path"])
	elif data.has("texture") and typeof(data["texture"]) == TYPE_STRING:
		itemTexture = load(data["texture"])
	elif data.has("texture"):
		itemTexture = data["texture"]
