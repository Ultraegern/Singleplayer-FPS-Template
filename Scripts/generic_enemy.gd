extends CharacterBody3D
class_name Enemy

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

@export var max_health: float = 100
@export_group("Pathfinding")
@export var pathfinding: bool = true
@export var move_speed: float = 3.0
@export var attack_range: float = 2.0
@export var flee_threshold: float = 25.0
@export var patrol_points: Array[Vector3] = [] 
@export_group("Detection")
@export var detection_radius: float = 10.0
@export var field_of_view_deg: float = 90.0 

var health: float
var player_position: Vector3

# -- STATE MACHINE --
enum State { IDLE, PATROL, CHASE, ATTACK, FLEE, DEAD }
var state: State = State.PATROL

var patrol_index: int = 0
var attack_cooldown: float = 0.0

func _ready() -> void:
	health = max_health
	add_to_group("enemy")

func take_damage(damage: float) -> void:
	if state == State.DEAD:
		return
	health -= damage
	if health <= 0.0:
		change_state(State.DEAD)
	elif health <= flee_threshold and not state == State.FLEE:
		change_state(State.FLEE)

func _physics_process(delta: float) -> void:
	attack_cooldown = max(0.0, attack_cooldown - delta)
	
	_detect_player()
	
	match state:
		State.IDLE:
			velocity = Vector3.ZERO
		
		State.PATROL:
			if patrol_points.size() > 0:
				if navigation_agent.is_navigation_finished():
					# Go to the next patrol point
					patrol_index = (patrol_index + 1) % patrol_points.size()
					navigation_agent.set_target_position(patrol_points[patrol_index])
				else:
					_move_along_path()
		
		State.CHASE:
			if player_position.distance_to(global_position) <= attack_range:
				change_state(State.ATTACK)
			elif not navigation_agent.is_navigation_finished():
				_move_along_path()
			else:
				velocity = Vector3.ZERO
		
		State.ATTACK:
			velocity = Vector3.ZERO
			if player_position.distance_to(global_position) > attack_range:
				change_state(State.CHASE)
			elif attack_cooldown == 0.0:
				_perform_attack()
				attack_cooldown = 1.5  # cooldown seconds
		
		State.FLEE:
			# Run away from the player
			var flee_dir = (global_position - player_position).normalized()
			velocity = flee_dir * move_speed * 1.5  # faster than chasing
			# (Optional: navigate towards a safe point instead)
		
		State.DEAD:
			velocity = Vector3.ZERO
			queue_free()
	
	if velocity.length() > 0.1:
		var dir = velocity.normalized()
		var target_yaw = atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 5.0)

	
	
	move_and_slide()

func change_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state

func update_player_position(pos: Vector3) -> void:
	player_position = pos

func _move_along_path() -> void:
	if not navigation_agent.is_navigation_finished():
		var next = navigation_agent.get_next_path_position()
		var direction = (next - global_transform.origin).normalized()
		velocity = direction * move_speed

func _perform_attack() -> void:
	# Replace this with real attack logic later (shooting, melee, etc.)
	print("Enemy attacks the player!")

func _detect_player() -> void:
	var distance = global_position.distance_to(player_position)
	if distance > detection_radius:
		if state == State.CHASE or state == State.ATTACK:
			change_state(State.PATROL)
		return
	
	# Check vision cone
	var dir_to_player = (player_position - global_position).normalized()
	var forward = -global_transform.basis.z.normalized() # local -Z is forward in Godot
	var angle = rad_to_deg(acos(forward.dot(dir_to_player)))
	
	if angle <= field_of_view_deg * 0.5:
		# TODO: you can add raycast here to check line-of-sight
		navigation_agent.set_target_position(player_position)
		if state != State.ATTACK and state != State.FLEE:
			change_state(State.CHASE)
