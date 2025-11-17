extends CharacterBody3D

const SPEED = 10.0
const HEADBOB_MOVE_AMOUNT := 0.04
const HEADBOB_FREQ := 1.4

@export var jump_height: float = 1.5
@export var fall_multiplier: float = 1.5

@export var air_cap := 1.2
@export var air_accel := 800.0
@export var air_move_speed := 500.0
@export var crouch_speed: float= 5
@export var walk_speed: float= 10
@export var sprint_speed: float= 15
@export var ground_accel: float= 14
@export var ground_deccel: float= 10
@export var ground_fric: float= 5.0
@export var sliding_fric: float= 1.6
@export var speed_limit := 35

var is_crouched: bool= false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_motion := Vector2.ZERO
var headbob_time := 0.0
var lerp_speed := 10
var is_sliding := false

@onready var camera_pivot: Node3D = $CameraPivot
@onready var animation_player = %AnimationPlayer
@onready var player_arms = %player_arms

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if(velocity.length() <= sprint_speed and !Input.is_action_pressed("crouch")):
		is_sliding = false
	#Call camera motion function
	handle_camera_rotation()
	if velocity.length() > 0.0 and is_on_floor():
		animation_player.play("RUN", 1.2, get_move_speed() * .08)
	else:
		animation_player.play("IDLE", 1.2)
		
	# Add the gravity. And uses a different function to handle air movement.
	if not is_on_floor():
		air_physics(delta)

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = sqrt(jump_height * 3.0 * gravity)
		
	if Input.is_action_pressed("crouch") and Input.is_action_pressed("sprint") and is_on_floor():
		slide(delta)
	
	if Input.is_action_pressed("crouch") and !is_sliding:
		crouch(delta, input_dir)
	elif $CollisionShape3D.scale.y != 1 and not test_move(transform, Vector3(0,2,0)):
		$CollisionShape3D.scale.y = lerp($CollisionShape3D.scale.y,1.0,delta*lerp_speed)

	# Get the input direction and handle the movement/deceleration. This is cursed, but alas what can I do
	# As good practice, you should replace UI actions with custom gameplay actions.
	# Turning off movement in air, replacing with air strafing, can change at any point
	if is_on_floor():
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		movement(delta, direction, get_move_speed())
		
	move_and_slide()

	headbob_time += delta * velocity.length() * float(is_on_floor())
	camera_pivot.transform.origin = headbob_effect(headbob_time)
	#print(delta)
	

func _input(event: InputEvent) -> void:
	#Listens for mouse movement
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_motion = -event.relative * 0.001
	
	#Checks to see if escape is just pressed then flips mouse mode
	if event.is_action_pressed("escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#Function to return a set movespeed, I don't like this
func get_move_speed() -> float:
	if Input.is_action_pressed("sprint") and !Input.is_action_pressed("crouch"):
		return sprint_speed
	if Input.is_action_pressed("crouch") and !is_sliding:
		return crouch_speed
	if(Input.is_action_pressed("crouch") and Input.is_action_pressed("sprint") and is_sliding):
		return get_slide_speed()
	else:
		return walk_speed
		
func get_slide_speed() -> float:
	print("VELOCITY SPD", velocity.length());
#	TODO: We need to fix the velocity calculation here to lower velocity slower
	return velocity.length()

func crouch(delta: float, input: Vector2) -> void:
	#print("CROUCH")
	print(is_on_floor())
	$CollisionShape3D.scale.y = lerp($CollisionShape3D.scale.y,0.3333, delta*lerp_speed)
		
func slide(delta) -> void:
	#print("slide")
	if(!is_sliding && velocity.length() < speed_limit):
		print("SLIDE!!!!!!!!!!!!!!!!!!", delta)
		velocity.x += lerp(velocity.x, velocity.x, delta * lerp_speed)/2 #was velocity.x * 8
		velocity.z += lerp(velocity.z, velocity.z, delta * lerp_speed)/2
		is_sliding = true;
	
	
	
#This allows surfing
func clip_velocity(normal: Vector3, overbounce: float, delta: float) -> void:
	var backoff := velocity.dot(normal) * overbounce
	
	if backoff >= 0: return
	
	var change := normal * backoff
	velocity -= change
	
	var adjust := velocity.dot(normal)
	if adjust < 0.0:
		velocity -= normal * adjust

#Helper fucnction for Surfing
func is_surface_too_steep(normal: Vector3) -> bool:
	var max_slope_ang_dot = Vector3(0,1,0).rotated(Vector3(1,0,0), floor_max_angle).dot(Vector3(0,1,0))
	
	if normal.dot(Vector3(0,1,0)) < max_slope_ang_dot:
		return true
	return false

func air_physics(delta: float) -> void:
	if velocity.y >= 0:
		velocity += get_gravity() * delta
	else:
		velocity += get_gravity() * delta * fall_multiplier
	
	#anything below this is for air strafing, don't ask why I did what I did, you can but decaling vars in an if statement is wild
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var cur_speed_in_dir = velocity.dot(direction)
	var capped_speed = min((air_move_speed * direction).length(), air_cap)
	var add_speed_till_cap = capped_speed - cur_speed_in_dir
	
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		velocity += accel_speed * direction
	#This makes surfing feel better I guess, watch the youtube video he told me to
	if is_on_wall():
		if is_surface_too_steep(get_wall_normal()):
			motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		clip_velocity(get_wall_normal(), 1, delta)
		
func movement(delta: float, direction: Vector3, movement_speed: float) -> void:
	var cur_speed_in_direction = velocity.dot(direction)
	var add_speed_till_cap = movement_speed - cur_speed_in_direction
		
	if add_speed_till_cap > 0 and !is_sliding:
		var accel_speed = ground_accel * delta * movement_speed
		accel_speed = min(accel_speed, add_speed_till_cap)
		if((velocity + accel_speed * direction).length() < speed_limit):
			velocity += accel_speed * direction
		
			
	var new_speed = 0;
	if !is_sliding:
		var control = max(velocity.length(), ground_deccel)
		var drop = control * ground_fric * delta
		new_speed = max(velocity.length() - drop, 0.0)
	if is_sliding:
		var control = max(velocity.length(), ground_deccel)
		var drop = control * (sliding_fric) * delta
		new_speed = max(velocity.length() - drop, 0.0)
	
	if velocity.length() > 0:
		new_speed /= velocity.length()
	velocity *= new_speed
	

#Adds the headbob
func headbob_effect(time: float) -> Vector3:
	var headbob_position = Vector3.ZERO
	headbob_position.y = 1.75 + sin(headbob_time * HEADBOB_FREQ) * HEADBOB_MOVE_AMOUNT
	headbob_position.x = sin(headbob_time * HEADBOB_FREQ / 2) * HEADBOB_MOVE_AMOUNT
	
	return headbob_position

func handle_camera_rotation() -> void:
	rotate_y(mouse_motion.x)
	camera_pivot.rotate_x(mouse_motion.y)
	camera_pivot.rotation_degrees.x = clampf(
		camera_pivot.rotation_degrees.x,
		-90,
		90
	)
	
	#var update_rot = %player_arms.sway(mouse_motion)
	#%player_arms.update_position_rotation(update_rot)
	
	#Zero out the camera movement vector
	mouse_motion = Vector2.ZERO
