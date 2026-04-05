extends AnimationPlayer


func _enter_tree() -> void:
	EventSystem.connect_once("GAM_fast_forward_day_night_anim", Callable(self, "fast_forward_anim"))


func _ready() -> void:
	await get_tree().physics_frame
	set_time(12)


func set_time(time:float) -> void:
	seek(time)


func fast_forward_anim(time:float) -> void:
	seek(fmod(current_animation_position + time, current_animation_length))
