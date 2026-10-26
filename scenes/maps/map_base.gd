class_name MapBase
extends Node3D
## Interface comum dos mapas. Cada mapa precisa ter os nós:
## - HiderSpawns (Node3D com Marker3D filhos): onde os escondidos nascem
## - SeekerCage (Marker3D): sala de contagem do procurador
## - SeekerRelease (Marker3D): onde o procurador é solto no início da caçada

@export var map_name := "Mapa"


func get_hider_spawns() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for marker in $HiderSpawns.get_children():
		result.append((marker as Node3D).global_position)
	return result


func get_seeker_cage() -> Vector3:
	return ($SeekerCage as Node3D).global_position


func get_seeker_release() -> Vector3:
	return ($SeekerRelease as Node3D).global_position
