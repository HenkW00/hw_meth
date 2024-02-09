Config = {}

Config.Debug = true -- enable this for printing some server events

Config.WebhookURL = "https://discord.com/api/webhooks/1204238803057905664/HGhipSTPQKVAOgllMTmL3jSJt98nmZNooh3Gj7gH53q3wSFPfWUz-DXOCrDE9Xlp1qsw" -- place youre webhook here

Config.Locale = GetConvar('esx:locale', 'en')

Config.Delays = {
    MethProcessing = 1000 * 7  -- Adjusted for meth
}

Config.DrugDealerItems = {
    pure_meth = 300  -- Adjusted price for meth
}

Config.LicenseEnable = false -- Enable processing licenses? The player will be required to buy a license in order to process drugs. Requires esx_license

Config.LicensePrices = {
    meth_processing = {label = "Meth Processing License", price = 20000}  -- Adjusted for meth
}

Config.GiveBlack = true -- Give black money? If disabled, it'll give regular cash.

Config.CircleZones = {
    MethField = {coords = vector3(2043.98, 2804.92, 50.29), name = "Meth Lab", color = 25, sprite = 499, radius = 100.0},  -- Adjusted location for meth
    MethProcessing = {coords = vector3(1199.45, -3117.25, 5.54), name = "Meth Processing", color = 25, sprite = 499},  -- Adjusted location for meth

    DrugDealer = {coords = vector3(-1668.14, -1074.58, 13.15), name = "Drug Dealer", color = 6, sprite = 378},  -- Same dealer for all drugs
}

Config.Marker = {
    Distance = 100.0,
    Color = {r=60,g=230,b=60,a=255},
    Size = vector3(1.5,1.5,1.0),
    Type = 1,
}

-- Min and max amount of Config.DrugDealerItems to sell
Config.SellMenu = {
    Min = 1,
    Max = 50
}
