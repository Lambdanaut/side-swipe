extends TileMap

# Load modules
onready var Binheap = load("res://scripts/binheap.gd")

const BASE_LINE_WIDTH = 3.0
const DRAW_COLOR = Color.white

export(Vector2) var map_size = Vector2.ONE * 20

var path_start_position = Vector2() setget _set_path_start_position
var path_end_position = Vector2() setget _set_path_end_position

var _point_path = []

# get_used_cells_by_id is a method from the TileMap node.
# Here the id 0 corresponds to the grey tile, the obstacles.
onready var obstacles = get_used_cells()
onready var _half_cell_size = cell_size / 2

func _ready():
    var walkable_cells_list = get_walkable_cells(obstacles)
    var path = pathfinding(Vector2(15,3),Vector2(3, 3), walkable_cells_list)
    print(path)
    
func pathfinding(start, goal, grid):
    # Initialize the open set to only include the starting node
    var open_set = Binheap.new()
    open_set.insert([pathfinding_h(start, goal), start])
    
    # Map from node N to parent of node N
    var came_from = {}
    
    # Map from node N to the cost of the cheapest path to node N known
    var g_scores = {}
    g_scores[start] = 0

    while not open_set.is_empty():
        # Current node we're investigating
        var current_node = open_set.pop()[1]
        
        if current_node == goal:
            # Goal found. reconstruct the path working backwards from the goal 
            # node to the start node.
            var total_path = [current_node]
            while current_node in came_from.keys():
                current_node = came_from[current_node]
                total_path.insert(0, current_node)
            
            return total_path
        
        for neighbor in get_vector_adjacents(current_node):
            if not (neighbor in grid):
                continue
                
            # d(current,neighbor) is the weight of the edge from current to neighbor
            # tentative_gScore is the distance from start to the neighbor through current
            var tentative_g_score = g_scores[current_node] + pathfinding_tile_move_cost(current_node, neighbor)
            
            var neighbors_g_score = g_scores.get(neighbor, INF)
            if tentative_g_score < neighbors_g_score:
                # This path to neighbor is better than any previous one. Record it!
                came_from[neighbor] = current_node
                g_scores[neighbor] = tentative_g_score
                
                var new_f_score = tentative_g_score + pathfinding_h(neighbor, goal)
            
                if not (neighbor in open_set):
                    open_set.insert([new_f_score, neighbor])
                
    # Open set is empty but goal was never reached
    return []

func pathfinding_tile_move_cost(current_node, neighbor):
    return 0

func get_vector_adjacents(n: Vector2):
    return [
        Vector2(n.x+1, n.y),
        Vector2(n.x-1, n.y),
        Vector2(n.x, n.y+1),
        Vector2(n.x, n.y-1),
    ]

func pathfinding_h(p1: Vector2, p2: Vector2):
    return p1.distance_to(p2)

func get_walkable_cells(obstacle_list = []):
    # Returns a list of all walkable grid cells.
    var points_array = []
    for y in range(map_size.y):
        for x in range(map_size.x):
            var point = Vector2(x, y)

            if point in obstacle_list:
                continue
                
            points_array.append(point)
            
    return points_array

func is_outside_map_bounds(point):
    return point.x < 0 or point.y < 0 or point.x >= map_size.x or point.y >= map_size.y

func _recalculate_path():
    pass

# Setters for the start and end path values.
func _set_path_start_position(value):
    if value in obstacles:
        return
    if is_outside_map_bounds(value):
        return

    set_cell(path_start_position.x, path_start_position.y, -1)
    set_cell(value.x, value.y, 1)
    path_start_position = value
    if path_end_position and path_end_position != path_start_position:
        _recalculate_path()

func _set_path_end_position(value):
    if value in obstacles:
        return
    if is_outside_map_bounds(value):
        return

    set_cell(path_start_position.x, path_start_position.y, -1)
    set_cell(value.x, value.y, 2)
    path_end_position = value
    if path_start_position != value:
        _recalculate_path()

