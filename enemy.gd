class_name Enemy
extends CharacterBody2D

# Noeuds de l'ennemi
@onready var NODES: Dictionary[StringName, Node] = {
	navigationAgent = $NavigationAgent2D
}

# Informations de l'ennemi
@export var INFO: Dictionary[StringName, Variant] = {
	FOV = deg_to_rad(180.00),
	angleBetweenRays = deg_to_rad(5.00),
	
	maxViewDistance = 800.00,
	speed = 100.00,

	target = null,
	lastSeenPlayerPosition = null
}

func _ready() -> void:
	generate_raycasts()

func generate_raycasts() -> void:
	var raysToGenerate: int = int(INFO.FOV / INFO.angleBetweenRays)

	for i in range(raysToGenerate):
		var ray: RayCast2D = RayCast2D.new()
		var angle : float= INFO.angleBetweenRays * (i - raysToGenerate / 2.0)
		ray.target_position = Vector2.UP.rotated(angle) * INFO.maxViewDistance
		self.add_child(ray)
		ray.enabled = false

# Activer le raycasting de l'ennemi seulement s'il l'hote est autour de lui 
func _on_FOV_body_entered(body: Node2D) -> void:
	if body is Player and body.INFO.isHosting:
		for ray: Node in self.get_children():
			if ray is RayCast2D:
				ray.enabled = true

func _on_FOV_body_exited(body: Node2D) -> void:
	if body is Player and body.INFO.isHosting:
		for ray: Node in self.get_children():
			if ray is RayCast2D:
				ray.enabled = false

func _on_hit_radius_body_entered(body: Node2D) -> void:
	if body is Player and body.INFO.isHosting:
		if INFO.target != null:
				INFO.target.NODES.bleeding.emitting = true
				INFO.target.INFO.idleStaminaGain = 1.00
		
func _physics_process(delta: float) -> void:
	INFO.target = null

	for ray: Node in self.get_children():
		if ray is RayCast2D:
			if ray.is_colliding() and ray.get_collider() is Player and ray.get_collider().INFO.isHosting:
				INFO.target = ray.get_collider()
				INFO.lastSeenPlayerPosition = INFO.target.global_position

	if INFO.lastSeenPlayerPosition:
		if self.global_position.distance_to(INFO.lastSeenPlayerPosition) > 1.0:
			
			NODES.navigationAgent.target_position = INFO.lastSeenPlayerPosition
			var next_point = NODES.navigationAgent.get_next_path_position()
			var direction = (next_point - global_position).normalized()
			
			self.rotation = lerp_angle(rotation, direction.angle() + 90, delta * 20.00)
			velocity = direction * INFO.speed
			set_velocity(velocity)
			move_and_slide()
