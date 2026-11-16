extends CPUParticles2D

## Freeze the drift under reduced motion: no particles emit, nothing drifts,
## no attention demanded. The world simply looks calmer.

func _ready() -> void:
	if GameSettings.reduce_motion:
		emitting = false
