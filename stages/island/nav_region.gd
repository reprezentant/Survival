extends NavigationRegion3D


func _enter_tree() -> void:
	EventSystem.connect_once("GAM_update_navmesh", Callable(self, "bake_navigation_mesh"))
