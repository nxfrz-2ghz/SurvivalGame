extends WorldEnvironment

const envs := {
	"default": preload("res://scenes/world/world_environment.tres"),
	
}

func setup(type := "default") -> void:
	self.environment = envs[type]
