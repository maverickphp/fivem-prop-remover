fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'maverickphp'
description 'Admin world-prop remover with permanent, server-side persistence (works for everyone, survives restarts). ox_lib management menu, area wipe, readable names.'
version '2.0.0'
repository 'https://github.com/maverickphp/fivem-prop-remover'

dependency 'ox_lib'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'prop_names.lua',
    'shared.lua',
}

client_script 'client.lua'
server_script 'server.lua'

files {
    'locales/*.json',
}
