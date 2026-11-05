class_name CityData
extends RefCounted
const SIZE=Vector2i(32,26)
const HOMES=[
	{"id":"home","name":"Seu lar · Rua Ipê, 12","rect":Rect2i(3,3,8,7),"door":Vector2i(7,9),"color":Color("d5aa79")},
	{"id":"bia","name":"Casa da Bia · nº 18","rect":Rect2i(16,3,7,7),"door":Vector2i(19,9),"color":Color("82aaa1")},
	{"id":"cafe","name":"Café da Esquina","rect":Rect2i(19,17,9,7),"door":Vector2i(23,23),"color":Color("c98b77")}
]
const OBJECTS=[
	{"id":"bed","name":"Cama de solteiro","cell":Vector2i(4,4),"home":"home","action":"Dormir","need":1,"minutes":120.0,"gain":65.0,"kind":"bed","cost":0},
	{"id":"fridge","name":"Geladeira","cell":Vector2i(9,4),"home":"home","action":"Comer uma marmita","need":0,"minutes":25.0,"gain":48.0,"kind":"fridge","cost":0},
	{"id":"shower","name":"Chuveiro","cell":Vector2i(9,6),"home":"home","action":"Tomar banho","need":2,"minutes":25.0,"gain":75.0,"kind":"shower","cost":0},
	{"id":"toilet","name":"Vaso sanitário","cell":Vector2i(9,8),"home":"home","action":"Usar banheiro","need":3,"minutes":12.0,"gain":80.0,"kind":"toilet","cost":0},
	{"id":"sofa","name":"Sofá e leitura","cell":Vector2i(4,7),"home":"home","action":"Ler no sofá","need":5,"minutes":40.0,"gain":45.0,"kind":"sofa","cost":0},
	{"id":"table","name":"Mesa da cozinha","cell":Vector2i(7,5),"home":"home","action":"Fazer uma pausa","need":5,"minutes":15.0,"gain":12.0,"kind":"table","cost":0},
	{"id":"bia_bed","name":"Cama da Bia","cell":Vector2i(17,4),"home":"bia","action":"Observar","need":5,"minutes":5.0,"gain":2.0,"kind":"bed","cost":0},
	{"id":"bia_sofa","name":"Sofá da Bia","cell":Vector2i(21,5),"home":"bia","action":"Descansar como visita","need":1,"minutes":20.0,"gain":12.0,"kind":"sofa","cost":0},
	{"id":"counter","name":"Balcão do Café","cell":Vector2i(25,19),"home":"cafe","action":"Comprar lanche · V$ 12","need":0,"minutes":20.0,"gain":40.0,"kind":"counter","cost":12},
	{"id":"cafe_table","name":"Mesa do café","cell":Vector2i(21,20),"home":"cafe","action":"Tomar um café · V$ 4","need":1,"minutes":15.0,"gain":12.0,"kind":"table","cost":4},
	{"id":"bench","name":"Banco da Praça das Flores","cell":Vector2i(7,19),"home":"","action":"Contemplar a praça","need":5,"minutes":30.0,"gain":30.0,"kind":"bench","cost":0}
]
const TREES=[Vector2i(1,3),Vector2i(1,8),Vector2i(13,4),Vector2i(26,5),Vector2i(28,8),Vector2i(3,17),Vector2i(10,17),Vector2i(3,22),Vector2i(11,23),Vector2i(16,21),Vector2i(29,19),Vector2i(29,23)]
static func building_at(cell:Vector2i)->String:
	for h in HOMES:
		if h.rect.has_point(cell): return h.id
	return ""
static func can_enter(id:String,actor:String,invited:bool)->bool:
	return id=="" or id=="cafe" or (id=="home" and actor=="player") or (id=="bia" and (actor=="bia" or invited))
static func walkable(cell:Vector2i,actor:String="player",invited:bool=false)->bool:
	if cell.x<0 or cell.y<0 or cell.x>=SIZE.x or cell.y>=SIZE.y: return false
	for h in HOMES:
		var r:Rect2i=h.rect
		if r.has_point(cell):
			if not can_enter(h.id,actor,invited): return false
			if cell!=h.door and (cell.x==r.position.x or cell.y==r.position.y or cell.x==r.end.x-1 or cell.y==r.end.y-1): return false
	if cell in TREES: return false
	for o in OBJECTS:
		if o.cell==cell: return false
	return true
static func path(from:Vector2i,to:Vector2i,actor:String="player",invited:bool=false)->Array[Vector2i]:
	var result:Array[Vector2i]=[]
	if not walkable(to,actor,invited): return result
	var frontier:Array[Vector2i]=[from]
	var came:Dictionary={from:from}
	var index:=0
	while index<frontier.size():
		var at:=frontier[index]; index+=1
		if at==to: break
		for dir in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var next:Vector2i=at+dir
			if not came.has(next) and walkable(next,actor,invited): came[next]=at; frontier.append(next)
	if not came.has(to): return result
	var cursor:=to
	while cursor!=from: result.push_front(cursor); cursor=came[cursor]
	return result
static func object_by_id(id:String)->Dictionary:
	for o in OBJECTS:
		if o.id==id: return o.duplicate(true)
	return {}
