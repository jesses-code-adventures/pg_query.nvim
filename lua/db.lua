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
---@return DbCreds
function Get_db_creds(labels)
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
    return "postgresql://" .. creds.db_user .. ":" .. creds.db_password .. "@" .. creds.db_host .. ":" .. creds.db_port .. "/" .. creds.db_name
end
