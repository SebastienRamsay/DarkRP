-- Create a table for the preferred playermodels
--
-- Note: in DarkRP before 2024-09, there was a different table called
-- `darkp_playermodels` (note the misspelling of "darkp"). This table was
-- missing the server column, meaning that preferred job models would persist
-- across multiple servers. To make preferred job models store per server, this
-- new table (without the spelling mistake) was created.
--
-- See the original issue to create the player model preference feature:
-- https://github.com/FPtje/DarkRP/issues/979 and the subsequent refactor at
-- https://github.com/FPtje/DarkRP/pull/3266
sql.Query([[CREATE TABLE IF NOT EXISTS darkrp_playermodels(
    server TEXT NOT NULL,
    jobcmd TEXT NOT NULL,
    model TEXT NOT NULL,
    PRIMARY KEY (server, jobcmd)
);]])

sql.Query([[DROP TABLE IF EXISTS darkrp_playerbodygroups;]])
sql.Query([[CREATE TABLE IF NOT EXISTS darkrp_playerbodygroups(
    server TEXT NOT NULL,
    jobcmd TEXT NOT NULL,
    model TEXT NOT NULL,
    bodygroups TEXT NOT NULL,
    PRIMARY KEY (server, jobcmd)
);]])


local preferredModels = {}
local preferredBodygroups = {}


--[[---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------]]
function DarkRP.setPreferredJobModel(teamNr, model)
    local job = RPExtraTeams[teamNr]
    if not job then return end
    preferredModels[job.command] = model
    sql.Query(string.format([[REPLACE INTO darkrp_playermodels(server, jobcmd, model) VALUES(%s, %s, %s);]], sql.SQLStr(game.GetIPAddress()), sql.SQLStr(job.command), sql.SQLStr(model)))

    net.Start("DarkRP_preferredjobmodel")
        net.WriteUInt(teamNr, 8)
        net.WriteString(model)
    net.SendToServer()
end

function DarkRP.getPreferredJobModel(teamNr)
    local job = RPExtraTeams[teamNr]
    if not job then return end
    return preferredBodygroups[job.command]
end

function DarkRP.setPreferredJobBodyGroups(teamNr, groups)
    print(teamNr)
    PrintTable(groups)
    local job = RPExtraTeams[teamNr]
    if not job then return end
    preferredBodygroups[job.command] = groups
    PrintTable(preferredBodygroups)
    sql.Query(string.format([[REPLACE INTO darkrp_playerbodygroups(server, jobcmd, model, bodygroups) VALUES(%s, %s, %s, %s);]], sql.SQLStr(game.GetIPAddress()), sql.SQLStr(job.command), sql.SQLStr(job.model), sql.SQLStr(util.TableToJSON(groups))))

    net.Start("DarkRP_preferredBodyGroups")
        net.WriteUInt(teamNr, 8)
        net.WriteTable(groups)
    net.SendToServer()
end

function DarkRP.getPreferredBodyGroups(teamNr)
    local job = RPExtraTeams[teamNr]
    if not job then return end
    return preferredBodygroups[job.command]
end

--[[---------------------------------------------------------------------------
Load the preferred models
---------------------------------------------------------------------------]]
local function sendModels()
    net.Start("DarkRP_preferredjobmodels")
        for _, job in pairs(RPExtraTeams) do
            if not preferredModels[job.command] then net.WriteBit(false) continue end

            net.WriteBit(true)
            net.WriteString(preferredModels[job.command])
        end
    net.SendToServer()
end

local function jobHasModel(job, model)
    return istable(job.model) and table.HasValue(job.model, model) or job.model == model
end

local function setPreferredModels(models)
    for _, v in ipairs(models) do
        local job = DarkRP.getJobByCommand(v.jobcmd)
        if job == nil or not jobHasModel(job, v.model) then continue end

        preferredModels[v.jobcmd] = v.model
    end
end

local function setPreferredBodygroups(bodygroups)
    for _, v in pairs(bodygroups) do
        local job = DarkRP.getJobByCommand(v.jobcmd)
        if job == nil then continue end

        preferredBodygroups[v.jobcmd] = util.JSONToTable(v.bodygroups)
    end
end

-- The old table, darkp_playermodels, acts as a global mapping of preferred
-- models for jobs.
local function setModelsFromOldTable()
    local oldTableExists = tobool(sql.QueryValue([[SELECT 1 FROM sqlite_master WHERE type='table' AND name='darkp_playermodels']]))
    if not oldTableExists then return end

    local models = sql.Query([[SELECT jobcmd, model FROM darkp_playermodels;]])

    if not models then return end
    setPreferredModels(models)
end

-- The newer table is server specific.
local function setModelsFromNewTable()
    local models = sql.Query(string.format([[SELECT jobcmd, model FROM darkrp_playermodels WHERE server = %s;]], sql.SQLStr(game.GetIPAddress())))

    if not models then return end
    setPreferredModels(models)
end

local function setBodygGroupsFromTable()
    local bodygroups = sql.Query(string.format([[SELECT jobcmd, bodygroups FROM darkrp_playerbodygroups WHERE server = %s;]], sql.SQLStr(game.GetIPAddress())))

    if not bodygroups then return end
    setPreferredBodygroups(bodygroups)
end

timer.Simple(0, function()
    -- Run after the jobs have loaded, to make sure the jobs can be looked up.

    -- Set models from the old table, before overriding them with data from the
    -- new table. That way, server specific preferences always have precedence.
    setModelsFromOldTable()
    setModelsFromNewTable()
    setBodygGroupsFromTable()

    sendModels()
end)
