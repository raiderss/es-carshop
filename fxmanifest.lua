fx_version 'cerulean'
game 'gta5'

author 'EYES'
description 'ES Car Shop'
version '1.0.0'

shared_scripts {
    'main/shared.lua'
}

client_scripts {
    'main/client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'main/server/*.lua'
}

ui_page 'index.html'

files {
    'index.html',
    'vue.js',
    'assets/**/*'
}

escrow_ignore { 'main/shared.lua' }

lua54 'yes'
-- dependency '/assetpacks'