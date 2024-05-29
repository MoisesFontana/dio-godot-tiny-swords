class_name Enemy
extends Node2D

@export var health: int = 10
@export var death_prefab: PackedScene

func damage(amount: int) -> void:
	health -= amount
	#print("Recebeu dano de: ", amount, "- Vida restante: ", health )
	
	#--Piscar inimigo toda vez que ele tomar dano
	modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	#--Processar morte
	if health <= 0:
		die()


func die() -> void:
	if death_prefab:
		var death_object = death_prefab.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)
	
	#--Destrói o objeto da cena, nesse caso a caveirinha
	queue_free()
