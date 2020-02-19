/* Ideas/TODO

	Fix weird stats on transition report screen (possible?)
	Stop callouts from other survivors about teammates being restricted?
	Remove infinite ammo from swapping weapons (low priority)
		restore ammo when picking up again?
		lastAmmo array for each type, have ammo variable in spawn for each player
	Increase SI damage/lethality
	
----Done----
	Upgraded ammo is lost when reloading
	Removed SI kill notifications on the HUD
	Adrenaline costs HP
	Pain Pills HP decays faster
	Medkit gives temp health + some permanent health
	Defibbed players have reduced health
	Give permanent health as a reward for reaching the saferoom
	Rocks are instadowns
	Punches cause some amount of damage
	Can pick up 0 magazines from ammo pile
*/

/* Changelog
	v1.2 - 27/10/19
		Crosshair is no longer disabled by default
		Fixed commons dying in one shot
	v1.1 - 26/10/19
		Fixed odd music, character selection bugs, and crashes related to survivors not technically being connected
		Fixed bots using too many medkits
		Fixed survivors being in permadeath after a chapter or campaign restarts
		Fixed survivors not being in permadeath if multiple died on the same chapter
		Adrenaline now gives 50 temp health, which is removed when the adrenaline wears off
*/

HookController <- {}
IncludeScript("HookController", HookController)
HookController.IncludeImprovedMethods()
HookController.RegisterHooks(this)

IncludeScript("response_testbed")

class TrueRealismPlayer {
	ent = null
	infected = false
	
	constructor(ent){
		this.ent = ent
	}
	
	function IsInfected(){
		return infected
	}
	
	function SetInfected(bool){
		infected = bool
	}
	
	function GetEntity(){
		return ent
	}
	
	function IsValid(){
		return ent != null && ent.IsValid()
	}
}

class TrueRealismGame {
	constructor(){
		LoadSettings()
	}
	
	function HasSetting(settingName){
		return settingName in settings
	}
	
	function SetSetting(settingName, value){
		if(HasSetting(settingName)){
			settings[settingName] = value
			return true
		} else {
			return false
		}
	}
	
	function GetSetting(settingName){
		if(HasSetting(settingName)){
			return settings[settingName]
		} else {
			return -1
		}
	}
	
	function GetSettings(){
		return settings
	}
	
	function SaveSettings(){
		local text = ""
		local settingsArray = []
		
		foreach(key,val in GetSettings()){
			settingsArray.append({key = key, val = val})
		}
		
		local function sortFunc(a,b){
			if(a["key"] > b["key"]){
				return 1
			} else if(a["key"] < b["key"]){
				return -1
			}
			return 0
		}
		settingsArray.sort(sortFunc)
		
		foreach(setting in settingsArray){
			text += setting["key"] + "=" + setting["val"] + "\n"
		}
		
		StringToFile("truerealism_settings.cfg", text)
	}

	function LoadSettings(){
		local text = FileToString("truerealism_settings.cfg")
		
		if(text == null){
			SaveSettings()
			return
		}
		
		local newText = ""
		
		foreach(char in text){
			if(char != 32){
				newText += char.tochar()
			}
		}
		
		local settingsFound = []
		
		while(newText.find("=")){
			local key = newText.slice(0, newText.find("="))
			if(key in GetSettings()){
				local value = -1
				if(newText.find("\n")){
					value = newText.slice(newText.find("=") + 1, newText.find("\n"))
					newText = newText.slice(newText.find("\n") + 1)
				} else {
					value = newText.slice(newText.find("=") + 1, newText.find("\0"))
					newText = newText.slice(newText.find("\0"))
				}
				SetSetting(key, value.tofloat())
				settingsFound.append(key)
			} else {
				if(newText.find("\n")){
					newText = newText.slice(newText.find("\n") + 1)
				} else {
					newText = newText.slice(newText.len())
				}
			}
		}
		
		local newSettings = []
		
		foreach(key,val in GetSettings()){
			local foundKey = false
			
			for(local j=0; j < settingsFound.len(); j++){
				if(key == settingsFound[j]){
					foundKey = true
				}
			}
			
			if(!foundKey){
				newSettings.append(key)
			}
		}
		
		if(newSettings.len() > 0){
			SaveSettings()
		}
	}
	
	settings = {
		ammo_pile_start_ammo = -1
		ammo_pile_randomize_ammo = -1
		ammo_pile_randomize_variance = -1
		ammo_pile_magazines = 16
		ammo_pile_magazines_taken = 2
		
		
		saferoom_reached_bonus_health = 15
		
		adrenaline_temp_health = 50
		
		rifle_magazine = 50
		rifle_ak47_magazine = 40
		rifle_desert_magazine = 60
		rifle_sg552_magazine = 50
		
		smg_magazine = 50
		smg_mp5_magazine = 50
		smg_silenced_magazine = 50
		
		shotgun_chrome_magazine = 8
		pumpshotgun_magazine = 8
		shotgun_spas_magazine = 10
		autoshotgun_magazine = 10
		
		hunting_rifle_magazine = 15
		sniper_awp_magazine = 20
		sniper_military_magazine = 30
		sniper_scout_magazine = 15
		
		
		rifle_magazines = 8
		rifle_ak47_magazines = 10
		rifle_desert_magazines = 7
		rifle_sg552_magazines = 8
		
		smg_magazines = 14
		smg_mp5_magazines = 14
		smg_silenced_magazines = 14
		
		shotgun_chrome_magazines = 8
		pumpshotgun_magazines = 8
		shotgun_spas_magazines = 10
		autoshotgun_magazines = 10
		
		hunting_rifle_magazines = 11
		sniper_awp_magazines = 10
		sniper_military_magazines = 7
		sniper_scout_magazines = 13
		
		
		shotgun_chrome_start_ammo = 48
		pumpshotgun_start_ammo = 48
		shotgun_spas_start_ammo = 70
		autoshotgun_start_ammo = 70
	}
}

DirectorOptions <- {
	MaxSpecials = 2
	TankLimit = 1
	WitchLimit = 1
}

local map = null
local resetDeaths = false

function GetQueryData(data){
	if(typeof(data) == "instance"){
		data.Input("SpeakResponseConcept", "GetQueryData")
		return
	}
	
	local query = {}
	foreach(var,val in data){
		query[var.tolower()] <- val
	}
	
	if(query.concept == "GetQueryData"){
		map = query.map
	}
}

TrueRealismResponseRules <- [{
	name = "SurvivorJockeyedOther",
	criteria = [["concept", "SurvivorJockeyedOther"]],
	responses = [{scenename = ""}],
	group_params = RGroupParams({permitrepeats = true, sequential = false, norepeat = false})
},
{
	name = "QueryData",
	criteria =
	[
		[ "concept", "GetQueryData" ],
		[ GetQueryData ],
	],
	responses =
	[
		{
			scenename = "",
		}
	],
	group_params = RGroupParams({ permitrepeats = true, sequential = false, norepeat = false })
},
{
	name = "chargerpound",
	criteria = [["concept", "chargerpound"]],
	responses = [{scenename = ""}],
	group_params = RGroupParams({permitrepeats = true, sequential = false, norepeat = false})
}]
Game <- TrueRealismGame()

local transitionStarted = false

local players = []
local deathTable = {
	Nick = 0
	Ellis = 0
	Rochelle = 0
	Coach = 0
	Bill = 0
	Zoey = 0
	Louis = 0
	Francis = 0
}


function GetCodeNameFromDisplayName(name){
	switch(name.tolower()){
		case "nick":{
			return "Gambler"
		}
		case "rochelle":{
			return "Producer"
		}
		case "coach":{
			return "Coach"
		}
		case "ellis":{
			return "Mechanic"
		}
		case "bill":{
			return "NamVet"
		}
		case "louis":{
			return "Manager"
		}
		case "zoey":{
			return "TeenGirl"
		}
		case "francis":{
			return "Biker"
		}
	}
}

function IsL4D1Survivor(name){
	return name.tolower() == "bill" || name.tolower() == "louis" || name.tolower() == "zoey" || name.tolower() == "francis"
}

function FindPlayerObject(ent){
	for(local i = 0; i < players.len(); i++){
		if(players[i].GetEntity() == ent){
			return players[i]
		}
	}
}

function SaveDeathTable(){
	SaveTable("deathTable", deathTable)
}

function RestoreDeathTable(){
	RestoreTable("deathTable", deathTable)
}

function GetPrimary(ent){
	local table = {}
	GetInvTable(ent, table)
	if("slot0" in table && table["slot0"] != null){
		return table["slot0"]
	}
}

function HasPrimary(ent){
	local table = {}
	GetInvTable(ent, table)
	return "slot0" in table && table["slot0"] != null
}

function CantLoseAmmo(classname){
	return classname == "weapon_shotgun_chrome" || classname == "weapon_shotgun_spas" || classname == "weapon_pumpshotgun" || classname == "weapon_autoshotgun" || classname == "weapon_pistol" || classname == "weapon_pistol_magnum" || classname == "weapon_grenade_launcher"
}

function InitializeAmmoPiles(){
	foreach(ammoPile in HookController.EntitiesByClassname("weapon_ammo_spawn")){
		ammoPile.ValidateScriptScope()
		ammoPile.GetScriptScope()["ammo"] <- Game.GetSetting("ammo_pile_magazines")
	}
}

function StopChargerSounds(ent){
	for(local i=1; i <= 5; i++){
		StopSoundOn("Player.Manager_TankPound0" + i, ent)
	}
	for(local i=1; i <= 4; i++){
		StopSoundOn("Player.Biker_TankPound0" + i, ent)
	}
	for(local i=1; i <= 5; i++){
		StopSoundOn("Player.TeenGirl_TankPound0" + i, ent)
	}
	for(local i=1; i <= 3; i++){
		StopSoundOn("Player.NamVet_TankPound0" + i, ent)
	}
	for(local i=1; i <= 8; i++){
		StopSoundOn("Gambler_GrabbedByCharger0" + i, ent)
	}
	for(local i=1; i <= 9; i++){
		StopSoundOn("Mechanic_GrabbedByCharger0" + i, ent)
	}
	for(local i=1; i <= 9; i++){
		StopSoundOn("Producer_GrabbedByCharger0" + i, ent)
	}
	for(local i=1; i <= 9; i++){
		StopSoundOn("Coach_GrabbedByCharger0" + i, ent)
	}
}

function StopLostCallSounds(ent){
	for(local i=1; i <= 20; i++){
		local num = i
		if(i < 10){
			num = "0" + i
		}
		StopSoundOn("Player.Manager_LostCall" + num, ent)
		StopSoundOn("Player.Biker_LostCall" + num, ent)
		StopSoundOn("Player.TeenGirl_LostCall" + num, ent)
		StopSoundOn("Player.NamVet_LostCall" + num, ent)
		StopSoundOn("Gambler_LostCall" + num, ent)
		StopSoundOn("Mechanic_LostCall" + num, ent)
		StopSoundOn("Producer_LostCall" + num, ent)
		StopSoundOn("Coach_LostCall" + num, ent)
	}
}

function GetScreamCount(name){
	switch(name.tolower()){
		case "nick":{
			return 5
		}
		case "rochelle":{
			return 4
		}
		case "ellis":{
			return 6
		}
		case "coach":{
			return 9
		}
		case "bill":{
			return 5
		}
		case "louis":{
			return 3
		}
		case "zoey":{
			return 4
		}
		case "francis":{
			return 6
		}
	}
}

function GetRandomScreamSound(name){
	local sound = null
	if(IsL4D1Survivor(name)){
		sound = "Player." + GetCodeNameFromDisplayName(name) + "_IncapacitatedInjury0" + RandomInt(1, GetScreamCount(name))
	} else {
		sound = GetCodeNameFromDisplayName(name) + "_IncapacitatedInjury0" + RandomInt(1, GetScreamCount(name))
	}
}

function GetRandomChokeSound(name){
	switch(name.tolower()){
		case "nick":{
			local sounds = [2, 5, 6, 7]
			return "Gambler_Choke0" + sounds[RandomInt(0, sounds.len() - 1)]
		}
		case "rochelle":{
			local sounds = [3, 4, 5, 6]
			return "Producer_Choke0" + sounds[RandomInt(0, sounds.len() - 1)]
		}
		case "ellis":{
			local sounds = [1, 4, 5, 6]
			return "Mechanic_Choke0" + sounds[RandomInt(0, sounds.len() - 1)]
		}
		case "coach":{
			local sounds = [1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13]
			local sound = sounds[RandomInt(0, sounds.len() - 1)]
			if(sound < 10){
				sound = "0" + sound
			}
			return "Coach_Choke" + sound
		}
		case "bill":{
			local sounds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
			local sound = sounds[RandomInt(0, sounds.len() - 1)]
			if(sound < 10){
				sound = "0" + sound
			}
			return "Player.NamVet_Choke" + sound
		}
		case "louis":{
			local sounds = [1, 2, 3, 4, 5, 6, 7, 8]
			return "Player.Manager_Choke0" + sounds[RandomInt(0, sounds.len() - 1)]
		}
		case "zoey":{
			local sounds = [1, 2, 3, 4, 5, 6, 7, 8, 9]
			return "Player.TeenGirl_Choke0" + sounds[RandomInt(0, sounds.len() - 1)]
		}
		case "francis":{
			local sounds = [1, 2, 3, 4, 5, 6, 7, 8, 9]
			return "Gambler_Choke0" + sounds[RandomInt(0, sounds.len() - 1)]
		}
	}
}

function OnTick(){
	foreach(weapon in HookController.EntitiesByClassname("weapon_*")){
		weapon.ValidateScriptScope()
		if(weapon.GetClassname().find("_spawn")){
			/*if(!("ammo" in weapon.GetScriptScope()) && Game.HasSetting(weapon.GetClassname().slice("weapon_".len(), weapon.GetClassname().find("_spawn")) + "_start_ammo")){
				weapon.GetScriptScope()["ammo"] <- Game.GetSetting(weapon.GetClassname().slice("weapon_".len(), weapon.GetClassname().find("_spawn")) + "_start_ammo")
			}*/
		} else {
			weapon.GetScriptScope()["lastClip"] <- weapon.GetClip()
		}
	}
	foreach(survivor in HookController.PlayerGenerator()){
		if(survivor.IsSurvivor()){
			GetQueryData(survivor)
			
			local host_map = Convars.GetStr("host_map").slice(0, Convars.GetStr("host_map").find(".bsp"))
			if(!resetDeaths && map == host_map){ // new map
				foreach(key, val in deathTable){
					deathTable[key] = 0
					SaveDeathTable()
					resetDeaths = true
				}
			}
			
			survivor.SetProp("m_Local.m_iHideHUD", 64)
			
			local playerManager = Entities.FindByClassname(null, "terror_player_manager")
			playerManager.SetProp("m_iHealth", 0, survivor.GetEntityIndex())
			playerManager.SetProp("m_maxHealth", 99999999, survivor.GetEntityIndex())
			playerManager.SetProp("m_grenade", 0, survivor.GetEntityIndex())
			playerManager.SetProp("m_firstAidSlot", 0, survivor.GetEntityIndex())
			playerManager.SetProp("m_pillsSlot", 0, survivor.GetEntityIndex())
			
			survivor.ValidateScriptScope()
			if(survivor.GetChargeAttacker() != null){
				
			}
			if(survivor.GetLifeState() == 0){ // alive
				if(deathTable[GetCharacterDisplayName(survivor)] == 2 && !playerManager.GetInIntro()){
					local prevOrigin = survivor.GetOrigin()
					survivor.SetOrigin(Vector(32000, 32000, 32000))
					survivor.SetReviveCount(99999)
					survivor.TakeDamage(99999, 0, null)
					Entities.FindByClassnameNearest("survivor_death_model", survivor.GetOrigin(), 64).Kill()
					survivor.SetOrigin(prevOrigin)
				}
			}
			if(survivor.GetLifeState() == 1 && deathTable[GetCharacterDisplayName(survivor)] == 2 && Time() < 3){
				StopLostCallSounds(survivor)
				survivor.StopSound("Event.SurvivorDeathHit")
				survivor.StopSound("Event.SurvivorDeath")
			}
			//HookController.SendCommandToClient(survivor, "crosshair 0")
			local player = FindPlayerObject(survivor)
			if(player != null){
				
			} else {
				players.append(TrueRealismPlayer(survivor))
			}
			if(HasPrimary(survivor)){
				survivor.GetScriptScope()["lastAmmo"] <- survivor.GetAmmo(GetPrimary(survivor))
				survivor.GetScriptScope()["lastPrimary"] <- GetPrimary(survivor)
			}
		}
	}
	for(local i = 0; i < players.len(); i++){ // Removes invalid players
		if(!players[i].IsValid()){
			players.remove(i)
			i--
		}
	}
}

function OnGameEvent_weapon_pickup(params){
	
}

function OnGameEvent_player_use(params){
	/*
		set spawn ammo when player uses spawn with same weapon
		get spawn ammo and set player ammo when player uses spawn with any weapon
		anytime a player uses a weapon spawn the same as their current weapon, set their ammo to the last ammo they had when they used the same spawn
		
	*/
	
	/*local user = GetPlayerFromUserID(params.userid)
	local target = EntIndexToHScript(params.targetid)
	
	if(target.GetClassname().find("_spawn") == null || user.GetScriptScope()["lastPrimary"].GetClassname() != target.GetClassname().slice(0, target.GetClassname().find("_spawn"))){
		return
	}
	
	target.ValidateScriptScope()
	
	if(!("player_ammo" in target.GetScriptScope())){
		target.GetScriptScope()["player_ammo"] <- array(16, -1)
		return
	}
	if("lastAmmo" in user.GetScriptScope()){
		user.SetAmmo(user.GetActiveWeapon(), user.GetScriptScope()["lastAmmo"])
	}
	
	
	printl(user)
	printl(target)
	printl(user.GetActiveWeapon())*/
}

function OnGameEvent_adrenaline_used(params){
	local ent = GetPlayerFromUserID(params.userid)
	
	local newHealth = ent.GetHealthBuffer() + Game.GetSetting("adrenaline_temp_health")
	if(newHealth + ent.GetHealth() > 100){
		newHealth = 100 - ent.GetHealth()
	}
	ent.SetHealthBuffer(newHealth)
	HookController.ScheduleTask(function(){ent.SetHealthBuffer(ent.GetHealthBuffer() - health)}, Convars.GetFloat("adrenaline_duration"), {ent = ent, health = newHealth})
}

function OnGameEvent_heal_success(params){
	local subject = GetPlayerFromUserID(params.subject)
	local health = params.health_restored
	
	if(!subject.IsBot()){
		subject.SetHealth(subject.GetHealth() - health/2)
		subject.SetHealthBuffer(subject.GetHealthBuffer() + health/2)
	}
}

function OnGameEvent_mission_lost(params){
	foreach(key, val in deathTable){
		if(val == 1){
			deathTable[key] = 0
			SaveDeathTable()
		}
	}
}

function OnGameEvent_map_transition(params){
	foreach(survivor in HookController.PlayerGenerator()){
		if(survivor.IsSurvivor() && !survivor.IsDead()){
			local newHealth = survivor.GetHealth() + Game.GetSetting("saferoom_reached_bonus_health")
			if(newHealth > 100){
				newHealth = 100
			}
			survivor.SetHealth(newHealth)
		}
	}
	foreach(key, val in deathTable){
		if(val == 1){
			deathTable[key] = 2
			SaveDeathTable()
		}
	}
	SaveDeathTable()
}

function OnGameEvent_ammo_pickup(params){
	local ent = GetPlayerFromUserID(params.userid)
	local ammoPile = Entities.FindByClassnameNearest("weapon_ammo_spawn", ent.EyePosition(), 128)
	ent.ValidateScriptScope()
	ammoPile.ValidateScriptScope()
	local lastAmmo = ent.GetScriptScope()["lastAmmo"]
	local primary = GetPrimary(ent)
	local ammo = Game.GetSetting("ammo_pile_magazines_taken")
	
	if(ammoPile.GetScriptScope()["ammo"] <= ammo){
		ammo = ammoPile.GetScriptScope()["ammo"]
		ammoPile.Kill()
	} else {
		ammoPile.GetScriptScope()["ammo"] = ammoPile.GetScriptScope()["ammo"] - ammo
	}
	ent.SetAmmo(primary, lastAmmo + (ammo * Game.GetSetting(primary.GetClassname().slice("weapon_".len()) + "_magazine")))
	printl(ent + " picked up " + ammo + " magazines")
}

function OnGameEvent_player_disconnect(params){
	local ent = GetPlayerFromUserID(params.userid)
	//HookController.SendCommandToClient(ent, "crosshair 1")
}

function OnGameEvent_weapon_reload(params){
	local ent = GetPlayerFromUserID(params.userid)
	local weapon = ent.GetActiveWeapon()
	if(CantLoseAmmo(weapon.GetClassname())){
		return
	}
	weapon.ValidateScriptScope()
	local clip = weapon.GetScriptScope()["lastClip"]
	if(weapon.GetUpgradedAmmoLoaded() > 0){
		HookController.DoNextTick(function(){
			weapon.SetUpgradedAmmoLoaded(0)
			weapon.SetUpgrades(weapon.GetUpgrades() & ~3)
		})
	} else {
		HookController.DoNextTick(function(){ent.SetAmmo(weapon, ent.GetAmmo(weapon) - clip)})
	}
	printl(ent + " reloaded and lost " + clip + " ammo")
}

function OnGameEvent_player_death(params){
	if(!("userid" in params)){
		return
	}
	
	local ent = GetPlayerFromUserID(params.userid)
	
	if(ent.IsSurvivor() && deathTable[GetCharacterDisplayName(ent)] == 0){
		deathTable[GetCharacterDisplayName(ent)] = 1
		SaveDeathTable()
	}
}

function OnGameEvent_defibrillator_used(params){
	local ent = GetPlayerFromUserID(params.subject)
	
	deathTable[GetCharacterDisplayName(ent)] = 0
	SaveDeathTable()
}

function AllowTakeDamage(params){
	local attacker = params.Attacker
	local victim = params.Victim
	local damageDone = params.DamageDone
	local damageType = params.DamageType
	local weapon = params.Weapon
	
	if(attacker != null && victim != null && attacker.GetClassname() == "player" && victim.GetClassname() == "player" && attacker.GetZombieType() == HookController.ZombieTypes.TANK && victim.IsSurvivor()){
		local rock = Entities.FindByClassnameNearest("tank_rock", victim.GetOrigin(), 128)
		if(rock == null){ // not hit by a rock
			//params["DamageDone"] = 50
		} else { // hit by a rock
			if(rock.GetPropEntity("m_hThrower") == attacker){
				params["DamageDone"] = 100
			}
		}
	}
	
	if(attacker != null && victim != null && attacker.GetClassname() == "player" && victim.GetClassname() == "player" && attacker.GetZombieType() == HookController.ZombieTypes.CHARGER && victim.IsSurvivor() && victim.GetChargeAttacker() == attacker){
		//EmitSoundOn(GetRandomScreamSound(victim.GetCharacterName()), victim)
	}
	
	if(attacker != null && victim != null && attacker.GetClassname() == "player" && victim.GetClassname() == "player" && attacker.GetZombieType() == HookController.ZombieTypes.SMOKER && victim.IsSurvivor() && victim.GetTongueAttacker() == attacker){
		if(RandomInt(0, 100) > 50){
			EmitSoundOn(GetRandomChokeSound(victim.GetCharacterName()), victim)
		}
	}
	
	if(attacker != null && victim != null && attacker.GetClassname() == "player" && victim.GetClassname() == "player" && attacker.GetZombieType() == HookController.ZombieTypes.HUNTER && victim.IsSurvivor() && victim.GetPounceAttacker() == attacker){
		victim.ValidateScriptScope()
		local sound = null
		if(IsL4D1Survivor(victim.GetCharacterName())){
			sound = "Player." + GetCodeNameFromDisplayName(victim.GetCharacterName()) + "_DeathScream0" + RandomInt(1, GetScreamCount(victim.GetCharacterName()))
		} else {
			sound = GetCodeNameFromDisplayName(victim.GetCharacterName()) + "_DeathScream0" + RandomInt(1, GetScreamCount(victim.GetCharacterName()))
		}
		if(!("screamTimestamp" in victim.GetScriptScope())){
			victim.GetScriptScope()["screamTimestamp"] <- Time()
			victim.GetScriptScope()["screamDuration"] <- RandomFloat(3, 5)
		} else if(Time() > victim.GetScriptScope()["screamTimestamp"] + victim.GetScriptScope()["screamDuration"]){
			victim.GetScriptScope()["screamTimestamp"] <- Time()
			victim.GetScriptScope()["screamDuration"] <- RandomFloat(3, 5)
			EmitSoundOn("Player.StopVoice", victim)
			EmitSoundOn(sound, victim)
		}
	}
	
	if(attacker != null && victim != null && attacker.GetClassname() == "infected" && victim.GetClassname() == "player" && victim.IsSurvivor()){
		if(RandomInt(0, 99) < 30){
			FindPlayerObject(victim).SetInfected(true)
		}
	}
	
	return true
}

function OnGameplayStart(){
	rr_ProcessRules(TrueRealismResponseRules)
	InitializeAmmoPiles()
	HookController.KillByClassname("info_survivor_rescue")
	RestoreDeathTable()
	local introCheck = function(){
		if(Entities.FindByClassname(null, "terror_gamerules").GetInIntro()){
			foreach(key,val in deathTable){
				deathTable[key] = 0
			}
			g_ModeScript.SaveDeathTable()
		}
	}
	HookController.DoNextTick(introCheck)
}