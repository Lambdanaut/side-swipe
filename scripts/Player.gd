extends KinematicBody2D

# Load modules
onready var Terrain = get_parent().get_node("Terrain")
onready var GoalMarking = load("res://Goal-marking.tscn")

# Physics
const ACCELERATION = 512
const MAX_SPEED = 64
const FRICTION = 0.25
const AIR_RESISTANCE = 0.02
const GRAVITY = 180
const JUMP_FORCE = 120
enum States { IDLE, FOLLOW }

var velocity = Vector2.ZERO
var is_moving = false
var is_jumping = false

# Pathfinding
const AI_JUMP_LIMIT = 4
const PATHFINDING_MIN_NODE_DISTANCE = 18
var current_state = null
var current_path = []
var next_path_node = Vector2()
var path_goal_node = Vector2()
var goal_debug_markers = []

onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer

func _ready():
    change_state(States.IDLE)

func _physics_process(delta):
    var x_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    is_moving = false  # reset moving flag

    # Apply gravity
    velocity.y += GRAVITY * delta

    if is_on_floor():
        is_jumping = false
        
    # Do pathfinding to next node in path
    run_ai()
        
    if x_input != 0:
        move(x_input)

    if is_on_floor():
        if not is_moving:
            velocity.x = lerp(velocity.x, 0, FRICTION)
            animation_player.play("Stand")
    else:
        if Input.is_action_just_released("ui_up"):
            stop_jumping()

        if not is_moving:
            velocity.x = lerp(velocity.x, 0, AIR_RESISTANCE)
    
    if Input.is_action_just_pressed("ui_up"):
        jump()
        
    velocity = move_and_slide(velocity, Vector2.UP)

func _input(event):
    if event.is_action_pressed("click"):
        var global_mouse_pos = get_global_mouse_position()
        if Input.is_key_pressed(KEY_SHIFT):
            global_position = global_mouse_pos
        else:
            path_goal_node = (global_mouse_pos / 16).floor()
            change_state(States.FOLLOW)

func change_state(new_state):
    current_state = new_state
    if new_state == States.FOLLOW:
        set_path(path_goal_node)

func set_path(target):
    current_path = Terrain.pathfinding((global_position / 16).floor(), target, AI_JUMP_LIMIT)
    current_path = adjust_path(current_path)

    if not current_path or len(current_path) == 1:
        change_state(States.IDLE)
        return
        
    for marker in goal_debug_markers:
        marker.queue_free()
            
    goal_debug_markers = []
    for n in [current_path[-1]]:
        var marker = GoalMarking.instance()

        get_tree().get_root().get_node("World").add_child(marker)

        marker.global_position = n[0]*16
        goal_debug_markers.append(marker)
            
    # The index 0 is the starting cell
    # we don't want the character to move back to it
    next_path_node = current_path[1]
    
func run_ai():
    if current_state == States.FOLLOW:
        if is_on_floor() and position.distance_to(next_path_node[0]*16) > 28:
            set_path(path_goal_node)
            
        var arrived_to_next_point = move_to(next_path_node)
        if arrived_to_next_point:
            current_path.remove(0)
            if len(current_path) == 0:
                change_state(States.IDLE)
            else:
                next_path_node = current_path[0]

func move_to(p):
    var adjusted_point = p[0] * 16
    var jumping_val = p[1]
    var distance = position.distance_to(adjusted_point)
    
    # Horizontal movement
    var x_input = 1 if adjusted_point.x - global_position.x > 0 else -1
    move(x_input)
    
    # Vertical movement
    if jumping_val > 0 and jumping_val < AI_JUMP_LIMIT+1:
        if adjusted_point.y < position.y:
            jump()
        else:
            stop_jumping()
    
        
    var node_reached = distance < PATHFINDING_MIN_NODE_DISTANCE and (jumping_val or is_on_floor())
    
    return node_reached

func move(x_input):
    if not is_moving and not is_jumping:
        animation_player.play("Run")

    is_moving = true
    velocity.x += x_input * ACCELERATION * get_physics_process_delta_time()
    velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
    sprite.flip_h = x_input < 0
    
func jump():
    if is_on_floor():
        is_jumping = true
        animation_player.play("Jump")
        velocity.y = -JUMP_FORCE
    
func stop_jumping():
    if not is_on_floor() and velocity.y < -JUMP_FORCE/2:
        velocity.y = -JUMP_FORCE/2

func adjust_path(path):
    var adjusted_path = []
    for p in path:
        p[0] += Vector2(0.5, 0.5)
        adjusted_path.append(p)
    return adjusted_path

func is_diagonal(p1, p2):
    var diagonals = [
        Vector2(p1.x+1, p1.y+1),
        Vector2(p1.x+1, p1.y-1),
        Vector2(p1.x-1, p1.y+1),
        Vector2(p1.x-1, p1.y-1),
    ]
    for p in diagonals:
        if p2 == p:
            return true
    return false
