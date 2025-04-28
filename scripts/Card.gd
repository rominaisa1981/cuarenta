extends Node2D

var numero = 0
var palo = ""

func configurar_carta(nuevo_numero, nuevo_palo):
	numero = nuevo_numero
	palo = nuevo_palo
	actualizar_sprite()

func actualizar_sprite():
	#var nombre_numero = "AS" if numero == 1 else str(numero)
	
	var nombre_numero = ""

	if numero == 1:
		nombre_numero = "AS"
	elif numero == 10:
		nombre_numero = "J"
	elif numero == 11:
		nombre_numero = "Q"
	elif numero == 12:
		nombre_numero = "K"
	else:
		nombre_numero = str(numero)
	
	var nombre_palo = palo.to_upper()
		
	var ruta = "res://assets/cartas/" + nombre_numero + nombre_palo + ".png"
	
	if $Sprite2D and ResourceLoader.exists(ruta):
		$Sprite2D.texture = load(ruta)
		#$Sprite2D.scale = Vector2(1.5, 1.5)
		
	else:
		print("No se encontró la imagen de la carta: ", ruta)

func _input_event(viewport, event, shape_idx): 
	if event is InputEventScreenTouch and event.pressed:
		print("Tocaste la carta: ", numero, " de ", palo)
		# Aquí podrías llamar a una función para "jugar" esta carta
