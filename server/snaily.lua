ESX = exports["es_extended"]:getSharedObject()

local API_URL = Config.Snaily.API_URL
local API_TOKEN = Config.Snaily.API_TOKEN
local API_TOKEN_HEADER_NAME = Config.Snaily.API_TOKEN_HEADER_NAME

local citizen_id = "error"
local citizen_ssn = "citizen_ssn"
local vehicleModelId = "error"

local function split(str, sep)
    sep = sep or "%s"
    local t = {}
    local pos = 1
    while true do
        local idx = string.find(str, sep, pos)
        if idx then
            table.insert(t, string.sub(str, pos, idx - 1))
            pos = idx + 1
        else
            table.insert(t, string.sub(str, pos))
            break
        end
    end
    return t
end

function formatDOB(dateofbirth)
    --   YYYY-MM-DD HH:MM:SS
    local dob = "1999-01-01 00:00:00"
    local sep = "-"
    local res = split(dateofbirth, sep)
    local dob = res[3] .. '-' .. res[2] .. '-' .. res[1] .. ' 00:00:00'
    return tostring(dob)
end

function formatForSnaily(ctype, data)
    local snailyFormatted = {}
    local sex = data.sex
    if ctype == "character" then
        if type(data) == "string" then
            data = json.decode(data)
        end
        if data.sex == "m" then
            sex = "cm8799uyo01pl5jf6wdi6jteb" -- MALE
        elseif data.sex == "f" then
            sex = "cm8799uyp01pm5jf6mlly38jq" -- FEMALE
        else
            sex = "cm8799uyp01pn5jf6fm9j4jb6"
        end
        snailyFormatted = {
            name = tostring(data.firstName),
            surname = tostring(data.lastName),
            gender = tostring(sex),
            ethnicity = "cm8799mmf01pe5jf64nrfte7l", -- UNKNOWN
            dateOfBirth = formatDOB(data.dateofbirth),
            weight = "-/-",
            height = "-/-",
            hairColor = "-/-",
            eyeColor = "-/-",
            address = tostring("cm87980c000rj5jf6voxdkoxh")
        }
    elseif ctype == "911" then
        if type(data) == "string" then
            data = json.decode(data)
        end
        snailyFormatted = {
            location = tostring(data.street),
            name = tostring(data.name),
            postal = tostring(data.postal)
        }
    end
    while snailyFormatted == {} do
        Wait(0)
    end
    return snailyFormatted
end

function SnailyAPIHTTPX(method, point, data, vehicleData)
    if method == "PUT" then
        --
    elseif method == "POST" then
        if point == "addcop" then
            -- CITIZENiD - xxx
            -- DEPARTMENT - cm8798z6i01p35jf675rwsk4p
            -- CALLSIGN - ??
            -- CALLSIGN2 - ??
            -- RANK - ??
            --[[PerformHttpRequest(API_URL .. "leo", function(errorCode, resultData, resultHeaders)
                local errorC = tostring(errorCode) == "200"
                if not errorC then
                    print("Returned error code:" .. tostring(errorCode))
                    print("Returned data:" .. tostring(resultData))
                    print("Returned result Headers:" .. tostring(json.encode(resultHeaders)))
                    return false
                else
                    return true
                end
            end, "POST", json.encode(data), {
                [API_TOKEN_HEADER_NAME] = API_TOKEN,
                ["accept"] = "application/json",
                ["Content-Type"] = "application/json"
            })--]]
        elseif point == "citizen" then
            PerformHttpRequest(API_URL .. point, function(errorCode, resultData, resultHeaders)
                local errorC = tostring(errorCode) == "200"
                if not errorC then
                    print("Returned error code:" .. tostring(errorCode))
                    print("Returned data:" .. tostring(resultData))
                    print("Returned result Headers:" .. tostring(json.encode(resultHeaders)))
                    return false
                else
                    return true
                end
            end, "POST", json.encode(data), {
                [API_TOKEN_HEADER_NAME] = API_TOKEN,
                ["accept"] = "application/json",
                ["Content-Type"] = "application/json"
            })
        elseif point == "vehicles" then
            --print(json.encode(data))
            PerformHttpRequest(API_URL .. point, function(errorCode, resultData, resultHeaders)
                local errorC = tostring(errorCode) == "200"
                if not errorC then
                    print("Returned error code:" .. tostring(errorCode))
                    print("Returned data:" .. tostring(resultData))
                    print("Returned result Headers:" .. tostring(json.encode(resultHeaders)))
                    return false
                else
                    return true
                end
            end, "POST", json.encode(data), {
                [API_TOKEN_HEADER_NAME] = API_TOKEN,
                ["accept"] = "application/json",
                ["Content-Type"] = "application/json"
            })
        elseif point == "911-calls" then
            PerformHttpRequest(API_URL .. point, function(errorCode, resultData, resultHeaders)
                local errorC = tostring(errorCode) == "200"
                if not errorC then
                    print("Returned error code:" .. tostring(errorCode))
                    print("Returned data:" .. tostring(resultData))
                    print("Returned result Headers:" .. tostring(json.encode(resultHeaders)))
                    return false
                else
                    return true
                end
            end, "POST", json.encode(data), {
                [API_TOKEN_HEADER_NAME] = API_TOKEN,
                ["Content-Type"] = "application/json"
            })
        end
    elseif method == "GET" then
        if point == "citizen_id" then
            citizen_id = "error"
            PerformHttpRequest(API_URL .. 'citizen?query=' .. data, function(errorCode, resultData, resultHeaders)
                local errorC = tostring(errorCode) == "200"
                if not errorC then
                    print("Returned error code:" .. tostring(errorCode))
                    print("Returned data:" .. tostring(resultData))
                    print("Returned result Headers:" .. tostring(json.encode(resultHeaders)))
                    return false
                else
                    local daten = json.decode(resultData)
                    citizen_id = daten.citizens[1].id
                    return true
                end
            end, "GET", null, {
                [API_TOKEN_HEADER_NAME] = API_TOKEN,
                ["Content-Type"] = "application/json"
            })
        elseif point == "admin/values/vehicle/search" then
            PerformHttpRequest(API_URL .. point .. '?query=' .. data, function(errorCode, resultData, resultHeaders)
                local errorC = tostring(errorCode) == "200"
                if not errorC then
                    print("Returned error code:" .. tostring(errorCode))
                    print("Returned data:" .. tostring(resultData))
                    print("Returned result Headers:" .. tostring(json.encode(resultHeaders)))
                    return false
                else
                    local daten = json.decode(resultData)
                    for i, item in pairs(daten) do
                        if data == string.lower(item.hash) then
                            vehicleData.model = item.id
                            SnailyAPIHTTPX("POST", "vehicles", vehicleData)
                            break
                        end
                    end
                    return true
                end
            end, "GET", null, {
                [API_TOKEN_HEADER_NAME] = API_TOKEN,
                ["Content-Type"] = "application/json"
            })
        elseif point == "citizen_ssn" then
            citizen_ssn = "error"
            PerformHttpRequest(API_URL .. 'citizen?query=' .. data, function(errorCode, resultData, resultHeaders)
                local errorC = tostring(errorCode) == "200"
                if not errorC then
                    print("Returned error code:" .. tostring(errorCode))
                    print("Returned data:" .. tostring(resultData))
                    print("Returned result Headers:" .. tostring(json.encode(resultHeaders)))
                    return false
                else
                    local daten = json.decode(resultData)
                    citizen_ssn = daten.citizens[1].socialSecurityNumber
                    return true
                end
            end, "GET", null, {
                [API_TOKEN_HEADER_NAME] = API_TOKEN,
                ["accept"] = "application/json",
                ["Content-Type"] = "application/json"
            })
        end
    end
end

RegisterNetEvent('jan2k17:snaily:911', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local plz = exports['nearest-postal']:getPostalServer(vec3(data.x, data.y, data.z))
    local pData = {}
    pData.street = data.street
    pData.postal = plz.code
    pData.name = xPlayer.variables.firstName .. ' ' .. xPlayer.variables.lastName
    SnailyAPI911CreateNew(pData)
end)

--[[ CREATE 911 ]] --
function SnailyAPI911CreateNew(data)

    local snailyData = formatForSnaily("911", data)
    local resp = SnailyAPIHTTPX("POST", "911-calls", snailyData)
    while resp == nil do
        Wait(0)
    end
    if resp then
        print("Created 911-call: " .. snailyData.name .. " " .. snailyData.surname)
    else
        print("Failed to create 911-call: " .. snailyData.name .. " " .. snailyData.surname)
    end
end

--[[ CREATE CITIZEN ]] --
function SnailyAPIUserCreateNew(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    while xPlayer == nil do
        Wait(0)
    end
    if xPlayer ~= 0 then
        print("Got user data for: " .. source .. " (" .. GetPlayerName(source) .. ")")
        local snailyData = formatForSnaily("character", xPlayer.variables)
        local resp = SnailyAPIHTTPX("POST", "citizen", snailyData)
        while resp == nil do Wait(0) end
        if resp then
            --print("Created user: " .. snailyData.name .. " " .. snailyData.surname)
            return true
        else
            print("Failed to create user: " .. snailyData.name .. " " .. snailyData.surname)
            return false
        end
    else
        print("Failed to get user data for: " .. source .. " (" .. GetPlayerName(source) .. ")")
        return false
    end
end

RegisterNetEvent('jan2k17:snaily:createCitizen', function()
    SnailyAPIUserCreateNew(source)
end)

--[[ CREATE VEHICLE ]] --
RegisterNetEvent('jan2k17:snaily:createVehicle', function(data, src)
    print("triggered: createVehicle")
    local cId = getCitizen(src)
    local vData = data
    vData.citizenId = cId
    vData.model = data.model
    vData.plate = data.plate
    vData.color = data.color
    vData.registrationStatus = data.registrationStatus
    vData.insuranceStatus = data.insuranceStatus
    getVehicleID(vData.model, vData)
end)

function getVehicleID(model, vehicleData)
    SnailyAPIHTTPX("GET", "admin/values/vehicle/search", model, vehicleData)
end

function SnailyAPIVehicleCreateNew(vehicleData)
    local snailyData = vehicleData
    local resp = SnailyAPIHTTPX("POST", "vehicles", snailyData)
    while resp == nil do
        Wait(0)
    end
    if resp then
        print("Created vehicle: " .. snailyData.model .. " " .. snailyData.plate)
        -- return true
    else
        print("Failed to create vehicle: " .. snailyData.model .. " " .. snailyData.plate)
        -- return false
    end
end

function getCitizen(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    while xPlayer == nil do
        Wait(0)
    end

    if xPlayer ~= 0 then
        -- /citizen?query=
        local name = xPlayer.variables.firstName .. '%20' .. xPlayer.variables.lastName
        SnailyAPIHTTPX("GET", "citizen_id", name)
        while citizen_id == "error" do
            Wait(0)
        end
        return citizen_id
    end
end

RegisterNetEvent('jan2k17:snaily:getCitizenSSN', function()
    return getCitizenSSN(source)
end)

ESX.RegisterServerCallback('jan2k17:snaily:call:getCitizenSSN', function(src, cb)
    getCitizenSSN(src)
    cb(citizen_ssn)
end)

function getCitizenSSN(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    while xPlayer == nil do
        Wait(0)
    end

    if xPlayer ~= 0 then
        -- /citizen?query=
        local name = xPlayer.variables.firstName .. '%20' .. xPlayer.variables.lastName
        SnailyAPIHTTPX("GET", "citizen_ssn", name)
        while citizen_ssn == "error" do
            Wait(0)
        end
        return citizen_ssn
    end
end