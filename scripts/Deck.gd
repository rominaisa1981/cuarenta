extends Node

# OJO: En singular
var palos = ["espada", "brillo", "corazon", "trebol"]
var numeros = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12]  # Sin 8 y 9

var mazo = []

func _ready():
	crear_mazo()
	barajar()

func crear_mazo():
	mazo.clear()
	for palo in palos:
		for numero in numeros:
			var carta = {
				"numero": numero,
				"palo": palo
			}
			mazo.append(carta)
	print("Mazo creado con ", mazo.size(), " cartas.")

func barajar():
	mazo.shuffle()
	print("Mazo barajado.")
