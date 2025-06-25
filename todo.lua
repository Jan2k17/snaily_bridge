--[[ TODO LISTE ]]--
--[[
    - export für socialSecurityNumber um diese auf dem Ausweis zu legen
    - bild export ins cad bei ausweiserstellung
    - Impound automatisch im CAD eintragen
        [ CLIENT
            RegisterNetEvent("jobs_creator:actions:vehicleImpounded", function(vehiclePlate, vehicleModel)
                -- You can add your impound script exports here
                -- TriggerServerEvent("impound_script:impoundVehicle", vehiclePlate, vehicleModel)
            end)
        ]
    - Job automatisch setzen von MD, PD
        [ SERVER
            RegisterNetEvent("jobs_creator:boss:playerHired", function(playerId, jobName)
            end)
        ]
    - Job automatisch entfernen bei Kündigung
        [ SERVER
            RegisterNetEvent("jobs_creator:boss:employeeFired", function(employeeIdentifier, jobName)
            end)
        ]
]]--