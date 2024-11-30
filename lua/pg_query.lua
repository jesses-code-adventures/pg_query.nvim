require("utils")
require("temp_files")
require("output")
require("parse_from_vim")
require("parse_from_pg_query")
require("db")

---@class OUTPUT_MODE
---@field PBCOPY "PBCOPY"
---@field PSQL_TMUX "PSQL_TMUX"
local OUTPUT_MODE = {
    PBCOPY = "PBCOPY",
    PSQL_TMUX = "PSQL_TMUX",
}

local M = {}

function M.edit()
    local query = Get_nearest_sql_command()
    local details = Parse_pg_query_prepare_details(query)
    if details == nil then
        print("No query found")
        return
    end
    local query_file_path = Query_file_path(details)
    local values_file_path = Values_file_path(details)
    Write_query_details_no_params(query_file_path, details)
    M.buf = M.ui.open_edit_window(details, values_file_path, M.ui_opts)
end

---@param mode "PBCOPY"|"PSQL_TMUX"
---@param query string 
---@param db_creds DbCreds
local function getCommand(mode, query, db_creds)
    if mode == OUTPUT_MODE.PBCOPY then
        return "echo \"" .. query .. '"' .. " | pbcopy"
    elseif mode == OUTPUT_MODE.PSQL_TMUX then
        local connection_string = Get_connection_string(db_creds)
        local formatted_query = query:gsub("\n", " "):gsub("%s+", " ")
        local tmux_command = [[
tmux list-windows \
    | grep -q 'pg_query' && tmux select-window -t pg_query \
    || tmux new-window -n pg_query
tmux send-keys -t pg_query "psql -d ]]
.. connection_string
.. [[ -c \"]] .. formatted_query .. [[\"" Enter]]
        return tmux_command
    end
end

function M.run()
    local query = Get_nearest_sql_command()
    local details = Parse_pg_query_prepare_details(query)
    if details == nil then
        print("No query found")
        return
    end
    local values_file_path = Values_file_path(details)
    if not Exists(values_file_path) then
        M.edit()
        return
    end
    Parse_query_values(values_file_path, details)
    local replaced = Render_inplace_placeholders(query, details.params, M.mode == OUTPUT_MODE.PSQL_TMUX)
    local command = getCommand(M.mode, replaced, M.db_creds)
    Run_command(command)
end

---@class PgQueryOpts
---@field output_mode string @The program that handles the query. Defaults to `pbcopy`, but you can pass `tmux-psql` too. 
---@field db_cred_labels DbCredLabels? @Optional name of the environment variable to source the DB_NAME.
---@field ui UIOpts

---@param mode string
---@return "PBCOPY"|"PSQL_TMUX"
local function handle_output_mode(mode)
    local transformed = mode:gsub("-", "_"):upper()
    if transformed == OUTPUT_MODE.PBCOPY then
        return OUTPUT_MODE.PBCOPY
    elseif transformed == OUTPUT_MODE.PSQL_TMUX then
        return OUTPUT_MODE.PSQL_TMUX
    else
        print("invalid output_mode [" .. mode .. "], defaulting to pbcopy.")
        return OUTPUT_MODE.PBCOPY
    end
end

---@param opts PgQueryOpts
function M.setup(opts)
    opts = opts or {}
    if not Ensure_binary_available("pg_query_prepare") then
        error("please install `pg_query_prepare` - see 'prerequisites' in `README.md`.")
        return
    end
    M.mode = handle_output_mode(opts.output_mode or "pbcopy")
    -- TODO: handle checking for prereqs based on output_mode
    M.ui = require("ui")
    M.ui_opts = opts.ui or {}
    M.db_creds = Get_db_creds(opts.db_cred_labels or {})
    if M.db_creds.db_password then
        vim.env.PGPASSWORD = M.db_creds.db_password
    end
    local success, msg = Run_command("mkdir -p " .. Get_temp_dir())
    if not success then
        error("Could not create pg_query temp_dir: " .. msg)
    end
end

return M
