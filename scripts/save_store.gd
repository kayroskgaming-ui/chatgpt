class_name SaveStore
extends RefCounted
const FILE="user://vida.json"
const FIELDS=["minutes","speed","needs","money","food","player_name","skin","hair","outfit","pronouns","personality_trait","aspiration","skills","cell","facing","visit_until","queue","current","route","autonomous","need_rate","invited","friendship","relationships","npcs","ledger","shift_prompt","shift_day","warned_day","paid_days","skipped_days","deferred_until","working","work_end","work_style","auto_work","performance","mood_cause","mood_until","ui_large","audio_volume","audio_muted"]
static func encode(value:Variant)->Variant:
	if value is Vector2i: return {"_cell":[value.x,value.y]}
	if value is Array:
		var a:=[]
		for item in value: a.append(encode(item))
		return a
	if value is Dictionary:
		var d:={}
		for k in value: d[k]=encode(value[k])
		return d
	return value
static func decode(value:Variant)->Variant:
	if value is Dictionary:
		if value.has("_cell"): return Vector2i(int(value._cell[0]),int(value._cell[1]))
		var d:={}
		for k in value: d[k]=decode(value[k])
		return d
	if value is Array:
		var a:=[]
		for item in value: a.append(decode(item))
		return a
	return value
static func save_game(sim:LifeSimulation,path:String=FILE)->Error:
	var data:={"version":2}
	for key in FIELDS: data[key]=encode(sim.get(key))
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data,"\t")); file.flush(); file.close()
	if FileAccess.file_exists(path):
		var error:=DirAccess.copy_absolute(path,path+".bak")
		if error!=OK: return error
	return DirAccess.rename_absolute(path+".tmp",path)
static func load_game(sim:LifeSimulation,path:String=FILE)->bool:
	var data:=read_valid(path)
	if data.is_empty(): data=read_valid(path+".bak")
	if data.is_empty(): return false
	for key in FIELDS:
		var value:Variant=decode(data[key])
		if key=="route":
			sim.route.clear()
			for at in value: sim.route.append(at)
		else: sim.set(key,value)
	for tx in sim.ledger: tx.amount=int(tx.amount)
	for field in ["paid_days","skipped_days"]:
		var a:Array=sim.get(field)
		for i in range(a.size()): a[i]=int(a[i])
	if sim.current.has("cost"): sim.current.cost=int(sim.current.cost)
	if not sim.current.is_empty() and not sim.current.has("committed"): sim.current.committed=sim.current.get("arrived",false)
	sim.reservations.clear()
	if sim.current.get("kind","")=="object": sim.reservations[sim.current.id]="player"
	sim.npc_system.ensure_state(sim)
	for npc in sim.npcs:
		if not npc.action.is_empty():
			if sim.reservations.has(npc.action.id): npc.action={}; npc.route=[]
			else: sim.reservations[npc.action.id]=npc.id
	# A v1 save may contain a route across a newly introduced partition.
	var needs_repath:=false
	for at in sim.route:
		if not CityData.walkable(at,"player",sim.invited): needs_repath=true
	if not CityData.walkable(sim.cell,"player",sim.invited):
		for direction in [Vector2i.DOWN,Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP]:
			if CityData.walkable(sim.cell+direction,"player",sim.invited): sim.cell+=direction; needs_repath=true; break
	if needs_repath and not sim.current.is_empty():
		var target:Vector2i=sim.current.get("target",sim.cell)
		if sim.current.get("kind","")=="object":
			target=sim.nearest_use(CityData.object_by_id(sim.current.id).cell)
		if target.x>=0:
			sim.route=CityData.path(sim.cell,target,"player",sim.invited)
			if target!=sim.cell and sim.route.is_empty(): sim.fail_action("A disposição da casa mudou. Escolha novamente a interação.")
			elif not sim.current.is_empty(): sim.current.arrived=target==sim.cell
		else: sim.fail_action("A disposição da casa mudou. Escolha novamente a interação.")
	sim.autosave_at=sim.minutes; sim.changed.emit()
	return true
static func numeric(value:Variant)->bool: return (value is int or value is float) and is_finite(float(value))
static func valid_cell(value:Variant)->bool:
	if not value is Dictionary or not value.get("_cell") is Array: return false
	var a:Array=value._cell
	return a.size()==2 and numeric(a[0]) and numeric(a[1]) and a[0]>=0 and a[1]>=0 and a[0]<CityData.SIZE.x and a[1]<CityData.SIZE.y
static func valid_action(value:Variant)->bool:
	if not value is Dictionary or not value.get("name") is String: return false
	if value.has("remaining") and not numeric(value.remaining): return false
	if value.has("cost") and not numeric(value.cost): return false
	match value.get("kind",""):
		"move","bell": return valid_cell(value.get("target"))
		"work": return numeric(value.get("started"))
		"object": return value.get("id") is String and not CityData.object_by_id(value.id).is_empty()
		"social": return value.get("id","") in ["bia","caio"]
	return false
static func read_valid(path:String)->Dictionary:
	if not FileAccess.file_exists(path): return {}
	var json:=JSON.new()
	if json.parse(FileAccess.get_file_as_string(path))!=OK: return {}
	var data:Variant=json.data
	if not data is Dictionary or int(data.get("version",0)) not in [1,2]: return {}
	if data.version==1:
		if not numeric(data.get("minutes")): return {}
		data["facing"]={"_cell":[0,1]}; data["visit_until"]=float(data.minutes)+240
	var template:=LifeSimulation.new()
	for key in FIELDS:
		if not data.has(key): return {}
		var expected:Variant=template.get(key); var actual:Variant=data[key]
		if expected is int or expected is float:
			if not numeric(actual): return {}
		elif expected is Vector2i:
			if key=="facing":
				if not actual is Dictionary or not actual.get("_cell") is Array or actual._cell.size()!=2: return {}
				for n in actual._cell:
					if not numeric(n) or absf(n)>1: return {}
			elif not valid_cell(actual): return {}
		elif typeof(expected)!=typeof(actual): return {}
	if data.needs.size()!=6: return {}
	for n in data.needs:
		if not numeric(n) or n<0 or n>100: return {}
	if data.skin<0 or data.skin>3 or data.hair<0 or data.hair>3 or data.outfit<0 or data.outfit>3: return {}
	if data.speed<0 or data.speed>3 or data.work_style<0 or data.work_style>2 or data.minutes<0 or data.food<0: return {}
	if data.need_rate<0.5 or data.need_rate>1.5: return {}
	if not data.skills.has("criatividade") or not data.skills.has("carisma"): return {}
	for n in data.skills.values():
		if not numeric(n): return {}
	for at in data.route:
		if not valid_cell(at): return {}
	for npc in data.npcs:
		if not npc is Dictionary or not valid_cell(npc.get("cell")): return {}
		for field in ["id","name","job","state"]:
			if not npc.get(field) is String: return {}
		if npc.has("needs"):
			if not npc.needs is Array or npc.needs.size()!=6: return {}
			for n in npc.needs:
				if not numeric(n) or n<0 or n>100: return {}
		if npc.has("route"):
			if not npc.route is Array: return {}
			for at in npc.route:
				if not valid_cell(at): return {}
		if npc.has("action"):
			if not npc.action is Dictionary: return {}
			if not npc.action.is_empty():
				if not npc.action.get("id") is String or CityData.object_by_id(npc.action.id).is_empty(): return {}
				for key in ["need","duration","remaining","gain"]:
					if not numeric(npc.action.get(key)): return {}
				if npc.action.need<0 or npc.action.need>5 or npc.action.duration<=0 or npc.action.remaining<0: return {}
	for tx in data.ledger:
		if not tx is Dictionary or not numeric(tx.get("amount")) or not numeric(tx.get("minute")) or not tx.get("reason") is String: return {}
	for action in data.queue:
		if not valid_action(action): return {}
	if not data.current.is_empty() and not valid_action(data.current): return {}
	return data
