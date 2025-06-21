fx_version 'cerulean'
game 'gta5'

description 'Locker system'
author 'Kilian'
version '1.0.0'

shared_script '@es_extended/imports.lua'

client_script 'client.lua'
server_script {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

--[[
CREATE TABLE IF NOT EXISTS kilian_locker_db (
    identifier VARCHAR(50) NOT NULL,
    items LONGTEXT DEFAULT NULL,
    weapons LONGTEXT DEFAULT NULL,
    PRIMARY KEY (identifier)
);
]]
