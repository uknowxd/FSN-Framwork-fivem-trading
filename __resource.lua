--[[/	:FSN:	\]]--
resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'
client_script '@fsn_main/cl_utils.lua'
server_script '@fsn_main/sv_utils.lua'
client_script '@fsn_main/server_settings/sh_settings.lua'
server_script '@fsn_main/server_settings/sh_settings.lua'
server_script '@mysql-async/lib/MySQL.lua'
--[[/	:FSN:	\]]--

ui_page 'ui/ui.html'

dependency 'mysql-async'

client_scripts {
	'client.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'server.lua'
}

-- NUI Files
files {
	'ui/ui.html',
	'ui/ui.js',
    'ui/lcn.jpg'
}



-- Thank Script Base : es_stockmarket 
-- Thank Source Code : kanersps
-- Modify By : UknowXD 