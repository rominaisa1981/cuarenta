# scripts/Player.gd
extends RefCounted

var nombre: String
var puntaje: int = 0
var cartas_capturadas: Array = []

func _init(nom: String):
	nombre = nom

func sumar_puntos(puntos: int):
	puntaje += puntos
	print(nombre, " ahora tiene ", puntaje, " puntos.")

func agregar_capturadas(cartas: Array):
	cartas_capturadas.append_array(cartas)

func reset():
	puntaje = 0
	cartas_capturadas.clear()
