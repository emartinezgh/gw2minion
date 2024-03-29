-- This file contains ranger specific combat routines

-- load routine only if player is a ranger
if ( 4 ~= Player.profession ) then
	return
end
-- The following values have to get set ALWAYS for ALL professions!!
wt_profession_ranger  =  inheritsFrom( nil )
wt_profession_ranger.professionID = 4 -- needs to be set
wt_profession_ranger.professionRoutineName = "Ranger"
wt_profession_ranger.professionRoutineVersion = "1.0"
wt_profession_ranger.RestHealthLimit = 70

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
local debug_slot, debug_tid = nil, nil
local debug_attack, debug_move, debug_heal = true, true, true

local debug_attack_msg_format	= "Ranger: Use %s (Slot %u) on %s (%u) - Dist %.f"
local debug_move_msg_format		= "Ranger: Move to %s (%u) - Dist %.f"
local debug_heal_msg_format		= "Ranger: Use %s - Slot %u - %u"

function debug_msg( tid, t, slot, name )
	if ( slot ~= nil ) then
		if ( debug_attack  and tid ~= nil ) then
			if ( debug_slot ~= slot ) then
				wt_debug( string.format( debug_attack_msg_format, tostring( name ) or "", slot, t.name or "MOB", tid, t.distance ) )
				debug_slot = slot
			end
		elseif ( debug_heal and tid == nil ) then
			if ( debug_slot ~= slot ) then
				wt_debug( string.format(  debug_heal_msg_format, tostring( name ) or "", slot, Player.health.percent ).."% health" )
				debug_slot = slot
			end
		end
		if ( debug_tid ~= tid ) then
			debug_tid = tid
		end
	else
		if ( debug_move ) then
			if ( debug_tid ~= tid ) then
				wt_debug( string.format( debug_move_msg_format, t.name or "MOB", tid, t.distance ) )
				debug_tid = tid
			end
		end
		debug_slot = nil
	end
end

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
--[[ Human weapon information - name = { skill_x = range_y, ect. }
mainhand = {
	Sword		=	{	s1 = 130,	s2 = 130,	s3 = 130							}
	Longbow		=	{	s1 = 1200,	s2 = 1200,	s3 = 1200,	s4 = 750,	s5 = 1200	} s1 -> s2, s2 -> s3, s3 -> s4, s4 -> s1, s5 -> s5
	Shortbow	=	{	s1 = 1200,	s2 = 1200,	s3 = 1200,	s4 = 1200,	s5 = 1200	}
	Axe			=	{	s1 = 900,	s2 = 900,	s3 = 900							}
	Greatsword	=	{	s1 = 150,	s2 = 150,	s3 = 1100,	s4 = 300,	s5 = 300	}
	Spear		=	{	s1 = 150,	s2 = 150,	s3 = 900,	s4 = 240,	s5 = 150	}
	HarpoonGun	=	{	s1 = 1200,	s2 = 1200,	s3 = 1200,	s4 = 1200,	s5 = 1200	}
}
offhand = {
	Axe			=	{	s4 = 900,	s5 = 150	}
	Dagger		=	{	s4 = 250,	s5 = 900	}
	Torch		=	{	s4 = 900,	s5 = 120	}
	Warhorn		=	{	s4 = 900,	s5 = 600	}
}
]]--

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- NeedHeal Check
wt_profession_ranger.c_heal_action = inheritsFrom( wt_cause )
wt_profession_ranger.e_heal_action = inheritsFrom( wt_effect )

function wt_profession_ranger.c_heal_action:evaluate()
	return ( Player.health.percent < 50 and not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_6 ) )
end
wt_profession_ranger.e_heal_action.usesAbility = true

function wt_profession_ranger.e_heal_action:execute()
	local s6 = Player:GetSpellInfo( GW2.SKILLBARSLOT.Slot_6 )
	if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_6 ) ) then
--		wt_debug( "e_heal_action" )
		if ( Player:IsCasting( GW2.SKILLBARSLOT.Slot_6 ) and  Player:GetCurrentlyCastedSpell() == GW2.SKILLBARSLOT.Slot_6 ) then
			debug_msg( nil, nil, 6, s6.name )
		end
		Player:CastSpell( GW2.SKILLBARSLOT.Slot_6 )
	end
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Move Closer to Target Check
wt_profession_ranger.c_MoveCloser = inheritsFrom( wt_cause )
wt_profession_ranger.e_MoveCloser = inheritsFrom( wt_effect )

function wt_profession_ranger.c_MoveCloser:evaluate()
	if ( wt_core_state_combat.CurrentTarget ~= 0 ) then
		local T = CharacterList:Get( wt_core_state_combat.CurrentTarget )
		local Distance = T ~= nil and T.distance or 0
		local LOS = T~=nil and T.los or false
		if ( Distance >= wt_global_information.AttackRange or LOS ~= true ) then
			return true
		else
			if ( Player:GetTarget() ~= wt_core_state_combat.CurrentTarget ) then
				Player:SetTarget( wt_core_state_combat.CurrentTarget )
			end
		end
	end
	return false
end

function wt_profession_ranger.e_MoveCloser:execute()
local TID = wt_core_state_combat.CurrentTarget
	local T = CharacterList:Get( TID )
	if ( T ~= nil ) then
		debug_msg( TID, T, nil)
		Player:MoveTo( T.pos.x, T.pos.y, T.pos.z, 120 ) -- the last number is the distance to the target where to stop
	end
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Update Weapon Data
wt_profession_ranger.c_update_weapons = inheritsFrom( wt_cause )
wt_profession_ranger.e_update_weapons = inheritsFrom( wt_effect )

function wt_profession_ranger.c_update_weapons:evaluate()
	wt_profession_ranger.MHweapon = Inventory:GetEquippedItemBySlot( GW2.EQUIPMENTSLOT.MainHandWeapon )
	wt_profession_ranger.OHweapon = Inventory:GetEquippedItemBySlot( GW2.EQUIPMENTSLOT.OffHandWeapon )
	return false
end

function wt_profession_ranger.e_update_weapons:execute()
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Combat Default Attack
wt_profession_ranger.c_attack_default = inheritsFrom( wt_cause )
wt_profession_ranger.e_attack_default = inheritsFrom( wt_effect )

function wt_profession_ranger.c_attack_default:evaluate()
	  return wt_core_state_combat.CurrentTarget ~= 0
end

wt_profession_ranger.e_attack_default.usesAbility = true
function wt_profession_ranger.e_attack_default:execute()
	Player:StopMoving()
	TID = wt_core_state_combat.CurrentTarget
	if ( TID ~= 0 ) then
		local T = CharacterList:Get( TID )
		if ( T ~= nil) then
			Player:SetFacing( T.pos.x-Player.pos.x, T.pos.z-Player.pos.z, T.pos.y-Player.pos.y )
			local s1 = Player:GetSpellInfo( GW2.SKILLBARSLOT.Slot_1 )
			local s2 = Player:GetSpellInfo( GW2.SKILLBARSLOT.Slot_2 )
			local s3 = Player:GetSpellInfo( GW2.SKILLBARSLOT.Slot_3 )
			local s4 = Player:GetSpellInfo( GW2.SKILLBARSLOT.Slot_4 )
			local s5 = Player:GetSpellInfo( GW2.SKILLBARSLOT.Slot_5 )
--[[
						-- Utility & Elite slots
			local s7 = Player:GetSpellInfo( GW2.SKILLBARSLOT.Slot_7 )
			local s8 = Player:GetSpellInfo( GW2.SKILLBARSLOT.Slot_8 )
			local s9 = Player:GetSpellInfo( GW2.SKILLBARSLOT.Slot_9 )
			local s10 = Player:GetSpellInfo( GW2.SKILLBARSLOT.Slot_10 )
			if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_7 ) and s7 ~= nil and ( T.distance < s7.maxRange ) ) then
				Player:CastSpell( GW2.SKILLBARSLOT.Slot_7, TID )
				debug_msg( TID, T, 7 )
			end
]]--
			if( wt_profession_ranger.MHweapon ~= nil and wt_profession_ranger.OHweapon == nil ) then
				if ( wt_profession_ranger.MHweapon.weapontype == GW2.WEAPONTYPE.Sword ) then
					wt_global_information.AttackRange = 130
					if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 130 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
						debug_msg( TID, T, 3, s3.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 130 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
						debug_msg( TID, T, 2, s2.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 130 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
						debug_msg( TID, T, 1, s1.name )
					end
				elseif ( wt_profession_ranger.MHweapon.weapontype == GW2.WEAPONTYPE.Longbow ) then
					wt_global_information.AttackRange = 1200
					if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
						debug_msg( TID, T, 5, s5.name ) -- Barrage ( bar slot 5 )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
						debug_msg( TID, T, 1, s4.name ) -- Long Range Shot ( bar slot 1 )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 750 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
						debug_msg( TID, T, 4, s3.name ) -- Point Blank Shot ( bar slot 4 )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
						debug_msg( TID, T, 3, s2.name ) -- Hunter's Shot ( bar slot 3 )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
						debug_msg( TID, T, 2, s1.name ) -- Rapid Fire ( bar slot 2 )
					end
				elseif ( wt_profession_ranger.MHweapon.weapontype == GW2.WEAPONTYPE.Shortbow ) then
					wt_global_information.AttackRange = 1200
					if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
						debug_msg( TID, T, 5, s5.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
						debug_msg( TID, T, 4, s4.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
						debug_msg( TID, T, 3, s3.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
						debug_msg( TID, T, 2, s2.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
						debug_msg( TID, T, 1, s1.name )
					end
				elseif ( wt_profession_ranger.MHweapon.weapontype == GW2.WEAPONTYPE.Axe ) then
					wt_global_information.AttackRange = 900
					if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 900 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
						debug_msg( TID, T, 3, s3.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 900 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
						debug_msg( TID, T, 2, s2.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 900 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
						debug_msg( TID, T, 1, s1.name )
					end
				elseif ( wt_profession_ranger.MHweapon.weapontype == GW2.WEAPONTYPE.Greatsword ) then
					wt_global_information.AttackRange = 150
					if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 300 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
						debug_msg( TID, T, 5, s5.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 300 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
						debug_msg( TID, T, 4, s4.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 1100 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
						debug_msg( TID, T, 3, s3.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 150 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
						debug_msg( TID, T, 2, s2.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 150 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
						debug_msg( TID, T, 1, s1.name )
					end
				elseif ( wt_profession_ranger.MHweapon.weapontype == GW2.WEAPONTYPE.Spear ) then
					wt_global_information.AttackRange = 150
					if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 150 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
						debug_msg( TID, T, 5, s5.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 240 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
						debug_msg( TID, T, 4, s4.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 900 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
						debug_msg( TID, T, 3, s3.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 150 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
						debug_msg( TID, T, 2, s2.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 150 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
						debug_msg( TID, T, 1, s1.name )
					end
				elseif ( wt_profession_ranger.MHweapon.weapontype == GW2.WEAPONTYPE.HarpoonGun ) then
					wt_global_information.AttackRange = 1200
					if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
						debug_msg( TID, T, 5, s5.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
						debug_msg( TID, T, 4, s4.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
						debug_msg( TID, T, 3, s3.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
						debug_msg( TID, T, 2, s2.name )
					elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 1200 ) ) then
						Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
						debug_msg( TID, T, 1, s1.name )
					end
				end
			elseif(wt_profession_ranger.MHweapon ~= nil and wt_profession_ranger.OHweapon ~= nil ) then
				if ( wt_profession_ranger.MHweapon.weapontype == GW2.WEAPONTYPE.Sword ) then
					if ( wt_profession_ranger.OHweapon.weapontype == GW2.WEAPONTYPE.Axe ) then
						wt_global_information.AttackRange = 130
						if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 150 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
							debug_msg( TID, T, 5, s5.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
							debug_msg( TID, T, 4, s4.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 130 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
							debug_msg( TID, T, 3, s3.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 130 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
							debug_msg( TID, T, 2, s2.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 130 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
							debug_msg( TID, T, 1, s1.name )
						end
					elseif ( wt_profession_ranger.OHweapon.weapontype == GW2.WEAPONTYPE.Dagger ) then
						wt_global_information.AttackRange = 130
						if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
							debug_msg( TID, T, 5, s5.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 250 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
							debug_msg( TID, T, 4, s4.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 130 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
							debug_msg( TID, T, 3, s3.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 130 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
							debug_msg( TID, T, 2, s2.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 130 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
							debug_msg( TID, T, 1, s1.name )
						end
					elseif ( wt_profession_ranger.OHweapon.weapontype == GW2.WEAPONTYPE.Torch ) then
						wt_global_information.AttackRange = 130
						if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 120 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
							debug_msg( TID, T, 5, s5.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
							debug_msg( TID, T, 4, s4.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 130 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
							debug_msg( TID, T, 3, s3.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 130 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
							debug_msg( TID, T, 2, s2.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 130 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
							debug_msg( TID, T, 1, s1.name )
						end
					elseif ( wt_profession_ranger.OHweapon.weapontype == GW2.WEAPONTYPE.Warhorn ) then
						wt_global_information.AttackRange = 130
						if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 600 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
							debug_msg( TID, T, 5, s5.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
							debug_msg( TID, T, 4, s4.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 130 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
							debug_msg( TID, T, 3, s3.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 130 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
							debug_msg( TID, T, 2, s2.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 130 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
							debug_msg( TID, T, 1, s1.name )
						end
					end
				elseif ( wt_profession_ranger.MHweapon.weapontype == GW2.WEAPONTYPE.Axe ) then
					if ( wt_profession_ranger.OHweapon.weapontype == GW2.WEAPONTYPE.Axe ) then
						wt_global_information.AttackRange = 900
						if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 150 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
							debug_msg( TID, T, 5, s5.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
							debug_msg( TID, T, 4, s4.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
							debug_msg( TID, T, 3, s3.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
							debug_msg( TID, T, 2, s2.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
							debug_msg( TID, T, 1, s1.name )
						end
					elseif ( wt_profession_ranger.OHweapon.weapontype == GW2.WEAPONTYPE.Dagger ) then
						wt_global_information.AttackRange = 900
						if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
							debug_msg( TID, T, 5, s5.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 250 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
							debug_msg( TID, T, 4, s4.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
							debug_msg( TID, T, 3, s3.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
							debug_msg( TID, T, 2, s2.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
							debug_msg( TID, T, 1, s1.name )
						end
					elseif ( wt_profession_ranger.OHweapon.weapontype == GW2.WEAPONTYPE.Torch ) then
						wt_global_information.AttackRange = 900
						if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 120 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
							debug_msg( TID, T, 5, s5.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
							debug_msg( TID, T, 4, s4.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
							debug_msg( TID, T, 3, s3.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
							debug_msg( TID, T, 2, s2.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
							debug_msg( TID, T, 1, s1.name )
						end
					elseif ( wt_profession_ranger.OHweapon.weapontype == GW2.WEAPONTYPE.Warhorn ) then
						wt_global_information.AttackRange = 900
						if ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_5 ) and s5 ~= nil and ( T.distance < s5.maxRange or s5.maxRange < 600 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_5, TID )
							debug_msg( TID, T, 5, s5.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_4 ) and s4 ~= nil and ( T.distance < s4.maxRange or s4.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_4, TID )
							debug_msg( TID, T, 4, s4.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_3 ) and s3 ~= nil and ( T.distance < s3.maxRange or s3.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_3, TID )
							debug_msg( TID, T, 3, s3.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_2 ) and s2 ~= nil and ( T.distance < s2.maxRange or s2.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_2, TID )
							debug_msg( TID, T, 2, s2.name )
						elseif ( not Player:IsSpellOnCooldown( GW2.SKILLBARSLOT.Slot_1 ) and s1 ~= nil and ( T.distance < s1.maxRange or s1.maxRange < 900 ) ) then
							Player:CastSpell( GW2.SKILLBARSLOT.Slot_1, TID )
							debug_msg( TID, T, 1, s1.name )
						end
					end
				end
			end
		end
	end
end

-----------------------------------------------------------------------------------
-- Registration and setup of causes and effects to the different states
-----------------------------------------------------------------------------------

-- We need to check if the players current profession is ours to only add our profession specific routines
if ( wt_profession_ranger.professionID > -1 and wt_profession_ranger.professionID == Player.profession ) then

	wt_debug( "Initalizing profession routine for Ranger" )
	-- Default Causes & Effects that are already in the wt_core_state_combat for all classes:
	-- Death Check 				- Priority 10000   --> Can change state to wt_core_state_dead.lua
	-- Combat Over Check 		- Priority 500      --> Can change state to wt_core_state_idle.lua


	-- Our C & E�s for Ranger combat:
	local ke_heal_action = wt_kelement:create( "heal_action", wt_profession_ranger.c_heal_action, wt_profession_ranger.e_heal_action, 100 )
		wt_core_state_combat:add( ke_heal_action )

	local ke_MoveClose_action = wt_kelement:create( "Move closer", wt_profession_ranger.c_MoveCloser, wt_profession_ranger.e_MoveCloser, 75 )
		wt_core_state_combat:add( ke_MoveClose_action )

	local ke_Update_weapons = wt_kelement:create( "UpdateWeaponData", wt_profession_ranger.c_update_weapons, wt_profession_ranger.e_update_weapons, 55 )
		wt_core_state_combat:add( ke_Update_weapons )


	local ke_Attack_default = wt_kelement:create( "Attackdefault", wt_profession_ranger.c_attack_default, wt_profession_ranger.e_attack_default, 45 )
		wt_core_state_combat:add( ke_Attack_default )


	-- We need to set the Currentprofession to our profession , so that other parts of the framework can use it.
	wt_global_information.Currentprofession = wt_profession_ranger
	wt_global_information.AttackRange = 900
end
-----------------------------------------------------------------------------------