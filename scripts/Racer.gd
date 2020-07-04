extends KinematicBody2D

# Load modules
onready var Terrain = get_parent().get_node("Terrain")
onready var GoalMarking = load("res://Goal-marking.tscn")

# Physics
const ACCELERATION = 700
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
const AI_REPATH_TIMER_LIMIT = 1.5
var current_state = null
var current_path = []
var next_path_node = Vector2()
var path_goal_node = Vector2()
var goal_debug_markers = []
var ai_repath_timer = 0

var is_ai = true

onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer

func _ready():
    modulate = Color(randf(), randf(), randf())
    change_state(States.IDLE)

func _physics_process(delta):
    var x_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    is_moving = false  # reset moving flag

    # Apply gravity
    velocity.y += GRAVITY * delta

    if is_on_floor():
        is_jumping = false
        
    # Do pathfinding to next node in path
    if is_ai:
        run_ai()
        
    if x_input != 0 and not is_ai:
        move(x_input)

    if is_on_floor():
        if not is_moving:
            velocity.x = lerp(velocity.x, 0, FRICTION)
            animation_player.play("Stand")
    else:
        if Input.is_action_just_released("ui_up") and not is_ai:
            stop_jumping()

        if not is_moving:
            velocity.x = lerp(velocity.x, 0, AIR_RESISTANCE)
    
    if Input.is_action_just_pressed("ui_up") and not is_ai:
        jump()
        
    velocity = move_and_slide(velocity, Vector2.UP)

func _input(event):
    if is_ai:
        if event.is_action_pressed("click"):
            var global_mouse_pos = get_global_mouse_position()

            path_goal_node = (global_mouse_pos / 16).floor()
            change_state(States.FOLLOW)

func change_state(new_state):
    current_state = new_state
    if new_state == States.FOLLOW:
        ai_repath_timer = 0
        set_path(path_goal_node)
    
func run_ai():
    if current_state == States.FOLLOW:
        ai_repath_timer += get_physics_process_delta_time()
        
        if is_on_floor() and ai_repath_timer > AI_REPATH_TIMER_LIMIT:
            set_path(path_goal_node)
            
        var arrived_to_next_point = move_to(next_path_node)
        if arrived_to_next_point:
            current_path.remove(0)
            if len(current_path) == 0:
                change_state(States.IDLE)
            else:
                next_path_node = current_path[0]
                ai_repath_timer = 0
#                goal_debug_markers.pop_front().queue_free()
                
func set_path(target):
    current_path = Terrain.pathfinding((global_position / 16).floor(), target, AI_JUMP_LIMIT)
    current_path = smooth_path(adjust_path(current_path))

    if not current_path or len(current_path) == 1:
        change_state(States.IDLE)
        return
        
    for marker in goal_debug_markers:
        marker.queue_free()
            
#    goal_debug_markers = []
#    for n in current_path:
#        var marker = GoalMarking.instance()
#
#        get_tree().get_root().get_node("World").add_child(marker)
#
#        marker.global_position = n[0]*16
#        goal_debug_markers.append(marker)
            
    # The index 0 is the starting cell
    # we don't want the character to move back to it
    next_path_node = current_path[1]
    
func move_to(p):
    var adjusted_point = p[0] * 16
    var jumping_val = p[1]
    var distance = position.distance_to(adjusted_point)
    
    # Horizontal movement
    var x_input = 1 if adjusted_point.x - position.x > 0 else -1
    move(x_input)
    
    # Vertical movement
    if (jumping_val > 0) or adjusted_point.y + 8 < position.y:
        if jumping_val < AI_JUMP_LIMIT+1:
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
    
func smooth_path(path):
    return path
    if not path:
        return []
        
    # Start smoothed path with start node
    var smoothed_path = [path[0],]
    for p_i in range(1, len(path)-1):        
        var p = path[p_i]
        var p_p = p[0]
        var p_jump = p[1]
        
        var p_next = path[p_i + 1]
        var p_next_p = p_next[0]
        var p_next_jump = p_next[1]
        
        var p_prev = path[p_i - 1]
        var p_prev_p = p_prev[0]
        var p_prev_jump = p_prev[1]
        
#        # Skip middle of 3 consecutive vertical nodes
#        if p_prev_p.x == p_p.x and p_p.x == p_next_p.x:
#            continue
#        # Skip middle of 3 consecutive horizontal nodes
#        if p_prev_p.y == p_p.y and p_p.y == p_next_p.y:
#            continue       
  
        if p_next_jump == 0 and p_jump > 0:
            continue   
      
        smoothed_path.append(p)
        
    # Add end node
    smoothed_path.append(path[-1])
        
    return smoothed_path

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
