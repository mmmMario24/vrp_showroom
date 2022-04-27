local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","vRP_showroom")
 
------ CallBacks
ServerCallbacks = {}

RegisterServerEvent(GetCurrentResourceName()..':triggerServerCallBack')
AddEventHandler(GetCurrentResourceName()..':triggerServerCallBack',function(name,requestId,...)
    local playerId = source
    
    TriggerServerCallback(name,requestId,playerId,function(...)
        TriggerClientEvent(GetCurrentResourceName()..':serverCallBack',playerId,requestId,...)
    end,...)
end)

function RegisterServerCallback(name,cb)
    ServerCallbacks[name] = cb
end

function TriggerServerCallback(name,requestId,source,cb,...)
    if ServerCallbacks[name] then
        ServerCallbacks[name](source,cb,...)
    end
end
------ CallBacks

RegisterServerCallback('sc-vehicleshop:checkPlatePrice', function(source, cb, plate) 
    if vRP.getMoney({vRP.getUserId({source})}) >= 3000 then
      cardata = exports.ghmattimysql:executeSync("SELECT vehicle_plate FROM vrp_user_vehicles WHERE vehicle_plate ='"..plate.."' ", {})
      if #cardata == 0 then 
        cb(true)
        vRP.tryFullPayment({vRP.getUserId({source}),3000})
      end
    else
        vRPclient.notify(source,{"Nu ai 3000 la tine"})
    end
end)

RegisterServerCallback('esx_vehicleshop:isPlateTaken', function (source, cb, plate)
    exports.ghmattimysql:execute('SELECT * FROM vrp_user_vehicles WHERE vehicle_plate = @plate', {
        ['@plate'] = plate
    }, function (result)
        cb(result[1] ~= nil)
    end)
end)


RegisterServerCallback('vrp_vehshop:checkPrice', function(source, cb, data) 
    local src = source
    if vRP.getMoney({vRP.getUserId({src})}) >= data.price then 
       vRP.tryPayment({vRP.getUserId({src}),data.price})
          cb(true)
    end
end)
 

RegisterNetEvent('vrp_vehshop:server:givecar')
AddEventHandler('vrp_vehshop:server:givecar', function(props)
    local src = source
    exports.ghmattimysql:execute("INSERT INTO vrp_user_vehicles (user_id, vehicle, vehicle_plate) VALUES ('"..vRP.getUserId({src}).."', '"..json.encode(props).."', '"..props.plate.."')", {})
end)
