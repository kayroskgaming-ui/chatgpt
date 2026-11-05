class_name ControllerSupport
extends Node
const DEADZONE=0.24
var game:Node
var device:=-1
var active:=false
var axes:={}
var cursor_active:=false
var digital:={}
var cursor_position:=Vector2.ZERO
var cursor:Control
var glyph_label:Label
var axis_zoom_latched:={}
func _ready()->void:
	install_ui_actions()
	Input.joy_connection_changed.connect(connection_changed)
	cursor=Control.new(); cursor.mouse_filter=Control.MOUSE_FILTER_IGNORE; cursor.custom_minimum_size=Vector2(18,18); cursor.hide(); game.root.add_child(cursor)
	for rect in [Rect2(7,0,2,18),Rect2(0,7,18,2)]:
		var bar:=ColorRect.new(); bar.position=rect.position; bar.size=rect.size; bar.color=Color("e8e9a3"); bar.mouse_filter=Control.MOUSE_FILTER_IGNORE; cursor.add_child(bar)
	glyph_label=game.label("",11); glyph_label.position=Vector2(14,148); game.root.add_child(glyph_label); glyph_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if not Input.get_connected_joypads().is_empty(): device=Input.get_connected_joypads()[0]; activate()
func install_ui_actions()->void:
	for entry in [["ui_accept",JOY_BUTTON_A],["ui_cancel",JOY_BUTTON_B],["ui_up",JOY_BUTTON_DPAD_UP],["ui_down",JOY_BUTTON_DPAD_DOWN],["ui_left",JOY_BUTTON_DPAD_LEFT],["ui_right",JOY_BUTTON_DPAD_RIGHT]]:
		var event:=InputEventJoypadButton.new(); event.button_index=entry[1]
		if not InputMap.action_has_event(entry[0],event): InputMap.action_add_event(entry[0],event)
	for entry in [["ui_left",JOY_AXIS_LEFT_X,-1.0],["ui_right",JOY_AXIS_LEFT_X,1.0],["ui_up",JOY_AXIS_LEFT_Y,-1.0],["ui_down",JOY_AXIS_LEFT_Y,1.0]]:
		var event:=InputEventJoypadMotion.new(); event.axis=entry[1]; event.axis_value=entry[2]
		if not InputMap.action_has_event(entry[0],event): InputMap.action_add_event(entry[0],event)
func activate()->void:
	active=true
	glyph_label.text="Xbox · A interagir · B cancelar · X ações · Y destinos · Start menu"
func connection_changed(id:int,connected:bool)->void:
	if connected: device=id; activate(); game.log_message("Controle conectado. A: interagir · Start: menu.")
	elif device==id:
		axes.clear(); digital.clear(); active=false; cursor_active=false; cursor.hide(); game.world.highlight=Vector2i(-1,-1); glyph_label.text="Controle desconectado · mouse e teclado disponíveis"
		if game.started: game.sim.speed=0; game.log_message("Controle desconectado. Jogo pausado.")
func _input(event:InputEvent)->void:
	if event is InputEventMouseMotion or event is InputEventKey:
		if active:
			active=false; cursor.hide(); game.world.highlight=Vector2i(-1,-1); glyph_label.text="Mouse: clique para andar / interagir · WASD: movimento"
	if event is InputEventJoypadMotion:
		device=event.device; axes[event.axis]=event.axis_value
		if absf(event.axis_value)>DEADZONE: activate()
		if event.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT] and not game.modal_layer.visible:
			if event.axis_value>0.6 and not axis_zoom_latched.get(event.axis,false):
				game.world.zoom_level=clampi(game.world.zoom_level+(1 if event.axis==JOY_AXIS_TRIGGER_RIGHT else -1),0,3); axis_zoom_latched[event.axis]=true
			elif event.axis_value<0.3: axis_zoom_latched[event.axis]=false
	if event is InputEventJoypadButton and not game.modal_layer.visible and not game.context.visible and event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]:
		digital[event.button_index]=event.pressed; device=event.device; activate(); get_viewport().set_input_as_handled(); return
	if event is InputEventJoypadButton and event.pressed:
		device=event.device; activate()
		if handle_button(event.button_index): get_viewport().set_input_as_handled()
func handle_button(index:int)->bool:
	if game.name_keyboard!=null:
		if index==JOY_BUTTON_B: game.close_name_keyboard(); return true
		return false
	if game.context.visible:
		if index==JOY_BUTTON_B: game.context.hide(); return true
		return false
	if game.modal_layer.visible:
		if index in [JOY_BUTTON_B,JOY_BUTTON_START] and game.started and not game.sim.shift_prompt: game.close_modal(); return true
		var focused:=get_viewport().gui_get_focus_owner()
		if index==JOY_BUTTON_A and focused is LineEdit: game.show_name_keyboard(focused); return true
		return false
	if not game.started: return false
	match index:
		JOY_BUTTON_A:
			if cursor_active: game.on_cell(game.world.screen_cell(cursor_position))
			else: game.interact_nearest()
		JOY_BUTTON_B: game.sim.cancel_all()
		JOY_BUTTON_X: game.show_nearby()
		JOY_BUTTON_Y: game.show_map()
		JOY_BUTTON_START: game.show_menu()
		JOY_BUTTON_BACK: game.sim.speed=1 if game.sim.speed==0 else 0
		JOY_BUTTON_LEFT_SHOULDER: game.sim.speed=maxi(0,game.sim.speed-1)
		JOY_BUTTON_RIGHT_SHOULDER: game.sim.speed=mini(3,game.sim.speed+1)
		JOY_BUTTON_RIGHT_STICK: cursor_active=false; game.follow()
		_: return false
	return true
func _process(delta:float)->void:
	if active:
		glyph_label.text="Controle · A confirmar · B voltar · Direcional navegar" if game.modal_layer.visible else "Xbox · A interagir · B cancelar · X ações · Y destinos · Start menu"
	if not active or game.modal_layer.visible or game.context.visible: cursor.hide(); return
	var right:=Vector2(axes.get(JOY_AXIS_RIGHT_X,0.0),axes.get(JOY_AXIS_RIGHT_Y,0.0))
	if right.length()>DEADZONE:
		if not cursor_active: cursor_position=game.world.offset()+game.world.iso(game.world.visual_position)*game.world.zooms[game.world.zoom_level]
		cursor_active=true; cursor_position+=right*460*delta
		cursor_position=cursor_position.clamp(Vector2(12,185),get_viewport().get_visible_rect().size-Vector2(330,78))
	cursor.visible=cursor_active
	if cursor_active:
		cursor.position=cursor_position-Vector2(8,8); game.world.highlight=game.world.screen_cell(cursor_position)
	if not game.started: return
	var stick:=Vector2(axes.get(JOY_AXIS_LEFT_X,0.0),axes.get(JOY_AXIS_LEFT_Y,0.0))
	var dpad:=Vector2(int(digital.get(JOY_BUTTON_DPAD_RIGHT,false))-int(digital.get(JOY_BUTTON_DPAD_LEFT,false)),int(digital.get(JOY_BUTTON_DPAD_DOWN,false))-int(digital.get(JOY_BUTTON_DPAD_UP,false)))
	if dpad!=Vector2.ZERO: stick=dpad
	if stick.length()>DEADZONE:
		game.sim.manual_step(screen_direction(stick))
static func screen_direction(stick:Vector2)->Vector2i:
	# Project screen axes into the isometric grid; diagonal steps check both corners.
	var world_direction:=Vector2(stick.x+stick.y*2,stick.y*2-stick.x)
	var largest:=maxf(absf(world_direction.x),absf(world_direction.y))
	if largest<DEADZONE: return Vector2i.ZERO
	return Vector2i(signi(world_direction.x) if absf(world_direction.x)>largest*0.4 else 0,signi(world_direction.y) if absf(world_direction.y)>largest*0.4 else 0)
