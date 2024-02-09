ESX = exports["es_extended"]:getSharedObject()

local playersProcessingMeth = {}
local outofbound = true
local alive = true

local function ValidatePickupMeth(src)
	local ECoords = Config.CircleZones.MethField.coords
	local PCoords = GetEntityCoords(GetPlayerPed(src))
	local Dist = #(PCoords-ECoords)
	if Dist <= 90 then return true end
end

local function ValidateProcessMeth(src)
	local ECoords = Config.CircleZones.MethProcessing.coords
	local PCoords = GetEntityCoords(GetPlayerPed(src))
	local Dist = #(PCoords-ECoords)
	if Dist <= 5 then return true end
end

local function FoundExploiter(src,reason)
	-- ADD YOUR BAN EVENT HERE UNTIL THEN IT WILL ONLY KICK THE PLAYER --
	DropPlayer(src,reason)
	SendDiscordLog("Exploit Attempt", "Player ID: "..src.." tried to exploit: "..reason, 16711680) -- Red color for alert
end

function SendDiscordLog(name, message, color)
    local embed = {
        {
            ["title"] = name,
            ["description"] = message,
            ["type"] = "rich",
            ["color"] = color,
            ["footer"] = {
                ["text"] = "HW Scripts | Logs"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, 'POST', json.encode({username = "Server Logs", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

RegisterServerEvent('hw_meth:sellDrug')
AddEventHandler('hw_meth:sellDrug', function(itemName, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local price = Config.DrugDealerItems[itemName]
    local xItem = xPlayer.getInventoryItem(itemName)

    if type(amount) ~= 'number' or type(itemName) ~= 'string' then
        SendDiscordLog("Invalid Sale Attempt", ('%s attempted to sell with invalid input type!'):format(xPlayer.identifier), 16711680)
        FoundExploiter(xPlayer.source, 'SellDrugs Event Trigger')
        return
    end

    if not price then
        SendDiscordLog("Invalid Drug Sale", ('%s attempted to sell an invalid drug!'):format(xPlayer.identifier), 16711680)
        return
    end

    if amount < 0 or xItem == nil or xItem.count < amount then
        xPlayer.showNotification(TranslateCap('dealer_notenough'))
        return
    end

    price = ESX.Math.Round(price * amount)

    if Config.GiveBlack then
        xPlayer.addAccountMoney('black_money', price, "Drugs Sold")
    else
        xPlayer.addMoney(price, "Drugs Sold")
    end

    xPlayer.removeInventoryItem(xItem.name, amount)
    xPlayer.showNotification(TranslateCap('dealer_sold', amount, xItem.label, ESX.Math.GroupDigits(price)))
    SendDiscordLog("Drug Sale", ('%s sold %s amount of %s for %s'):format(xPlayer.identifier, amount, itemName, price), 65280) -- Green color for success

    if Config.Debug then
        print("^7[^1DEBUG^7] A player sold drugs: " .. itemName .. " for " .. price)
    end

end)

ESX.RegisterServerCallback('hw_meth:buyLicense', function(source, cb, licenseName)
	local xPlayer = ESX.GetPlayerFromId(source)
	local license = Config.LicensePrices[licenseName]

	if license then
		if xPlayer.getMoney() >= license.price then
			xPlayer.removeMoney(license.price)

			TriggerEvent('esx_license:addLicense', source, licenseName, function()
				cb(true)

                if Config.Debug then
                    print("^7[^1DEBUG^7] A player bought a license:" .. licenseName)
                end

			end)
		else
			cb(false)
		end
	else
		print(('hw_meth: %s attempted to buy an invalid license!'):format(xPlayer.identifier))
		cb(false)
	end
end)

RegisterServerEvent('hw_meth:pickedUpMeth')
AddEventHandler('hw_meth:pickedUpMeth', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local cime = math.random(5,10)
    if ValidatePickupMeth(src) then
        if xPlayer.canCarryItem('meth', cime) then
            xPlayer.addInventoryItem('meth', cime)
            SendDiscordLog("Meth Pickup", ('%s picked up %s meth'):format(xPlayer.identifier, cime), 65280)

            if Config.Debug then
                print("^7[^1DEBUG^7] A player picked up meth")
            end

        else
            xPlayer.showNotification(TranslateCap('meth_inventoryfull'))
        end
    else
        FoundExploiter(src, 'Meth Pickup Trigger')
    end
end)

ESX.RegisterServerCallback('hw_meth:canPickUp', function(source, cb, item)
	local xPlayer = ESX.GetPlayerFromId(source)
	cb(xPlayer.canCarryItem(item, 1))
end)

RegisterServerEvent('hw_meth:outofbound')
AddEventHandler('hw_meth:outofbound', function()
	outofbound = true
end)

ESX.RegisterServerCallback('hw_meth:meth_count', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xMeth = xPlayer.getInventoryItem('meth').count
	cb(xMeth)
end)

RegisterServerEvent('hw_meth:processMeth')
AddEventHandler('hw_meth:processMeth', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    -- Validate the player is in the processing area
    if ValidateProcessMeth(_source) then
        -- Ensure the player has enough meth to start processing
        if xPlayer.getInventoryItem('meth').count >= 3 then
            -- Flag this player as processing
            if not playersProcessingMeth[_source] then
                playersProcessingMeth[_source] = true
                
                -- Inform the player processing has started
                xPlayer.showNotification(TranslateCap('meth_processing_started'))

                -- Start processing loop
                Citizen.CreateThread(function()
                    while playersProcessingMeth[_source] do
                        Citizen.Wait(Config.Delays.MethProcessing)
                        if xPlayer.getInventoryItem('meth').count >= 3 then
                            if xPlayer.canSwapItem('meth', 3, 'pure_meth', 1) then
                                xPlayer.removeInventoryItem('meth', 3)
                                xPlayer.addInventoryItem('pure_meth', 1)
                                SendDiscordLog("Meth Processed", ('%s processed meth into pure_meth'):format(xPlayer.identifier), 65280)

                                if Config.Debug then
                                    print("^7[^1DEBUG^7] A player processed meth into pure_meth")
                                end

                            else
                                xPlayer.showNotification(TranslateCap('meth_processingfull'))
                                playersProcessingMeth[_source] = false
                            end
                        else
                            xPlayer.showNotification(TranslateCap('meth_processingenough'))
                            playersProcessingMeth[_source] = false
                        end
                    end
                end)
            end
        else
            xPlayer.showNotification(TranslateCap('meth_processingenough'))
        end
    else
        FoundExploiter(_source, 'Meth Processing Trigger')
    end
end)

function CancelProcessing(playerId)
	if playersProcessingMeth[playerId] then
		ESX.ClearTimeout(playersProcessingMeth[playerId])
		playersProcessingMeth[playerId] = nil
	end
end

RegisterServerEvent('hw_meth:stopProcessing')
AddEventHandler('hw_meth:stopProcessing', function()
    local _source = source
    if playersProcessingMeth[_source] then
        playersProcessingMeth[_source] = false
        SendDiscordLog("Processing Stopped", ('%s stopped processing meth.'):format(ESX.GetPlayerFromId(_source).identifier), 65280)

        if Config.Debug then
            print("^7[^1DEBUG^7] A player stopped the meth processing")
        end

    end
end)

RegisterServerEvent('hw_meth:cancelProcessing')
AddEventHandler('hw_meth:cancelProcessing', function()
	CancelProcessing(source)
	SendDiscordLog("Meth Cancel", ('%s canceled meth progress'):format(xPlayer.identifier), 65280)
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
	CancelProcessing(playerId)
end)

RegisterServerEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
	CancelProcessing(source)
end)
