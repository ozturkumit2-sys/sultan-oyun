class_name CharacterRig
extends Resource
## Sadeleştirilmiş insan iskeleti (MakeHuman CC0 tabanlı): kemik adları, ebeveynler,
## dinlenme dönüşümleri (model uzayı) ve şekil anahtarı başına kemik kökeni kaymaları.

@export var bone_names: PackedStringArray = []
@export var bone_parents: PackedInt32Array = []
@export var bone_rest: Array[Transform3D] = []          # model uzayı (global) dinlenme
@export var shape_names: PackedStringArray = []
@export var shape_bone_deltas: Array[PackedVector3Array] = []   # şekil -> kemik başına köken farkı
@export var shape_floor_deltas: PackedFloat32Array = []


func bone_index(n: String) -> int:
	return bone_names.find(n)


func shape_index(n: String) -> int:
	return shape_names.find(n)


## Verilen şekil ağırlıklarıyla model-uzayı dinlenme dönüşümleri
func rest_for(weights: Dictionary) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for i in range(bone_names.size()):
		var t: Transform3D = bone_rest[i]
		var o := t.origin
		for k in weights.keys():
			var si := shape_names.find(String(k))
			if si >= 0:
				o += shape_bone_deltas[si][i] * float(weights[k])
		out.append(Transform3D(t.basis, o))
	return out


func floor_offset(weights: Dictionary) -> float:
	var f := 0.0
	for k in weights.keys():
		var si := shape_names.find(String(k))
		if si >= 0:
			f += shape_floor_deltas[si] * float(weights[k])
	return f
