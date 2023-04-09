if GlobalSys:CommandLineCheck("-novr") then
    DoIncludeScript("flashlight.lua", nil)
    DoIncludeScript("jumpfix.lua", nil)
	local isModActive = false -- Mod support by Hypercycle

    if player_hurt_ev ~= nil then
        StopListeningToGameEvent(player_hurt_ev)
    end

    player_hurt_ev = ListenToGameEvent('player_hurt', function(info)
        -- Hack to stop pausing the game on death
        if info.health == 0 then
            SendToConsole("reload")
            SendToConsole("r_drawvgui 0")
        end

        -- Kill on fall damage
        if GetPhysVelocity(Entities:GetLocalPlayer()).z < -450 then
            SendToConsole("ent_fire !player SetHealth 0")
        end
    end, nil)

    if entity_killed_ev ~= nil then
        StopListeningToGameEvent(entity_killed_ev)
    end

    entity_killed_ev = ListenToGameEvent('entity_killed', function(info)
        local player = Entities:GetLocalPlayer()
        player:SetThink(function()
            function GibBecomeRagdoll(classname)
                ent = Entities:FindByClassname(nil, classname)
                while ent do
                    if vlua.find(ent:GetModelName(), "models/creatures/headcrab_classic/headcrab_classic_gib") or vlua.find(ent:GetModelName(), "models/creatures/headcrab_armored/armored_hc_gib") then
                        DoEntFireByInstanceHandle(ent, "BecomeRagdoll", "", 0.01, nil, nil)
                    end
                    ent = Entities:FindByClassname(ent, classname)
                end
            end

            GibBecomeRagdoll("prop_physics")
            GibBecomeRagdoll("prop_ragdoll")
        end, "GibBecomeRagdoll", 0)

        local ent = EntIndexToHScript(info.entindex_killed):GetChildren()[1]
        if ent and ent:GetClassname() == "weapon_smg1" then
            ent:SetThink(function()
                if ent:GetMoveParent() then
                    return 0
                else
                    DoEntFireByInstanceHandle(ent, "BecomeRagdoll", "", 0.02, nil, nil)
                end
            end, "BecomeRagdollWhenNoParent", 0)
        end
    end, nil)

    if changelevel_ev ~= nil then
        StopListeningToGameEvent(changelevel_ev)
    end

    changelevel_ev = ListenToGameEvent('change_level_activated', function(info)
        SendToConsole("r_drawvgui 0")
    end, nil)

    if pickup_ev ~= nil then
        StopListeningToGameEvent(pickup_ev)
    end

    pickup_ev = ListenToGameEvent('physgun_pickup', function(info)
        local ent = EntIndexToHScript(info.entindex)
        ent:Attribute_SetIntValue("picked_up", 1)
        ent:SetThink(function()
            ent:Attribute_SetIntValue("picked_up", 0)
        end, "", 0.45)
        DoEntFireByInstanceHandle(ent, "RunScriptFile", "useextra", 0, nil, nil)
    end, nil)

    Convars:RegisterConvar("chosen_upgrade", "", "", 0)

    Convars:RegisterConvar("weapon_in_crafting_station", "", "", 0)

    Convars:RegisterCommand("chooseupgrade1", function()
        local t = {}
        Entities:GetLocalPlayer():GatherCriteria(t)

        if t.current_crafting_currency >= 10 then
            if Convars:GetStr("weapon_in_crafting_station") == "pistol" then
                Convars:SetStr("chosen_upgrade", "pistol_upgrade_aimdownsights")
                SendToConsole("ent_fire prop_hlvr_crafting_station_console RunScriptFile useextra")
                SendToConsole("hlvr_addresources 0 0 0 -10")
            elseif Convars:GetStr("weapon_in_crafting_station") == "shotgun" then
                Convars:SetStr("chosen_upgrade", "shotgun_upgrade_doubleshot")
                SendToConsole("ent_fire prop_hlvr_crafting_station_console RunScriptFile useextra")
                SendToConsole("hlvr_addresources 0 0 0 -10")
            elseif Convars:GetStr("weapon_in_crafting_station") == "smg" then
                Convars:SetStr("chosen_upgrade", "smg_upgrade_aimdownsights")
                SendToConsole("ent_fire prop_hlvr_crafting_station_console RunScriptFile useextra")
                SendToConsole("hlvr_addresources 0 0 0 -10")
            end
        else
            SendToConsole("ent_fire text_resin SetText #HLVR_CraftingStation_NotEnoughResin")
            SendToConsole("ent_fire text_resin Display")
            SendToConsole("play sounds/common/wpn_denyselect.vsnd")
            SendToConsole("cancelupgrade")
        end
    end, "", 0)

    Convars:RegisterCommand("chooseupgrade2", function()
        local t = {}
        Entities:GetLocalPlayer():GatherCriteria(t)

        if t.current_crafting_currency >= 20 then
            if Convars:GetStr("weapon_in_crafting_station") == "pistol" then
                Convars:SetStr("chosen_upgrade", "pistol_upgrade_burstfire")
                SendToConsole("ent_fire prop_hlvr_crafting_station_console RunScriptFile useextra")
                SendToConsole("hlvr_addresources 0 0 0 -20")
            elseif Convars:GetStr("weapon_in_crafting_station") == "shotgun" then
                Convars:SetStr("chosen_upgrade", "shotgun_upgrade_grenadelauncher")
                SendToConsole("ent_fire prop_hlvr_crafting_station_console RunScriptFile useextra")
                SendToConsole("hlvr_addresources 0 0 0 -20")
            elseif Convars:GetStr("weapon_in_crafting_station") == "smg" then
                Convars:SetStr("chosen_upgrade", "smg_upgrade_fasterfirerate")
                SendToConsole("ent_fire prop_hlvr_crafting_station_console RunScriptFile useextra")
                SendToConsole("hlvr_addresources 0 0 0 -20")
            end
        else
            SendToConsole("ent_fire text_resin SetText #HLVR_CraftingStation_NotEnoughResin")
            SendToConsole("ent_fire text_resin Display")
            SendToConsole("play sounds/common/wpn_denyselect.vsnd")
            SendToConsole("cancelupgrade")
        end
    end, "", 0)

    Convars:RegisterCommand("cancelupgrade", function()
        Convars:SetStr("chosen_upgrade", "cancel")
        SendToConsole("ent_fire weapon_in_fabricator Kill")
        -- TODO: Give weapon back, but don't fill magazine
        if Convars:GetStr("weapon_in_crafting_station") == "pistol" then
            SendToConsole("give weapon_pistol")
        elseif Convars:GetStr("weapon_in_crafting_station") == "shotgun" then
            SendToConsole("give weapon_shotgun")
        elseif Convars:GetStr("weapon_in_crafting_station") == "smg" then
            if Entities:GetLocalPlayer():Attribute_SetIntValue("smg_upgrade_fasterfirerate", 0) == 0 then
                SendToConsole("give weapon_ar2")
            else
                SendToConsole("give weapon_smg1")
            end
        end
        SendToConsole("ent_fire prop_hlvr_crafting_station_console RunScriptFile useextra")
    end, "", 0)


    -- Custom attack 2

    Convars:RegisterCommand("+customattack2", function()
        local viewmodel = Entities:FindByClassname(nil, "viewmodel")
        local player = Entities:GetLocalPlayer()
        if viewmodel and viewmodel:GetModelName() ~= "models/grenade.vmdl" then
            if viewmodel:GetModelName() == "models/shotgun.vmdl" then
                if player:Attribute_GetIntValue("shotgun_upgrade_doubleshot", 0) == 1 then
                    SendToConsole("+attack2")
                end
            elseif viewmodel:GetModelName() == "models/pistol.vmdl" then
                if player:Attribute_GetIntValue("pistol_upgrade_aimdownsights", 0) == 1 then
                    SendToConsole("toggle_zoom")
                end
            elseif viewmodel:GetModelName() == "models/smg.vmdl" then
                if player:Attribute_GetIntValue("smg_upgrade_aimdownsights", 0) == 1 then
                    SendToConsole("toggle_zoom")
                end
            end
        end
    end, "", 0)

    Convars:RegisterCommand("-customattack2", function()
        SendToConsole("-attack")
        SendToConsole("-attack2")
    end, "", 0)


    -- Custom attack 3

    Convars:RegisterCommand("+customattack3", function()
        local viewmodel = Entities:FindByClassname(nil, "viewmodel")
        local player = Entities:GetLocalPlayer()
        if viewmodel then
            if viewmodel:GetModelName() == "models/shotgun.vmdl" then
                if player:Attribute_GetIntValue("shotgun_upgrade_grenadelauncher", 0) == 1 then
                    SendToConsole("use weapon_frag")
                    SendToConsole("+attack")
                    SendToConsole("ent_fire weapon_frag hideweapon")
                    Entities:GetLocalPlayer():SetThink(function()
                        SendToConsole("-attack")
                    end, "StopAttack", 0.36)
                    Entities:GetLocalPlayer():SetThink(function()
                        SendToConsole("use weapon_shotgun")
                    end, "BackToShotgun", 0.66)
                end
            elseif viewmodel:GetModelName() == "models/pistol.vmdl" then
                if player:Attribute_GetIntValue("pistol_upgrade_burstfire", 0) == 1 then
                    SendToConsole("sk_plr_dmg_pistol 9")
                    SendToConsole("+attack")
                    Entities:GetLocalPlayer():SetThink(function()
                        SendToConsole("-attack")
                    end, "StopAttack", 0.02)
                    Entities:GetLocalPlayer():SetThink(function()
                        SendToConsole("+attack")
                    end, "StartAttack2", 0.14)
                    Entities:GetLocalPlayer():SetThink(function()
                        SendToConsole("-attack")
                    end, "StopAttack2", 0.16)
                    Entities:GetLocalPlayer():SetThink(function()
                        SendToConsole("+attack")
                    end, "StartAttack3", 0.28)
                    Entities:GetLocalPlayer():SetThink(function()
                        SendToConsole("-attack")
                        SendToConsole("sk_plr_dmg_pistol 7")
                    end, "StopAttack3", 0.3)
                end
            end
        end
    end, "", 0)

    Convars:RegisterCommand("-customattack3", function()
    end, "", 0)


    Convars:RegisterCommand("shootadvisorvortenergy", function()
        local ent = SpawnEntityFromTableSynchronous("env_explosion", {["origin"]="886 -4111.625 -1188.75", ["explosion_type"]="custom", ["explosion_custom_effect"]="particles/vortigaunt_fx/vort_beam_explosion_i_big.vpcf"})
        DoEntFireByInstanceHandle(ent, "Explode", "", 0, nil, nil)
        StartSoundEventFromPosition("VortMagic.Throw", Vector(886, -4111.625, -1188.75))
        SendToConsole("bind MOUSE1 \"\"")
        SendToConsole("ent_fire relay_advisor_dead Trigger")
    end, "", 0)

    Convars:RegisterCommand("shootvortenergy", function()
        local player = Entities:GetLocalPlayer()
        local startVector = player:EyePosition()
        local traceTable =
        {
            startpos = startVector;
            endpos = startVector + RotatePosition(Vector(0,0,0), player:GetAngles(), Vector(1000000, 0, 0));
            ignore = player;
            mask =  33636363
        }

        TraceLine(traceTable)

        if traceTable.hit then
            ent = SpawnEntityFromTableSynchronous("env_explosion", {["origin"]=traceTable.pos.x .. " " .. traceTable.pos.y .. " " .. traceTable.pos.z, ["explosion_type"]="custom", ["explosion_custom_effect"]="particles/vortigaunt_fx/vort_beam_explosion_i_big.vpcf"})
            DoEntFireByInstanceHandle(ent, "Explode", "", 0, nil, nil)
            SendToConsole("npc_kill")
            DoEntFire("!picker", "RunScriptFile", "vortenergyhit", 0, nil, nil)
            StartSoundEventFromPosition("VortMagic.Throw", startVector)
			local vortEnergyCell = Entities:FindByClassnameNearest("point_vort_energy", Vector(traceTable.pos.x,traceTable.pos.y,traceTable.pos.z), 15)
			if vortEnergyCell then
				vortEnergyCell:FireOutput("OnEnergyPulled", nil, nil, nil, 0)
			end
        end
    end, "", 0)

    Convars:RegisterCommand("useextra", function()
        local player = Entities:GetLocalPlayer()

        if not player:IsUsePressed() then
            DoEntFire("!picker", "RunScriptFile", "check_useextra_distance", 0, nil, nil)
            -- TODO: Remove this old method
            DoEntFire("!picker", "FireUser4", "", 0, nil, nil)

            if GetMapName() == "a5_vault" then
                if vlua.find(Entities:FindAllInSphere(Vector(-468, 2902, -519), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos -486 2908 -420")
                end
            end

            if GetMapName() == "a4_c17_parking_garage" then
                ent = Entities:FindByName(nil, "toner_sliding_ladder")
                ent:RedirectOutput("OnUser4", "ClimbGarageLadder", ent)
            end

            if GetMapName() == "a4_c17_water_tower" then
                if vlua.find(Entities:FindAllInSphere(Vector(3314, 6048, 64), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos 3276 6048 142")
                elseif vlua.find(Entities:FindAllInSphere(Vector(2374, 6207, -177), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos 2342 6257 -153")
                elseif vlua.find(Entities:FindAllInSphere(Vector(2432, 6662, 160), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos 2431 6715 310")
                elseif vlua.find(Entities:FindAllInSphere(Vector(2848, 6130, 384), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos 2850 6186 550")
                end
            end

            if GetMapName() == "a4_c17_tanker_yard" then
                if vlua.find(Entities:FindAllInSphere(Vector(6980, 2591, 13), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos 6965 2600 261")
                elseif vlua.find(Entities:FindAllInSphere(Vector(6069, 3902, 416), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos 6118 3903 686")
                elseif vlua.find(Entities:FindAllInSphere(Vector(5434, 5755, 273), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos 5450, 5714, 403")
                end
            end

            if GetMapName() == "a3_station_street" then
                if vlua.find(Entities:FindAllInSphere(Vector(934, 1883, -135), 20), player) then
                    SendToConsole("ent_fire_output 2_8127_elev_button_floor_1_call OnIn")
                end
            end

            if GetMapName() == "a3_hotel_interior_rooftop" then
                if vlua.find(Entities:FindAllInSphere(Vector(2381, -1841, 448), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos_exact 2339 -1839 560")
                elseif vlua.find(Entities:FindAllInSphere(Vector(2345, -1834, 758), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos_exact 2345 -1834 840")
                end
            end

            if GetMapName() == "a3_hotel_lobby_basement" then
                if vlua.find(Entities:FindAllInSphere(Vector(1059, -1475, 200), 20), player) then
                    SendToConsole("ent_fire_output elev_button_floor_1 OnIn")
                elseif vlua.find(Entities:FindAllInSphere(Vector(976, -1467, 208), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos_exact 975 -1507 280")
                end
            end

            if GetMapName() == "a2_headcrabs_tunnel" and vlua.find(Entities:FindAllInSphere(Vector(347,-242,-63), 20), player) then
                ClimbLadderSound()
                SendToConsole("fadein 0.2")
                SendToConsole("setpos_exact 347 -297 2")
            end

            if GetMapName() == "a2_hideout" then
                local startVector = player:EyePosition()
                local traceTable =
                {
                    startpos = startVector;
                    endpos = startVector + RotatePosition(Vector(0,0,0), player:GetAngles(), Vector(100, 0, 0));
                    ignore = player;
                    mask =  33636363
                }
            
                TraceLine(traceTable)
            
                if traceTable.hit 
                then
                    local ent = Entities:FindByClassnameNearest("func_physical_button", traceTable.pos, 10)
                    if ent then
                        ent:FireOutput("OnIn", nil, nil, nil, 0)
                        StartSoundEventFromPosition("Button_Basic.Press", player:EyePosition())
                    end
                end
            end

            if GetMapName() == "a3_c17_processing_plant" then
                if vlua.find(Entities:FindAllInSphere(Vector(-80, -2215, 760), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos_exact -26 -2215 870")
                end

                if vlua.find(Entities:FindAllInSphere(Vector(-240,-2875,392), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos_exact -241 -2823 410")
                end

                if vlua.find(Entities:FindAllInSphere(Vector(414,-2459,328), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos_exact 365 -2465 410")
                end

                if vlua.find(Entities:FindAllInSphere(Vector(-1392,-2471,115), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos_exact -1415 -2485 410")
                end

                if vlua.find(Entities:FindAllInSphere(Vector(-1420,-2482,472), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos_exact -1392 -2471 53")
                end
            end
			
			-- Mod support for Extra-Ordinary Value
			-- Ladders
			if GetMapName() == "youreawake" then
				if vlua.find(Entities:FindAllInSphere(Vector(-2953,409,-379), 20), player) then --1
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -2941 388 -145")	
				elseif vlua.find(Entities:FindAllInSphere(Vector(-2950,286,-148), 20), player) then --2
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -2981 323 51")	
				elseif vlua.find(Entities:FindAllInSphere(Vector(-2958,0,-153), 20), player) then --3
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -2983 19 51")	
				elseif vlua.find(Entities:FindAllInSphere(Vector(-3701,160,49), 20), player) then --4
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -3744 161 -152")
				elseif vlua.find(Entities:FindAllInSphere(Vector(-5755,263,-379), 20), player) then -- 5
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -5796 263 -281")
				elseif vlua.find(Entities:FindAllInSphere(Vector(-5867,265,-280), 20), player) then -- 6
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -5812 270 -185")
				elseif vlua.find(Entities:FindAllInSphere(Vector(-5802,254,-185), 20), player) then -- 7
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -5799 202 -34")
				elseif vlua.find(Entities:FindAllInSphere(Vector(-8124,-1080,-145), 20), player) then -- 8
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -8132 -1004 78")
				elseif vlua.find(Entities:FindAllInSphere(Vector(-8128,-45,-5), 20), player) then -- 9
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -8172 -49 169")
				elseif vlua.find(Entities:FindAllInSphere(Vector(-8742,-1596,181), 20), player) then -- 10
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -8757 -1592 -375")
				end
			end
			if GetMapName() == "seweroutskirts" then
				if vlua.find(Entities:FindAllInSphere(Vector(559,-273,2), 20), player) then -- 1
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 478 -269 163")
				elseif vlua.find(Entities:FindAllInSphere(Vector(2816,-1393,-95), 20), player) then -- 2
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 2851 -1397 34")	
				end
			end
			if GetMapName() == "facilityredux" then
				if vlua.find(Entities:FindAllInSphere(Vector(-1757,-856,323), 20), player) then -- 1
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -1750.5 -883 55")
				end
			end
			if GetMapName() == "helloagain" then
				if vlua.find(Entities:FindAllInSphere(Vector(437,-1090,-216), 20), player) then -- 1
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 409 -1087 0")
				end
			end 
			-- Mod support for Overcharge
			if GetMapName() == "mc1_higgue" then
				if vlua.find(Entities:FindAllInSphere(Vector(302,856,106), 20), player) then -- 1
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 305 810 170")
				elseif vlua.find(Entities:FindAllInSphere(Vector(302,520,243), 20), player) then -- window
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 341 521 200")
				elseif vlua.find(Entities:FindAllInSphere(Vector(2024,580,-151), 20), player) then -- 2
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 2024 614 -85") 
				elseif vlua.find(Entities:FindAllInSphere(Vector(-178,-1315,104), 20), player) then -- 3
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -180 -1351 130")
				elseif vlua.find(Entities:FindAllInSphere(Vector(-299,-1358,192), 20), player) then -- 4
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -299 -1318 220")
				elseif vlua.find(Entities:FindAllInSphere(Vector(-537,-1375,296), 20), player) then -- 5
					ClimbLadderSound() 
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -499 -1375 322")
				end
			end
			-- Mod support for Levitation
			if GetMapName() == "01_intro" then
				if vlua.find(Entities:FindAllInSphere(Vector(-7617,6629,-3216), 20), player) then -- 1
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -7617.810 6581.993 -3075")
				end
			end
			if GetMapName() == "03_metrodynamo" then
				if vlua.find(Entities:FindAllInSphere(Vector(-13,-2719,-69), 20), player) then -- 1
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -56.835 -2719.956 -37")
				end
			end
			if GetMapName() == "04_hehungers" then 
--				if vlua.find(Entities:FindAllInSphere(Vector(44,-3456,-832), 20), player) then -- 1 
--					ClimbLadderSound() -- player should climb to trigger something
--					SendToConsole("fadein 0.2")
--					SendToConsole("setpos_exact 20.192 -3512.422 -520")
				if vlua.find(Entities:FindAllInSphere(Vector(86,-3506,-448), 20), player) then -- 2
					ClimbLadderSound() 
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 110.031 -3492.221 -393")
				elseif vlua.find(Entities:FindAllInSphere(Vector(109,-3559,-286), 20), player) then -- 3
					ClimbLadderSound() 
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 67.597 -3547.483 -78")
				end
			end
			if GetMapName() == "05_pleasantville" then 
				if vlua.find(Entities:FindAllInSphere(Vector(899,-697,7790), 20), player) then -- 1
					ClimbLadderSound() 
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 961.730 -696.987 7891")
				elseif vlua.find(Entities:FindAllInSphere(Vector(924,-698,7920), 10), player) then -- 1r
					ClimbLadderSound() 
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 894.993 -698.078 7740")
				elseif vlua.find(Entities:FindAllInSphere(Vector(613,-990,7756), 20), player) then -- 2 TODO: with lock
					ClimbLadderSound() 
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 612.300 -1047.172 7891")
				elseif vlua.find(Entities:FindAllInSphere(Vector(613,-1040,7918), 10), player) then -- 2r
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 613.590 -985.104 7705")
				elseif vlua.find(Entities:FindAllInSphere(Vector(672,-797,7964), 20), player) then -- huge jump
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 676.863 -597.481 7918")
				end 
			end
			if GetMapName() == "06_digdeep" then 
				if vlua.find(Entities:FindAllInSphere(Vector(-913,1087,137), 20), player) then -- 1
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -915.140 1135.754 186")
				elseif vlua.find(Entities:FindAllInSphere(Vector(-356,716,664), 8), player) then -- 2r
					ClimbLadderSound() 
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -355.712 753.690 415")
				elseif vlua.find(Entities:FindAllInSphere(Vector(-355,749,464), 15), player) then -- 2
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -355.073 708.344 639")
				end 
			end
			if GetMapName() == "07_sectorx" then 
				if vlua.find(Entities:FindAllInSphere(Vector(-689,255,-236), 20), player) then -- 1
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact -689.281 296.020 -236")
				end
			end
			if GetMapName() == "08_burningquestions" then 
				if vlua.find(Entities:FindAllInSphere(Vector(158,248,-9128), 20), player) then -- 1
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 158.193 203.352 -8986")
				elseif vlua.find(Entities:FindAllInSphere(Vector(158,216,-8960), 10), player) then -- 1r
					ClimbLadderSound()
					SendToConsole("fadein 0.2")
					SendToConsole("setpos_exact 159.402 252.582 -9184") 
				end
			end

            if GetMapName() == "a3_distillery" then
                if vlua.find(Entities:FindAllInSphere(Vector(20,-518,211), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos_exact 20 -471 452")
                end

                if vlua.find(Entities:FindAllInSphere(Vector(515,1595,578), 20), player) then
                    ClimbLadderSound()
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos_exact 577 1597 668")
                end

                ent = Entities:FindByName(nil, "cellar_ladder")
                ent:RedirectOutput("OnUser4", "ClimbCellarLadder", ent)

                ent = Entities:FindByName(nil, "larry_ladder")
                if ent then
                    ent:RedirectOutput("OnUser4", "ClimbLarryLadder", ent)
                end
            end
        end
    end, "", 0)

    if player_spawn_ev ~= nil then
        StopListeningToGameEvent(player_spawn_ev)
    end

    player_spawn_ev = ListenToGameEvent('player_activate', function(info)
        if not IsServer() then return end

        local loading_save_file = false
        local ent = Entities:FindByClassname(ent, "player_speedmod")
        if ent then
            loading_save_file = true
        else
            SpawnEntityFromTableSynchronous("player_speedmod", nil)
        end

        SendToConsole("fps_max 120")

        if GetMapName() == "startup" then
            SendToConsole("sv_cheats 1")
            SendToConsole("hidehud 4")
            SendToConsole("mouse_disableinput 1")
            SendToConsole("bind MOUSE1 +use")
            if not loading_save_file then
                SendToConsole("ent_fire player_speedmod ModifySpeed 0")
                SendToConsole("setpos 0 -6154 6.473839")
            else
                GoToMainMenu()
            end
            ent = Entities:FindByName(nil, "startup_relay")
            ent:RedirectOutput("OnTrigger", "GoToMainMenu", ent)
        else
            SendToConsole("binddefaults")
            SendToConsole("bind space jumpfixed")
            SendToConsole("bind e \"+use;useextra\"")
            SendToConsole("bind v noclip")
            SendToConsole("hl2_sprintspeed 140")
            SendToConsole("bind F5 \"save quick;play sounds/ui/beepclear.vsnd;ent_fire text_quicksave showmessage\"")
            SendToConsole("bind F9 \"load quick\"")
            SendToConsole("bind M \"map startup\"")
            SendToConsole("bind MOUSE2 +customattack2")
            SendToConsole("bind MOUSE3 +customattack3")
            SendToConsole("r_drawviewmodel 0")
            SendToConsole("fov_desired 90")
            SendToConsole("sv_infinite_aux_power 1")
            SendToConsole("cc_spectator_only 1")
            SendToConsole("sv_gameinstructor_disable 1")
            SendToConsole("hud_draw_fixed_reticle 0")
            SendToConsole("r_drawvgui 1")
            SendToConsole("ent_fire *_locker_door_* DisablePickup")
            SendToConsole("ent_fire *_hazmat_crate_lid DisablePickup")
            SendToConsole("ent_fire electrical_panel_*_door* DisablePickup")
            SendToConsole("ent_remove player_flashlight")
            SendToConsole("hl_headcrab_deliberate_miss_chance 0")
            SendToConsole("headcrab_powered_ragdoll 0")
            SendToConsole("combine_grenade_timer 4")
            SendToConsole("sk_max_grenade 9999")
            SendToConsole("sk_auto_reload_time 9999")
            SendToConsole("sv_gravity 500")
            SendToConsole("alias -covermouth \"ent_fire !player suppresscough 0;ent_fire_output @player_proxy onplayeruncovermouth;ent_fire lefthand disable;viewmodel_offset_y 0\"")
            SendToConsole("alias +covermouth \"ent_fire !player suppresscough 1;ent_fire_output @player_proxy onplayercovermouth;ent_fire lefthand enable;viewmodel_offset_y -20\"")
            SendToConsole("mouse_disableinput 0")
            SendToConsole("-attack")
            SendToConsole("-attack2")
            SendToConsole("sk_headcrab_runner_health 69")
            SendToConsole("sk_plr_dmg_pistol 7")
            SendToConsole("sk_plr_dmg_ar2 9")
            SendToConsole("sk_plr_dmg_smg1 5")

            ent = Entities:GetLocalPlayer()
            if ent then
                local angles = ent:GetAngles()
                SendToConsole("setang " .. angles.x .. " " .. angles.y .. " 0")
                ent:SetThink(function()
                    if Entities:GetLocalPlayer():GetBoundingMaxs().z == 36 then
                        SendToConsole("cl_forwardspeed 86;cl_backspeed 86;cl_sidespeed 86")
                    else
                        SendToConsole("cl_forwardspeed 46;cl_backspeed 46;cl_sidespeed 46")
                    end
                    return 0
                end, "FixCrouchSpeed", 0)
            end

            SendToConsole("ent_remove text_quicksave")
            SendToConsole("ent_create env_message { targetname text_quicksave message GAMESAVED }")

            SendToConsole("ent_remove text_resin")
            -- TODO: Change holdtime to 3 when there is a proper weapon upgrade selection UI
            SendToConsole("ent_create game_text { targetname text_resin effect 2 spawnflags 1 color \"255 220 0\" color2 \"92 107 192\" fadein 0 fadeout 0.15 fxtime 0.25 holdtime 15 x 0.02 y -0.11 }")

            if GetMapName() == "a1_intro_world" then
                if not loading_save_file then
                    SendToConsole("ent_fire player_speedmod ModifySpeed 0")
                    SendToConsole("mouse_disableinput 1")
                    SendToConsole("give weapon_bugbait")
                    SendToConsole("hidehud 4")
                else
                    MoveFreely()
                end

                ent = Entities:FindByName(nil, "relay_teleported_to_refuge")
                ent:RedirectOutput("OnTrigger", "MoveFreely", ent)

                ent = Entities:FindByName(nil, "microphone")
                ent:RedirectOutput("OnUser4", "AcceptEliCall", ent)

                ent = Entities:FindByName(nil, "greenhouse_door")
                ent:RedirectOutput("OnUser4", "OpenGreenhouseDoor", ent)

                ent = Entities:FindByName(nil, "205_2653_door")
                ent:RedirectOutput("OnUser4", "OpenElevator", ent)
                ent = Entities:FindByName(nil, "205_2653_door2")
                ent:RedirectOutput("OnUser4", "OpenElevator", ent)
                ent = Entities:FindByName(nil, "205_8018_button_pusher_prop")
                ent:RedirectOutput("OnUser4", "OpenElevator", ent)

                ent = Entities:FindByName(nil, "205_8032_button_pusher_prop")
                ent:RedirectOutput("OnUser4", "RideElevator", ent)

                ent = Entities:FindByName(nil, "563_vent_door")
                ent:RedirectOutput("OnUser4", "EnterCombineElevator", ent)

                ent = Entities:FindByName(nil, "979_518_button_pusher_prop")
                ent:RedirectOutput("OnUser4", "OpenCombineElevator", ent)
            elseif GetMapName() == "a1_intro_world_2" then
                if not loading_save_file then
                    ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER1_TITLE"})
                    DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)
                    SendToConsole("ent_create env_message { targetname text_crouchjump message CROUCHJUMP }")
                    SendToConsole("ent_create env_message { targetname text_sprint message SPRINT }")
                end

                SendToConsole("give weapon_bugbait")
                SendToConsole("hidehud 96")
                SendToConsole("combine_grenade_timer 7")

                if not loading_save_file then
                    ent = Entities:FindByName(nil, "trigger_post_gate")
                    ent:RedirectOutput("OnTrigger", "ShowSprintTutorial", ent)
                end

                ent = Entities:FindByName(nil, "scavenge_trigger")
                ent:RedirectOutput("OnTrigger", "ShowCrouchJumpTutorial", ent)

                ent = Entities:FindByName(nil, "hint_crouch_trigger")
                ent:RedirectOutput("OnStartTouch", "GetOutOfCrashedVan", ent)
                
                ent = Entities:FindByName(nil, "spawner_scanner")
                ent:RedirectOutput("OnEntitySpawned", "RedirectHeadset", ent)

                ent = Entities:FindByName(nil, "4962_car_door_left_front")
                ent:RedirectOutput("OnUser4", "ToggleCarDoor", ent)

                ent = Entities:FindByName(nil, "balcony_ladder")
                ent:RedirectOutput("OnUser4", "ClimbBalconyLadder", ent)

                ent = Entities:FindByName(nil, "russell_entry_window")
                ent:RedirectOutput("OnUser4", "OpenRussellWindow", ent)

                ent = Entities:FindByName(nil, "621_6487_button_pusher_prop")
                ent:RedirectOutput("OnUser4", "OpenRussellDoor", ent)

                SendToConsole("ent_fire gg_training_start_trigger kill")

                ent = Entities:FindByName(nil, "glove_dispenser_brush")
                ent:RedirectOutput("OnUser4", "EquipGravityGloves", ent)

                ent = Entities:FindByName(nil, "trigger_heli_flyby2")
                ent:RedirectOutput("OnTrigger", "GivePistol", ent)

                ent = Entities:FindByName(nil, "relay_weapon_pistol_fakefire")
                ent:RedirectOutput("OnTrigger", "RedirectPistol", ent)
            else
                SendToConsole("hidehud 64")
                SendToConsole("r_drawviewmodel 1")
                Entities:GetLocalPlayer():Attribute_SetIntValue("gravity_gloves", 1)
				
				-- Mod support for Extra-Ordinary Value
				if GetMapName() == "youreawake" then
					isModActive = true
					ent = Entities:FindByName(nil, "1931_headset")
					if ent then
						ent:RedirectOutput("OnUser4", "ModExtraOrdinaryValue_EquipHeadset", ent)
					end
				elseif GetMapName() == "seweroutskirts" then
					isModActive = true
					SendToConsole("bind F inv_flashlight") -- too dark on some places
					if not loading_save_file then -- Start point is bugged here
						SendToConsole("setpos_exact -40 -496 105") 
					end
				elseif GetMapName() == "facilityredux" then
					isModActive = true
					SendToConsole("bind F inv_flashlight")
					if not loading_save_file then -- Start point is bugged here
						SendToConsole("setpos_exact -1734 -736 260") 
					end
					ent = Entities:FindByName(nil, "2461_inside_elevator_button")
					ent:RedirectOutput("OnUser4", "ModExtraOrdinaryValue_UseElevator", ent)
					
					local i = 0
					while i < 6 do -- Replace VR boxes to get player collision
						ModExtraOrdinaryValue_ReplacePhysicsBoxes()
						i = i + 1
					end
					
					ent = Entities:FindByName(nil, "2826_95_door_reset")
					ent:RedirectOutput("OnUser4", "ModExtraOrdinaryValue_UseFenceDoorSkip", ent)
				elseif GetMapName() == "helloagain" then
					isModActive = true
					SendToConsole("bind F inv_flashlight")
					ent = Entities:FindByName(nil, "393_elev_button_elevator")
					ent:RedirectOutput("OnUser4", "ModExtraOrdinaryValue_Map4UseElevatorButton", ent)
				-- Mod support for Overcharge
				elseif GetMapName() == "mc1_higgue" then
					isModActive = true
					SendToConsole("hl2_sprintspeed 180") -- pass jump on the end
					SendToConsole("bind F inv_flashlight")
					if not loading_save_file then
						SendToConsole("r_drawviewmodel 0")
						SendToConsole("hidehud 96")
					end
					ent = Entities:FindByName(nil, "introSEQ_button1_p")
					ent:RedirectOutput("OnUser4", "ModOvercharge_StartUseElevatorButton", ent)
					ent = Entities:FindByName(nil, "fightfinale_entry_button")
					ent:RedirectOutput("OnUser4", "ModOvercharge_UseFinaleEntryButton", ent)
					ent = Entities:FindByName(nil, "fightfinale_lift_button")
					ent:RedirectOutput("OnUser4", "ModOvercharge_UseFinaleLiftButton", ent)
					ent = Entities:FindByName(nil, "fightfinale_lift_intbutton")
					ent:RedirectOutput("OnUser4", "ModOvercharge_UseFinaleLiftIntButton", ent)
					ent = Entities:FindByName(nil, "fightfinale_end_button")
					ent:RedirectOutput("OnUser4", "ModOvercharge_UseFinaleEndButton", ent)
					ModOvercharge_AddClimbBox()
					ModOvercharge_AddClimbBox2()
				-- Mod support for Belomorskaya Station
				elseif GetMapName() == "belomorskaya" then
					isModActive = true
					ent = Entities:FindByName(nil, "857_button_pusher_prop")
					ent:RedirectOutput("OnUser4", "ModBelomorskaya_UseButton1", ent)
					
				-- Mod support for Levitation
				elseif GetMapName() == "01_intro" then
					isModActive = true
					SendToConsole("r_drawviewmodel 0")
					SendToConsole("hidehud 96") -- hide hud for intro
					--SendToConsole("ent_fire player_speedmod ModifySpeed 0")
					ent = Entities:FindByName(nil, "teleported") -- TODO doesn't work
					ent:RedirectOutput("OnTrigger", "ModLevitation_AllowMovement", ent)
				elseif GetMapName() == "02_notimelikenow" then
					isModActive = true
					if not loading_save_file then -- Start point collisions can be bugged here
						SendToConsole("setpos_exact -304.557 331.460 -761")
					end
					ent = Entities:FindByName(nil, "43250_button_pusher_prop")
					ent:RedirectOutput("OnUser4", "ModLevitation_PushUselessLiftButton", ent)
				elseif GetMapName() == "03_metrodynamo" then
					isModActive = true
				elseif GetMapName() == "04_hehungers" then
					isModActive = true
					SendToConsole("bind F inv_flashlight")
					if not loading_save_file then -- Start point collisions can be bugged here
						SendToConsole("setpos_exact 0.472 442.295 -100") 
					end
					ModLevitation_SpawnWorkaroundBottlesForJeff()
					ent = Entities:FindByName(nil, "43879_button_pusher_prop")
					ent:RedirectOutput("OnUser4", "ModLevitation_Map4PushLiftButton", ent)
					-- TODO: Hand covering mouth script required to be here!
				elseif GetMapName() == "05_pleasantville" then
					isModActive = true
					SendToConsole("bind F inv_flashlight")
					if not loading_save_file then -- Start point is bugged here
						SendToConsole("setpos_exact 868.050 -2345.072 7560") 
					end
					ent = Entities:FindByName(nil, "29473_button_pusher_prop")
					ent:RedirectOutput("OnUser4", "ModLevitation_Map5PushWaterBottlesButton", ent)
					ent = Entities:FindByName(nil, "29494_button_pusher_prop")
					ent:RedirectOutput("OnUser4", "ModLevitation_Map5PushSecretButton", ent)
					ent = Entities:FindByName(nil, "29732_button_pusher_prop")
					ent:RedirectOutput("OnUser4", "ModLevitation_Map5PushEndButton", ent)
				elseif GetMapName() == "06_digdeep" then
					isModActive = true
					SendToConsole("bind F inv_flashlight")
					if not loading_save_file then -- Start point is bugged here
						SendToConsole("setpos_exact 504.324 -3157.083 631") 
					end
					ent = Entities:FindByName(nil, "28212_button_pusher_prop")
					ent:RedirectOutput("OnUser4", "ModLevitation_Map6PushElevatorButton", ent)
					ent = Entities:FindByName(nil, "relay_vort_magic")
					ent:RedirectOutput("OnTrigger", "ModLevitation_Map6EndingTransition", ent)
				elseif GetMapName() == "07_sectorx" then
					isModActive = true
					SendToConsole("bind F inv_flashlight")
					if not loading_save_file then -- Start point is misplaced
						SendToConsole("setpos_exact 1212.703 -2168.029 -230") 
						SendToConsole("ent_create env_message { targetname text_vortenergy message VORTENERGY }")
						ModLevitation_Map7SpawnWorkaroundBattery()
						ModLevitation_Map7SpawnWorkaroundBattery2()
						ModLevitation_Map7SpawnWorkaroundJumpStructure()
					end
					ent = Entities:FindByName(nil, "novr_workaround_battery")
					ent:RedirectOutput("OnUser4", "ModLevitation_Map7PlayerTakeNoVRBattery", ent)
					ent = Entities:FindByName(nil, "novr_workaround_battery2")
					ent:RedirectOutput("OnUser4", "ModLevitation_Map7PlayerTakeNoVRBattery2", ent)
					ent = Entities:FindByName(nil, "airlock_ceilingdevices_start")
                    ent:RedirectOutput("OnTrigger", "ModLevitation_Map7EnterCombineTrap", ent)
					ent = Entities:FindByName(nil, "airlock_ceilingdevices_stop")
                    ent:RedirectOutput("OnTrigger", "GiveVortEnergy", ent)
					ent:RedirectOutput("OnTrigger", "ShowVortEnergyTutorial", ent)
					ent = Entities:FindByName(nil, "end_relay") -- TODO need other trigger
                    ent:RedirectOutput("OnTrigger", "ModLevitation_RemoveVortPowers", ent)
				elseif GetMapName() == "08_burningquestions" then
					isModActive = true
					SendToConsole("bind F inv_flashlight")
					SendToConsole("r_drawviewmodel 0")
					if not loading_save_file then -- Start point is misplaced
						SendToConsole("setpos_exact -465.745 -540.543 -9209") 
						SendToConsole("ent_create env_message { targetname text_vortenergy message VORTENERGY }")
					end
					ent = Entities:FindByName(nil, "plug_console_starter_lever")
                    ent:RedirectOutput("OnUser4", "ModLevitation_Map8Lever", ent)
					ent = Entities:FindByName(nil, "end_fight_relay")
					if ent then
						ent:RedirectOutput("OnTrigger", "GiveVortEnergy", ent)
						ent:RedirectOutput("OnTrigger", "ShowVortEnergyTutorial", ent)
                    end
					ent = Entities:FindByName(nil, "finish_relay")
					if ent then
						ent:RedirectOutput("OnTrigger", "ModLevitation_RemoveVortPowers", ent)
                    end
					ent = Entities:FindByName(nil, "pre_finale_gman")
                    ent:RedirectOutput("OnTrigger", "ModLevitation_Map8FinaleStopMove", ent)
				elseif isModActive == false then -- Default NoVR-mod weapon rule
					SendToConsole("give weapon_pistol")
				end

                if GetMapName() == "a2_quarantine_entrance" then
                    if not loading_save_file then
                        ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["renderamt"]=0, ["model"]="models/props/plastic_container_1.vmdl", ["origin"]="-2100.494 2792.368 200.265", ["angles"]="0 -37.1 0", ["parentname"]="puzzle_crate"})

                        ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER2_TITLE"})
                        DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)

                        SendToConsole("setpos 3215 2456 465")
                        SendToConsole("ent_fire traincar_border_trigger Disable")
                    end
                elseif GetMapName() == "a2_pistol" then
                    SendToConsole("ent_fire *_rebar EnablePickup")
                elseif GetMapName() == "a2_headcrabs_tunnel" then
                    if not loading_save_file then
                        ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER3_TITLE"})
                        DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)
                    end

                    ent = Entities:GetLocalPlayer()
                    if ent:Attribute_GetIntValue("has_flashlight", 0) == 1 then
                        SendToConsole("bind F inv_flashlight")
                    end
                elseif GetMapName() ~= "a2_hideout" then
                    SendToConsole("bind F inv_flashlight")
                    SendToConsole("give weapon_shotgun")

                    if GetMapName() == "a2_drainage" then
                        SendToConsole("ent_fire wheel2_socket setscale 4")
                    elseif GetMapName() == "a3_hotel_interior_rooftop" then
                        ent = Entities:FindByClassname(nil, "npc_headcrab_runner")
                        if not ent then
                            SendToConsole("ent_create npc_headcrab_runner { origin \"1657 -1949 710\" }")
                        end
                    elseif GetMapName() == "a3_station_street" then
                        if not loading_save_file then
                            ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER4_TITLE"})
                            DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)
                        end
                    elseif GetMapName() == "a3_hotel_lobby_basement" then
                        if not loading_save_file then
                            ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER5_TITLE"})
                            DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)
                        end
                    elseif GetMapName() == "a3_hotel_street" then
                        SendToConsole("ent_fire item_hlvr_weapon_tripmine OnHackSuccessAnimationComplete")
                        ent = Entities:FindByClassnameNearest("item_hlvr_weapon_tripmine", Vector(775, 1677, 248), 10)
                        if ent then
                            ent:Kill()
                        end
                        ent = Entities:FindByClassnameNearest("item_hlvr_weapon_tripmine", Vector(1440, 1306, 331), 10)
                        if ent then
                            ent:Kill()
                        end
                    elseif GetMapName() == "a3_c17_processing_plant" then
                        SendToConsole("ent_fire item_hlvr_weapon_tripmine OnHackSuccessAnimationComplete")

                        if not loading_save_file then
                            ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER6_TITLE"})
                            DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)
                        end

                        ent = Entities:FindByClassnameNearest("item_hlvr_weapon_tripmine", Vector(-896, -3768, 348), 10)
                        if ent then
                            ent:Kill()
                        end
                        ent = Entities:FindByClassnameNearest("item_hlvr_weapon_tripmine", Vector(-1165, -3770, 158), 10)
                        if ent then
                            ent:Kill()
                        end
                        ent = Entities:FindByClassnameNearest("item_hlvr_weapon_tripmine", Vector(-1105, -4058, 163), 10)
                        if ent then
                            ent:Kill()
                        end
                    elseif GetMapName() == "a3_distillery" then
                        SendToConsole("bind h +covermouth")

                        if not loading_save_file then
                            if not loading_save_file then
                                ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER7_TITLE"})
                                DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)
                            end

                            ent = Entities:FindByName(nil, "11578_2547_relay_koolaid_setup")
                            ent:RedirectOutput("OnTrigger", "FixJeffBatteryPuzzle", ent)

                            -- Hand for covering mouth animation
                            local viewmodel = Entities:FindByClassname(nil, "viewmodel")
                            local viewmodel_pos = viewmodel:GetAbsOrigin()
                            local viewmodel_ang = viewmodel:GetAngles()
                            ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["targetname"]="lefthand", ["model"]="models/hands/alyx_glove_left.vmdl", ["origin"]= viewmodel_pos.x - 24 .. " " .. viewmodel_pos.y .. " " .. viewmodel_pos.z - 4, ["angles"]= viewmodel_ang.x .. " " .. viewmodel_ang.y - 90 .. " " .. viewmodel_ang.z })
                            DoEntFire("lefthand", "SetParent", "!activator", 0, viewmodel, nil)
                            DoEntFire("lefthand", "Disable", "", 0, nil, nil)
                        end
                    else
                        SendToConsole("bind h \"\"")

                        if GetMapName() == "a4_c17_zoo" then
                            if not loading_save_file then
                                ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER8_TITLE"})
                                DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)
                            end

                            ent = Entities:FindByName(nil, "relay_power_receive")
                            ent:RedirectOutput("OnTrigger", "MakeLeverUsable", ent)

                            ent = Entities:FindByClassnameNearest("trigger_multiple", Vector(5380, -1848, -117), 10)
                            ent:RedirectOutput("OnStartTouch", "CrouchThroughZooHole", ent)

                            SendToConsole("ent_fire port_health_trap Disable")
                            SendToConsole("ent_fire health_trap_locked_door Unlock")
                            SendToConsole("ent_fire 589_toner_port_5 Disable")
                            SendToConsole("@prop_phys_portaloo_door DisablePickup")
                        elseif GetMapName() == "a4_c17_tanker_yard" then
                            SendToConsole("ent_fire elev_hurt_player_* Kill")

                            if not loading_save_file then
                                ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER9_TITLE"})
                                DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)
                            end
                        elseif GetMapName() == "a4_c17_water_tower" then
                            if not loading_save_file then
                                ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER10_TITLE"})
                                DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)
                            end
                        elseif GetMapName() == "a4_c17_parking_garage" then
                            SendToConsole("ent_fire falling_cabinet_door DisablePickup")

                            ent = Entities:FindByName(nil, "relay_ufo_beam_surge")
                            ent:RedirectOutput("OnTrigger", "UnequipCombinGunMechanical", ent)

                            ent = Entities:FindByName(nil, "relay_enter_ufo_beam")
                            ent:RedirectOutput("OnTrigger", "EnterVaultBeam", ent)
                        elseif GetMapName() == "a5_vault" then
                            SendToConsole("ent_fire player_speedmod ModifySpeed 1")
                            SendToConsole("ent_remove weapon_pistol;ent_remove weapon_shotgun;ent_remove weapon_ar2")
                            SendToConsole("r_drawviewmodel 0")

                            if not loading_save_file then
                                ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER11_TITLE"})
                                DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)

                                SendToConsole("ent_create env_message { targetname text_vortenergy message VORTENERGY }")
                            end

                            ent = Entities:FindByName(nil, "longcorridor_outerdoor1")
                            ent:RedirectOutput("OnFullyClosed", "GiveVortEnergy", ent)
                            ent:RedirectOutput("OnFullyClosed", "ShowVortEnergyTutorial", ent)

                            ent = Entities:FindByName(nil, "longcorridor_innerdoor")
                            ent:RedirectOutput("OnFullyClosed", "RemoveVortEnergy", ent)

                            ent = Entities:FindByName(nil, "longcorridor_energysource_01_activate_relay")
                            ent:RedirectOutput("OnTrigger", "GiveVortEnergy", ent)
                        elseif GetMapName() == "a5_ending" then
                            SendToConsole("ent_remove weapon_pistol;ent_remove weapon_shotgun;ent_remove weapon_ar2")
                            SendToConsole("r_drawviewmodel 0")
                            SendToConsole("bind F \"\"")

                            ent = Entities:FindByName(nil, "relay_advisor_void")
                            ent:RedirectOutput("OnTrigger", "GiveAdvisorVortEnergy", ent)

                            ent = Entities:FindByName(nil, "relay_first_credits_start")
                            ent:RedirectOutput("OnTrigger", "StartCredits", ent)

                            ent = Entities:FindByName(nil, "vcd_ending_eli")
                            ent:RedirectOutput("OnTrigger3", "EndCredits", ent)
                        end
                    end
                end
            end
        end
    end, nil)

    function GoToMainMenu(a, b)
        SendToConsole("setpos_exact 805 -80 -26")
        SendToConsole("setang_exact -5 0 0")
        SendToConsole("mouse_disableinput 0")
        SendToConsole("hidehud 96")
    end

    function MoveFreely(a, b)
        SendToConsole("mouse_disableinput 0")
        SendToConsole("ent_fire player_speedmod ModifySpeed 1")
        SendToConsole("hidehud 96")
    end

    function AcceptEliCall(a, b)
        SendToConsole("ent_fire call_button_relay trigger")
    end

    function OpenGreenhouseDoor(a, b)
        local ent = Entities:FindByName(nil, "greenhouse_door")
        if string.format("%.2f", ent:GetCycle()) == "0.05" then
            SendToConsole("ent_fire greenhouse_door playanimation alyx_door_open")
        end
    end

    function OpenElevator(a, b)
        SendToConsole("ent_fire debug_roof_elevator_call_relay trigger")
    end

    function RideElevator(a, b)
        SendToConsole("ent_fire debug_elevator_relay trigger")
    end

    function EnterCombineElevator(a, b)
        SendToConsole("fadein 0.2")
        SendToConsole("setpos_exact 574 -2328 -115")
        SendToConsole("ent_setpos 581 540.885 -2331.526 -71.911")
    end

    function OpenCombineElevator(a, b)
        SendToConsole("ent_fire debug_choreo_start_relay trigger")
    end

    function GetOutOfCrashedVan(a, b)
        SendToConsole("fadein 0.2")
        SendToConsole("setpos_exact -1408 2307 -104")
        SendToConsole("ent_fire 4962_car_door_left_front open")
    end

    function RedirectHeadset(a, b)
        local ent = Entities:FindByName(nil, "russell_headset")
        ent:RedirectOutput("OnUser4", "EquipHeadset", ent)
    end

    function EquipHeadset(a, b)
        SendToConsole("ent_fire debug_relay_put_on_headphones trigger")
        SendToConsole("ent_fire 4962_car_door_left_front close")
    end

    function ToggleCarDoor(a, b)
        SendToConsole("ent_fire 4962_car_door_left_front toggle")
    end

    function ClimbBalconyLadder(a, b)
        ClimbLadderSound()
        SendToConsole("fadein 0.2")
        SendToConsole("setpos_exact -1296 576 80")
    end

    function ClimbCellarLadder(a, b)
        ClimbLadderSound()
        SendToConsole("ent_fire cellar_ladder SetCompletionValue 1")
        SendToConsole("fadein 0.2")
        SendToConsole("setpos_exact 1004 1775 546")
    end

    function ClimbLarryLadder(a, b)
        ClimbLadderSound()
        SendToConsole("ent_fire larry_ladder SetCompletionValue 1")
        SendToConsole("fadein 0.2")
        SendToConsole("ent_fire relay_debug_intro_trench trigger")
    end

    function ClimbGarageLadder(a, b)
        ClimbLadderSound()
        SendToConsole("ent_fire toner_sliding_ladder SetCompletionValue 1")
        SendToConsole("fadein 0.2")
        SendToConsole("setpos_exact -367 -416 150")
    end

    function OpenRussellWindow(a, b)
        SendToConsole("fadein 0.2")
        SendToConsole("ent_fire russell_entry_window SetCompletionValue 1")
        SendToConsole("setpos -1728 275 100")
    end

    function OpenRussellDoor(a, b)
        SendToConsole("ent_fire 621_6487_button_branch test")
    end

    function EquipGravityGloves(a, b)
        SendToConsole("ent_fire relay_give_gravity_gloves trigger")
        SendToConsole("hidehud 1")
        Entities:GetLocalPlayer():Attribute_SetIntValue("gravity_gloves", 1)
    end

    function RedirectPistol(a, b)
        ent = Entities:FindByName(nil, "weapon_pistol")
        ent:RedirectOutput("OnPlayerPickup", "EquipPistol", ent)
    end

    function GivePistol(a, b)
        SendToConsole("ent_fire pistol_give_relay trigger")
    end

    function EquipPistol(a, b)
        SendToConsole("ent_fire_output weapon_equip_listener oneventfired")
        SendToConsole("hidehud 64")
        SendToConsole("r_drawviewmodel 1")
        SendToConsole("ent_fire item_hlvr_weapon_energygun kill")
    end

    function MakeLeverUsable(a, b)
        ent = Entities:FindByName(nil, "door_reset")
        ent:Attribute_SetIntValue("used", 0)
    end

    function CrouchThroughZooHole(a, b)
        SendToConsole("fadein 0.2")
        SendToConsole("setpos 5393 -1960 -125")
    end

    function ClimbLadderSound()
        local sounds = 0
        local player = Entities:GetLocalPlayer()
        player:SetThink(function()
            if sounds < 3 then
                SendToConsole("snd_sos_start_soundevent Step_Player.Ladder_Single")
                sounds = sounds + 1
                return 0.15
            end
        end, "LadderSound", 0)
    end

    function FixJeffBatteryPuzzle()
        SendToConsole("ent_fire @barnacle_battery kill")
        SendToConsole("ent_create item_hlvr_prop_battery { origin \"959 1970 427\" }")
        SendToConsole("ent_fire @crank_battery kill")
        SendToConsole("ent_create item_hlvr_prop_battery { origin \"1325 2245 435\" }")
        SendToConsole("ent_fire 11478_6233_math_count_wheel_installment SetHitMax 1")
    end

    function ShowSprintTutorial()
        SendToConsole("ent_fire text_sprint ShowMessage")
        SendToConsole("play play sounds/ui/beepclear.vsnd")
    end

    function ShowCrouchJumpTutorial()
        SendToConsole("ent_fire text_crouchjump ShowMessage")
        SendToConsole("play play sounds/ui/beepclear.vsnd")
    end

    function UnequipCombinGunMechanical()
        SendToConsole("ent_fire player_speedmod ModifySpeed 1")
        SendToConsole("ent_fire combine_gun_mechanical ClearParent")
        SendToConsole("bind MOUSE1 +attack")
        local ent = Entities:FindByName(nil, "combine_gun_mechanical")
        SendToConsole("ent_setpos " .. ent:entindex() .. " 1479.722 385.634 964.917")
        SendToConsole("r_drawviewmodel 1")
    end

    function EnterVaultBeam()
        SendToConsole("ent_remove weapon_pistol;ent_remove weapon_shotgun;ent_remove weapon_ar2;ent_remove weapon_frag")
        SendToConsole("r_drawviewmodel 0")
        SendToConsole("hidehud 4")
        SendToConsole("ent_fire player_speedmod ModifySpeed 0")
    end

    function ShowVortEnergyTutorial()
        SendToConsole("ent_fire text_vortenergy ShowMessage")
        SendToConsole("play play sounds/ui/beepclear.vsnd")
    end

    function GiveVortEnergy(a, b)
        SendToConsole("bind MOUSE1 shootvortenergy")
        SendToConsole("ent_remove weapon_pistol;ent_remove weapon_shotgun;ent_remove weapon_ar2;ent_remove weapon_frag")
        SendToConsole("r_drawviewmodel 0")
    end

    function RemoveVortEnergy(a, b)
        SendToConsole("bind MOUSE1 +attack")
        SendToConsole("r_drawviewmodel 1")
        SendToConsole("give weapon_frag")
    end

    function GiveAdvisorVortEnergy(a, b)
        SendToConsole("bind MOUSE1 shootadvisorvortenergy")
    end

    function StartCredits(a, b)
        SendToConsole("mouse_disableinput 1")
    end

    function EndCredits(a, b)
        SendToConsole("mouse_disableinput 0")
    end
	
	function ModExtraOrdinaryValue_EquipHeadset(a, b)
		StartSoundEventFromPosition("RadioHeadset.PutOn", Entities:GetLocalPlayer():EyePosition())
		SendToConsole("ent_fire_output 1931_headset onputonheadset trigger")
		SendToConsole("ent_fire 1931_headset kill")
	end

	function ModExtraOrdinaryValue_UseElevator(a, b)
		SendToConsole("ent_fire 2461_elev_button_elevator press")
	end

	function ModExtraOrdinaryValue_ReplacePhysicsBoxes() 
		ent = Entities:FindByClassnameNearest("prop_physics", Vector(186,237,-1035), 60)
		if ent then
			SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["alpha"]=0, ["model"]=ent:GetModelName(), ["origin"]=ent:GetOrigin(), ["angles"]=ent:GetAngles(), ["skin"]=0})
			ent:Kill() -- Remove VR physics box
		end
	end

	function ModExtraOrdinaryValue_UseFenceDoorSkip(a, b) 
		SendToConsole("ent_fire_output 2826_95_relay_power_receive OnTrigger")
		SendToConsole("ent_fire_output 2826_95_relay_flip_switch OnTrigger")
	end

	function ModExtraOrdinaryValue_Map4UseElevatorButton(a, b)
		SendToConsole("ent_fire 393_elev_button_elevator press")
	end

	function ModOvercharge_StartUseElevatorButton(a, b)
		SendToConsole("ent_fire_output introseq_button1 onin")
		SendToConsole("hidehud 64")
		SendToConsole("r_drawviewmodel 1")
		SendToConsole("give weapon_pistol") -- Pistol on start
	end

	function ModOvercharge_AddClimbBox()
		SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["alpha"]=0, ["model"]="models/props/plastic_container_1.vmdl", ["origin"]="-1800.434 314.410 56", ["angles"]="0 1 0", ["skin"]=4})
		SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["alpha"]=0, ["model"]="models/props/plastic_container_1.vmdl", ["origin"]="-1800.434 310.410 89", ["angles"]="0 31 0", ["skin"]=4})
	end

	function ModOvercharge_AddClimbBox2()
		SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["alpha"]=0, ["model"]="models/props/plastic_container_1.vmdl", ["origin"]="1234.502 -821.553 -264", ["angles"]="0 1 0", ["skin"]=4})
	end

	function ModOvercharge_UseFinaleEntryButton(a, b)
		StartSoundEventFromPosition("Button_Basic.Press", Entities:GetLocalPlayer():EyePosition())
		SendToConsole("ent_fire_output fightfinale_entry_relay ontrigger")
	end

	function ModOvercharge_UseFinaleLiftButton(a, b)
		StartSoundEventFromPosition("Button_Basic.Press", Entities:GetLocalPlayer():EyePosition())
		SendToConsole("ent_fire_output fightfinale_lift_button onin")
	end

	function ModOvercharge_UseFinaleLiftIntButton(a, b)
		StartSoundEventFromPosition("Button_Basic.Press", Entities:GetLocalPlayer():EyePosition())
		SendToConsole("ent_fire_output fightfinale_lift_intbutton onin")
	end

	function ModOvercharge_UseFinaleEndButton(a, b)
		StartSoundEventFromPosition("Button_Basic.Press", Entities:GetLocalPlayer():EyePosition())
		SendToConsole("ent_fire_output fightfinale_end_button onin")
		SendToConsole("r_drawviewmodel 0")
		SendToConsole("hidehud 4")
		SendToConsole("ent_fire player_speedmod ModifySpeed 0")
		SendToConsole("bind MOUSE1 \"\"")
	end

	function ModBelomorskaya_UseButton1(a, b)
		SendToConsole("ent_fire_output 857_button_center_pusher onin")
	end
	
	function ModLevitation_AllowMovement(a, b)
		SendToConsole("ent_fire player_speedmod ModifySpeed 1")
	end
	
	function ModLevitation_PushUselessLiftButton(a, b)
		StartSoundEventFromPosition("Button_Basic.Press", Entities:GetLocalPlayer():EyePosition())
	end
	
	function ModLevitation_SpawnWorkaroundBottlesForJeff()
		SpawnEntityFromTableSynchronous("prop_physics", {["solid"]=6, ["model"]="models/props/beer_bottle_1.vmdl", ["origin"]="-102.158 -4415.675 -151"})
		SpawnEntityFromTableSynchronous("prop_physics", {["solid"]=6, ["model"]="models/props/beer_bottle_1.vmdl", ["origin"]="-102.158 -4410.675 -151"})
	end
	
	function ModLevitation_Map4PushLiftButton(a, b)
		SendToConsole("ent_fire_output 43879_button_center_pusher onin")
	end
	
	function ModLevitation_Map5PushWaterBottlesButton(a, b)
		SendToConsole("ent_fire_output 29473_button_center_pusher onin")
	end
	
	function ModLevitation_Map5PushSecretButton(a, b)
		StartSoundEventFromPosition("Button_Basic.Press", Entities:GetLocalPlayer():EyePosition())
		SendToConsole("ent_fire_output 29494_button_center_pusher onin")
	end
	
	function ModLevitation_Map5SpawnWorkaroundJumpStructure()
		SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["model"]="models/props/tanks/vertical_tank.vmdl", ["origin"]="685.276 -701.073 7780", ["angles"]="0 0 0"})
		SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["model"]="models/props/industrial_small_tank_1.vmdl", ["origin"]="685.276 -701.073 7720", ["angles"]="0 0 0", ["skin"]=2})
		SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["model"]="models/props/industrial_small_tank_1.vmdl", ["origin"]="685.276 -701.073 7723", ["angles"]="0 0 180", ["skin"]=2})
	end
	
	function ModLevitation_Map5PushEndButton(a, b)
		SendToConsole("ent_fire_output 29732_button_center_pusher onin")
	end
	
	function ModLevitation_Map6PushElevatorButton(a, b)
		StartSoundEventFromPosition("Button_Basic.Press", Entities:GetLocalPlayer():EyePosition())
		SendToConsole("ent_fire_output 28212_button_center_pusher onin")
	end
	
	function ModLevitation_Map6EndingTransition(a, b)
		SendToConsole("r_drawviewmodel 0")
		SendToConsole("hidehud 4")
		SendToConsole("bind MOUSE1 \"\"")
	end
	
	function ModLevitation_Map7SpawnWorkaroundBattery()
		SpawnEntityFromTableSynchronous("item_hlvr_prop_battery", {["targetname"]="novr_workaround_battery", ["solid"]=6, ["origin"]="1121.042 -530.784 344"})
	end
	
	function ModLevitation_Map7PlayerTakeNoVRBattery()
		SendToConsole("ent_fire 8621_powerunit_relay_reviver_removed trigger")
	end
	
	function ModLevitation_Map7SpawnWorkaroundBattery2()
		SpawnEntityFromTableSynchronous("item_hlvr_prop_battery", {["targetname"]="novr_workaround_battery2", ["solid"]=6, ["origin"]="-666.762 493.066 -439.9"})
	end
	
	function ModLevitation_Map7PlayerTakeNoVRBattery2()
		SendToConsole("ent_fire 10554_powerunit_relay_reviver_removed trigger")
	end
	
	function ModLevitation_Map7SpawnWorkaroundJumpStructure()
		SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["alpha"]=0, ["model"]="models/props/plastic_container_1.vmdl", ["origin"]="-264.164 -1015.459 486", ["angles"]="0 0 0", ["skin"]=0})
		SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["alpha"]=0, ["model"]="models/props/plastic_container_1.vmdl", ["origin"]="-268.164 -1015.459 518.5", ["angles"]="0 21 0", ["skin"]=0})
		SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["alpha"]=0, ["model"]="models/props/plastic_container_1.vmdl", ["origin"]="-270.164 -1015.459 551", ["angles"]="0 7 0", ["skin"]=0})
		SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["alpha"]=0, ["model"]="models/props/plastic_container_1.vmdl", ["origin"]="-272.164 -1015.459 583.5", ["angles"]="0 -12 0", ["skin"]=0})
	end
	
	function ModLevitation_Map7EnterCombineTrap()
        SendToConsole("ent_remove weapon_pistol;ent_remove weapon_shotgun;ent_remove weapon_smg1;ent_remove weapon_frag")
        SendToConsole("r_drawviewmodel 0")
    end
	
	function ModLevitation_RemoveVortPowers(a, b)
		SendToConsole("bind MOUSE1 \"\"")
	end
	
	function ModLevitation_Map8Lever(a, b)
		SendToConsole("ent_fire_output lever_relay ontrigger")
	end
	
	function ModLevitation_Map8FinaleStopMove(a, b)
		SendToConsole("hidehud 4")
		SendToConsole("ent_fire player_speedmod ModifySpeed 0")
	end
end