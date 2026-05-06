class_name MapNodeData
extends RefCounted

enum State { LOCKED, AVAILABLE, COMPLETED }

var id: int = 0
var zone: int = 1
var col: int = 0
var enemy_type: EnemyData.Type = EnemyData.Type.GOBLIN
var state: State = State.LOCKED
var connections: Array[int] = []
