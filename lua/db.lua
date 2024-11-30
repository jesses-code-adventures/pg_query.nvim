---@class DbCredLabels
---@field db_host string? @The DB_HOST value
---@field db_name string? @The DB_NAME value
---@field db_port string? @The DB_PORT value
---@field db_password string? @The DB_PASSWORD value
---@field db_user string? @The DB_USER value

---@class DbCreds
---@field db_host string? @The DB_HOST value
---@field db_name string? @The DB_NAME value
---@field db_port string? @The DB_PORT value
---@field db_password string? @The DB_PASSWORD value
---@field db_user string? @The DB_USER value

---Force a non zero string out of any field with a non-null label.
---@param field string
---@param labels DbCredLabels
local function force_env_var(field, labels)
    if labels and labels[field] then
        return Env_var_must(labels[field])
    end
end

---@param labels DbCredLabels
---@param mode "PBCOPY"|"PSQL_TMUX"
---@return DbCreds
function Get_db_creds(labels, mode)
    -- TODO: use enum rather than literal.
    if mode == "PBCOPY" then
        return {}
    end
    return {
        db_host = force_env_var("db_host", labels),
        db_name = force_env_var("db_name", labels),
        db_port = force_env_var("db_port", labels),
        db_password = force_env_var("db_password", labels),
        db_user = force_env_var("db_user", labels),
    }
end

---@param creds DbCreds
---@return string
function Get_connection_string(creds)
    if not creds.db_user and not creds.db_host and not creds.db_password and not creds.db_port and not creds.db_name then
        error("At least one of db_user, db_host, db_password, db_port and db_name must be passed to create a connection string.")
    end
    local user_pass = (creds.db_user or "") .. (creds.db_password ~= nil and ":" .. creds.db_password or "")
    local host_port = (creds.db_host or "") .. (creds.db_port ~= nil and ":" .. creds.db_port or "")
    if (host_port and host_port ~= "") and (user_pass and user_pass ~= "") then
        user_pass = user_pass .. "@" .. host_port
    end
    if user_pass == nil or user_pass == "" then
        if host_port ~= nil and host_port ~= "" then
            user_pass = host_port
        end
    end
    if creds.db_name and (user_pass == nil or user_pass == "") then
        return creds.db_name
    end
    return "postgresql://" .. (user_pass or "") .. (creds.db_name ~= nil and "/" .. creds.db_name or "")
end
