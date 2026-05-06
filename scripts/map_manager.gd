extends Node

# Layout fisso: 6 nodi su 3 zone di difficoltà crescente.
# Zone 1 (2 nodi) → Zone 2 (3 nodi) → Zone 3 boss (1 nodo)
#
# Connessioni:
#   0 → [2, 3]
#   1 → [3, 4]
#   2 → [5]
#   3 → [5]
#   4 → [5]

var nodes: Array[MapNodeData] = []
var map_cleared: bool = false


func generate_new_map() -> void:
	nodes.clear()
	map_cleared = false

	var t1: Array[EnemyData.Type] = EnemyData.enemies_by_difficulty(1)
	var t2: Array[EnemyData.Type] = EnemyData.enemies_by_difficulty(2)
	var t3: Array[EnemyData.Type] = EnemyData.enemies_by_difficulty(3)
	t1.shuffle()
	t2.shuffle()
	t3.shuffle()

	_make(0, 1, 0, t1[0])
	_make(1, 1, 1, t1[1 % t1.size()])
	_make(2, 2, 0, t2[0])
	_make(3, 2, 1, t2[1 % t2.size()])
	_make(4, 2, 2, t2[2 % t2.size()])
	_make(5, 3, 0, t3.pick_random())

	nodes[0].connections = [2, 3]
	nodes[1].connections = [3, 4]
	nodes[2].connections = [5]
	nodes[3].connections = [5]
	nodes[4].connections = [5]
	nodes[5].connections = []

	nodes[0].state = MapNodeData.State.AVAILABLE
	nodes[1].state = MapNodeData.State.AVAILABLE

	_save()


func complete_node(node_id: int) -> void:
	var n := get_node_by_id(node_id)
	if n == null:
		return
	n.state = MapNodeData.State.COMPLETED
	for conn_id in n.connections:
		var conn := get_node_by_id(conn_id)
		if conn != null and conn.state == MapNodeData.State.LOCKED:
			conn.state = MapNodeData.State.AVAILABLE
	if node_id == 5:
		map_cleared = true
	_save()


func load_map() -> bool:
	var data := SaveManager.load_map_data()
	if data.is_empty():
		return false
	nodes.clear()
	map_cleared = data.get("cleared", false)
	for nd: Dictionary in data.get("nodes", []):
		var n := MapNodeData.new()
		n.id = nd["id"]
		n.zone = nd["zone"]
		n.col = nd["col"]
		n.enemy_type = nd["enemy_type"] as EnemyData.Type
		n.state = nd["state"] as MapNodeData.State
		n.connections.assign(nd["connections"])
		nodes.append(n)
	return true


func get_node_by_id(id: int) -> MapNodeData:
	for n in nodes:
		if n.id == id:
			return n
	return null


func _make(id: int, zone: int, col: int, enemy: EnemyData.Type) -> void:
	var n := MapNodeData.new()
	n.id = id
	n.zone = zone
	n.col = col
	n.enemy_type = enemy
	n.state = MapNodeData.State.LOCKED
	nodes.append(n)


func _save() -> void:
	var node_data: Array = []
	for n in nodes:
		node_data.append({
			"id": n.id,
			"zone": n.zone,
			"col": n.col,
			"enemy_type": int(n.enemy_type),
			"state": int(n.state),
			"connections": Array(n.connections),
		})
	SaveManager.save_map_data(node_data, map_cleared)
