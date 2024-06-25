fx_version 'cerulean'
games { 'gta5' }

author 'VyHub'
description ''
version '1.0.0'

shared_scripts {
    'init.lua',
    'config/sh_config.lua',
    'shared/*.lua',
}

server_scripts {
    'config/sv_config.lua',
    'server/*.lua',
    'modules/*.lua',
}

client_scripts {
    'client/*.lua',
    'client/modules/*.lua'
}

files {"/client/html/**"}
ui_page "/client/html/index.html"


