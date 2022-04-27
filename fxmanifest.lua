fx_version 'adamant'
game 'gta5'

client_scripts { "@vrp/client/Proxy.lua", "@vrp/client/Tunnel.lua", 'config.lua', 'client.lua', 'utils.lua'}

server_scripts { "@vrp/lib/utils.lua", 'server.lua'}
 

ui_page 'ui/ui.html'
files {
	'ui/ui.html',
	'ui/js/*.js',
	'ui/css/*.css',
	'ui/images/*.png',
	'ui/css/fonts/*.ttf',

}

exports {
	'GeneratePlate'
}