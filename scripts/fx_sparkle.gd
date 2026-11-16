extends RefCounted
class_name FxSparkle

## One-shot CPU particle bursts shared by every scene that celebrates a hit:
## bin sparkles, dive pickups, upgrade glimmers, reward fountains. Instantiates
## the authored scene (never builds nodes in code), fires the burst, and
## queues the emitter for deletion once the last particle has faded.
##
## Usage:
##   FxSparkle.burst(self, global_position, Color(0.7, 1.0, 0.6), {"amount": 24})
##
## `host` decides where the emitter lives: a Node2D for world-space bursts,
## a CanvasLayer/Control child for screen-space ones. `at` must already be in
## the host's space (global_position for Node2D hosts).

const SPARKLE_SCENE: PackedScene = preload("res://scenes/ui/c_p_u_particles2_d.tscn")


static func burst(host: Node, at: Vector2, color: Color, opts: Dictionary = {}) -> CPUParticles2D:
	var p := SPARKLE_SCENE.instantiate() as CPUParticles2D
	if p == null:
		push_warning("FxSparkle: could not instantiate sparkle scene")
		return null
	p.one_shot = true
	p.explosiveness = float(opts.get("explosiveness", 1.0))
	p.amount = int(opts.get("amount", 16))
	p.lifetime = float(opts.get("lifetime", 0.45))
	p.global_position = at
	p.spread = float(opts.get("spread", 360.0))
	p.initial_velocity_min = float(opts.get("vel_min", 40.0))
	p.initial_velocity_max = float(opts.get("vel_max", 120.0))
	var gravity_y := float(opts.get("gravity", 120.0))
	p.gravity = Vector2(0.0, gravity_y)
	p.scale_amount_min = float(opts.get("scale_min", 2.0))
	p.scale_amount_max = float(opts.get("scale_max", 4.0))
	p.color = color
	host.add_child(p)
	p.emitting = true
	# The emitter outlives the burst by one lifetime; freeing on an interval
	# avoids holding dozens of idle CPUParticles2D alive between scenes.
	var tw := host.create_tween()
	tw.tween_interval(p.lifetime + 0.1)
	tw.tween_callback(p.queue_free)
	return p
