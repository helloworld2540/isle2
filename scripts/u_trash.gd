extends Node2D
class_name Trash

const TRASH_MAP := {
	"trash_net.png": ["Nylon", 35],
	"trash_bottle.png": ["Glass", 15],
	"trash_plasticblue.png": ["Polypropylene", 40],
	"trash_plasticwhite.png": ["Polypropylene", 35],
	"trash_straw.png": ["Polyethylene", 17],
}

@onready var sprite = $"Body/Sprite"

var mat := ""
var size := 1

func init(texture: String) -> void:
	if not TRASH_MAP.has(texture):
		mat = "Polyethylene"
		size = 1
		if sprite:
			sprite.texture = null
		return
	var entry: Array = TRASH_MAP[texture]
	mat = str(entry[0])
	size = int(entry[1])
	set_meta("material", mat)
	set_meta("size", size)
	if sprite:
		var tex := load("res://sprites/rr/" + texture)
		if tex is Texture2D:
			sprite.texture = tex
	scale = Vector2(log(max(1, size)) / log(100.0) / 3.0, log(max(1, size)) / log(100.0) / 3.0)

func _ready() -> void:
	pass
