Config = {}

Config.Snaily = {
    API_URL = GetConvar("snailycad_v4_api_url"),
    API_TOKEN = GetConvar("snailycad_v4_api_token"),
    API_TOKEN_HEADER_NAME = "snaily-cad-api-token"
}

-- IDs für SnailyCAD-Werte zur einfacheren Konfiguration
Config.Snaily.IDs = {
    -- Geschlechter
    GENDER_MALE = "cm8799uyo01pl5jf6wdi6jteb",
    GENDER_FEMALE = "cm8799uyp01pm5jf6mlly38jq",
    GENDER_OTHER = "cm8799uyp01pn5jf6fm9j4jb6",

    -- Ethnien (Beispiel: European)
    ETHNICITY_UNKNOWN = "cm8799mmf01pe5jf64nrfte7l",

    -- Standardadresse (Beispiel: Unbekannt)
    ADDRESS_UNKNOWN = "cm87980c000rj5jf6voxdkoxh",

     -- IDs für erforderliche Bürgerdaten
    HAIR_COLOR_UNKNOWN = "-/-",
    EYE_COLOR_UNKNOWN = "-/-",
    WEIGHT_UNKNOWN = "-/-",
    HEIGHT_UNKNOWN = "-/-",

    COLOR_UNKNOWN = "-/-",
    
    INSURANCE_UNKNOWN = "cm879a4g501po5jf6lv0gi31k"
}

-- IDs für Fahrzeug- und Job-Status
Config.Snaily.StatusIDs = {
    VEHICLE_IMPOUNDED = "cm879am6i02vs5jf60724h1dg",
    VEHICLE_NONE = "cm879a4g501po5jf6lv0gi31k"
}

-- Konfiguration für die Job-Synchronisation
-- HINWEIS: Passe die Job-Namen und IDs an deine Server- und CAD-Konfiguration an.
Config.Snaily.JobSync = {
    police = {
        job_names = {"police"}, -- In-game job names (z.B. aus ESX)
        departmentId = "cm8798z6i01p35jf675rwsk4p",
        defaultRankId = "cm87g1khj003c13yycjdjt7g0"
    },
    ems = {
        job_names = {"ambulance"},
        departmentId = "cm8798z6i01p65jf68ju0z6kx",
        defaultRankId = "cm87g1rko003e13yy4khawgxs"
    }
}