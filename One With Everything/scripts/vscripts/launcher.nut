local FIRE_INTERVAL = 21 		// How many counts before the explosion can be fired again.
local TRACE_MAX_DISTANCE = 99999 	// How far the attack ray trace goes.

local power = 0
local fireDelay = FIRE_INTERVAL
local beepNextTick = false
local beeped = false
local disabled = false

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
}

// Called when the player ends firing.
function OnKeyPressEnd_Attack(player)
{
	if(!disabled){
		if(fireDelay <= 0){
			g_ModeScript.FireGrenade(player)
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
	EmitSoundOn("GrenadeLauncher.Deploy", player)
}

// Called when a player switches away from the weapon.
function OnUnequipped()
{
	g_ModeScript.ResetPowerText()
	g_ModeScript.ResetDamageText()
	power = 0
	beeped = false
	beepNextTick = false
}