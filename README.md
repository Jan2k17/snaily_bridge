# Snaily Bridge für FiveM & SnailyCAD v4

Dies ist eine Bridge, um einen FiveM-Server, der das ESX-Framework nutzt, mit einer SnailyCAD v4 Instanz zu verbinden. Sie ermöglicht die Synchronisation von Bürgern, Fahrzeugen, Notrufen und Jobs zwischen dem Spiel und dem CAD-System.

## Funktionen

-   **Bürger-Synchronisation**: Erstellt automatisch Bürger im CAD.
-   **Fahrzeug-Registrierung**: Registriert gekaufte Fahrzeuge im CAD.
-   **Notrufe**: Ermöglicht Spielern, 911-Notrufe direkt aus dem Spiel heraus abzusetzen, die im CAD erscheinen.
-   **Automatisierte Job-Verwaltung**: Setzt oder entfernt den LEO/EMS-Status eines Spielers im CAD, wenn dieser eingestellt oder gefeuert wird.
-   **Automatisierte Fahrzeug-Beschlagnahmung**: Markiert Fahrzeuge im CAD als beschlagnahmt und legt sie bei Bedarf neu an.
-   **Asynchron**: Nutzt asynchrone Callbacks für eine bessere Server-Performance.

## Installation

1.  Lade das Skript herunter und platziere den `snaily_bridge`-Ordner in deinem `resources`-Verzeichnis.
2.  Trage das Skript in deiner `server.cfg`-Datei ein: `ensure snaily_bridge`.
3.  Passe die `config.lua`-Datei an (siehe unten).
4.  Starte deinen Server neu.

## Konfiguration

Bevor die Events genutzt werden können, stelle sicher, dass die `config.lua` korrekt ausgefüllt ist.

-   **API-Daten**: Trage deine SnailyCAD API-URL und dein API-Token ein.
-   **IDs**: Fülle die IDs für Geschlechter, Ethnien, Abteilungen, Ränge und Statuswerte aus. Diese müssen exakt mit den Werten aus deiner SnailyCAD-Instanz übereinstimmen (zu finden unter `Admin -> Werte`).
-   **JobSync**: Definiere, welche In-Game-Job-Namen mit welchen Abteilungen im CAD synchronisiert werden sollen.

## API & Events Dokumentation

### Client-seitige Events & Exporte

Diese Funktionen können aus jedem anderen **client-seitigen** Skript aufgerufen werden.

#### `export911`

Löst einen 911-Notruf im SnailyCAD aus. Das Skript ermittelt automatisch die Position und die Straße des Spielers.

-   **Typ:** Export
-   **Parameter:** Keine

**Beispiel:**
```lua
-- In einem anderen Client-Skript
Citizen.CreateThread(function()
    -- Wenn der Spieler eine Taste drückt
    if IsControlJustReleased(0, 38) then -- E-Taste
        exports['snaily_bridge']:export911()
    end
end)
```

#### `getSSN`

Ruft die Sozialversicherungsnummer (SSN) des Spielers asynchron vom Server ab. Da die Abfrage Zeit benötigt, muss eine Callback-Funktion verwendet werden.

-   **Typ:** Export
-   **Parameter:** `callback` (Funktion): Eine Funktion, die aufgerufen wird, sobald die SSN verfügbar ist. Sie erhält die SSN als ersten Parameter.

**Beispiel:**
```lua
-- In einem anderen Client-Skript, z.B. um die SSN auf einem Ausweis anzuzeigen
exports['snaily_bridge']:getSSN(function(ssn)
    if ssn then
        -- Logik zur Anzeige des Ausweises mit der SSN
        ESX.ShowNotification("Meine SSN lautet: " .. ssn)
    else
        ESX.ShowNotification("Konnte keine SSN finden.")
    end
end)
```

### Server-seitige Events

Diese Events können von jedem anderen **server-seitigen** oder **client-seitigen** Skript aus getriggert werden.

#### `jan2k17:snaily:createCitizen`

Erstellt den Spieler, der das Event auslöst, als neuen Bürger im SnailyCAD, falls er dort noch nicht existiert.

-   **Typ:** Server-Event
-   **Parameter:** Keine

**Beispiel (vom Client ausgelöst):**
```lua
-- Löst die Erstellung für den eigenen Charakter aus
TriggerServerEvent('jan2k17:snaily:createCitizen')
```

#### `jan2k17:snaily:createVehicle`

Registriert ein neues Fahrzeug im SnailyCAD und verknüpft es mit einem Spieler.

-   **Typ:** Server-Event
-   **Parameter:**
- - `vehicledata` (Tabelle): Eine Tabelle mit den Fahrzeugdaten.
- - `source` (Integer): Die Server-ID des Spielers, dem das Fahrzeug gehören soll.

**Struktur von `vehicleData`:**
```lua
local vehicleData = {
    model = "adder", -- Der Spawn-Name des Fahrzeugs
    plate = "BEISPIEL", -- Das Kennzeichen
    color = "Schwarz", -- Die Farbe
    registrationStatus = "Gültig", -- Der Zulassungsstatus
    insuranceStatus = "Versichert" -- Der Versicherungsstatus
}
```

**Beispiel (von einem Server-Skript aus):**
```lua
-- Annahme: 'targetPlayer' ist die Server-ID des Käufers
local targetPlayer = 1 

local vehicleData = {
    model = "adder",
    plate = "COOL123",
    color = "Blau",
    registrationStatus = "Gültig",
    insuranceStatus = "Versichert"
}

TriggerServerEvent('jan2k17:snaily:createVehicle', vehicleData, targetPlayer)
```

### **Reagierende Events (Events, auf die das Skript hört)**

Das `snaily_bridge`-Skript hört auf diese Events, die von anderen Skripten (z.B. einem Job-System) ausgelöst werden müssen.

#### `jobs_creator:actions:vehicleImpounded`

Wenn dieses Event ausgelöst wird, wird das entsprechende Fahrzeug im CAD als "Beschlagnahmt" markiert. Wenn das Fahrzeug nicht existiert, wird es neu angelegt.

-   **Typ:** Server-Event (das Skript hört zu)
-   **Parameter:**
- - `vehiclePlate` (String): Das Kennzeichen des zu beschlagnahmenden Fahrzeugs.
- - `vehicleModel` (String): Der Spawn-Name des Fahrzeugmodells.

**Beispiel (in deinem Polizei-Skript):**
```lua
local plate = "FALSCHPKR"
local model = "stratum"
TriggerServerEvent('jobs_creator:actions:vehicleImpounded', plate, model)
```

#### `jobs_creator:boss:playerHired`

Wenn ein Spieler für einen Job eingestellt wird, der in der `config.lua` unter `JobSync` definiert ist, wird sein Status im CAD automatisch gesetzt.

-   **Typ:** Server-Event (das Skript hört zu)
-   **Parameter:**
- - `playerId` (Integer): Die Server-ID des eingestellten Spielers.
- - `jobName` (String): Der Name des Jobs (z.B. "police").

**Beispiel (in deinem Job-System):**
```lua
local targetPlayerId = 1
local newJob = "police"
TriggerServerEvent('jobs_creator:boss:playerHired', targetPlayerId, newJob)
```

#### `jobs_creator:boss:employeeFired`

Entfernt den Job-Status eines Spielers im CAD, wenn er gefeuert wird.

-   **Typ:** Server-Event (das Skript hört zu)
-   **Parameter:**
-- `employeeIdentifier` (String): Der permanente Identifier des Spielers (z.B. `license:xxxxxxxx`).
-- `jobName` (String): Der Name des Jobs, aus dem der Spieler entlassen wurde.

**Beispiel (in deinem Job-System):**
```lua
local playerIdentifier = "license:xxxxxxxxxxxxxxxxxxxxxxxx"
local oldJob = "police"
TriggerServerEvent('jobs_creator:boss:employeeFired', playerIdentifier, oldJob)
```