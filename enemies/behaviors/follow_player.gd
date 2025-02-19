extends Node

@export var speed: float = 1

var enemy: Enemy #--Herda da classe Enemy do script "enemy.gd"
var sprite: AnimatedSprite2D


func _ready():
	enemy = get_parent()
	sprite = enemy.get_node("AnimatedSprite2D")


func _physics_process(delta: float) -> void:
	#--Calcular direção
	var player_position = GameManager.player_position
	var difference = player_position - enemy.position
	var input_vector = difference.normalized()
	
	#--Movimento
	enemy.velocity = input_vector * speed * 100.0
	enemy.move_and_slide()

	#--Girar sprite/character
	if input_vector.x > 0:
		#--Desmarcar Flip H da config Offset do Sprite2D
		sprite.flip_h = false
	elif input_vector.x < 0:
		#--Marcar Flip H da config Offset do Sprite2D
		sprite.flip_h = true
