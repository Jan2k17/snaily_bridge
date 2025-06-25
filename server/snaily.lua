ESX = exports["es_extended"]:getSharedObject()

local API_URL = Config.Snaily.API_URL
local API_TOKEN = Config.Snaily.API_TOKEN
local API_TOKEN_HEADER_NAME = Config.Snaily.API_TOKEN_HEADER_NAME

-- Hilfsfunktion für Logging
local function LogError(point, errorCode, resultData)
    print(string.format("[snaily_bridge] Fehler bei API-Anfrage an '%s'. Code: %s, Daten: %s", point, tostring(errorCode), tostring(resultData)))
end

-- Zentrale Funktion für alle API-Anfragen an SnailyCAD
local function PerformSnailyRequest(method, endpoint, data, callback)
    local headers = {
        [API_TOKEN_HEADER_NAME] = API_TOKEN,
        ["Content-Type"] = "application/json",
        ["accept"] = "application/json"
    }
    
    local body = (data and json.encode(data)) or ""

    PerformHttpRequest(API_URL .. endpoint, function(errorCode, resultData, resultHeaders)
        local status = tostring(errorCode)
        if status == "200" or status == "201" or status == "204" then
            if callback then
                if resultData and resultData ~= "" then
                    local success, decodedData = pcall(json.decode, resultData)
                    if success then
                        callback(decodedData, true)
                    else
                        LogError(endpoint, errorCode, "Fehler beim Parsen der JSON-Antwort.")
                        callback(nil, false)
                    end
                else
                    callback(true, true) -- Erfolgreich, aber keine Daten (z.B. bei DELETE)
                end
            end
        else
            LogError(endpoint, errorCode, resultData)
            if callback then
                callback(nil, false)
            end
        end
    end, method, body, headers)
end

-- Hilfsfunktion zum Aufteilen von Strings
local function split(str, sep)
    sep = sep or "%s"
    local t = {}
    for s in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(t, s)
    end
    return t
end

-- Formatiert das ESX-Datumsformat in das von SnailyCAD benötigte Format
function formatDOB(dateofbirth)
    local res = split(dateofbirth, "-")
    return string.format("%s-%s-%s 00:00:00", res[3], res[2], res[1])
end

-- Formatiert die Daten für verschiedene Endpunkte
function formatForSnaily(ctype, data)
    local snailyFormatted = {}
    if ctype == "character" then
        local sexId = Config.Snaily.IDs.GENDER_OTHER
        if data.sex == "m" then
            sexId = Config.Snaily.IDs.GENDER_MALE
        elseif data.sex == "f" then
            sexId = Config.Snaily.IDs.GENDER_FEMALE
        end

        snailyFormatted = {
            name = tostring(data.firstName),
            surname = tostring(data.lastName),
            gender = sexId,
            ethnicity = Config.Snaily.IDs.ETHNICITY_UNKNOWN,
            dateOfBirth = formatDOB(data.dateofbirth),
            weight = "-/-",
            height = "-/-",
            hairColor = "-/-",
            eyeColor = "-/-",
            address = Config.Snaily.IDs.ADDRESS_UNKNOWN
        }
    elseif ctype == "911" then
        snailyFormatted = {
            location = tostring(data.street),
            name = tostring(data.name),
            postal = tostring(data.postal)
        }
    end
    return snailyFormatted
end

--[[ BÜRGER-FUNKTIONEN ]]--

function getCitizenData(source, callback)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        callback(nil)
        return
    end

    local nameQuery = xPlayer.variables.firstName .. '%20' .. xPlayer.variables.lastName
    PerformSnailyRequest("GET", 'citizen?query=' .. nameQuery, nil, function(data, success)
        if success and data.citizens and #data.citizens > 0 then
            callback(data.citizens[1], xPlayer)
        else
            callback(nil, xPlayer)
        end
    end)
end

ESX.RegisterServerCallback('jan2k17:snaily:call:getCitizenSSN', function(source, cb)
    getCitizenData(source, function(citizen)
        if citizen and citizen.socialSecurityNumber then
            cb(citizen.socialSecurityNumber)
        else
            cb(nil)
        end
    end)
end)

RegisterNetEvent('jan2k17:snaily:createCitizen', function()
    local source = source
    getCitizenData(source, function(citizen, xPlayer)
        if citizen or not xPlayer then return end
        
        local snailyData = formatForSnaily("character", xPlayer.variables)
        PerformSnailyRequest("POST", "citizen", snailyData, function(data, success)
            if success then
                print("[snaily_bridge] Bürger erfolgreich erstellt: " .. snailyData.name .. " " .. snailyData.surname)
            else
                print("[snaily_bridge] Fehler beim Erstellen des Bürgers: " .. snailyData.name .. " " .. snailyData.surname)
            end
        end)
    end)
end)

--[[ 911-FUNKTIONEN ]]--

RegisterNetEvent('jan2k17:snaily:911', function(data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local plz = exports['nearest-postal']:getPostalServer(vec3(data.x, data.y, data.z))
    local pData = {
        street = data.street,
        postal = plz and plz.code or "N/A",
        name = xPlayer.variables.firstName .. ' ' .. xPlayer.variables.lastName
    }
    
    local snailyData = formatForSnaily("911", pData)
    PerformSnailyRequest("POST", "911-calls", snailyData, function(data, success)
        if success then
            print("[snaily_bridge] 911-Anruf erfolgreich erstellt von: " .. snailyData.name)
        else
            print("[snaily_bridge] Fehler beim Erstellen des 911-Anrufs von: " .. snailyData.name)
        end
    end)
end)

--[[ FAHRZEUG-FUNKTIONEN ]]--

local function getVehicleModelIdFromCad(modelHash, callback)
    local modelQuery = string.lower(modelHash)
    PerformSnailyRequest("GET", "admin/values/vehicle/search?query=" .. modelQuery, nil, function(modelData, success)
        if not (success and modelData) then
            print("[snaily_bridge] Fahrzeugmodell-Suche fehlgeschlagen für: " .. modelQuery)
            callback(nil)
            return
        end
        
        local foundModelId
        for _, item in ipairs(modelData) do
            if string.lower(item.hash) == modelQuery then
                foundModelId = item.id
                break
            end
        end

        if not foundModelId then
            print("[snaily_bridge] Passendes Fahrzeugmodell-Hash nicht gefunden für: " .. modelQuery)
        end
        callback(foundModelId)
    end)
end

local function postNewVehicleToCad(vehicleData, callback)
    PerformSnailyRequest("POST", "vehicles", vehicleData, function(_, createSuccess)
        if createSuccess then
            print("[snaily_bridge] Fahrzeug erfolgreich im CAD erstellt: " .. vehicleData.plate)
        else
            print("[snaily_bridge] Fehler beim Erstellen des Fahrzeugs im CAD: " .. vehicleData.plate)
        end
        if callback then callback(createSuccess) end
    end)
end

RegisterNetEvent('jan2k17:snaily:createVehicle', function(data, src)
    getCitizenData(src, function(citizen)
        if not (citizen and citizen.id) then return print("[snaily_bridge] Konnte Bürger-ID für Fahrzeughalter nicht finden.") end
        
        getVehicleModelIdFromCad(data.model, function(modelId)
            if not modelId then return end

            local vehicleData = {
                citizenId = citizen.id,
                model = modelId,
                plate = data.plate,
                color = data.color,
                registrationStatus = data.registrationStatus,
                insuranceStatus = data.insuranceStatus
            }
            postNewVehicleToCad(vehicleData)
        end)
    end)
end)

RegisterNetEvent("jobs_creator:actions:vehicleImpounded", function(vehiclePlate, vehicleModel)
    print(("[snaily_bridge] Event 'vehicleImpounded' für Kennzeichen %s ausgelöst."):format(vehiclePlate))
    
    PerformSnailyRequest("GET", "search/vehicle?query=" .. vehiclePlate, nil, function(data, success)
        if success and data and #data > 0 then
            local vehicleId = data[1].id
            local updateData = { registrationStatus = Config.Snaily.StatusIDs.VEHICLE_IMPOUNDED }

            PerformSnailyRequest("PUT", "vehicles/" .. vehicleId, updateData, function(_, updateSuccess)
                if updateSuccess then
                    print(("[snaily_bridge] Fahrzeug %s erfolgreich als beschlagnahmt markiert."):format(vehiclePlate))
                else
                    print(("[snaily_bridge] Fehler beim Markieren des Fahrzeugs %s als beschlagnahmt."):format(vehiclePlate))
                end
            end)
        else
            print(("[snaily_bridge] Fahrzeug %s nicht im CAD gefunden. Lege es neu an..."):format(vehiclePlate))
            
            ESX.TriggerServerCallback('esx_vehicleshop:getVehicleOwner', function(ownerIdentifier)
                if not ownerIdentifier then
                    return print(("[snaily_bridge] Konnte keinen Halter für das Kennzeichen %s in der Datenbank finden."):format(vehiclePlate))
                end
                
                local ownerPlayer = ESX.GetPlayerFromIdentifier(ownerIdentifier)
                if not ownerPlayer then
                    return print(("[snaily_bridge] Halter für Kennzeichen %s ist nicht online."):format(vehiclePlate))
                end

                getCitizenData(ownerPlayer.source, function(citizen)
                    if not (citizen and citizen.id) then
                        return print(("[snaily_bridge] Konnte CAD-Bürger für Halter von %s nicht finden."):format(vehiclePlate))
                    end

                    getVehicleModelIdFromCad(vehicleModel, function(modelId)
                        if not modelId then return end

                        local vehicleData = {
                            citizenId = citizen.id,
                            model = modelId,
                            plate = vehiclePlate,
                            color = "Unbekannt",
                            registrationStatus = Config.Snaily.StatusIDs.VEHICLE_IMPOUNDED,
                            insuranceStatus = "Unbekannt"
                        }
                        postNewVehicleToCad(vehicleData)
                    end)
                end)
            end, vehiclePlate)
        end
    end)
end)

--[[ JOB-SYNCHRONISATION ]]--

local function getJobConfig(jobName)
    for jobType, config in pairs(Config.Snaily.JobSync) do
        for _, name in ipairs(config.job_names) do
            if name == jobName then
                return config, jobType
            end
        end
    end
    return nil, nil
end

local function setPlayerJobInCad(citizen, jobConfig, jobType)
    local apiEndpoint
    if jobType == "police" then apiEndpoint = "leo"
    elseif jobType == "ems" then apiEndpoint = "ems-fd" end
    if not apiEndpoint then return end
    
    local officerData = {
        citizenId = citizen.id,
        department = jobConfig.departmentId,
        rank = jobConfig.defaultRankId
    }

    PerformSnailyRequest("POST", apiEndpoint, officerData, function(data, success)
        if success then
            print(("[snaily_bridge] Job für %s %s erfolgreich im CAD gesetzt."):format(citizen.name, citizen.surname))
        else
            print(("[snaily_bridge] Fehler beim Setzen des Jobs für %s %s im CAD."):format(citizen.name, citizen.surname))
        end
    end)
end

RegisterNetEvent("jobs_creator:boss:playerHired", function(playerId, jobName)
    local jobConfig, jobType = getJobConfig(jobName)
    if not jobConfig then return end

    print(("[snaily_bridge] Spieler %d wurde als %s eingestellt. Synchronisiere mit CAD..."):format(playerId, jobName))
    
    getCitizenData(playerId, function(citizen, xPlayer)
        if citizen then
            -- Bürger existiert, Job setzen
            setPlayerJobInCad(citizen, jobConfig, jobType)
        elseif xPlayer then
            -- Bürger existiert nicht, aber Spieler ist online -> zuerst erstellen
            print(("[snaily_bridge] Bürger für Spieler %s existiert nicht. Erstelle ihn zuerst..."):format(xPlayer.getName()))
            
            local snailyData = formatForSnaily("character", xPlayer.variables)
            PerformSnailyRequest("POST", "citizen", snailyData, function(newCitizenData, success)
                if success then
                    print(("[snaily_bridge] Bürger erfolgreich erstellt: %s %s. Setze nun den Job..."):format(snailyData.name, snailyData.surname))
                    -- Jetzt, da der Bürger erstellt ist, den Job setzen
                    setPlayerJobInCad(newCitizenData, jobConfig, jobType)
                else
                    print(("[snaily_bridge] Konnte Bürger für Job-Sync nicht erstellen (PlayerID: %d)."):format(playerId))
                end
            end)
        else
            print(("[snaily_bridge] Konnte Spieler für Job-Sync nicht finden (PlayerID: %d)."):format(playerId))
        end
    end)
end)

RegisterNetEvent("jobs_creator:boss:employeeFired", function(employeeIdentifier, jobName)
    local jobConfig, jobType = getJobConfig(jobName)
    if not jobConfig then return end

    local xPlayer = ESX.GetPlayerFromIdentifier(employeeIdentifier)
    if not xPlayer then return print(("[snaily_bridge] Konnte Spieler für Kündigungs-Sync nicht finden (Identifier: %s)."):format(employeeIdentifier)) end

    print(("[snaily_bridge] Spieler %s wurde als %s gefeuert. Synchronisiere mit CAD..."):format(xPlayer.getName(), jobName))

    getCitizenData(xPlayer.source, function(citizen)
        if not (citizen and citizen.id) then
            return print(("[snaily_bridge] Konnte Bürger für Kündigungs-Sync nicht finden (Player: %s)."):format(xPlayer.getName()))
        end
        
        local apiEndpoint
        if jobType == "police" then apiEndpoint = "leo/" .. citizen.id
        elseif jobType == "ems" then apiEndpoint = "ems-fd/" .. citizen.id end
        if not apiEndpoint then return end

        PerformSnailyRequest("DELETE", apiEndpoint, nil, function(_, success)
            if success then
                print(("[snaily_bridge] Job für %s %s erfolgreich im CAD entfernt."):format(citizen.name, citizen.surname))
            else
                print(("[snaily_bridge] Fehler beim Entfernen des Jobs für %s %s im CAD."):format(citizen.name, citizen.surname))
            end
        end)
    end)
end)