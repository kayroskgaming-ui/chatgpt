class_name CityWorld
extends Node2D
signal selected(cell:Vector2i)
var sim:LifeSimulation
var camera:=Vector2.ZERO
var pan:=Vector2.ZERO
var zoom_level:=1
var zooms:=[0.85,1.15,1.5,1.85]
var roof_alpha:={"home":1.0,"bia":1.0,"caio":1.0,"cafe":1.0}
var door_open:={}
var npc_positions:={}
var previous_visual:=Vector2.ZERO
var walking:=false
var highlight:=Vector2i(-1,-1)
var visual_position:=Vector2.ZERO
var debug:=false
var following:=true
var elapsed:=0.0
var drag:=false
const SKINS=[Color("f4ccaa"),Color("c38e66"),Color("82563f"),Color("543c32")]
const CLOTHES=[Color("6dbbb6"),Color("dc936d"),Color("a59dc4"),Color("dfbd58")]
const HAIRS=[Color("403338"),Color("986344"),Color("d5b173"),Color("78727f")]
func iso(v:Vector2)->Vector2: return Vector2((v.x-v.y)*24,(v.x+v.y)*12)
func offset()->Vector2: return Vector2((get_viewport_rect().size.x-322)/2,get_viewport_rect().size.y/2+38)-camera*zooms[zoom_level]+pan
func screen_cell(screen:Vector2)->Vector2i:
	var v:Vector2=(screen-offset())/zooms[zoom_level]
	return Vector2i(floori(v.x/48+v.y/24+0.5),floori(v.y/24-v.x/48+0.5))
func _ready()->void:
	visual_position=Vector2(sim.cell); camera=iso(visual_position)
func _process(delta:float)->void:
	elapsed+=delta*sim.speed
	previous_visual=visual_position
	var difference:=Vector2(sim.cell)-visual_position
	if difference.length()>5: visual_position=Vector2(sim.cell)
	else: visual_position=visual_position.move_toward(Vector2(sim.cell),delta*9*maxi(1,sim.speed))
	walking=visual_position.distance_to(previous_visual)>0.0001
	for npc in sim.npcs:
		var old:Vector2=npc_positions.get(npc.id,Vector2(npc.cell))
		npc_positions[npc.id]=old.move_toward(Vector2(npc.cell),delta*7*maxi(1,sim.speed))
	var doors:Array=CityData.INNER_DOORS.duplicate()
	for home in CityData.HOMES: doors.append(home.door)
	for at in doors:
		var building_id:=CityData.building_at(at)
		var near:=Vector2(at).distance_to(Vector2(sim.cell))<1.5 and CityData.can_enter(building_id,"player",sim.invited)
		for npc in sim.npcs:
			if Vector2(at).distance_to(Vector2(npc.cell))<1.5 and CityData.can_enter(building_id,npc.id,false): near=true
		door_open[at]=move_toward(door_open.get(at,0.0),1.0 if near else 0.0,delta*5)
	if following: camera=camera.lerp(iso(visual_position),1-exp(-delta*6))
	for h in CityData.HOMES:
		roof_alpha[h.id]=move_toward(roof_alpha[h.id],0.0 if h.rect.has_point(sim.cell) else 1.0,delta*3)
	queue_redraw()
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_MIDDLE: drag=event.pressed
		if event.pressed:
			if event.button_index==MOUSE_BUTTON_WHEEL_UP: zoom_level=mini(3,zoom_level+1)
			elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN: zoom_level=maxi(0,zoom_level-1)
			elif event.button_index==MOUSE_BUTTON_LEFT: selected.emit(screen_cell(event.position))
	elif event is InputEventMouseMotion and drag: pan+=event.relative; following=false
func diamond(p:Vector2,color:Color,size:Vector2=Vector2(24,12))->void:
	draw_colored_polygon(PackedVector2Array([p+Vector2(-size.x,0),p+Vector2(0,-size.y),p+Vector2(size.x,0),p+Vector2(0,size.y)]),color)
func box(p:Vector2,width:float,depth:float,height:float,color:Color)->void:
	var a:=p+Vector2(-width,0); var b:=p+Vector2(0,-depth); var c:=p+Vector2(width,0); var d:=p+Vector2(0,depth); var up:=Vector2(0,-height)
	draw_colored_polygon(PackedVector2Array([a,d,d+up,a+up]),color.darkened(0.26))
	draw_colored_polygon(PackedVector2Array([d,c,c+up,d+up]),color.darkened(0.12))
	draw_colored_polygon(PackedVector2Array([a+up,b+up,c+up,d+up]),color.lightened(0.08))
func text_at(p:Vector2,message:String,size:int=12,color:Color=Color("f2e5ca"))->void:
	draw_string(ThemeDB.fallback_font,p,message,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func _draw()->void:
	if sim==null: return
	draw_set_transform(offset().round(),0,Vector2.ONE*zooms[zoom_level])
	for y in range(CityData.SIZE.y):
		for x in range(CityData.SIZE.x):
			var cell:=Vector2i(x,y); var p:=iso(Vector2(cell))
			var road:=y in [12,13,14] or x in [13,14]
			var pavement:=y in [10,11,15,16] or x in [11,12,15,16]
			var c:=Color("607e60") if (x+y)%2==0 else Color("648363")
			if road: c=Color("3b4b52") if (x+y)%2==0 else Color("3e4e55")
			elif pavement: c=Color("9eae9e") if (x+y)%2==0 else Color("a8b5a5")
			if x>=4 and x<=10 and y>=18 and y<=22: c=Color("a6a680")
			var building:=CityData.building_at(cell)
			if building!="": c=Color("b9a486") if (x+y)%2==0 else Color("b19c80")
			if building=="home":
				for room in CityData.ROOMS:
					if room.rect.has_point(cell): c=room.color.lightened(0.03 if (x+y)%2==0 else 0.0)
			diamond(p,c)
			if road and y==13 and x%3==0 and x not in [12,13,14,15]: diamond(p,Color("d9cd9f"),Vector2(10,2))
			if pavement: draw_line(p+Vector2(0,11),p+Vector2(22,0),Color("889d91"),1)
			if not road and not pavement and building=="" and (x*7+y*13)%19==0:
				draw_rect(Rect2(p+Vector2(-4,-3),Vector2(2,3)),Color("9ca974")); draw_rect(Rect2(p+Vector2(1,-1),Vector2(2,2)),Color("4b7059"))
	for h in CityData.HOMES:
		var r:Rect2i=h.rect
		for y in range(r.position.y,r.end.y):
			for x in range(r.position.x,r.end.x):
				if x==r.position.x or y==r.position.y: box(iso(Vector2(x,y)),24,12,28,h.color)
		var door:=iso(Vector2(h.door)); diamond(door,Color("dfc994")); text_at(door+Vector2(-35,27),"ENTRADA",9)
	for at in CityData.INNER_WALLS:
		box(iso(Vector2(at)),24,12,9 if roof_alpha.home<0.5 else 28,Color("c9b28c"))
	for at in CityData.INNER_DOORS:
		var p:=iso(Vector2(at)); diamond(p,Color("d9c492"))
		var opened:float=door_open.get(at,0.0)
		box(p+Vector2(opened*17,-2),4,7,17,Color(0.43,0.35,0.25,1.0-opened*0.65))
	if roof_alpha.home<0.1:
		for room in CityData.ROOMS: text_at(iso(Vector2(room.rect.position))+Vector2(-20,23),room.name.to_upper(),8,Color("5c6156"))
	var items:Array=[]
	for o in CityData.OBJECTS: items.append({"type":"object","at":Vector2(o.cell),"data":o})
	for t in CityData.TREES: items.append({"type":"tree","at":Vector2(t)})
	for n in sim.npcs:
		var at:Vector2=npc_positions.get(n.id,Vector2(n.cell))
		if n.get("action",{}).get("started",false):
			var object:=CityData.object_by_id(n.action.id)
			if object.kind in ["bed","sofa","shower","toilet","bench"]: at=Vector2(object.cell)
		items.append({"type":"npc","at":at,"data":n})
	var player_at:=visual_position
	if sim.current.get("kind","")=="object" and sim.current.get("arrived",false):
		var o:=CityData.object_by_id(sim.current.id)
		if o.kind in ["bed","sofa","shower","toilet","bench"]: player_at=Vector2(o.cell)
	items.append({"type":"player","at":player_at})
	items.sort_custom(func(a,b):
		var da:float=a.at.x+a.at.y; var db:float=b.at.x+b.at.y
		if is_equal_approx(da,db): return a.type!="player" and b.type=="player"
		return da<db)
	for item in items:
		var p:=iso(item.at).round()
		match item.type:
			"tree": draw_tree(p)
			"object": draw_object(p,item.data)
			"player": draw_person(p,sim.skin,sim.outfit,true)
			"npc": draw_person(p,2 if item.data.id=="bia" else 0,1 if item.data.id=="bia" else 2,false,item.data)
	for h in CityData.HOMES: draw_roof(h)
	if highlight.x>=0: diamond(iso(Vector2(highlight)),Color(0.9,0.95,0.6,0.4),Vector2(22,11))
	for t in [Vector2(4,18),Vector2(10,22),Vector2(17,11),Vector2(27,16)]:
		var p:=iso(t); box(p,10,5,5,Color("a66a53"))
		for k in range(5): draw_rect(Rect2(p+Vector2(k*4-9,-9-(k%2)*3),Vector2(3,4)),Color("e4ab9d") if k%2 else Color("e8d484"))
	var night:=0.38 if sim.hour_minute()<360 or sim.hour_minute()>1140 else (0.16 if sim.hour_minute()>1020 else 0.0)
	if night>0:
		draw_set_transform(Vector2.ZERO); draw_rect(get_viewport_rect(),Color(0.06,0.09,0.23,night)); draw_set_transform(offset().round(),0,Vector2.ONE*zooms[zoom_level])
	for pos in [Vector2(2,11),Vector2(12,19),Vector2(27,15),Vector2(17,10)]:
		var p:=iso(pos); draw_rect(Rect2(p+Vector2(-2,-38),Vector2(3,38)),Color("344b4b")); draw_rect(Rect2(p+Vector2(-6,-42),Vector2(12,7)),Color("f2d58b") if night>0 else Color("bfc4ad"))
		if night>0: diamond(p,Color(1,0.85,0.4,0.12),Vector2(40,20))
	if debug:
		for y in range(CityData.SIZE.y):
			for x in range(CityData.SIZE.x):
				if not CityData.walkable(Vector2i(x,y),"player",sim.invited): diamond(iso(Vector2(x,y)),Color(1,0.2,0.2,0.3))
		for at in sim.route: diamond(iso(Vector2(at)),Color(0.3,1,0.8,0.7),Vector2(5,3))
		for o in CityData.OBJECTS:
			var use:=sim.nearest_use(o.cell)
			if use.x>=0: diamond(iso(Vector2(use)),Color(1,0.85,0.1,0.5),Vector2(8,4))
func draw_tree(p:Vector2)->void:
	var person:=iso(visual_position)
	var alpha:=0.4 if absf(person.x-p.x)<25 and person.y>p.y-62 and person.y<p.y+4 else 1.0
	diamond(p+Vector2(3,0),Color(0.1,0.2,0.15,0.25),Vector2(24,10))
	var trunk:=Color("705b46"); trunk.a=alpha; draw_rect(Rect2(p+Vector2(-3,-32),Vector2(6,31)),trunk)
	var colors:=[Color("315b48"),Color("3e7151"),Color("56815a"),Color("789760")]
	for i in range(colors.size()): colors[i].a=alpha
	draw_rect(Rect2(p+Vector2(-18,-62),Vector2(36,26)),colors[0]); draw_rect(Rect2(p+Vector2(-23,-52),Vector2(44,24)),colors[1]); draw_rect(Rect2(p+Vector2(-13,-68),Vector2(25,34)),colors[2]); draw_rect(Rect2(p+Vector2(-13,-61),Vector2(10,8)),colors[3])
func draw_object(p:Vector2,o:Dictionary)->void:
	match o.kind:
		"bed":
			box(p,20,10,9,Color("73584a")); box(p+Vector2(0,-10),18,9,5,Color("d5d4ab")); box(p+Vector2(4,-8),14,6,6,Color("648f9b")); box(p+Vector2(-10,-14),7,4,3,Color("efe0b8"))
		"fridge":
			box(p,14,8,38,Color("c2d1c5")); draw_line(p+Vector2(0,-26),p+Vector2(13,-33),Color("78948e"),2); draw_rect(Rect2(p+Vector2(5,-23),Vector2(2,7)),Color("536c68"))
		"shower":
			box(p,18,9,3,Color("d9d4b9")); draw_rect(Rect2(p+Vector2(-10,-40),Vector2(3,34)),Color("769d9c")); draw_line(p+Vector2(-9,-40),p+Vector2(7,-40),Color("c6d3c8"),3)
			if object_active(o.id):
				for i in range(7): draw_rect(Rect2(p+Vector2((i*7)%22-10,-35+fmod(elapsed*20+i*6,30)),Vector2(1,5)),Color("b9dee0"))
		"toilet":
			box(p+Vector2(0,-10),10,5,17,Color("cdd9cf")); box(p,12,7,8,Color("e2e4d2")); diamond(p+Vector2(0,-9),Color("667c78"),Vector2(7,3))
		"sofa","bench":
			box(p,22,10,9,Color("547e79") if o.kind=="sofa" else Color("9b7752")); box(p+Vector2(-9,-9),13,6,12,Color("71938a") if o.kind=="sofa" else Color("a8875e"))
		"table":
			box(p,15,8,14,Color("9a7455")); box(p+Vector2(0,-14),20,10,3,Color("d7b37d")); draw_rect(Rect2(p+Vector2(-3,-23),Vector2(5,6)),Color("d7dfc4"))
		"counter":
			box(p,22,11,22,Color("a97955")); box(p+Vector2(0,-22),24,12,3,Color("d7cba6")); box(p+Vector2(3,-27),8,4,11,Color("536665"))
	if debug: text_at(p+Vector2(-18,-45),o.id,10)
func draw_person(p:Vector2,skin:int,clothes:int,player:bool,npc:Dictionary={})->void:
	var act:String=sim.current.get("id","") if player and sim.current.get("arrived",false) and sim.current.get("kind","")=="object" else ""
	if not player and npc.get("action",{}).get("started",false): act=npc.action.id
	var kind:=CityData.object_by_id(act).get("kind","") as String
	var direction:Vector2i=sim.facing if player else npc.get("facing",Vector2i.DOWN)
	var is_walking:bool=walking if player else not npc.get("route",[]).is_empty()
	diamond(p,Color(0.1,0.15,0.16,0.3),Vector2(9,4))
	if kind=="bed":
		draw_rect(Rect2(p+Vector2(-13,-13),Vector2(22,8)),CLOTHES[clothes]); draw_rect(Rect2(p+Vector2(-19,-16),Vector2(8,8)),SKINS[skin]); text_at(p+Vector2(0,-28),"z Z",12)
	else:
		var bob:=int(sin(elapsed*8)*2) if is_walking else 0
		var h:=7 if kind in ["sofa","table","bench","toilet"] else 0
		draw_rect(Rect2(p+Vector2(-5,-9+h),Vector2(4,9)),Color("324959")); draw_rect(Rect2(p+Vector2(2,-9+h+bob),Vector2(4,9-bob)),Color("324959")); draw_rect(Rect2(p+Vector2(-7,-22+h),Vector2(14,14)),CLOTHES[clothes])
		draw_rect(Rect2(p+Vector2(-9,-20+h-bob),Vector2(3,10)),SKINS[skin]); draw_rect(Rect2(p+Vector2(7,-20+h+bob),Vector2(3,10)),SKINS[skin]); draw_rect(Rect2(p+Vector2(-6,-33+h),Vector2(12,12)),SKINS[skin])
		draw_rect(Rect2(p+Vector2(-7,-35+h),Vector2(14,5)),HAIRS[sim.hair] if player else Color("493a3d")); draw_rect(Rect2(p+Vector2(2 if direction.x>=0 else -4,-28+h),Vector2(2,2)),Color("343b3e"))
		if direction.y<0 and direction.x<=0: draw_rect(Rect2(p+Vector2(-6,-31+h),Vector2(12,8)),HAIRS[sim.hair] if player else Color("493a3d"))
		if kind in ["fridge","counter"]:
			var lift:=sin(elapsed*3)*2; draw_rect(Rect2(p+Vector2(5,-24+lift),Vector2(7,5)),Color("e3b86e"))
		if kind in ["sofa","bench"]:
			draw_rect(Rect2(p+Vector2(-6,-17),Vector2(12,7)),Color("e9d8a6")); draw_line(p+Vector2(0,-17),p+Vector2(0,-10),Color("8a7561"),1)
		if (player and sim.current.get("kind","")=="social" and sim.route.is_empty()) or (not player and npc.get("state","")=="Conversando"):
			text_at(p+Vector2(9,-40),"···",14)
	if player: diamond(p+Vector2(0,-49),Color("dcefa7"),Vector2(5,7))
func draw_roof(h:Dictionary)->void:
	var alpha:float=roof_alpha[h.id]
	if alpha<0.01: return
	var r:Rect2i=h.rect; var color:Color=h.color; color.a=alpha
	for x in range(r.position.x,r.end.x):
		var cell:=Vector2i(x,r.end.y-1); var p:=iso(Vector2(cell))
		if cell!=h.door:
			box(p,24,12,28,color)
			if x%2==0:
				var glass:=Color("577c87"); glass.a=alpha
				draw_colored_polygon(PackedVector2Array([p+Vector2(-21,-23),p+Vector2(-4,-14),p+Vector2(-4,-3),p+Vector2(-21,-12)]),glass)
		else:
			var door_color:=Color("6b5d4c"); door_color.a=alpha*(1.0-float(door_open.get(h.door,0.0)))
			draw_colored_polygon(PackedVector2Array([p+Vector2(-18,-25),p+Vector2(-1,-16),p+Vector2(-1,9),p+Vector2(-18,0)]),door_color)
	for y in range(r.position.y,r.end.y-1):
		var p:=iso(Vector2(r.end.x-1,y)); box(p,24,12,28,color)
		if y%2==0:
			var glass:=Color("577c87"); glass.a=alpha
			draw_colored_polygon(PackedVector2Array([p+Vector2(4,-14),p+Vector2(21,-23),p+Vector2(21,-12),p+Vector2(4,-3)]),glass)
	var a:=iso(Vector2(r.position))+Vector2(0,-40); var b:=iso(Vector2(r.end.x-1,r.position.y))+Vector2(0,-40); var c:=iso(Vector2(r.end-Vector2i.ONE))+Vector2(0,-40); var d:=iso(Vector2(r.position.x,r.end.y-1))+Vector2(0,-40)
	var ridge_a:=(a+d)/2+Vector2(0,-28); var ridge_b:=(b+c)/2+Vector2(0,-28)
	var roof:=Color("a86c53") if h.id!="cafe" else Color("527b76"); roof.a=alpha
	var shadow:=roof.darkened(0.2); shadow.a=alpha
	draw_colored_polygon(PackedVector2Array([a+Vector2(-20,0),ridge_a+Vector2(-20,0),d+Vector2(-20,10)]),shadow); draw_colored_polygon(PackedVector2Array([b+Vector2(20,0),ridge_b+Vector2(20,0),c+Vector2(20,10)]),color)
	draw_colored_polygon(PackedVector2Array([a+Vector2(-20,0),b+Vector2(20,0),ridge_b+Vector2(20,0),ridge_a+Vector2(-20,0)]),shadow); draw_colored_polygon(PackedVector2Array([ridge_a+Vector2(-20,0),ridge_b+Vector2(20,0),c+Vector2(20,10),d+Vector2(-20,10)]),roof)
	var line:=Color("c38a65") if h.id!="cafe" else Color("6b9790"); line.a=alpha
	for i in range(1,r.size.x*2):
		var f:=float(i)/(r.size.x*2); draw_line(ridge_a.lerp(ridge_b,f),d.lerp(c,f),line,2)
	var plaque:=iso(Vector2(h.door))+Vector2(-50,-35); var sign_color:=Color("223b42"); sign_color.a=alpha
	draw_rect(Rect2(plaque+Vector2(-4,-14),Vector2(138,22)),sign_color)
	text_at(plaque,"CAFÉ DA ESQUINA" if h.id=="cafe" else ("RUA IPÊ, 12 · SEU LAR" if h.id=="home" else ("RUA IPÊ, 18 · BIA" if h.id=="bia" else "RUA IPÊ, 24 · CAIO")),10,Color(1,0.94,0.8,alpha))

func object_active(id:String)->bool:
	if sim.current.get("id","")==id and sim.current.get("arrived",false): return true
	for npc in sim.npcs:
		if npc.get("action",{}).get("id","")==id and npc.action.get("started",false): return true
	return false
