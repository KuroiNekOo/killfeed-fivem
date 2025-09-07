fx_version 'cerulean'
game 'gta5'

author 'Xam42'
description 'Killfeed NovaCity'
version '1.0.0'

-- Interface utilisateur
-- Indique le fichier HTML à utiliser pour l'interface
ui_page 'html/index.html'

-- Fichiers de l'interface
-- Fichiers accessibles côté client
files {
    'html/index.html',
    'html/script.js',
    'html/style.css'
}

-- Scripts serveur
server_scripts {
    'config.lua',
    'server/points.lua',
    'server/discord.lua',
    'server/server.lua',
    'server/commands.lua'
}

-- Scripts client
client_scripts {
    'config.lua',
    'client/ui.lua',
    'client/events.lua',
    'client/commands.lua',
    'client/client.lua'
}