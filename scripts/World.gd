extends Node2D

onready var Racer = load("res://Racer.tscn")

var player
var ai_racers = []

# Called when the node enters the scene tree for the first time.
func _ready():
    
    for i in range(9):
        var ai = Racer.instance()
        add_child(ai)
        ai_racers.append(ai)
        ai.position = Vector2(40, 30+i*16)
    
#    player = Racer.instance()
#    add_child(player)
#    player.position = Vector2(40,75)
#    player.is_ai = false
