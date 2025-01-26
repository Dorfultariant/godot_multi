class_name DamageComponent extends Node3D 

func deal_damage(collision, damage : float = 0.0) -> bool:
	if !collision.has_method("get_collider"):
		return false
	
	var colliding_body = collision.get_collider()
	var health_component : HealthComponent = null
	if colliding_body.has_method("find_child"):
		health_component = colliding_body.find_child("HealthComponent")
	if !is_instance_valid(health_component) or health_component == null:
		return false
	
	print("Dealing damage")
	health_component.hit(1, damage)
	return true
