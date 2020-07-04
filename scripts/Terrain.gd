extends TileMap

# Load modules
var Binheap = load("res://scripts/binheap.gd")

const BASE_LINE_WIDTH = 3.0
const DRAW_COLOR = Color.white

export(Vector2) var map_size = Vector2.ONE * 20

var _point_path = []

func _ready():
    pass
    
func pathfinding(start, goal, jump_limit=INF, grid=null):
    # Returns the path from start to goal, as an array of arrays [[p1, jumpval], [p2, jumpval] ...]

    if not grid:
        grid = get_walkable_cells(get_used_cells())
        
    # Number of jumps performed in this search so far
    var jump_i = 0
    
    # 3D start node with jump addition
    var start_node_3D = Vector3(start.x, start.y, jump_i)

    # Initialize the open set to only include the starting node
    var open_set = Binheap.new()
    open_set.insert([pathfinding_h(start, goal), [start_node_3D, 0] ])
    
    # Map from node N to parent of node N, storing jump values
    var came_from = {}
    
    # Map from node N to the cost of the cheapest path to node N known
    var g_scores = {}
    g_scores[start_node_3D] = 0

    while not open_set.is_empty():
        # Current node we're investigating
        var current = open_set.pop()[1]
        var current_node_3D = current[0]
        var current_node_jump = current[1]
        var current_node_jump_i = current_node_3D.z
        var current_node_2D = Vector2(current_node_3D.x, current_node_3D.y)
        
        if current_node_2D == goal:
            # Goal found. reconstruct the path working backwards from the goal 
            # node to the start node.
            var total_path = [[Vector2(current_node_3D.x, current_node_3D.y), current_node_jump]]
            
            var came_from_keys = came_from.keys()
            
            while current_node_3D in came_from_keys:
                current = came_from[current_node_3D]
                current_node_3D = current[0]
                
                var to_return = [Vector2(current_node_3D.x, current_node_3D.y), current[1]]
                total_path.insert(0, to_return)
            
            return total_path
        
        for neighbor in get_neighbors(current_node_2D, current_node_jump, grid, jump_limit):
            var neighbor_node_2D = neighbor[0]
            var neighbor_jump = neighbor[1]
            
            if not (neighbor_node_2D in grid):
                # Ignore impassable nodes
                continue
                
            # Add jump dimension to number the jump out of all jumps searched
            if neighbor_jump > 0:
                if current_node_jump == 0:
                    # New jump initiated. Increment jump counter
                    jump_i += 1
                    neighbor.append(jump_i)
                else:
                    # Jump continuation. Maintain jump counter
                    neighbor.append(current_node_jump_i)
            else:
                # Not jumping. No jump index needed
                neighbor.append(0)
                
            var neighbor_jump_i = neighbor[2]
            var neighbor_node_3D = Vector3(neighbor_node_2D.x, neighbor_node_2D.y, neighbor_jump_i)
            
            # d(current,neighbor) is the weight of the edge from current to neighbor
            # tentative_gScore is the distance from start to the neighbor through current
            var tentative_g_score = g_scores[current_node_3D] + pathfinding_tile_move_cost(current_node_3D, neighbor_node_3D)
            
            var neighbors_g_score = g_scores.get(neighbor_node_3D, INF)
            if tentative_g_score < neighbors_g_score:
                # This path to neighbor is better than any previous one. Record it!
                
                came_from[neighbor_node_3D] = current
                g_scores[neighbor_node_3D] = tentative_g_score
                
                var new_f_score = tentative_g_score + pathfinding_h(neighbor_node_2D, goal)

                var neighbor_3D = [neighbor_node_3D, neighbor_jump]

                if not open_set.contains(neighbor_3D):
                    open_set.insert([new_f_score, neighbor_3D])

    # Open set is empty but goal was never reached
    return []

func pathfinding_tile_move_cost(from_node_3D, to_node_3D):
    return 1

func get_neighbors(n: Vector2, current_jump, grid, jump_limit):
    # Returns adjacent nodes, with an additional value to represent jumping count
    # Jump calculation done like this:
    # https://gamedevelopment.tutsplus.com/tutorials/how-to-adapt-a-pathfinding-to-a-2d-grid-based-platformer-theory--cms-24662
    
    var neighbors = []
    
    var next_vertical_jump_val = current_jump + 1 + (1 if current_jump % 2 == 0 else 0)
    
    var down = [Vector2(n.x, n.y+1), max(jump_limit, next_vertical_jump_val)]
    neighbors.append(down)
    
    if current_jump < jump_limit:
        var up = [Vector2(n.x, n.y-1), next_vertical_jump_val]
        neighbors.append(up)
        
    var fall_increment = 2 if current_jump < jump_limit * 1.6 else 4
    
    if current_jump % fall_increment == 0:
        var left = [Vector2(n.x-1, n.y), 0]
        var bottom_left = Vector2(n.x-1, n.y+1)
        if bottom_left in grid:
            # left has no ground below. require jump
            left[1] = current_jump + 1
        neighbors.append(left)
        
        var right = [Vector2(n.x+1, n.y), 0]
        var bottom_right = Vector2(n.x+1, n.y+1)
        if bottom_right in grid:
            # right has no ground below. require jump
            right[1] = current_jump + 1
        neighbors.append(right)
            
    return neighbors

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
