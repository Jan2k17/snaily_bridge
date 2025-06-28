ESX = exports["es_extended"]:getSharedObject()

function export911()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local zone = GetNameOfZone(coords.x, coords.y, coords.z);
    local var1, var2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z, Citizen.ResultAsInteger(), Citizen.ResultAsInteger())
    local hash1 = GetStreetNameFromHashKey(var1);
    
    local data = {}
    data.street = hash1
    data.x = coords[1]
    data.y = coords[2]
    data.z = coords[3]
    TriggerServerEvent("jan2k17:snaily:911", data)
end
exports('export911', export911)

function getSSN()
    ESX.TriggerServerCallback('jan2k17:snaily:call:getCitizenSSN', function(ssn)
        return ssn
    end)
end
exports('getSSN', getSSN)

RegisterNetEvent('jan2k17:snaily:client:createCitizen')
AddEventHandler('jan2k17:snaily:client:createCitizen', function()
    TriggerServerEvent('jan2k17:snaily:createCitizen')
end)

--[[ Beispiel für den Aufruf von einem Client-Skript:

-- 1. Erstelle die Daten für den Notruf in einer Lua-Tabelle
local callData = {
    location = "Teststraße 123",
    postal = "565",
    name = "Testfall",
    description = "Ein Testeintrag zur Fehlersuche.",
    gtaMapPosition = {
        x = 250.222,
        y = 444.5312,
        z = 0.0,
        heading = 360.0
    }
}

-- 2. Sende die Daten an den neuen Server-Event
TriggerServerEvent('jan2k17:snaily:create911Call', callData)--]]