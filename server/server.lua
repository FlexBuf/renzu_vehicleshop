ESX = nil
local vehicles = {}
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
RegisterServerEvent('renzu_vehicleshop:GetAvailableVehicle')
AddEventHandler('renzu_vehicleshop:GetAvailableVehicle', function()
    local src = source 
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.identifier
    local Owned_Vehicle = MySQL.Sync.fetchAll('SELECT * FROM vehicles', {})
    TriggerClientEvent("renzu_vehicleshop:receive_vehicles", src , Owned_Vehicle)
end)

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
-- encoding
function veh(data)
	data = tostring(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

local NumberCharset = {}
for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end
function GetRandomNumber(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
	else
		return ''
	end
end

RegisterCommand('testa', function()
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles', {}, function (result)
        print(#result,"ASO")
        local plate = veh(tonumber(92299))
        plate = plate:gsub("=", "")
        print(plate)
        local total = 8 - plate:len()
        print(total)
        if total ~= 0 then
            plate = veh(tonumber(92299))..GetRandomNumber(total)
            plate = plate:gsub("=", "")
        end
        print(plate,plate:len())
        cb(plate)
	end)
end)

ESX.RegisterServerCallback('renzu_vehicleshop:GenPlate', function (source, cb)
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles', {}, function (result)
        print(#result,"ASO")
        local plate = veh(tonumber(#result))
        plate = plate:gsub("=", "")
        local total = 8 - plate:len()
        print(total)
        if total ~= 0 then
            plate = veh(tonumber(#result))..GetRandomNumber(total)
            plate = plate:gsub("=", "")
        end
        print(plate,plate:len())
        cb(plate)
	end)
end)

ESX.RegisterServerCallback('renzu_vehicleshop:buyvehicle', function (source, cb, model, props)
    local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT * FROM vehicles WHERE model = @model LIMIT 1', {
		['@model'] = model
    }, function (result)
        if #result > 0 then
            print("tikol")
            local model = result[1].model
            local price = result[1].price
            local stock = result[1].stock
            stock = 999
            if stock > 0 then           
                if xPlayer.getMoney() >= tonumber(price) then
                    xPlayer.removeMoney(tonumber(price))
                    -- local societyAccount = nil
                    -- TriggerEvent('esx_addonaccount:getSharedAccount', 'society_monkey', function(account)
                    -- societyAccount = account
                    -- end)
                    -- if vehiclePrice < 50000000 then
                    -- societyAccount.addMoney(vehiclePrice * 0.15)
                    -- end
                    stock = stock - 1
                    local data = json.encode(props)
                    MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, stored) VALUES (@owner, @plate, @props, @stored)',
                    {
                        ['@owner']   = xPlayer.identifier,
                        ['@plate']   = props.plate,
                        ['@props'] = data,
                        ['@stored'] = 1
                    },
                    function (rowsChanged)
                        TriggerClientEvent("vehicleshop.sussessbuy", source, name, props, price)
                        MySQL.Sync.execute('UPDATE vehicles SET stock = @stock WHERE model = @model',
                        {
                            ['@stock'] = stock,
                            ['@model'] = model
                        })
                        cb(true)
                    end)
                else
                    cb(false)
                    xPlayer.ShowNotification('Not Enough Money')
                end
            else
                cb(false)
                xPlayer.ShowNotification('Vehicle Out of stock')
            end
        else
            cb(false)
            xPlayer.ShowNotification('Vehicle does not Exist')
        end
    end)
end)