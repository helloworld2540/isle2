extends Node2D
class_name Trash

const TRASH_MAP := {
	"trash_net.png": ["Nylon", 35],
	"trash_bottle.png": ["Polyethylene", 15],
	"trash_plasticblue.png": ["Polypropylene", 40],
	"trash_plasticwhite.png": ["Polypropylene", 35],
	"trash_straw.png": ["Polyethylene", 17],
}
@onready var sprite = $Body/Sprite

var mat := ""
var size := 1

func init(texture: String) -> void:
	var entry: Array = TRASH_MAP[texture]
	mat = entry[0]
	size = entry[1]
	sprite.texture = load("res://sprites/rr/" + texture)
	
	scale = Vector2(log(size) / log(100) / 3, log(size) / log(100) / 3)
	
func _ready() -> void:
	pass
