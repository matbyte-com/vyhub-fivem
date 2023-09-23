VyHub.Config = VyHub.Config or {}

-- VyHub Server Config
-- BEWARE: Additional config values can be set in vyhub-fivem/data/config.json with the `vh_config <key> <value>` console command.
--         The configuration in this file is overwritten by the configuration in vyhub-fivem/data/config.json

-- ONLY SET THE 3 FOLLOWING OPTIONS IF YOU KNOW WHAT YOU ARE DOING!
-- PLEASE FOLLOW THE INSTALLATION INSTRUCTIONS HERE: https://docs.vyhub.net/latest/game/fivem/#installation
VyHub.Config.api_url = "" -- https://api.vyhub.app/<name>/v1
VyHub.Config.api_key = "" -- Admin -> Settings -> Server -> Serverbundle -> Keys
VyHub.Config.server_id = "" -- Admin -> Settings -> Server

-- Every x seconds an advert is displayed (if configured)
VyHub.Config.advert_interval = 120
-- Advert prefix
VyHub.Config.advert_prefix = "[★] "