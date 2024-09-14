extends Node2D
class_name Monster

# Behaviour Tree tutorial that I followed: https://youtu.be/aR6wt5BlE-E

enum TreeNodeState {
	RUNNING,
	SUCCESS,
	FAILURE,
}

const GO_TO_PLAYER_SPEED := 1.5;
const GRAB_DST := 75.0;
const CHARGE_TIME_THROW := 0.6;
const LEG_DST_TO_THROW := 15.0;
const THROW_DEAFEN_TIME := 0.5;
const THROW_VELOCITY := 250.0;
const TIME_TO_HURT := 0.5;
const RETREAT_SPEED := 1.0;
const TIME_CHANGE_ROOM := 20.0;
const WANDER_SPEED := 1.0;
const SEARCH_SPEED := 1.75;
const DAMAGE: int = 2;

class TreeNode:
	var state: TreeNodeState;
	var parent: TreeNode;
	var children: Array[TreeNode];
	var _dataContext: Dictionary;
	
	func _init(childs: Array[TreeNode] = []) -> void:
		self.parent = null;
		self.children = [];
		for child in childs:
			_attach(child);
		
	func _attach(node: TreeNode) -> void:
		node.parent = self;
		children.append(node);
	
	# override this method
	func evaluate(_delta: float) -> TreeNodeState:
		return TreeNodeState.FAILURE;

	# still not sure about this object
	func setData(key: String, obj) -> void:
		_dataContext[key] = obj;

	func getData(key: String):
		var value = null;
		if _dataContext.has(key):
			return _dataContext[key];
			
		var node: TreeNode = parent;
		while(node != null):
			value = node.getData(key);
			if value != null:
				return value
			node = node.parent;
		return null;
		
	func clearData(key: String) -> bool:
		if _dataContext.has(key):
			_dataContext.erase(key)
			return true;
			
		var node: TreeNode = parent;
		while(node != null):
			var cleared = node.clearData(key);
			if cleared:
				return true;
			node = node.parent;
		return false;
		
class BehaviorTree:
	var _root: TreeNode;
	
	func _init() -> void:
		_root = setupTree();
	
	# call this every frame
	func update(delta):
		if _root != null:
			_root.evaluate(delta);
	
	# override this function
	func setupTree() -> TreeNode:
		return null;

# Only if every child succeed is Sequence also succeeds
# kinda like AND-Gate
class Sequence extends TreeNode:
	func _init(childs: Array[TreeNode] = []) -> void:
		super(childs);
	
	func evaluate(delta: float) -> TreeNodeState:
		var anyChildRunning := false;
		for node in children:
			match node.evaluate(delta):
				TreeNodeState.FAILURE:
					state = TreeNodeState.FAILURE;
					return state;
				TreeNodeState.SUCCESS:
					continue;
				TreeNodeState.RUNNING:
					anyChildRunning = true;
					break;
				_:
					state = TreeNodeState.SUCCESS;
					return state;
		state = TreeNodeState.RUNNING if anyChildRunning else TreeNodeState.SUCCESS;
		return state;

# Return early if some child has succeed or is running, 
# kinda like OR-Gate
class Selector extends TreeNode:
	func _init(childs: Array[TreeNode] = []) -> void:
		super(childs);
	
	func evaluate(delta: float) -> TreeNodeState:
		for node in children:
			match node.evaluate(delta):
				TreeNodeState.FAILURE:
					continue;
				TreeNodeState.SUCCESS:
					state = TreeNodeState.SUCCESS;
					return state;
				TreeNodeState.RUNNING:
					state = TreeNodeState.RUNNING;
					return state;
				_:
					continue
		state = TreeNodeState.FAILURE;
		return state;

class TaskWander extends TreeNode:
	var _monsterBody: MonsterBody;
	var _modules: Array[Module];
	var _navigationAgent: NavigationAgent2D;
	var _rndRoomToGo: Module;
	var _changeRoomTimer: float;
	
	func _init(monsterBody: MonsterBody, modules: Array[Module], navigationAgent: NavigationAgent2D) -> void:
		super();
		_monsterBody = monsterBody;
		_modules = modules.filter(func(module: Module): return module.type != Modules.ModuleType.CORRIDOR);
		_navigationAgent = navigationAgent;
		_rndRoomToGo = _modules.pick_random();
		_changeRoomTimer = 0.0;
	
	func evaluate(delta: float) -> TreeNodeState:
		_changeRoomTimer += delta
		var dst := _monsterBody.global_position.distance_to(_rndRoomToGo.global_position);
		if dst < Modules.GRID_SIZE || _changeRoomTimer >= TIME_CHANGE_ROOM:
			_changeRoomTimer = 0.0;
			_rndRoomToGo = _modules.pick_random();
		
		_navigationAgent.target_position = _rndRoomToGo.global_position;
		var direction = (_navigationAgent.get_next_path_position() - _monsterBody.global_position).normalized();
		_monsterBody.move(direction * WANDER_SPEED);

		state = TreeNodeState.RUNNING;
		return state;

class CheckPlayerInFOVRange extends TreeNode:
	var _monsterBody: MonsterBody;
	var _player: Player;
	
	func _init(monsterBody: MonsterBody, player: Player) -> void:
		super();
		_monsterBody = monsterBody;
		_player = player;
	
	func evaluate(_delta: float) -> TreeNodeState:
		if _monsterBody.canSeePlayer():
			parent.parent.setData("lastPlayerPos", _player.global_position);
			return TreeNodeState.SUCCESS
		_monsterBody.grabPlayer(false);
		return TreeNodeState.FAILURE;

class TaskGoToPlayer extends TreeNode:
	var _monsterBody: MonsterBody;
	var _navigationAgent: NavigationAgent2D;
	
	func _init(monsterBody: MonsterBody, navigationAgent: NavigationAgent2D) -> void:
		super();
		_monsterBody = monsterBody;
		_navigationAgent = navigationAgent;
		
	func evaluate(_delta: float) -> TreeNodeState:
		_navigationAgent.target_position = parent.parent.getData("lastPlayerPos");
		var direction = (_navigationAgent.get_next_path_position() - _monsterBody.global_position).normalized();
		_monsterBody.move(direction * GO_TO_PLAYER_SPEED);
		
		var dst := _monsterBody.global_position.distance_to(_navigationAgent.target_position);
		
		if dst < GRAB_DST + 10.0:
			return TreeNodeState.SUCCESS;
		
		_monsterBody.grabPlayer(false);
		return TreeNodeState.RUNNING;
		
class TaskSearchPlayer extends TreeNode:
	var _monsterBody: MonsterBody;
	var _navigationAgent: NavigationAgent2D;
	
	func _init(monsterBody: MonsterBody, navigationAgent: NavigationAgent2D) -> void:
		super();
		_monsterBody = monsterBody;
		_navigationAgent = navigationAgent;
		
	func evaluate(_delta: float) -> TreeNodeState:
		var lastPlayerPos = parent.getData("lastPlayerPos");
		if lastPlayerPos == null or !(lastPlayerPos is Vector2):
			return TreeNodeState.FAILURE;
		
		var dst := _monsterBody.global_position.distance_to(_navigationAgent.target_position);
		
		if dst < 50.0:
			# player is lost
			parent.clearData("lastPlayerPos");
			_monsterBody.move(Vector2.ZERO);
			return TreeNodeState.SUCCESS;
		
		# Go to last seen position
		_navigationAgent.target_position = lastPlayerPos;
		var direction = (_navigationAgent.get_next_path_position() - _monsterBody.global_position).normalized();
		_monsterBody.move(direction * SEARCH_SPEED);
		return TreeNodeState.RUNNING;
		
class TaskGrabPlayer extends TreeNode:
	var _monsterBody: MonsterBody;
	var _player: Player;
	
	func _init(monsterBody: MonsterBody, player: Player) -> void:
		super();
		_monsterBody = monsterBody;
		_player = player;
	
	func evaluate(_delta: float) -> TreeNodeState:
		if _monsterBody.global_position.distance_to(_player.global_position) <= GRAB_DST:
			# Stop moving
			_monsterBody.move(Vector2.ZERO);
			
			# Remember when attack started
			var time = parent.parent.getData("attackTime");
			if time == null || !(time is int):
				parent.parent.setData("attackTime", int(Time.get_ticks_msec() / 1000));
			
			# Grab player
			_monsterBody.grabPlayer(true);
			return TreeNodeState.SUCCESS;
		
		# Player is to far
		_monsterBody.grabPlayer(false);
		parent.parent.clearData("attackTime");
		return TreeNodeState.FAILURE

class TaskThrowPlayer extends TreeNode:
	var _monsterBody: MonsterBody;
	var _player: Player;
	
	func _init(monsterBody: MonsterBody, player: Player) -> void:
		super();
		_monsterBody = monsterBody;
		_player = player;
	
	func evaluate(_delta: float) -> TreeNodeState:
		var time = parent.parent.getData("attackTime");
		if time == null || !(time is int):
			return TreeNodeState.FAILURE;
		
		# If monster is holding player for CHARGE_TIME_THROW seconds
		if int(Time.get_ticks_msec() / 1000) - (time as int) <= CHARGE_TIME_THROW:
			return TreeNodeState.RUNNING;

		# And monster leg is on player
		var dst := _monsterBody.grabPlayer(true); # just gets dst
		if dst > LEG_DST_TO_THROW:
			return TreeNodeState.RUNNING;
		
		# Push player in oposite side and deafen him
		_player.deafen(THROW_DEAFEN_TIME);
		var throwSide := signf(_monsterBody.global_position.x - _player.global_position.x);
		_player.velocity = Vector2(THROW_VELOCITY * throwSide, THROW_VELOCITY * float(randi_range(-1, 1)));
		
		# Reset after attack
		_monsterBody.grabPlayer(false);
		parent.parent.clearData("attackTime");
		return TreeNodeState.SUCCESS;
		
class CheckIsMonsterHurt extends TreeNode:
	var _monsterBody: MonsterBody;
	var _hurtTime: int;
	
	func _init(monsterBody: MonsterBody) -> void:
		super();
		_monsterBody = monsterBody;
	
	func evaluate(_delta: float) -> TreeNodeState:
		var oldHealth = getData("oldHealth");
		var healthNow := _monsterBody.getHealth();
		var hurt: bool = false;
		if oldHealth != null and oldHealth is int:
			hurt = oldHealth > healthNow;
		setData("oldHealth", healthNow as int);
		if hurt:
			_hurtTime = int(Time.get_ticks_msec() / 1000)
			_monsterBody.grabPlayer(false);
			
		var timeSinceHurt = int(Time.get_ticks_msec() / 1000) - _hurtTime;
		return TreeNodeState.SUCCESS if hurt or timeSinceHurt < TIME_TO_HURT else TreeNodeState.FAILURE;

class TaskRetreat extends TreeNode:
	var _monsterBody: MonsterBody;
	var _player: Player;
	
	func _init(monsterBody: MonsterBody, player: Player) -> void:
		super();
		_monsterBody = monsterBody;
		_player = player;
	
	func evaluate(_delta: float) -> TreeNodeState:
		var directionToPlayer := _monsterBody.global_position.direction_to(_player.global_position);
		_monsterBody.move(directionToPlayer * -RETREAT_SPEED);
		return TreeNodeState.RUNNING;
		
class CheckMonsterAlive extends TreeNode:
	var _monsterBody: MonsterBody;
	
	func _init(monsterBody: MonsterBody) -> void:
		super();
		_monsterBody = monsterBody;
		
	func evaluate(_delta: float) -> TreeNodeState:
		if _monsterBody.getHealth() <= 0:
			_monsterBody.move(Vector2.ZERO);
			return TreeNodeState.FAILURE;
		return TreeNodeState.SUCCESS;

class CheckSpawned extends TreeNode:
	var _monsterBody: MonsterBody;
	var _modules: Array[Module];
	var _storm: Storm;
	var _navigationAgent: NavigationAgent2D;
	var _player: Player;
	var _targetModule: Module;
	var _spawned: bool;
	
	func _init(monsterBody: MonsterBody, modules: Array[Module], storm: Storm, navigationAgent: NavigationAgent2D, player: Player) -> void:
		super();
		_monsterBody = monsterBody;
		_modules = modules;
		_storm = storm;
		_navigationAgent = navigationAgent;
		_player = player;
		_targetModule = null;
		_spawned = false;
		
	func _findMostDistantModule() -> Module:
		var biggestDst: float = -100;
		var mostDistantModule := _modules[0];
		for module: Module in _modules:
			var dst := module.global_position.distance_to(_player.global_position);
			if dst > biggestDst:
				biggestDst = dst
				mostDistantModule = module;
		return mostDistantModule;
		
	func teleport(pos: Vector2) -> void:
		_monsterBody.get_parent().global_position = pos;
		_monsterBody.position = Vector2(0, 0);
		_monsterBody._center = pos;
		_monsterBody.resetLegs();
		for face in _monsterBody._faces:
			face.position = Vector2(0, 0);
			face.linear_velocity = Vector2(0, 0);
			face.angular_velocity = 0;
		_monsterBody.get_parent().global_position = pos;
	
	func evaluate(delta: float) -> TreeNodeState:
		# spawn
		if not _spawned and _storm.isStorm():
			_spawned = true;
			_targetModule = null;
			_monsterBody.visible = true;
			teleport(_findMostDistantModule().global_position);
			
		# despawn
		elif _spawned and not _storm.isStorm():
			# Go to distant room
			if _targetModule == null:
				_targetModule = _findMostDistantModule();
			_navigationAgent.target_position = _targetModule.global_position;
			var direction = (_navigationAgent.get_next_path_position() - _monsterBody.global_position).normalized();
			_monsterBody.move(direction * 4.0);
			_monsterBody.grabPlayer(false);
			
			# If reached the most far room, despawn
			var dstToMonster := _monsterBody.global_position.distance_to(_targetModule.global_position);
			if dstToMonster < Modules.GRID_SIZE:
				_monsterBody.visible = false;
				teleport(Vector2(-1e5, -1e5));
				_targetModule = null;
				_spawned = false;
			return TreeNodeState.RUNNING;
		
		return TreeNodeState.SUCCESS if _storm.isStorm() else TreeNodeState.FAILURE;

class MonsterBT extends BehaviorTree:
	var _monsterBody: MonsterBody;
	var _modules: Array[Module];
	var _navigationAgent: NavigationAgent2D;
	var _player: Player;
	var _storm: Storm;
	
	func _init(monsterBody: MonsterBody, modules: Array[Module], navigationAgent: NavigationAgent2D, player: Player, storm: Storm) -> void:
		_monsterBody = monsterBody;
		_modules = modules;
		_navigationAgent = navigationAgent;
		_player = player;
		_storm = storm;
		super(); # has to be last, because it will call setupTree(), that needs all above
	
	func setupTree() -> TreeNode:
		var root = Sequence.new([
			CheckMonsterAlive.new(_monsterBody),
			CheckSpawned.new(_monsterBody, _modules, _storm, _navigationAgent, _player),
			Selector.new([
				Sequence.new([
					CheckIsMonsterHurt.new(_monsterBody),
					TaskRetreat.new(_monsterBody, _player)
				]),
				Sequence.new([
					CheckPlayerInFOVRange.new(_monsterBody, _player),
					TaskGoToPlayer.new(_monsterBody, _navigationAgent),
					TaskGrabPlayer.new(_monsterBody, _player), # TODO: Enable this line
					TaskThrowPlayer.new(_monsterBody, _player) # TODO: Enable this line
				]),
				TaskSearchPlayer.new(_monsterBody, _navigationAgent),
				TaskWander.new(_monsterBody, _modules, _navigationAgent)
			])
		])
		return root;

@export var monsterBody: MonsterBody = null;
@export var player: Player = null;
@export var navigationAgent: NavigationAgent2D = null;
@export var modules: NavigationRegion2D = null;
@export var storm: Storm = null;
var _isNavigationMapBaked: bool = false;
var _monsterBT: MonsterBT;

func getAllModules() -> Array[Module]:
	var arr: Array[Module] = [];
	for child in modules.get_children():
		if child is Module:
			arr.append(child);
	return arr;
	
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if _monsterBT != null:
		_monsterBT.update(delta);
	queue_redraw();

func _draw() -> void:
	pass
	
func takeDamage() -> void:
	monsterBody.setHealth(max(0, monsterBody.getHealth() - DAMAGE));

func _on_modules_bake_finished() -> void:
	_isNavigationMapBaked = true;
	call_deferred("createTree"); # Need this because await can create funny situation

func createTree() -> void:
	await get_tree().physics_frame; # need this to wait for navigation map to update
	var arr := getAllModules();
	_monsterBT = MonsterBT.new(monsterBody, arr, navigationAgent, player, storm);
