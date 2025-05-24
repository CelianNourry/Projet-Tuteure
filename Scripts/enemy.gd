class_name Enemy
extends CharacterBody2D

# Noeuds de l'ennemi
@onready var NODES: Dictionary[StringName, Node] = {
	navigationAgent = $NavigationAgent2D,
	sprite = $Sprite2D
}

# Informations de l'ennemi
@export var INFO: Dictionary[StringName, Variant] = {
	FOV = deg_to_rad(180.00), # Champ de vision de l'ennemi
	angleBetweenRays = deg_to_rad(5.00), # Angle entre chaque raycast
	
	maxViewDistance = 800.00, # Distance maximale à laquelle l'ennemi peut voir
	speed = 30.00, # Vitesse de l'ennemi

	target = null, # La cible del'ennemi
	lastSeenTargetPosition = null, # La dernière position d'une cible vue par l'ennemi
	traveledToTarget = true, # L'ennemi est-il allé vers la target ou est-il encore en chemin ?
	
	isRevealed = false,
	spriteAlpha = 0.0  # entre 0.0 (invisible) et 1.0 (visible)
}

var nav_map: RID
var navigation_ready := false
var current_patrol_point: Vector2 = Vector2.ZERO
var reached_patrol_point := true
		
func _ready() -> void:
	add_to_group("enemies")
	Global.generate_raycasts(self, INFO.FOV, INFO.angleBetweenRays, INFO.maxViewDistance, false)

	# Obtenir le RID de la carte de navigation de ce NavigationAgent2D
	nav_map = NODES.navigationAgent.get_navigation_map()

	# Connecte-toi au signal pour savoir quand la carte est prête
	NavigationServer2D.map_changed.connect(_on_navigation_ready)

	
func _on_navigation_ready(map_rid: RID) -> void:
	if map_rid == nav_map:
		navigation_ready = true

# Activer le raycasting de l'ennemi seulement s'il l'hote est autour de lui 
func _on_FOV_body_entered(body: Node2D) -> void:
	if body is Body:
		for ray: Node in self.get_children():
			if ray is RayCast2D:
				ray.enabled = true

func _on_FOV_body_exited(body: Node2D) -> void:
	if body is Body:
		for ray: Node in self.get_children():
			if ray is RayCast2D:
				ray.enabled = false

func _on_hit_radius_body_entered(body: Node2D) -> void:
	if body is Body:
		if INFO.target != null:
			print("Un ennemi a attaqué un joueur")
			INFO.target.NODES.bleeding.emitting = true
			INFO.target.INFO.idleStaminaGain = 1.00

func get_random_patrol_point() -> Vector2:
	
	if not navigation_ready:
		return self.global_position
		
	if nav_map == null:
		return global_position
	
	# Définis la taille de la carte (par exemple : un carré autour de la position actuelle)
	var patrol_range := 800.00
	var random_point := global_position + Vector2(
		randf_range(-patrol_range, patrol_range),
		randf_range(-patrol_range, patrol_range)
	)
	
	# Trouve le point navigable le plus proche
	var valid_point = NavigationServer2D.map_get_closest_point(nav_map, random_point)
	return valid_point

func _physics_process(delta: float) -> void:
	if not navigation_ready:
		return
	
	"""
	var target_alpha = 1.0 if INFO.isRevealed else 0.0
	INFO.spriteAlpha = lerp(INFO.spriteAlpha, target_alpha, delta * 5.0)

	# Appliquer l'alpha au sprite
	var color = NODES.sprite.modulate
	color.a = INFO.spriteAlpha 
	NODES.sprite.modulate = color
	"""
	NODES.sprite.visible = INFO.isRevealed

	INFO.target = null
	for ray in get_children():
		if ray is RayCast2D and ray.is_colliding():
			var collider = ray.get_collider()
			if collider is Body:
				INFO.target = collider
				INFO.lastSeenTargetPosition = collider.global_position
				INFO.traveledToTarget = false
				break

	if INFO.target:
		NODES.navigationAgent.target_position = INFO.lastSeenTargetPosition
		INFO.speed = 50.0

	elif not INFO.traveledToTarget:
		NODES.navigationAgent.target_position = INFO.lastSeenTargetPosition
		INFO.speed = 50.0
		if global_position.distance_to(INFO.lastSeenTargetPosition) < 10.0:
			INFO.traveledToTarget = true
			reached_patrol_point = true

	elif reached_patrol_point or NODES.navigationAgent.is_navigation_finished():
		current_patrol_point = get_random_patrol_point()
		NODES.navigationAgent.target_position = current_patrol_point
		INFO.speed = 30.0
		reached_patrol_point = false

	var next_point = NODES.navigationAgent.get_next_path_position()
	var direction = (next_point - global_position).normalized()

	if INFO.traveledToTarget and global_position.distance_to(current_patrol_point) < 10.0:
		reached_patrol_point = true

	for node in get_children():
		if node is Sprite2D or node is Area2D or node is RayCast2D:
			node.rotation = lerp_angle(node.rotation, direction.angle() + PI / 2, delta * 2.0)
	velocity = velocity.lerp(direction * INFO.speed, 7.0 * delta)
	move_and_slide()
