CBaseEntity["HasProp"] <- function(propertyName){return NetProps.HasProp(this, propertyName)}
CBaseEntity["GetPropType"] <- function(propertyName){return NetProps.GetPropType(this, propertyName)}
CBaseEntity["GetPropArraySize"] <- function(propertyName){return NetProps.GetPropArraySize(this, propertyName)}

CBaseEntity["GetPropInt"] <- function(propertyName){return NetProps.GetPropInt(this, propertyName)}
CBaseEntity["GetPropEntity"] <- function(propertyName){return NetProps.GetPropEntity(this, propertyName)}
CBaseEntity["GetPropString"] <- function(propertyName){return NetProps.GetPropString(this, propertyName)}
CBaseEntity["GetPropFloat"] <- function(propertyName){return NetProps.GetPropFloat(this, propertyName)}
CBaseEntity["GetPropVector"] <- function(propertyName){return NetProps.GetPropVector(this, propertyName)}
CBaseEntity["SetPropInt"] <- function(propertyName, value){return NetProps.SetPropInt(this, propertyName, value)}
CBaseEntity["SetPropEntity"] <- function(propertyName, value){return NetProps.SetPropEntity(this, propertyName, value)}
CBaseEntity["SetPropString"] <- function(propertyName, value){return NetProps.SetPropString(this, propertyName, value)}
CBaseEntity["SetPropFloat"] <- function(propertyName, value){return NetProps.SetPropFloat(this, propertyName, value)}
CBaseEntity["SetPropVector"] <- function(propertyName, value){return NetProps.SetPropVector(this, propertyName, value)}

CBaseEntity["GetPropIntArray"] <- function(propertyName, index){return NetProps.GetPropIntArray(this, propertyName, index)}
CBaseEntity["GetPropEntityArray"] <- function(propertyName, index){return NetProps.GetPropEntityArray(this, propertyName, index)}
CBaseEntity["GetPropStringArray"] <- function(propertyName, index){return NetProps.GetPropStringArray(this, propertyName, index)}
CBaseEntity["GetPropFloatArray"] <- function(propertyName, index){return NetProps.GetPropFloatArray(this, propertyName, index)}
CBaseEntity["GetPropVectorArray"] <- function(propertyName, index){return NetProps.GetPropVectorArray(this, propertyName, index)}
CBaseEntity["SetPropIntArray"] <- function(propertyName, index, value){return NetProps.SetPropIntArray(this, propertyName, value, index)}
CBaseEntity["SetPropEntityArray"] <- function(propertyName, index, value){return NetProps.SetPropEntityArray(this, propertyName, value, index)}
CBaseEntity["SetPropStringArray"] <- function(propertyName, index, value){return NetProps.SetPropStringArray(this, propertyName, value, index)}
CBaseEntity["SetPropFloatArray"] <- function(propertyName, index, value){return NetProps.SetPropFloatArray(this, propertyName, value, index)}
CBaseEntity["SetPropVectorArray"] <- function(propertyName, index, value){return NetProps.SetPropVectorArray(this, propertyName, value, index)}


CBaseEntity["GetModelIndex"] <- function(){return this.GetPropInt("m_nModelIndex")}
CBaseEntity["GetModelName"] <- function(){return this.GetPropString("m_ModelName")}
CBaseEntity["SetName"] <- function(name){this.SetPropString("m_iName", name)}

CBaseEntity["GetFriction"] <- function(){return GetFriction(this)}
CBaseEntity["GetPhysVelocity"] <- function(){return GetPhysVelocity(this)}

CBaseEntity["GetFlags"] <- function(){return this.GetPropInt("m_fFlags")}
CBaseEntity["SetFlags"] <- function(flag){this.SetPropInt("m_fFlags", flag)}
CBaseEntity["AddFlag"] <- function(flag){this.SetPropInt("m_fFlags", this.GetPropInt("m_fFlags") | flag)}
CBaseEntity["RemoveFlag"] <- function(flag){this.SetPropInt("m_fFlags", this.GetPropInt("m_fFlags") & ~flag)}

CBaseEntity["GetMoveType"] <- function(){return this.GetPropInt("movetype")}
CBaseEntity["SetMoveType"] <- function(type){this.SetPropInt("movetype", type)}

CBaseEntity["GetSpawnflags"] <- function(){return this.GetPropInt("m_spawnflags")}
CBaseEntity["SetSpawnFlags"] <- function(flags){this.SetPropInt("m_spawnflags", flags)}

CBaseEntity["GetGlowType"] <- function(){return this.GetPropInt("m_Glow.m_iGlowType")}
CBaseEntity["SetGlowType"] <- function(type){this.SetPropInt("m_Glow.m_iGlowType", type)}

CBaseEntity["GetGlowRange"] <- function(){return this.GetPropInt("m_Glow.m_nGlowRange")}
CBaseEntity["SetGlowRange"] <- function(range){this.SetPropInt("m_Glow.m_nGlowRange", range)}

CBaseEntity["GetGlowRangeMin"] <- function(){return this.GetPropInt("m_Glow.m_nGlowRangeMin")}
CBaseEntity["SetGlowRangeMin"] <- function(range){this.SetPropInt("m_Glow.m_nGlowRangeMin", range)}

CBaseEntity["GetGlowColor"] <- function(){return this.GetPropInt("m_Glow.m_glowColorOverride")}
CBaseEntity["SetGlowColor"] <- function(r, g, b){
	local color = r
	color += 256 * g
	color += 65536 * b
	this.SetPropInt("m_Glow.m_glowColorOverride", color)
}
CBaseEntity["SetGlowColorVector"] <- function(vector){
	local color = vector.x
	color += 256 * vector.y
	color += 65536 * vector.z
	this.SetPropInt("m_Glow.m_glowColorOverride", color)
}
CBaseEntity["ResetGlowColor"] <- function(){this.SetPropInt("m_Glow.m_glowColorOverride", -1)}

CBaseEntity["GetTeam"] <- function(){return this.GetPropInt("m_iTeamNum")}

CBaseEntity["GetGlowFlashing"] <- function(){return this.GetPropInt("m_Glow.m_bFlashing")}
CBaseEntity["SetGlowFlashing"] <- function(flashing){this.SetPropInt("m_Glow.m_bFlashing", flashing)}

CBaseEntity["PlaySound"] <- function(soundName){EmitSoundOn(soundName, this)}
CBaseEntity["StopSound"] <- function(soundName){StopSoundOn(soundName, this)}

CBaseEntity["Input"] <- function(input, value = "", delay = 0, activator = null){DoEntFire("!self", input.tostring(), value.tostring(), delay.tofloat(), activator, this)}
CBaseEntity["SetAlpha"] <- function(alpha){Input("Alpha", alpha)}
CBaseEntity["GetValidatedScriptScope"] <- function(){
	this.ValidateScriptScope()
	return this.GetScriptScope()
}


CBaseAnimating["PlaySound"] <- function(soundName){EmitSoundOn(soundName, this)}
CBaseAnimating["StopSound"] <- function(soundName){StopSoundOn(soundName, this)}

CBaseAnimating["GetFlags"] <- function(){return this.GetPropInt("m_fFlags")}
CBaseAnimating["SetFlags"] <- function(flag){this.SetPropInt("m_fFlags", flag)}
CBaseAnimating["AddFlag"] <- function(flag){this.SetPropInt("m_fFlags", this.GetPropInt("m_fFlags") | flag)}
CBaseAnimating["RemoveFlag"] <- function(flag){this.SetPropInt("m_fFlags", this.GetPropInt("m_fFlags") & ~flag)}

CBaseAnimating["GetSpawnflags"] <- function(){return this.GetPropInt("m_spawnflags")}
CBaseAnimating["SetSpawnFlags"] <- function(flags){this.SetPropInt("m_spawnflags", flags)}

CBaseAnimating["GetGlowType"] <- function(){return this.GetPropInt("m_Glow.m_iGlowType")}
CBaseAnimating["SetGlowType"] <- function(type){this.SetPropInt("m_Glow.m_iGlowType", type)}

CBaseAnimating["GetGlowRange"] <- function(){return this.GetPropInt("m_Glow.m_nGlowRange")}
CBaseAnimating["SetGlowRange"] <- function(range){this.SetPropInt("m_Glow.m_nGlowRange", range)}

CBaseAnimating["GetGlowRangeMin"] <- function(){return this.GetPropInt("m_Glow.m_nGlowRangeMin")}
CBaseAnimating["SetGlowRangeMin"] <- function(range){this.SetPropInt("m_Glow.m_nGlowRangeMin", range)}

CBaseAnimating["GetGlowColor"] <- function(){return this.GetPropInt("m_Glow.m_glowColorOverride")}
CBaseAnimating["SetGlowColor"] <- function(r, g, b){
	local color = r
	color += 256 * g
	color += 65536 * b
	this.SetPropInt("m_Glow.m_glowColorOverride", color)
}
CBaseAnimating["SetGlowColorVector"] <- function(vector){
	local color = vector.x
	color += 256 * vector.y
	color += 65536 * vector.z
	this.SetPropInt("m_Glow.m_glowColorOverride", color)
}
CBaseAnimating["ResetGlowColor"] <- function(){this.SetPropInt("m_Glow.m_glowColorOverride", -1)}

CBaseAnimating["GetSequence"] <- function(){return this.GetPropInt("m_nSequence")}
CBaseAnimating["GetValidatedScriptScope"] <- function(){
	this.ValidateScriptScope()
	return this.GetScriptScope()
}

CBaseAnimating["Input"] <- function(input, value = "", delay = 0, activator = null){DoEntFire("!self", input.tostring(), value.tostring(), delay.tofloat(), activator, this)}

CBaseAnimating["GetMoveType"] <- function(){return this.GetPropInt("movetype")}
CBaseAnimating["SetMoveType"] <- function(type){this.SetPropInt("movetype", type)}

CBaseAnimating["GetModelIndex"] <- function(){return this.GetPropInt("m_nModelIndex")}
CBaseAnimating["GetModelName"] <- function(){return this.GetPropString("m_ModelName")}
CBaseAnimating["SetName"] <- function(name){this.SetPropString("m_iName", name)}

CBaseAnimating["HasProp"] <- function(propertyName){return NetProps.HasProp(this, propertyName)}
CBaseAnimating["GetPropType"] <- function(propertyName){return NetProps.GetPropType(this, propertyName)}
CBaseAnimating["GetPropArraySize"] <- function(propertyName){return NetProps.GetPropArraySize(this, propertyName)}

CBaseAnimating["GetPropInt"] <- function(propertyName){return NetProps.GetPropInt(this, propertyName)}
CBaseAnimating["GetPropEntity"] <- function(propertyName){return NetProps.GetPropEntity(this, propertyName)}
CBaseAnimating["GetPropString"] <- function(propertyName){return NetProps.GetPropString(this, propertyName)}
CBaseAnimating["GetPropFloat"] <- function(propertyName){return NetProps.GetPropFloat(this, propertyName)}
CBaseAnimating["GetPropVector"] <- function(propertyName){return NetProps.GetPropVector(this, propertyName)}
CBaseAnimating["SetPropInt"] <- function(propertyName, value){return NetProps.SetPropInt(this, propertyName, value)}
CBaseAnimating["SetPropEntity"] <- function(propertyName, value){return NetProps.SetPropEntity(this, propertyName, value)}
CBaseAnimating["SetPropString"] <- function(propertyName, value){return NetProps.SetPropString(this, propertyName, value)}
CBaseAnimating["SetPropFloat"] <- function(propertyName, value){return NetProps.SetPropFloat(this, propertyName, value)}
CBaseAnimating["SetPropVector"] <- function(propertyName, value){return NetProps.SetPropVector(this, propertyName, value)}

CBaseAnimating["GetPropIntArray"] <- function(propertyName, index){return NetProps.GetPropIntArray(this, propertyName, index)}
CBaseAnimating["GetPropEntityArray"] <- function(propertyName, index){return NetProps.GetPropEntityArray(this, propertyName, index)}
CBaseAnimating["GetPropStringArray"] <- function(propertyName, index){return NetProps.GetPropStringArray(this, propertyName, index)}
CBaseAnimating["GetPropFloatArray"] <- function(propertyName, index){return NetProps.GetPropFloatArray(this, propertyName, index)}
CBaseAnimating["GetPropVectorArray"] <- function(propertyName, index){return NetProps.GetPropVectorArray(this, propertyName, index)}
CBaseAnimating["SetPropIntArray"] <- function(propertyName, index, value){return NetProps.SetPropIntArray(this, propertyName, value, index)}
CBaseAnimating["SetPropEntityArray"] <- function(propertyName, index, value){return NetProps.SetPropEntityArray(this, propertyName, value, index)}
CBaseAnimating["SetPropStringArray"] <- function(propertyName, index, value){return NetProps.SetPropStringArray(this, propertyName, value, index)}
CBaseAnimating["SetPropFloatArray"] <- function(propertyName, index, value){return NetProps.SetPropFloatArray(this, propertyName, value, index)}
CBaseAnimating["SetPropVectorArray"] <- function(propertyName, index, value){return NetProps.SetPropVectorArray(this, propertyName, value, index)}

CBaseAnimating["SetClip"] <- function(clip){this.SetPropInt("m_iClip1", clip)}
CBaseAnimating["GetClip"] <- function(){return this.GetPropInt("m_iClip1")}
CBaseAnimating["SetReserveAmmo"] <- function(ammo){this.SetPropInt("m_iExtraPrimaryAmmo", ammo)}
CBaseAnimating["GetReserveAmmo"] <- function(){return this.GetPropInt("m_iExtraPrimaryAmmo")}



CTerrorPlayer["Input"] <- function(input, value = "", delay = 0, activator = null){DoEntFire("!self", input.tostring(), value.tostring(), delay.tofloat(), activator, this)}

CTerrorPlayer["GetValidatedScriptScope"] <- function(){
	this.ValidateScriptScope()
	return this.GetScriptScope()
}

CTerrorPlayer["GetMoveType"] <- function(){return this.GetPropInt("movetype")}
CTerrorPlayer["SetMoveType"] <- function(type){this.SetPropInt("movetype", type)}

CTerrorPlayer["GetFlags"] <- function(){return this.GetPropInt("m_fFlags")}
CTerrorPlayer["SetFlags"] <- function(flag){this.SetPropInt("m_fFlags", flag)}
CTerrorPlayer["AddFlag"] <- function(flag){this.SetPropInt("m_fFlags", this.GetPropInt("m_fFlags") | flag)}
CTerrorPlayer["RemoveFlag"] <- function(flag){this.SetPropInt("m_fFlags", this.GetPropInt("m_fFlags") & ~flag)}

CTerrorPlayer["GetGlowType"] <- function(){return this.GetPropInt("m_Glow.m_iGlowType")}
CTerrorPlayer["SetGlowType"] <- function(type){this.SetPropInt("m_Glow.m_iGlowType", type)}

CTerrorPlayer["GetGlowRange"] <- function(){return this.GetPropInt("m_Glow.m_nGlowRange")}
CTerrorPlayer["SetGlowRange"] <- function(range){this.SetPropInt("m_Glow.m_nGlowRange", range)}

CTerrorPlayer["GetGlowRangeMin"] <- function(){return this.GetPropInt("m_Glow.m_nGlowRangeMin")}
CTerrorPlayer["SetGlowRangeMin"] <- function(range){this.SetPropInt("m_Glow.m_nGlowRangeMin", range)}

CTerrorPlayer["GetGlowColor"] <- function(){return this.GetPropInt("m_Glow.m_glowColorOverride")}
CTerrorPlayer["SetGlowColor"] <- function(r, g, b){
	local color = r
	color += 256 * g
	color += 65536 * b
	this.SetPropInt("m_Glow.m_glowColorOverride", color)
}
CTerrorPlayer["SetGlowColorVector"] <- function(vector){
	local color = vector.x
	color += 256 * vector.y
	color += 65536 * vector.z
	this.SetPropInt("m_Glow.m_glowColorOverride", color)
}
CTerrorPlayer["ResetGlowColor"] <- function(){this.SetPropInt("m_Glow.m_glowColorOverride", -1)}

CTerrorPlayer["GetModelIndex"] <- function(){return this.GetPropInt("m_nModelIndex")}
CTerrorPlayer["GetModelName"] <- function(){return this.GetPropString("m_ModelName")}
CTerrorPlayer["SetName"] <- function(name){this.SetPropString("m_iName", name)}

CTerrorPlayer["HasProp"] <- function(propertyName){return NetProps.HasProp(this, propertyName)}
CTerrorPlayer["GetPropType"] <- function(propertyName){return NetProps.GetPropType(this, propertyName)}
CTerrorPlayer["GetPropArraySize"] <- function(propertyName){return NetProps.GetPropArraySize(this, propertyName)}

CTerrorPlayer["GetPropInt"] <- function(propertyName){return NetProps.GetPropInt(this, propertyName)}
CTerrorPlayer["GetPropEntity"] <- function(propertyName){return NetProps.GetPropEntity(this, propertyName)}
CTerrorPlayer["GetPropString"] <- function(propertyName){return NetProps.GetPropString(this, propertyName)}
CTerrorPlayer["GetPropFloat"] <- function(propertyName){return NetProps.GetPropFloat(this, propertyName)}
CTerrorPlayer["GetPropVector"] <- function(propertyName){return NetProps.GetPropVector(this, propertyName)}
CTerrorPlayer["SetPropInt"] <- function(propertyName, value){return NetProps.SetPropInt(this, propertyName, value)}
CTerrorPlayer["SetPropEntity"] <- function(propertyName, value){return NetProps.SetPropEntity(this, propertyName, value)}
CTerrorPlayer["SetPropString"] <- function(propertyName, value){return NetProps.SetPropString(this, propertyName, value)}
CTerrorPlayer["SetPropFloat"] <- function(propertyName, value){return NetProps.SetPropFloat(this, propertyName, value)}
CTerrorPlayer["SetPropVector"] <- function(propertyName, value){return NetProps.SetPropVector(this, propertyName, value)}

CTerrorPlayer["GetPropIntArray"] <- function(propertyName, index){return NetProps.GetPropIntArray(this, propertyName, index)}
CTerrorPlayer["GetPropEntityArray"] <- function(propertyName, index){return NetProps.GetPropEntityArray(this, propertyName, index)}
CTerrorPlayer["GetPropStringArray"] <- function(propertyName, index){return NetProps.GetPropStringArray(this, propertyName, index)}
CTerrorPlayer["GetPropFloatArray"] <- function(propertyName, index){return NetProps.GetPropFloatArray(this, propertyName, index)}
CTerrorPlayer["GetPropVectorArray"] <- function(propertyName, index){return NetProps.GetPropVectorArray(this, propertyName, index)}
CTerrorPlayer["SetPropIntArray"] <- function(propertyName, index, value){return NetProps.SetPropIntArray(this, propertyName, value, index)}
CTerrorPlayer["SetPropEntityArray"] <- function(propertyName, index, value){return NetProps.SetPropEntityArray(this, propertyName, value, index)}
CTerrorPlayer["SetPropStringArray"] <- function(propertyName, index, value){return NetProps.SetPropStringArray(this, propertyName, value, index)}
CTerrorPlayer["SetPropFloatArray"] <- function(propertyName, index, value){return NetProps.SetPropFloatArray(this, propertyName, value, index)}
CTerrorPlayer["SetPropVectorArray"] <- function(propertyName, index, value){return NetProps.SetPropVectorArray(this, propertyName, value, index)}

CTerrorPlayer["GetCurrentFlowDistance"] <- function(){return GetCurrentFlowDistanceForPlayer(this)}
CTerrorPlayer["GetCurrentFlowPercent"] <- function(){return GetCurrentFlowPercentForPlayer(this)}
CTerrorPlayer["GetCharacterName"] <- function(){return GetCharacterDisplayName(this)}
CTerrorPlayer["Say"] <- function(message, teamOnly = false){::Say(this, message, teamOnly)}
CTerrorPlayer["IsBot"] <- function(){return IsPlayerABot(this)}
CTerrorPlayer["PickupObject"] <- function(entity){PickupObject(this, entity)}
CTerrorPlayer["SetAngles"] <- function(angles){
	local prevPlayerName = this.GetName()
	local playerName = UniqueString()
	this.SetName(playerName)
	local teleportEntity = SpawnEntityFromTable("point_teleport", {origin = this.GetOrigin(), angles = angles.ToKVString(), target = playerName, targetname = UniqueString()})
	DoEntFire("!self", "Teleport", "", 0, null, teleportEntity)
	DoEntFire("!self", "Kill", "", 0, null, teleportEntity)
	DoEntFire("!self", "AddOutput", "targetname " + prevPlayerName, 0.01, null, this)
}
CTerrorPlayer["GetLifeState"] <- function(){return this.GetPropInt("m_lifeState")}
CTerrorPlayer["PlaySound"] <- function(soundName){EmitSoundOn(soundName, this)}
CTerrorPlayer["StopSound"] <- function(soundName){StopSoundOn(soundName, this)}
CTerrorPlayer["PlaySoundOnClient"] <- function(soundName){EmitSoundOnClient(soundName, this)}
CTerrorPlayer["GetAmmo"] <- function(weapon){return this.GetPropIntArray("m_iAmmo", weapon.GetPropInt("m_iPrimaryAmmoType"))}
CTerrorPlayer["SetAmmo"] <- function(weapon, ammo){this.SetPropIntArray("m_iAmmo", weapon.GetPropInt("m_iPrimaryAmmoType"), ammo)}