extends CharacterBody2D

@export var speed: float = 3.0
@export var sword_damage: int = 2
@export var health: int = 100
@export var death_prefab: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitboxArea

var input_vector: Vector2 = Vector2(0, 0)
var is_running: bool = false
var was_running: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var hitbox_cooldown: float = 0.0


func _process(delta: float) -> void:
	#--Injeta a posição do player no script GameManager para
	#--ser acessado no script do inimigo "follow_player.gd"
	GameManager.player_position = position
	
	#--Ler inputs
	read_input()
	
	#--Processar ataque
	update_attack_cooldown(delta)
	#if Input.is_action_just_pressed("attack"):
	if Input.is_action_pressed("attack"):
		attack()
	
	#--Processar animação e rotação do character
	play_run_idle_animation()
	if not is_attacking:
		rotate_sprite()
		
	#--Processar dano no player
	update_hitbox_detection(delta)

func _physics_process(delta: float) -> void:
	#--Aplicar/modificar a velocidade
	var target_velocity = input_vector * speed * 100.0
	if is_attacking:
		target_velocity *= 0.25
	velocity = lerp(velocity, target_velocity, 0.05)
	move_and_slide()
	#move_and_collide(velocity * delta)

func update_attack_cooldown(delta: float) -> void:
	#--Atualiza temporizador do ataque até zerar
	if is_attacking:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")


func read_input() -> void:
	#--Obter o input vector
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	#--Corrigir o deadzone dos controles de console para que o character
	#--se movimente em linha reta nas direções direita e esquerda
	var deadzone = 0.15
	if abs(input_vector.x) < 0.15:
		input_vector.x = 0.0
	if abs(input_vector.y) < 0.15:
		input_vector.y = 0.0
	
	#--Atualizar o is_running
	was_running = is_running
	is_running = not input_vector.is_zero_approx()


func play_run_idle_animation() -> void:
	#--Tocar animação
	if not is_attacking:
		if was_running != is_running:
			if is_running:
				animation_player.play("run")
			else:
				animation_player.play("idle")


func rotate_sprite() -> void:
	#--Girar sprite/character
	if input_vector.x > 0:
		#--Desmarcar Flip H da config Offset do Sprite2D
		sprite.flip_h = false
	elif input_vector.x < 0:
		#--Marcar Flip H da config Offset do Sprite2D
		sprite.flip_h = true


func attack() -> void:
	#--Se já estiver atacando, não faz nada
	if is_attacking:
		return
	
	#--Attack side 1 ou attack side 2
	var rng = RandomNumberGenerator.new()
	var random_attack: int = rng.randi_range(1, 2)
	#print(random_attack)
	var attack_side: String
	if random_attack == 1:
		attack_side = "attack_side_1"
	else:
		attack_side = "attack_side_2"
	animation_player.play(attack_side)
	
	#--Configurar temporizador do ataque
	attack_cooldown = 0.6
	
	#--Marcar ataque
	is_attacking = true


func deal_damage_to_enemies() -> void:
	var bodies = sword_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			
			var direction_to_enemy = (enemy.position - position).normalized()
			var attack_direction: Vector2
			if sprite.flip_h:
				attack_direction = Vector2.LEFT
			else:
				attack_direction = Vector2.RIGHT
			var dot_product = direction_to_enemy.dot(attack_direction)
			if dot_product >= 0.3:
				enemy.damage(sword_damage)


func update_hitbox_detection(delta: float) -> void:
	#--Temporizador
	hitbox_cooldown -= delta
	if hitbox_cooldown > 0:
		return
	
	#--Frequência de dano ao player em segundos
	hitbox_cooldown = 0.5
	
	#--Detecta inimigos que estão na HitboxArea
	var bodies = hitbox_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var damage_amount = 1
			damage(damage_amount)


func damage(amount: int) -> void:
	if health <= 0: 
		return
	
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
