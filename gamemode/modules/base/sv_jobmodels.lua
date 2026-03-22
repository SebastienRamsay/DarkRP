util.AddNetworkString("DarkRP_preferredjobmodels")
util.AddNetworkString("DarkRP_preferredjobmodel")
util.AddNetworkString("DarkRP_preferredBodyGroups")
util.AddNetworkString("DarkRP_all_preferredBodyGroups")
util.AddNetworkString("DarkRP_preferredSkin")
util.AddNetworkString("DarkRP_preferredSkins")

local preferredJobModels = {}
local preferredBodyGroups = {}
local preferredSkins = {}
local plyMeta = FindMetaTable("Player")

local received = {}
net.Receive("DarkRP_preferredjobmodels", function(len, ply)
    preferredJobModels[ply] = {}

    for i in pairs(RPExtraTeams) do
        if net.ReadBit() == 0 then continue end

        preferredJobModels[ply][i] = net.ReadString()
    end

    if not received[ply] and preferredJobModels[ply][ply:Team()] then
        gamemode.Call("PlayerSetModel", ply)
    end

    received[ply] = true
end)

net.Receive("DarkRP_preferredjobmodel", function(len, ply)
    local teamNr = net.ReadUInt(8)
    local model = net.ReadString()

    if not RPExtraTeams[teamNr] then return end

    preferredJobModels[ply] = preferredJobModels[ply] or {}
    preferredJobModels[ply][teamNr] = model
end)

local receivedBG = {}
net.Receive("DarkRP_all_preferredBodyGroups", function(len, ply)
    preferredBodyGroups[ply] = {}

    for i in pairs(RPExtraTeams) do
        if net.ReadBit() == 0 then continue end

        preferredBodyGroups[ply][i] = net.ReadTable()
    end

    receivedBG[ply] = true
end)

net.Receive("DarkRP_preferredBodyGroups", function(len, ply)
    local teamNr = net.ReadUInt(8)
    local bodygroups = net.ReadTable()

    if not RPExtraTeams[teamNr] then return end

    preferredBodyGroups[ply] = preferredBodyGroups[ply] or {}
    preferredBodyGroups[ply][teamNr] = bodygroups
end)

local receivedSkins = {}
net.Receive("DarkRP_preferredSkins", function(len, ply)
    preferredSkins[ply] = {}

    for i in pairs(RPExtraTeams) do
        if net.ReadBit() == 0 then continue end

        preferredSkins[ply][i] = net.ReadUInt(10)
    end

    receivedSkins[ply] = true
end)

net.Receive("DarkRP_preferredSkin", function(len, ply)
    local teamNr = net.ReadUInt(8)
    local skin = net.ReadUInt(10)

    if not RPExtraTeams[teamNr] then return end

    preferredSkins[ply] = preferredJobModels[ply] or {}
    preferredSkins[ply][teamNr] = skin
end)

function plyMeta:getPreferredModel(TeamNr)
    preferredJobModels[self] = preferredJobModels[self] or {}

    return preferredJobModels[self][TeamNr]
end

function plyMeta:getPreferredBodyGroups(TeamNr)
    preferredBodyGroups[self] = preferredBodyGroups[self] or {}

    return preferredBodyGroups[self][TeamNr]
end

function plyMeta:getPreferredSkin(TeamNr)
    preferredSkins[self] = preferredSkins[self] or {}

    return preferredSkins[self][TeamNr]
end