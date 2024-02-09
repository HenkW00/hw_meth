ESX = exports["es_extended"]:getSharedObject()

local spawnedMeths = 0
local methPlants = {}
local isPickingUp, isProcessing = false, false

CreateThread(function() 
	while true do
		Wait(700)
		local coords = GetEntityCoords(PlayerPedId())

		if #(coords - Config.CircleZones.MethField.coords) < 50 then
			SpawnMethPlants()
		end
	end
end)

CreateThread(function()
	while true do
		local wait = 1000
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		if #(coords - Config.CircleZones.MethProcessing.coords) < 1 then
			wait = 2
			if not isProcessing then
				ESX.ShowHelpNotification(TranslateCap('meth_processprompt'))
			end

			if IsControlJustReleased(0, 38) and not isProcessing then
				ESX.TriggerServerCallback('hw_meth:meth_count', function(xMeth)
					if Config.LicenseEnable then
						ESX.TriggerServerCallback('hw_meth:checkLicense', function(hasProcessingLicense)
							if hasProcessingLicense then
								ProcessMeth(xMeth)
							else
								OpenBuyLicenseMenu('meth_processing')
							end
						end, GetPlayerServerId(PlayerId()), 'meth_processing')
					else
						ProcessMeth(xMeth)
					end
				end)
			end
		end
		Wait(wait)
	end
end)

function ProcessMeth(xMeth)
	isProcessing = true
	ESX.ShowNotification(TranslateCap('meth_processingstarted'))
  TriggerServerEvent('hw_meth:processMeth')
	if(xMeth <= 3) then
		xMeth = 0
	end
  local timeLeft = (Config.Delays.MethProcessing * xMeth) / 1000
	local playerPed = PlayerPedId()

	while timeLeft > 0 do
		Wait(1000)
		timeLeft = timeLeft - 1

		if #(GetEntityCoords(playerPed) - Config.CircleZones.MethProcessing.coords) > 4 then
			ESX.ShowNotification(TranslateCap('meth_processingtoofar'))
			TriggerServerEvent('hw_meth:cancelProcessing')
			TriggerServerEvent('hw_meth:outofbound')
			break
		end
	end

	isProcessing = false
end

CreateThread(function()
	while true do
		local Sleep = 1500

		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local nearbyObject, nearbyID

		for i=1, #methPlants, 1 do
			if #(coords - GetEntityCoords(methPlants[i])) < 1.5 then
				nearbyObject, nearbyID = methPlants[i], i
			end
		end

		if nearbyObject and IsPedOnFoot(playerPed) then
			Sleep = 0
			if not isPickingUp then
				ESX.ShowHelpNotification(TranslateCap('meth_pickupprompt'))
			end

			if IsControlJustReleased(0, 38) and not isPickingUp then
				isPickingUp = true

				ESX.TriggerServerCallback('hw_meth:canPickUp', function(canPickUp)
					if canPickUp then
						TaskStartScenarioInPlace(playerPed, 'world_human_gardener_plant', 0, false)

						Wait(2000)
						ClearPedTasks(playerPed)
						Wait(1500)
		
						ESX.Game.DeleteObject(nearbyObject)
		
						table.remove(methPlants, nearbyID)
						spawnedMeths = spawnedMeths - 1
		
						TriggerServerEvent('hw_meth:pickedUpMeth')
					else
						ESX.ShowNotification(TranslateCap('meth_inventoryfull'))
					end

					isPickingUp = false
				end, 'meth')
			end
		end
	Wait(Sleep)
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for k, v in pairs(methPlants) do
			ESX.Game.DeleteObject(v)
		end
	end
end)

function SpawnMethPlants()
	while spawnedMeths < 25 do
		Wait(0)
		local methCoords = GenerateMethCoords()

		ESX.Game.SpawnLocalObject('prop_rad_waste_barrel_01', methCoords, function(obj)
			PlaceObjectOnGroundProperly(obj)
			FreezeEntityPosition(obj, true)

			table.insert(methPlants, obj)
			spawnedMeths = spawnedMeths + 1
		end)
	end
end

function ValidateMethCoord(plantCoord)
	if spawnedMeths > 0 then
		local validate = true

		for k, v in pairs(methPlants) do
			if #(plantCoord - GetEntityCoords(v)) < 5 then
				validate = false
			end
		end

		if #(plantCoord - Config.CircleZones.MethField.coords) > 50 then
			validate = false
		end

		return validate
	else
		return true
	end
end

function GenerateMethCoords()
	while true do
		Wait(0)

		local methCoordX, methCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-90, 90)

		Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-90, 90)

		methCoordX = Config.CircleZones.MethField.coords.x + modX
		methCoordY = Config.CircleZones.MethField.coords.y + modY

		local coordZ = GetCoordZ(methCoordX, methCoordY)
		local coord = vector3(methCoordX, methCoordY, coordZ)

		if ValidateMethCoord(coord) then
			return coord
		end
	end
end

function GetCoordZ(x, y)
	local groundCheckHeights = { 48.0, 49.0, 50.0, 51.0, 52.0, 53.0, 54.0, 55.0, 56.0, 57.0, 58.0 }

	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

		if foundGround then
			return z
		end
	end

	return 43.0
end
