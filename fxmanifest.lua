fx_version 'adamant'
game 'gta5'
lua54 'yes'

author 'HenkW'
description 'Simple meth script'

version '1.1.0'

shared_script '@es_extended/imports.lua'

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua',
	'server/main.lua',
	'server/version.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua',
	'client/main.lua',
	'client/meth.lua'
}

dependencies {
	'es_extended'
}

escrow_ignore {
    'config.lua',
    'fxmanifest.lua',
	'locales/*.lua',
}

shared_script '@es_extended/imports.lua'