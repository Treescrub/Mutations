/*
	make OnEquipped and OnUnequipped for non-custom weapons?
*/

/*options
fire custom weapon while restricted (default is off)
print debug info (default is on)
*/


enum Keys {
	ATTACK = 1,
	JUMP = 2,
	CROUCH = 4,
	FORWARD = 8,
	BACKWARD = 16,
	USE = 32,
	LEFT = 512,
	RIGHT = 1024,
	ATTACK2 = 2048,
	RELOAD = 8192,
	SHOWSCORES = 65536,
	WALK = 131072,
	ZOOM = 524288
}

const ATTACK = 1
const JUMP = 2
const CROUCH = 4
const FORWARD = 8
const BACKWARD = 16
const USE = 32
const LEFT = 512
const RIGHT = 1024
const ATTACK2 = 2048
const RELOAD = 8192
const SHOWSCORES = 65536
const WALK = 131072
const ZOOM = 524288

const CHAR_SPACE = 32
const CHAR_NEWLINE = 10

const PRINT_START = "Hook Controller: "

class PlayerInfo {
	entity = null
	disabled = false
	disabledLast = false
	heldButtonsMask = 0
	
	lastWeapon = null
	lastWeapons = []
	
	constructor(ent){
		entity = ent
	}
	
	function SetDisabled(isDisabled){
		disabledLast = disabled
		disabled = isDisabled
	}
	
	function IsDisabled(){
		return disabled
	}
	
	function WasDisabled(){
		return disabledLast
	}
	
	
	function GetEntity(){
		return entity
	}
	
	
	function GetHeldButtonsMask(){
		return heldButtonsMask
	}
	
	function SetHeldButtonsMask(mask){
		heldButtonsMask = mask
	}
	
	
	function GetLastWeapon(){
		return lastWeapon
	}
	
	
	function SetLastWeapon(ent){
		lastWeapon = ent
	}
	
	function GetLastWeaponsArray(){
		return lastWeapons
	}
	function SetLastWeaponsArray(array){
		lastWeapons = array
	}
}

class CustomWeapon {
	viewmodel = null
	worldmodel = null
	scope = null
	
	constructor(vmodel, wmodel, scriptscope){
		viewmodel = vmodel
		worldmodel = wmodel
		scope = scriptscope
	}
	
	function GetViewmodel(){
		return viewmodel
	}
	
	function GetWorldModel(){
		return worldmodel
	}
	
	function GetScope(){
		return scope
	}
}

class EntityCreateListener {
	oldEntities = []
	scope = null
	classname = null
	
	constructor(className, scriptscope){
		classname = className
		scope = scriptscope
	}
	
	function GetClassname(){
		return classname
	}
	
	function GetScope(){
		return scope
	}
	
	function GetOldEntities(){
		return oldEntities
	}
	function SetOldEntities(array){
		oldEntities = array
	}
}

class EntityMoveListener {
	lastPosition = null
	entity = null
	scope = null
	
	constructor(ent, scriptScope){
		entity = ent
		scope = scriptScope
		lastPosition = entity.GetOrigin()
	}
	
	function GetScope(){
		return scope
	}
	
	function GetEntity(){
		return entity
	}
	
	function GetLastPosition(){
		return lastPosition
	}
	
	function SetLastPosition(position){
		lastPosition = position
	}
}

class BileExplodeListener {
	scope = null
	
	constructor(scope){
		this.scope = scope
	}
	
	function GetScope(){
		return scope
	}
}

class Task {
	functionKey = null
	args = null
	endTime = null
	
	/*
		We place the function in a table with the arguments so that the function can access the arguments
	*/
	constructor(func, arguments, time){
		functionKey = UniqueString("TaskFunction")
		args = arguments
		args[functionKey] <- func
		endTime = time
	}
	
	function CallFunction(){
		args[functionKey]()
	}
	
	function ReachedTime(){
		return Time() >= endTime
	}
}

class Timer {
	constructor(hudField, time, callFunction, countDown, formatTime){
		this.hudField = hudField
		this.time = time
		this.callFunction = callFunction
		this.countDown = countDown
		this.formatTime = formatTime
		
		start = Time()
	}
	
	function FormatTime(time){
		local seconds = ceil(time) % 60
		local minutes = floor(ceil(time) / 60)
		if(seconds < 10){
			return minutes.tointeger() + ":0" + seconds.tointeger()
		} else {
			return minutes.tointeger() + ":" + seconds.tointeger()
		}
	}
	
	function Update(){
		local timeRemaining = -1
		
		if(countDown){
			timeRemaining = time - (Time() - start)
		} else {
			timeRemaining = Time() - start
		}
		
		if(formatTime){
			hudField.dataval = FormatTime(timeRemaining)
		} else {
			if(countDown){
				timeRemaining = ceil(timeRemaining).tointeger()
			} else {
				timeRemaining = floor(timeRemaining).tointeger()
			}
			hudField.dataval = timeRemaining
		}
		
		return (countDown && timeRemaining <= 0) || (!countDown && timeRemaining >= time)
	}
	
	function CallFunction(){
		callFunction()
	}
	
	function GetHudField(){
		return hudField
	}
	
	hudField = null
	start = -1
	time = -1
	callFunction = null
	countDown = true
	formatTime = false
}

class ChatCommand {
	inputCommand = false
	commandString = null
	commandFunction = null
	
	constructor(command, func, isInput){
		commandString = command
		commandFunction = func
		inputCommand = isInput
	}
	
	function CallFunction(ent, input = null){
		if(inputCommand){
			commandFunction(ent, input)
		} else {
			commandFunction(ent)
		}
	}
	
	function GetCommand(){
		return commandString
	}
	
	function IsInputCommand(){
		return inputCommand
	}
}

class ConvarListener {
	convar = null
	convarType = null
	lastValue = null
	scope = null
	
	/*
		type should be either "string" or "float"
	*/
	constructor(convarName, type, scriptScope){
		convar = convarName
		convarType = type
		scope = scriptScope
	}
	
	function GetScope(){
		return scope
	}
	
	function GetConvar(){
		return convar
	}
	
	function GetCurrentValue(){
		if(type == "string"){
			return Convars.GetStr(convar)
		} else if(type == "float"){
			return Convars.GetFloat(convar)
		}
	}
	
	function GetLastValue(){
		return lastValue
	}
	
	function SetLastValue(){
		if(type == "string"){
			lastValue = Convars.GetStr(convar)
		} else if(type == "float"){
			lastValue = Convars.GetFloat(convar)
		}
	}
}

class FunctionListener {
	checkFunctionTable = null
	checkFunctionKey = null
	callFunction = null
	singleUse = false
	
	constructor(checkFunction, callFunction, args, singleUse){
		checkFunctionTable = args
		checkFunctionKey = UniqueString()
		checkFunctionTable[checkFunctionKey] <- checkFunction
		this.callFunction = callFunction
		this.singleUse = singleUse
	}
	
	function CheckValue(){
		if(checkFunctionTable[checkFunctionKey]()){
			callFunction()
			return true
		}
		return false
	}
	
	function IsSingleUse(){
		return singleUse
	}
}

class LockedEntity {
	entity = null
	angles = null
	origin = null
	
	constructor(entity, angles, origin){
		this.entity = entity
		this.angles = angles
		this.origin = origin
	}
	
	function DoLock(){
		entity.SetAngles(angles)
		entity.SetOrigin(origin)
	}
}

class ThrownBile {
	entity = null
	thrower = null
	lastPosition = null
	lastVelocity = null
	
	constructor(entity, thrower, lastPosition, lastVelocity){
		this.entity = entity
		this.thrower = thrower
		this.lastPosition = lastPosition
		this.lastVelocity = lastVelocity
	}
	
	function CheckRemoved(){
		return entity == null || !entity.IsValid()
	}
	
	function GetLastPosition(){
		return lastPosition
	}
	
	function GetLastVelocity(){
		return lastVelocity
	}
	
	function GetThrower(){
		return thrower
	}
}

printl("Hook Controller loaded. (Made by Daroot Leafstorm)")

// options
local debugPrint = true

local customWeapons = []
local hookScripts = []
local tickScripts = []
local tickFunctions = []
local entityMoveListeners = []
local entityCreateListeners = []
local bileExplodeListeners = []
local convarListeners = []
local functionListeners = []
local chatCommands = []
local timers = []
local tasks = []
local lockedEntities = []

local bileJars = []

local players = []


// This initializes the timer responsible for the calls to the Think function
local timer = SpawnEntityFromTable("logic_timer",{RefireTime = 0.01})
timer.ValidateScriptScope()
timer.GetScriptScope()["scope"] <- this
timer.GetScriptScope()["func"] <- function(){
	scope.Think()
}
timer.ConnectOutput("OnTimer", "func")
EntFire("!self","Enable",null,0,timer)

if(debugPrint){
	printl(PRINT_START + "HookController initialized at " + Time() + "\n\ttimer: " + timer)
}

local function GetSurvivors(){
	local array = []
	local ent = null
	while (ent = Entities.FindByClassname(ent, "player")){
		if(ent.IsValid() && ent.IsSurvivor()){
			array.append(ent)
		}
	}

	return array
}

local function FindPlayerObject(entity){
	foreach(player in players){
		if(player.GetEntity() == entity){
			return player
		}
	}
}

local function FindCustomWeapon(viewmodel){ // make this so it won't break really easy
	foreach(weapon in customWeapons){
		if(weapon.GetViewmodel() == viewmodel){
			return weapon
		}
	}
}

local function CallFunction(scope, funcName, ent = null, player = null){ // if parameters has entity (or ent), pass ent, if has player, pass player
	if(scope != null && funcName in scope && typeof(scope[funcName]) == "function"){
		local params = scope[funcName].getinfos().parameters
		local index_offset = 0 // sometimes it contains "this" sometimes it doesn't?
		if(params.find("this") != null){
			index_offset = -1
		}
		if(params.find("player") != null){
			if(params.find("ent") != null){
				if(params.find("ent") + index_offset == 0){
					scope[funcName](ent, player)
				} else {
					scope[funcName](player, ent)
				}
			} else if(params.find("entity") != null) {
				if(params.find("entity") + index_offset == 0){
					scope[funcName](ent, player)
				} else {
					scope[funcName](player, ent)
				}
			} else {
				scope[funcName](player)
			}
		} else if(params.find("ent") != null || params.find("entity") != null){
			scope[funcName](ent)
		} else {
			scope[funcName]()
		}
	}
}

local function CallInventoryChangeFunction(scope, ent, droppedWeapons, newWeapons){
	if(scope != null && "OnInventoryChange" in scope && typeof(scope["OnInventoryChange"]) == "function"){
		scope["OnInventoryChange"](ent, droppedWeapons, newWeapons)
	}
}

local function CallKeyPressFunctions(player, scope, keyId, keyName){
	if(player.GetEntity().GetButtonMask() & keyId){
		if(player.GetHeldButtonsMask() & keyId){
			foreach(script in hookScripts){
				CallFunction(script, "OnKeyPressTick_" + keyName, player.GetEntity().GetActiveWeapon(), player.GetEntity())
			}
			CallFunction(scope, "OnKeyPressTick_" + keyName, player.GetEntity().GetActiveWeapon(), player.GetEntity())
		} else {
			player.SetHeldButtonsMask(player.GetHeldButtonsMask() | keyId)
			foreach(script in hookScripts){
				CallFunction(script, "OnKeyPressStart_" + keyName, player.GetEntity().GetActiveWeapon(), player.GetEntity())
			}
			CallFunction(scope, "OnKeyPressStart_" + keyName, player.GetEntity().GetActiveWeapon(), player.GetEntity())
		}
	} else if(player.GetHeldButtonsMask() & keyId){
		player.SetHeldButtonsMask(player.GetHeldButtonsMask() & ~keyId)
		foreach(script in hookScripts){
			CallFunction(script, "OnKeyPressEnd_" + keyName, player.GetEntity().GetActiveWeapon(), player.GetEntity())
		}
		CallFunction(scope, "OnKeyPressEnd_" + keyName, player.GetEntity().GetActiveWeapon(), player.GetEntity())
	}
}

local function CallWeaponEquipFunctions(player, weaponModel){
	if(player.GetLastWeapon() != null && NetProps.GetPropString(player.GetLastWeapon(), "m_ModelName") != weaponModel){ //we changed weapons!
		foreach(weapon in customWeapons){
			if(NetProps.GetPropString(player.GetLastWeapon(), "m_ModelName") == weapon.GetViewmodel()){
				CallFunction(weapon.GetScope(),"OnUnequipped",player.GetLastWeapon(),player.GetEntity())
			} else if(weaponModel == weapon.GetViewmodel()){
				CallFunction(weapon.GetScope(),"OnEquipped",player.GetLastWeapon(),player.GetEntity())
			}
		}
	}
}

local function CallConvarChangeFunction(scope, funcName, previousValue, newValue){
	if(scope != null && funcName in scope && typeof(scope[funcName]) == "function"){
		scope[funcName](previousValue, newValue)
	}
}

local function HandleCallback(scope, weaponModel, player){ // scope = scope of custom weapon, model = model of current weapon
	CallWeaponEquipFunctions(player, weaponModel)
	
	CallKeyPressFunctions(player, scope, ATTACK, "Attack")
	CallKeyPressFunctions(player, scope, ATTACK2, "Attack2")
	CallKeyPressFunctions(player, scope, CROUCH, "Crouch")
	CallKeyPressFunctions(player, scope, LEFT, "Left")
	CallKeyPressFunctions(player, scope, RIGHT, "Right")
	CallKeyPressFunctions(player, scope, FORWARD, "Forward")
	CallKeyPressFunctions(player, scope, BACKWARD, "Backward")
	CallKeyPressFunctions(player, scope, USE, "Use")
	CallKeyPressFunctions(player, scope, RELOAD, "Reload")
	CallKeyPressFunctions(player, scope, SHOWSCORES, "Showscores")
	CallKeyPressFunctions(player, scope, WALK, "Walk")
	CallKeyPressFunctions(player, scope, ZOOM, "Zoom")
	CallKeyPressFunctions(player, scope, JUMP, "Jump")
}

function Think(){
	foreach(script in hookScripts){
		CallFunction(script, "OnTick")
	}
	foreach(script in tickScripts){
		CallFunction(script, "OnTick")
	}
	foreach(func in tickFunctions){
		func()
	}
	foreach(weapon in customWeapons){
		CallFunction(weapon.GetScope(), "OnTick")
	}
	foreach(survivor in GetSurvivors()){
		if(players.len() == 0){
			players.append(PlayerInfo(survivor))
		} else {
			local found = false
			for(local i=0; i<players.len();i++){
				if(players[i].GetEntity() != null && players[i].GetEntity().IsValid()){
					if(survivor.GetPlayerUserId() == players[i].GetEntity().GetPlayerUserId()){
						found = true
					}
					
					if(players[i].WasDisabled() && !players[i].IsDisabled()){
						foreach(weapon in customWeapons){
							CallFunction(weapon.GetScope(), "OnReleased", players[i].GetEntity().GetActiveWeapon(), players[i].GetEntity())
						}
					}
					if(!players[i].WasDisabled() && players[i].IsDisabled()){
						foreach(weapon in customWeapons){
							CallFunction(weapon.GetScope(), "OnRestricted", players[i].GetEntity().GetActiveWeapon(), players[i].GetEntity())
						}
					}
				} else {
					players.remove(i)
					i -= 1
				}
			}
			if(!found){
				players.append(PlayerInfo(survivor))
			}
		}
	}
	
	if(bileExplodeListeners.len() > 0){
		foreach(bileJar in bileJars){
			if(bileJar.CheckRemoved()){
				foreach(listener in bileExplodeListeners){
					if("OnBileExplode" in listener.GetScope() && typeof(listener.GetScope()["OnBileExplode"]) == "function"){
						listener.GetScope()["OnBileExplode"](bileJar.GetThrower(), bileJar.GetLastPosition())
					}
				}
			}
		}
		
		bileJars.clear()
		
		local bileJar = null
		while(bileJar = Entities.FindByClassname(bileJar, "vomitjar_projectile")){
			bileJars.append(ThrownBile(bileJar, NetProps.GetPropEntity(bileJar, "m_hThrower"), bileJar.GetOrigin(), bileJar.GetVelocity()))
		}
	}
	
	for(local i=0; i<tasks.len(); i+=1){
		if(tasks[i].ReachedTime()){
			try{
				tasks[i].CallFunction()
			} catch(e){
				printl(e)
			}
			tasks.remove(i)
			i -= 1
		}
	}
	
	for(local i=0; i < timers.len(); i++){
		if(timers[i].Update()){
			timers[i].CallFunction()
			timers.remove(i)
			i--
		}
	}
	
	for(local i=0; i < functionListeners.len(); i+=1){
		if(functionListeners[i].CheckValue() && functionListeners[i].IsSingleUse()){
			functionListeners.remove(i)
			i -= 1
		}
	}
	
	foreach(lockedEntity in lockedEntities){
		lockedEntity.DoLock()
	}
	
	foreach(listener in entityMoveListeners){
		local currentPosition = listener.GetEntity().GetOrigin()
		local oldPosition = listener.GetLastPosition()
		if(oldPosition != null && currentPosition != oldPosition){
			CallFunction(listener.GetScope(),"OnEntityMove",listener.GetEntity())
		}
		listener.SetLastPosition(listener.GetEntity().GetOrigin())
	}
	
	foreach(listener in entityCreateListeners){
		local ent = null
		local entityArray = []
		while((ent = Entities.FindByClassname(ent,listener.GetClassname())) != null){
			entityArray.append(ent)
		}
		if(listener.GetOldEntities() != null && listener.GetOldEntities().len() < entityArray.len()){ // this may miss entities if an entity of the same type is killed at the same time as one is spawned
			entityArray.sort(@(a, b) a.GetEntityIndex() <=> b.GetEntityIndex())
			local newEntities = entityArray.slice(listener.GetOldEntities().len())
			foreach(newEntity in newEntities){
				CallFunction(listener.GetScope(), "OnEntCreate_" + listener.GetClassname(), newEntity)
			}
		}
		listener.SetOldEntities(entityArray)
	}
	
	foreach(listener in convarListeners){
		if(listener.GetCurrentValue() != listener.GetLastValue){
			CallConvarChangeFunction(listener.GetScope(), "OnConvarChange_" + listener.GetConvar(), listener.GetLastValue(), listener.GetCurrentValue())
		}
		
		listener.SetLastValue()
	}
	
	if(customWeapons.len() > 0 || hookScripts.len() > 0){
		foreach(player in players){
			if(player.GetEntity() == null || !player.GetEntity().IsValid() || player.GetEntity().IsDead()){
				player.SetDisabled(true)
			} else {
				local weaponModel = NetProps.GetPropString(player.GetEntity().GetActiveWeapon(), "m_ModelName")
				local customWeapon = FindCustomWeapon(weaponModel)
				if(customWeapon != null){
					HandleCallback(customWeapon.GetScope(), weaponModel, player)
					player.SetLastWeapon(player.GetEntity().GetActiveWeapon())
				} else {
					HandleCallback(null,weaponModel, player)
					player.SetLastWeapon(player.GetEntity().GetActiveWeapon())
				}
				
		
				local currentWeapons = []
				local newWeapons = []
				local droppedWeapons = player.GetLastWeaponsArray()
				
				local inventoryIndex = 0
				local item = null
				
				while(inventoryIndex < 5){
					item = NetProps.GetPropEntityArray(player.GetEntity(), "m_hMyWeapons", inventoryIndex)
					if(item != null){
						currentWeapons.append(item)
						newWeapons.append(item)
					}
					inventoryIndex += 1
				}
				
				if(player.GetLastWeaponsArray() == null){
					droppedWeapons = currentWeapons
				}
				
				for(local i=0;i < droppedWeapons.len();i+=1){
					for(local j=0;j < newWeapons.len();j+=1){
						if(i < droppedWeapons.len() && droppedWeapons[i] != null){
							if(newWeapons != null && droppedWeapons != null && newWeapons[j] != null && droppedWeapons[i] != null && newWeapons[j].IsValid() && droppedWeapons[i].IsValid() && newWeapons[j].GetEntityIndex() == droppedWeapons[i].GetEntityIndex()){
								newWeapons.remove(j)
								droppedWeapons.remove(i)
								if(i != 0){
									i -= 1
								}
								j -= 1
							}
						}
					}
				}
				
				if(newWeapons.len() > 0) {
					foreach(ent in newWeapons){
						foreach(weapon in customWeapons){
							if(NetProps.GetPropString(ent, "m_ModelName") == weapon.GetViewmodel()){
								CallFunction(weapon.GetScope(), "OnPickup", ent, player.GetEntity())
							}
						}
					}
				}
				if(droppedWeapons.len() > 0){
					foreach(ent in droppedWeapons){
						foreach(weapon in customWeapons){
							if(NetProps.GetPropString(ent, "m_ModelName") == weapon.GetWorldModel()){
								CallFunction(weapon.GetScope(), "OnDrop", ent, player.GetEntity())
							}
						}
					}
				}
				if(newWeapons.len() > 0 || droppedWeapons.len() > 0){
					foreach(scope in hookScripts){
						CallInventoryChangeFunction(scope, player.GetEntity(), droppedWeapons, newWeapons)
					}
				}
				
				player.SetLastWeaponsArray(currentWeapons)
			}
		}
	}
}

function RegisterFunctionListener(checkFunction, callFunction, args, singleUse){
	functionListeners.append(FunctionListener(checkFunction, callFunction, args, singleUse))
	if(debugPrint){
		printl(PRINT_START + "Registered function listener")
	}
	return true
}

function RegisterCustomWeapon(viewmodel, worldmodel, script){
	local failed = "Failed to register a custom weapon script "
	local script_scope = {}
	if(!IncludeScript(script, script_scope)){
		if(debugPrint){
			printl(PRINT_START + failed + "(Could not include script)")
		}
		return false
	}
	if(viewmodel.slice(viewmodel.len()-4) != ".mdl"){
		viewmodel = viewmodel + ".mdl"
	}
	if(worldmodel.slice(worldmodel.len()-4) != ".mdl"){
		worldmodel = worldmodel + ".mdl"
	}
	customWeapons.append(CustomWeapon(viewmodel,worldmodel,script_scope))
	if("OnInitialize" in script_scope){
		script_scope["OnInitialize"]()
	}
	if(debugPrint){
		printl(PRINT_START + "Registered custom weapon script " + script)
	}
	return script_scope
}

function RegisterHooks(scriptscope){ //basically listens for keypresses and calls hooks
	if(scriptscope != null){
		hookScripts.append(scriptscope)
		if(debugPrint){
			printl(PRINT_START + "Registered hooks")
		}
		return true
	}
	if(debugPrint){
		printl(PRINT_START + "Failed to register hooks (The scope is null)")
	}
	return false
}

function RegisterOnTick(scriptscope){
	if(scriptscope != null){
		tickScripts.append(scriptscope)
		if(debugPrint){
			printl(PRINT_START + "Registered OnTick")
		}
		return true
	}
	if(debugPrint){
		printl(PRINT_START + "Failed to register OnTick (The scope is null)")
	}
	return false
}

function RegisterTickFunction(func){
	tickFunctions.append(func)
	if(debugPrint){
		printl(PRINT_START + "Registered tick function")
	}
}

function RegisterEntityCreateListener(classname, scope){
	if(classname != null && scope != null){
		entityCreateListeners.append(EntityCreateListener(classname,scope))
		if(debugPrint){
			printl(PRINT_START + "Registered entity create listener on " + classname + " entities")
		}
		return true
	}
	if(debugPrint){
		printl(PRINT_START + "Failed to register an entity create listener for " + classname + " entities (Classname or scope is null)")
	}
	return false
}

function RegisterEntityMoveListener(ent,scope){
	if(ent != null && scope != null){
		entityMoveListeners.append(EntityMoveListener(ent,scope))
		if(debugPrint){
			printl(PRINT_START + "Registered entity move listener on " + ent)
		}
		return true
	} else {
		if(debugPrint){
			printl(PRINT_START + "Failed to register an entity move listener for " + ent + " (Entity or scope is null)")
		}
		return false
	}
}

function RegisterTimer(hudField, time, callFunction, countDown = true, formatTime = false){
	timers.append(Timer(hudField, time, callFunction, countDown, formatTime))
}

function StopTimer(hudField){
	for(local i=0; i < timers.len(); i++){
		if(timers[i].GetHudField() == hudField){
			timers.remove(i)
			return true
		}
	}
	return false
}

function ScheduleTask(func, args, time){ // can only check every 33 milliseconds so be careful
	local failed = "Failed to schedule a task "
	if(func != null && time != null){
		if(typeof(time) == "integer" || typeof(time) == "float"){
			if(time > 0){
				if(typeof(func) == "function"){
					tasks.append(Task(func, args, Time()+time))
					if(debugPrint){
						printl(PRINT_START + "Registered a task to execute at " + (Time()+time))
					}
					return true
				}
			} else {
				if(debugPrint){
					printl(PRINT_START + failed + "(Time cannot be less than or equal to zero)")
				}
				return false
			}
		} else {
			if(debugPrint){
				printl(PRINT_START + failed + "(Time has to be an integer or a float)")
			}
			return false
		}
	}
	if(debugPrint){
		printl(PRINT_START + failed + "(Function or time is null)")
	}
	return false
}

function RegisterChatCommand(command, func, isInputCommand = false){
	chatCommands.append(ChatCommand(command, func, isInputCommand))
	if(debugPrint){
		printl(PRINT_START + "Registered chat command (isInput=" + isInputCommand + ", command=" + command + ")")
	}
	return true
}

function RegisterConvarListener(convar, convarType, scope){
	convarListeners.append(ConvarListener(convar, convarType, scope))
	if(debugPrint){
		printl(PRINT_START + "Registered convar listener (convar=" + convar + ", convarType=" + convarType + ")")
	}
	return true
}

function RegisterBileExplodeListener(scope){
	bileExplodeListeners.append(BileExplodeListener(scope))
	if(debugPrint){
		printl(PRINT_START + "Registered a bile explode listener")
	}
	return true
}

function LockEntity(entity){
	lockedEntities.append(LockedEntity(entity, entity.GetAngles(), entity.GetOrigin))
	if(debugPrint){
		printl(PRINT_START + "Locked entity: " + entity)
	}
	return true
}

function UnlockEntity(entity){
	for(local i=0; i < lockedEntities.len(); i++){
		if(lockedEntities[i] == entity){
			lockedEntities.remove(i)
			return true
		}
	}
	return true
}


function OnGameEvent_tongue_grab(params){
	PlayerRestricted(params.victim)	
}
function OnGameEvent_choke_start(params){
	PlayerRestricted(params.victim)	
}
function OnGameEvent_lunge_pounce(params){
	PlayerRestricted(params.victim)	
}
function OnGameEvent_charger_carry_start(params){
	PlayerRestricted(params.victim)	
}
function OnGameEvent_charger_pummel_start(params){
	PlayerRestricted(params.victim)	
}
function OnGameEvent_jockey_ride(params){
	PlayerRestricted(params.victim)	
}

function OnGameEvent_tongue_release(params){
	if("victim" in params)
	{
		PlayerReleased(params.victim)
	}
}
function OnGameEvent_choke_end(params){
	if("victim" in params)
	{
		PlayerReleased(params.victim)
	}
}
function OnGameEvent_pounce_end(params){
	if("victim" in params)
	{
		PlayerReleased(params.victim)
	}
}
function OnGameEvent_pounce_stopped(params){
	if("victim" in params)
	{
		PlayerReleased(params.victim)
	}
}
function OnGameEvent_charger_carry_end(params){
	if("victim" in params)
	{
		PlayerReleased(params.victim)
	}
}
function OnGameEvent_charger_pummel_end(params){
	if("victim" in params)
	{
		PlayerReleased(params.victim)
	}
}
function OnGameEvent_jockey_ride_end(params){
	if("victim" in params)
	{
		PlayerReleased(params.victim)
	}
}
function PlayerRestricted(playerId){
	local player = FindPlayerObject(GetPlayerFromUserID(playerId))
	if(player != null){
		player.SetDisabled(true)
	}
}
function PlayerReleased(playerId){
	local player = FindPlayerObject(GetPlayerFromUserID(playerId))
	if(player != null){
		player.SetDisabled(false)
	}
}


local function IsCommand(msg,ent,command){
	local message = ""
	local found_start = false
	local found_end = false
	local last_char = 0
	foreach(char in msg){
		if(char != CHAR_SPACE && char != CHAR_NEWLINE){
			if(!found_start){
				found_start = true
			}
			message += char.tochar()
		} else if(char == CHAR_SPACE){
			if(last_char != CHAR_SPACE){
				found_end = true
			}
			if(found_start && !found_end){
				message += char.tochar()
			}
		}
	}
	return message == command
}

local function GetInputCommand(msg,ent,command){
	local message = ""
	local found_start = false
	local found_end = false
	local last_char = 0
	local index = 0
	foreach(char in msg){
		if(char != CHAR_SPACE && char != CHAR_NEWLINE){
			if(!found_start){
				found_start = true
			}
			message += char.tochar()
		} else if(char == CHAR_SPACE){
			if(last_char != CHAR_SPACE){
				found_end = true
				if(message != command || index == msg.len() - 1){
					return false
				}
				return msg.slice(index + 1, msg.len())
			}
			if(found_start && !found_end){
				message += char.tochar()
			}
		}
		index += 1
	}
	return false
}

function OnGameEvent_player_say(params){
	local text = params["text"]
	local ent = GetPlayerFromUserID(params["userid"])
	
	foreach(command in chatCommands){ 
		if(command.IsInputCommand()){
			local input = GetInputCommand(text, ent, command.GetCommand())
			if(input != false){
				command.CallFunction(ent, input)
			}
		} else {
			if(IsCommand(text, ent, command.GetCommand())){
				command.CallFunction(ent)
			}
		}
	}
}

__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener)