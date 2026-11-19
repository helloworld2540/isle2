extends Node2D
class_name Trash

## One belt item on the Upcycle bench: carries a material (from the
## sprite TRASH_MAP), its unit size, and an optional golden tint.

const TRASH_MAP := {
	# Grants are sized to ~25–50% of a fresh 10 kg bag so one sort never
	# silently maxes the hold; a bag levels up roughly every 2–3 sorts early,
	# which keeps the dive → sort → sell loop tight.
	"trash_net.png": ["Nylon", 1],
	"trash_bottle.png": ["Glass", 1],
	"trash_plasticblue.png": ["Polypropylene", 2],
	"trash_plasticwhite.png": ["Polypropylene", 2],
	"trash_straw.png": ["Polyethylene", 2],
}

@onready var sprite = $"Body/Sprite"

var mat := ""
var size := 1

var _sprite_cache: Dictionary = {}

func _sprite(path: String) -> Texture2D:
	var cached := _sprite_cache.get(path) as Texture2D
	if cached:
		return cached
	var tex := load("res://sprites/rr/" + path) as Texture2D
	if tex:
		_sprite_cache[path] = tex
	return tex

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
		var tex := _sprite(texture)
		if tex:
			sprite.texture = tex
	# Fixed on-screen size; the material-unit `size` no longer doubles as a
	# logarithm so visual scale and economy stay decoupled.
	scale = Vector2(0.28, 0.28)

func _ready() -> void:
	pass
