extends CharacterBody3D
class_name Player

@onready var camera: Camera3D = $Neck/Camera3D
@onready var neck: Node3D = $Neck
@onready var gun_ray_cast: RayCast3D = $Neck/GunRayCast3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var sensitivity: float = 0.005
@export var gun_scenes: Array[PackedScene]

var guns: Array[Gun] = []
var gun_timers: Array[Timer] = []
var curently_selected_gun: int = 0

func _ready():
	for gun_scene in gun_scenes:
		instantiate_gun(gun_scene)

func instantiate_gun(gun_scene: PackedScene) -> void:
	var gun = gun_scene.instantiate()
	if gun is Gun:
		neck.add_child(gun)
		guns.append(gun)
		var timer = Timer.new()
		gun.add_child(timer)
		gun_timers.append(timer)
	else:
		push_warning("%s is not a Gun!" % gun_scene.resource_path)
	switch_gun()

func _unhandled_input(event: InputEvent) -> void:
	#Camera control
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity)
		neck.rotate_x(-event.relative.y * sensitivity)
	neck.rotation.x = clamp(neck.rotation.x, deg_to_rad(-90.0), deg_to_rad(90.0))
	
	#Mouse capturing
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	#Fire gun
	if event.is_action_pressed("Shoot"):
		if gun_ray_cast.is_colliding():
			if gun_ray_cast.get_collider() is Enemy and gun_timers[curently_selected_gun].time_left <= 0.0:
				gun_ray_cast.get_collider().take_damage(guns[curently_selected_gun].damage)
				gun_timers[curently_selected_gun].start(1 / (guns[curently_selected_gun].fire_rate))
				print(curently_selected_gun)
				print(guns[curently_selected_gun].damage)


#Hide/show guns
func switch_gun() -> void:
	for index in guns.size():
		if curently_selected_gun == index:
			guns[index].show()
		else:
			guns[index].hide()

func _process(_delta: float) -> void:
	#Change gun
	if Input.is_action_just_pressed("Next_Gun"):
		curently_selected_gun = (curently_selected_gun + 1) % (guns.size())
		switch_gun()
	elif Input.is_action_just_pressed("Previous_Gun"):
		curently_selected_gun = (curently_selected_gun - 1 + guns.size()) % guns.size()
		switch_gun()


func _physics_process(delta: float) -> void:
	#Movement
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	var input_dir: Vector2 = Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
