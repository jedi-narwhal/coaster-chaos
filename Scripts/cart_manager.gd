extends Node


var carts: Array[AnimatedSprite2D] = []
@export var start_carts: int = 3
@export var collider: CollisionShape2D
@export var cart_reference: AnimatedSprite2D


func _ready() -> void:
	add_cart(start_carts) # Setup adding carts
	await get_tree().create_timer(1.0).timeout
	add_cart(-1)

func add_cart(num: int) -> void:
	if (num > 0):
		for i in range(num):
			var cart: AnimatedSprite2D = cart_reference.duplicate()
			cart.global_position = collider.position + Vector2(carts.size() * -20, 0)
			add_child(cart)
			cart.show()
			cart.play("rolling")
			carts.append(cart)
			cart.name = "Cart" + str(carts.size())
	else:
		for i in range(0, num, -1):
			print("Remove")

func _process(delta: float) -> void:
	pass # Check rotation in here
