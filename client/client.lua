local RSGCore = exports['rsg-core']:GetCoreObject()
-- Tables --
local pedstable = {}
local promptstable = {}
local blipsTable = {}
local JobsDone = {}
local JobCount = 0
local DropCount = 0
local BlipScale = 0.10

-- Checks --
local hasJob = false
local PickedUp = false
local AttachedProp = false

-- Blips & Prompts --
local dropBlip
local jobBlip
local closestJob = {}

-----------------------------------------
-------------- EXTRA --------------------
-----------------------------------------
-- REMOVE PROPS COMMAND --
if Config.StuckPropCommand then
    RegisterCommand('propstuck', function()
        for k, v in pairs(GetGamePool('CObject')) do
            if IsEntityAttachedToEntity(PlayerPedId(), v) then
                SetEntityAsMissionEntity(v, true, true)
                DeleteObject(v)
                DeleteEntity(v)
            end
        end
    end)
end

--------------------------------------
-------------- FUNCTIONS -------------
--------------------------------------

local function PickupBrickLocation()
    local player = PlayerPedId()
    local playercoords = GetEntityCoords(player)
    PickupLocation = math.random(1, #Config.Locations[closestJob]["BrickLocations"])

    if Config.Prints then
        print(closestJob)
    end

    jobBlip = N_0x554d9d53f696d002(1664425300, Config.Locations[closestJob]["BrickLocations"][PickupLocation].coords.x, Config.Locations[closestJob]["BrickLocations"][PickupLocation].coords.y, Config.Locations[closestJob]["BrickLocations"][PickupLocation].coords.z)

    SetBlipSprite(jobBlip, 1116438174, 1)
    SetBlipScale(jobBlip, 0.05)

    RSGCore.Functions.Notify('Go Grab A Brick', 'error')
    --TriggerEvent('rNotify:NotifyLeft', "          Go grab a brick", "", "generic_textures", "tick", 4500)
end

local function DropBrickLocation()
    local player = PlayerPedId()
    local playercoords = GetEntityCoords(player)
    DropLocation = math.random(1, #Config.Locations[closestJob]["DropLocations"])

    dropBlip = N_0x554d9d53f696d002(1664425300, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.x, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.y, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.z)

    SetBlipSprite(dropBlip, 1116438174, 0.5)
    SetBlipScale(dropBlip, 0.10)

    RSGCore.Functions.Notify('Head Over To Where This Brick Is Needed', 'error')
end

--------------------------------------
--------------- THREADS --------------
--------------------------------------
CreateThread(function()
	for _, v in pairs(Config.JobNpc) do
        local blip = N_0x554d9d53f696d002(1664425300, v["Pos"].x, v["Pos"].y, v["Pos"].z)
        SetBlipSprite(blip, 2305242038, 0.5)
		SetBlipScale(blip, 0.10)
		Citizen.InvokeNative(0x9CB1A1623062F402, blip, "Brick Layer Job")
    end
    table.insert(blipsTable, blip)
end)

CreateThread(function()
    while true do
        Wait(0)
        if hasJob then
            local player = PlayerPedId()
            local coords = GetEntityCoords(player)
            if not PickedUp then
                if GetDistanceBetweenCoords(coords, Config.Locations[closestJob]["BrickLocations"][PickupLocation].coords.x, Config.Locations[closestJob]["BrickLocations"][PickupLocation].coords.y, Config.Locations[closestJob]["BrickLocations"][PickupLocation].coords.z, true) < 1.3  then
                    DrawText3D(Config.Locations[closestJob]["BrickLocations"][PickupLocation].coords.x, Config.Locations[closestJob]["BrickLocations"][PickupLocation].coords.y, Config.Locations[closestJob]["BrickLocations"][PickupLocation].coords.z, "[G] | Pickup Brick")
                    if IsControlJustReleased(0, Config.Keys["G"]) then
                        TriggerEvent('danglr-bricklayer:PickupBrick')
                        Wait(1000)
                    end
                end
            elseif PickedUp and not IsPedRagdoll(PlayerPedId()) then
                if Config.DisableSprintJump then
                    DisableControlAction(0, 0x8FFC75D6, true) -- Shift
                    DisableControlAction(0, 0xD9D0E1C0, true) -- Spacebar
                end
                if GetDistanceBetweenCoords(coords, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.x, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.y, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.z, true) < 1.5  then
                    DrawText3D(Config.Locations[closestJob]["DropLocations"][DropLocation].coords.x, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.y, Config.Locations[closestJob]["DropLocations"][DropLocation].coords.z, "[G] | Place Brick")
                    if IsControlJustReleased(0, Config.Keys["G"]) then
                        TriggerEvent('danglr-bricklayer:DropBrick')
                    end
                end
            end
        end
    end
end)

--------------------------------------
--------------- EVENTS --------------
--------------------------------------

RegisterNetEvent('danglr-bricklayer:StartJob', function()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)

    if not hasJob then
        for k, v in pairs(Config.Locations) do
            if Config.Prints then
                print(k)
            end
            if GetDistanceBetweenCoords(coords, Config.Locations[k]["Location"].x, Config.Locations[k]["Location"].y, Config.Locations[k]["Location"].z, true) < 5 then
                closestJob = k
            end
        end
        PickupBrickLocation()
        hasJob = true

        if Config.Prints then
            print(hasJob)
        end

    else
        RSGCore.Functions.Notify('You already have this job!', 'error')
    end
end)

RegisterNetEvent('danglr-bricklayer:EndJob', function()
    if hasJob then
        hasJob = false
        JobCount = 0
        DropCount = 0

        RemoveBlip(jobBlip)
        RemoveBlip(dropBlip)

        if Config.Prints then
            print(hasJob)
        end
    end
    RSGCore.Functions.Notify('You have stopped working!', 'error')
    --TriggerEvent('rNotify:NotifyLeft', "You Have Finished The Job", "", "generic_textures", "tick", 4500)
end)

RegisterNetEvent('danglr-bricklayer:CollectPaycheck', function()
    print("Drop Count: "..DropCount)

    TriggerServerEvent('danglr-bricklayer:GetDropCount', DropCount)
    Wait(100)
    if DropCount ~= 0 then
        RSGCore.Functions.TriggerCallback('danglr-bricklayer:CheckIfPaycheckCollected', function(hasBeenPaid)
            if hasBeenPaid then
                TriggerEvent('danglr-bricklayer:EndJob')
                RSGCore.Functions.Notify('You have been paid for your work!', 'error')

                if Config.Prints then
                    print(hasBeenPaid)
                end

            else -- Paid the money after initial check IE attempted to exploit
                RSGCore.Functions.Notify('You have been paid for your work!', 'error')

                if Config.Prints then
                    print(hasBeenPaid)
                end

            end
        end, source)
    else
        RSGCore.Functions.Notify('You didn\'t do any work!', 'error')
    end
end)

RegisterNetEvent('danglr-bricklayer:PickupBrick', function()
    local coords = GetEntityCoords(PlayerPedId())
    if hasJob then
        if not PickedUp then
            PickedUp = true
            local BrickProp = CreateObject(GetHashKey("p_brick01x"), coords.x, coords.y, coords.z, 1, 0, 1)
            SetEntityAsMissionEntity(BrickProp, true, true)
            RequestAnimDict("mech_loco_m@generic@carry@ped@walk")
            while not HasAnimDictLoaded("mech_loco_m@generic@carry@ped@walk") do
                Wait(100)
            end
            TaskPlayAnim(PlayerPedId(), "mech_loco_m@generic@carry@ped@walk", "idle", 2.0, -2.0, -1, 67109393, 0.0, false, 1245184, false, "UpperbodyFixup_filter", false)
            Citizen.InvokeNative(0x6B9BBD38AB0796DF, BrickProp, PlayerPedId(), GetEntityBoneIndexByName(PlayerPedId(),"SKEL_L_Hand"), 0.1, 0.08, 0.07, 35.0, 90.0, 0, true, true, false, true, 1, true)
            AttachedProp = true                                                                                                 ---         X      Y     Z    90.0, 0 = angle of prop
            RemoveBlip(jobBlip)

            Wait(500)
            for _,v in pairs(promptstable) do
                PromptDelete(promptstable[v].PickupBrickPrompt)
            end

            DropBrickLocation()
        end
    end
end)

RegisterNetEvent('danglr-bricklayer:DropBrick', function()
    local coords = GetEntityCoords(PlayerPedId())
    
    if hasJob and DropCount <= Config.DropCount then
        -- REMOVES THE BRICK PROP --
        for k, v in pairs(GetGamePool('CObject')) do
            if IsEntityAttachedToEntity(PlayerPedId(), v) then
                SetEntityAsMissionEntity(v, true, true)
                DeleteObject(v)
                DeleteEntity(v)
            end
        end
        ClearPedTasks(PlayerPedId())
        Wait(100)
        PickedUp = false

        -- START ANIMATION --
        TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('world_player_dynamic_kneel'), -1, true, false, false, false)
        RSGCore.Functions.Progressbar("placebrick", "Placing Brick...", (Config.PlaceTime * 1000), false, true, {
            disableMovement = true,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done

            DropCount = DropCount + 1

            if Config.Prints then
                print("Drop Count: "..DropCount)
            end

            RemoveBlip(dropBlip)

            Wait(100)

            if DropCount < Config.DropCount then
                PickupBrickLocation()
            else
                RSGCore.Functions.Notify('Work Completed! Go Get Your Check', 'error') 
            end
        end) 
    else
        RSGCore.Functions.Notify('Work done! Collect Your Check!', 'error') 
    end
end)

--------------------------------------
--------------- JOB MENU -------------
--------------------------------------

RegisterNetEvent('danglr-bricklayer:OpenJobMenu', function()

    if not hasJob then

        jobMenu = {
            {
                header = "| Brick Layer Job |",
                isMenuHeader = true,
            },
            {
                header = "Start Brick Layer Job",
                txt = "",
                params = {
                    event = 'danglr-bricklayer:StartJob',
                }
            },
            {
                header = "Close Menu",
                txt = '',
                params = {
                    event = '[X] Close Menu',
                }
            },
        }

    elseif hasJob then

        jobMenu = {
            {
                header = "| Brick Layer Job |",
                isMenuHeader = true,
            },
            {
                header = "Finish Job",
                txt = "",
                params = {
                    event = 'danglr-bricklayer:CollectPaycheck',
                }
            },
            {
                header = "[X] Close Menu",
                txt = '',
                params = {
                    event = 'rsg-menu:closeMenu',
                }
            },
        }

    end

    exports['rsg-menu']:openMenu(jobMenu)
end)

--------------------------
------- PED SPAWNING -----
--------------------------

function SET_PED_RELATIONSHIP_GROUP_HASH ( iVar0, iParam0 )
    return Citizen.InvokeNative( 0xC80A74AC829DDD92, iVar0, _GET_DEFAULT_RELATIONSHIP_GROUP_HASH( iParam0 ) )
end

function _GET_DEFAULT_RELATIONSHIP_GROUP_HASH ( iParam0 )
    return Citizen.InvokeNative( 0x3CC4A718C258BDD0 , iParam0 );
end

function modelrequest( model )
    CreateThread(function()
        RequestModel( model )
    end)
end

CreateThread(function()
    for z, x in pairs(Config.JobNpc) do
        while not HasModelLoaded( GetHashKey(Config.JobNpc[z]["Model"]) ) do
            Wait(500)
            modelrequest( GetHashKey(Config.JobNpc[z]["Model"]) )
        end
        local npc = CreatePed(GetHashKey(Config.JobNpc[z]["Model"]), Config.JobNpc[z]["Pos"].x, Config.JobNpc[z]["Pos"].y, Config.JobNpc[z]["Pos"].z - 1, Config.JobNpc[z]["Heading"], false, false, 0, 0)
        while not DoesEntityExist(npc) do
            Wait(300)
        end
        exports['rsg-target']:AddTargetModel(Config.JobNpc[z]["Model"], {
            options = {
                {
                    type = "client",
                    event = "danglr-bricklayer:OpenJobMenu",
                    icon = "fas fa-person-digging",
                    style = "",
                    label = "Brick Job",
                },
            },
            distance = 2.5
        })
        Citizen.InvokeNative(0x283978A15512B2FE, npc, true)
        FreezeEntityPosition(npc, false)
        SetEntityInvincible(npc, true)
        TaskStandStill(npc, -1)
        Wait(100)
        SET_PED_RELATIONSHIP_GROUP_HASH(npc, GetHashKey(Config.JobNpc[z]["Model"]))
        SetEntityCanBeDamagedByRelationshipGroup(npc, false, `PLAYER`)
        SetEntityAsMissionEntity(npc, true, true)
        SetModelAsNoLongerNeeded(GetHashKey(Config.JobNpc[z]["Model"]))
        table.insert(pedstable, npc)

    end
end)

------------------------------------
------------ DRAWTEXT --------------
------------------------------------

function DrawText3D(x, y, z, text)
	local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
	local px,py,pz=table.unpack(GetGameplayCamCoord())
	local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
	local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
	if onScreen then
	  SetTextScale(0.30, 0.30)
	  SetTextFontForCurrentCommand(1)
	  SetTextColor(255, 255, 255, 215)
	  SetTextCentre(1)
	  DisplayText(str,_x,_y)
	  local factor = (string.len(text)) / 225
	  DrawSprite("feeds", "hud_menu_4a", _x, _y+0.0125,0.015+ factor, 0.03, 0.1, 35, 35, 35, 190, 0)
	end
end

------------------------------------
------- RESOURCE START / STOP -----
------------------------------------

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _,v in pairs(pedstable) do
            DeletePed(v)
        end
        for _,v in pairs(blipsTable) do
            RemoveBlip(v)
        end
        for k,_ in pairs(promptstable) do
			PromptDelete(promptstable[k].name)
		end
        RemoveBlip(jobBlip)
        RemoveBlip(dropBlip)
    end
end)
