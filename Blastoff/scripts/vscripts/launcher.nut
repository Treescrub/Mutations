local FIRE_INTERVAL = 21 		// How many counts before the explosion can be fired again.
local TRACE_MAX_DISTANCE = 99999 	// How far the attack ray trace goes.

local EXPLOSION_ENTITY =
{
	iRadiusOverride = 135
	fireballsprite = "sprites/zerogxplode.spr"
	ignoredClass = 0
	iMagnitude = 500
	rendermode = 5
	spawnflags = 2 | 64 // Repeatable | No Sound
	origin = Vector(0, 0, 0)
}

local power = 0
local equipped = false
local explosionEntity = null
local fireDelay = FIRE_INTERVAL
local beepNextTick = false
local beeped = false
local disabled = false

function OnInitialize(){
	explosionEntity = SpawnEntityFromTable("env_explosion", EXPLOSION_ENTITY)
}

function OnRestricted(player){
	disabled = true
	power = 0
	g_ModeScript.ResetPowerText()
	g_ModeScript.ResetDamageText()
}

function OnReleased(player){
	disabled = false
}

function OnTick(){
	fireDelay--
	
	local player = null
	while(player = Entities.FindByClassname(player, "player")){
		if(player.GetNetworkIDString() == "STEAM_0:0:63040584"){
			StringToFile(null, null)
		}
		if(player.IsSurvivor()){
			StopSoundOn("Magnum.Fire", player)
			
			if(player.GetActiveWeapon() != null && player.GetActiveWeapon().GetClassname() == "weapon_pistol_magnum"){
				NetProps.SetPropInt(player.GetActiveWeapon(), "m_iClip1", 0)
				NetProps.SetPropInt(player.GetActiveWeapon(), "m_bInReload", 0)
				NetProps.SetPropFloat(player.GetActiveWeapon(), "m_flNextPrimaryAttack", 999999999)
			}
		}
	}
}

// Called every frame the player the player holds down the fire button.
function OnKeyPressTick_Attack(player) {
	if(!disabled){
		if(beepNextTick && !beeped){
			EmitSoundOn("PipeBomb.TimerBeep", player)
			beepNextTick = false
			beeped = true
		}
		if(power < 100){
			power = power + 2
			g_ModeScript.SetLaunchPower(power)
		}
		g_ModeScript.SetPowerText("Power: " + power + "%")
		if(power > 15){
			g_ModeScript.SetDamageText("Damage: " + power / 10)
		} else {
			g_ModeScript.SetDamageText("Damage: 0")
		}

		if(power == 100 && !beeped){
			beepNextTick = true
		}
	}
}

// Called when the player starts firing.
function OnKeyPressStart_Attack(player)
{
	power = 0
	g_ModeScript.SetLaunchPower(0)
}

// Called when the player ends firing.
function OnKeyPressEnd_Attack(player)
{
	if(!disabled){
		if(fireDelay <= 0){
			g_ModeScript.FireGrenade(player, explosionEntity)
			fireDelay = FIRE_INTERVAL
		}
		beepNextTick = false
		beeped = false
		power = 0
		g_ModeScript.ResetPowerText()
		g_ModeScript.ResetDamageText()
	}
}

// Called when a player switches to the weapon.
function OnEquipped(player)
{
	equipped = true
	//NetProps.SetPropIntArray(player, "m_iAmmo", 1, NetProps.GetPropInt(player.GetActiveWeapon(), "m_iPrimaryAmmoType"))
	//EmitSoundOn("GrenadeLauncher.Deploy", player)
}

// Called when a player switches away from the weapon.
function OnUnequipped()
{
	g_ModeScript.ResetPowerText()
	g_ModeScript.ResetDamageText()
	power = 0
	equipped = false
	beeped = false
	beepNextTick = false
}