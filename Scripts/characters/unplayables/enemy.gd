class_name Enemy
extends CharacterBody2D

#region Nodes
@onready var navigationAgent: NavigationAgent2D = $NavigationAgent2D
@onready var animatedSprite: AnimatedSprite2D = $AnimatedSprite2D
#endregion

#region Informations
@export var FOV: float = deg_to_rad(180.00) # Champ de vision de l'ennemi
@export var angleBetweenRays: float = deg_to_rad(5.00) # Angle entre chaque raycast

@export var maxViewDistance: float = 800.00 # Distance maximale à laquelle l'ennemi peut voir
@export var currentSpeed: float = 30.00 # Vitesse actuelle de l'ennemi
@export var runSpeed: float = 50.00
@export var patrolSpeed: float = 30.00

var target: Body # La cible de l'ennemi
var lastSeenTargetPosition: Vector2 # La dernière position d'une cible vue par l'ennemi
var traveledToTarget: bool = true # L'ennemi est-il allé vers la target ou est-il encore en chemin ?

var isRevealed: bool = true
var spriteAlpha: float = 0.00  # entre 0.0 (invisible) et 1.0 (visible)

var nav_map: RID
var navigation_ready: bool = false
var current_patrol_point: Vector2 = Vector2.ZERO
var reached_patrol_point: bool = true
var previousPosition: Vector2
var isMoving: bool
#endregion
		
func _ready() -> void:
	add_to_group("enemies")
	Global.generate_raycasts(self, FOV, angleBetweenRays, maxViewDistance, false)

	nav_map = navigationAgent.get_navigation_map()
	NavigationServer2D.map_changed.connect(_on_navigation_ready)

func _physics_process(delta: float) -> void:
	var anim: String = "idle_S"
	if not navigation_ready: return
	
	""" revealing
	var target_alpha = 1.0 if isRevealed else 0.0
	spriteAlpha = lerp(spriteAlpha, target_alpha, delta * 5.0)

	# Appliquer l'alpha au sprite
	var color = animatedSprite.modulate
	color.a = spriteAlpha 
	animatedSprite.modulate = color
	"""
	animatedSprite.visible = isRevealed
	
	var detectedBodyPosition: Variant = detect_body()
	
	if detectedBodyPosition != null:
		lastSeenTargetPosition = detectedBodyPosition
		navigationAgent.target_position = lastSeenTargetPosition
		traveledToTarget = false
		currentSpeed = runSpeed

	elif not traveledToTarget:
		navigationAgent.target_position = lastSeenTargetPosition
		currentSpeed = runSpeed
		if global_position.distance_to(lastSeenTargetPosition) < 10.0:
			traveledToTarget = true
			reached_patrol_point = true

	elif reached_patrol_point or navigationAgent.is_navigation_finished():
		current_patrol_point = get_random_patrol_point()
		navigationAgent.target_position = current_patrol_point
		currentSpeed = patrolSpeed
		reached_patrol_point = false

	var next_point: Vector2 = navigationAgent.get_next_path_position()
	var direction: Vector2 = (next_point - global_position).normalized()

	if traveledToTarget and global_position.distance_to(current_patrol_point) < 10.0:
		reached_patrol_point = true

	for node in get_children():
		if node is Area2D or node is RayCast2D:
			node.rotation = lerp_angle(node.rotation, direction.angle() + PI / 2, delta * 2.0)
	velocity = velocity.lerp(direction * currentSpeed, 7.0 * delta)
	
	# Tracking de si le joueur a bougé de 0.0100 ou pas
	isMoving = global_position.distance_to(previousPosition) > 0.0100
	var dir: String = Global.vector_to_compass_dir(velocity)
	# Si le joueur bouge, son animation se met à jour
	if isMoving:
		if dir != "None":
			anim = "run_" + dir
	
	update_animated_sprite(anim)
	previousPosition = self.global_position
	move_and_slide()
	
func update_animated_sprite(anim: String) -> void:
	animatedSprite.animation = anim
	animatedSprite.play(anim)

# Retourne la position d'un Body détécté par les RayCast2D de l'ennemi. Si aucun en est détécté, retourne null
func detect_body() -> Variant:
	for ray in get_children():
		if ray is RayCast2D and ray.is_colliding():
			var collider: Node = ray.get_collider()
			if collider is Body:
				return collider.global_position
	return null
	
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
			print("Un ennemi a attaqué un joueur")
			Global.get_player_node("body").take_damage(15.00, true)

func get_random_patrol_point() -> Vector2:
	if not navigation_ready: return self.global_position
	if nav_map == null: return global_position
	
	var patrol_range: float = 800.00
	var random_point: Vector2 = global_position + Vector2(
		randf_range(-patrol_range, patrol_range),
		randf_range(-patrol_range, patrol_range)
	)

	return NavigationServer2D.map_get_closest_point(nav_map, random_point)
