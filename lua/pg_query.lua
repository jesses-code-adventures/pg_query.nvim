require("utils")
require("temp_files")
require("output")
require("parse_from_vim")
require("parse_from_pg_query")

local M = {}

function M.edit()
    local query = Get_nearest_sql_command()
    local details = Parse_pg_query_prepare_details(query)
    if details == nil then
        print("No query found")
        return
    end
    local query_file_path = Query_file_path(details)
    Write_query_details_no_params(query_file_path, details)
    local values_file_path = Values_file_path(details)
    print(vim.inspect(details))
    M.buf = M.ui.open_edit_window(details, values_file_path, M.ui_opts)
end

function M.run()
    local query = Get_nearest_sql_command()
    local details = Parse_pg_query_prepare_details(query)
    if details == nil then
        print("No query found")
        return
    end
    local values_file_path = Values_file_path(details)
    if not values_file_path or not Exists(values_file_path) then
        M.edit()
        return
    end
    Parse_query_values(values_file_path, details)
    local replaced = Render_inplace_placeholders(query, details.params)
    local command = "echo \"" .. replaced .. '"' .. " | " .. M.output_cmd
    Run_command(command)
end

---@class DbCredLabels
---@field db_host string? @The DB_HOST value
---@field db_name string? @The DB_NAME value
---@field db_port string? @The DB_PORT value
---@field db_password string? @The DB_PASSWORD value
---@field db_user string? @The DB_USER value

---@class PgQueryOpts
---@field output_cmd string @The CLI program to pipe your SQL queries into. Defaults to 'pbcopy'.
---@field db_cred_labels DbCredLabels? @Optional name of the environment variable to source the DB_NAME.
---@field ui UIOpts

---@param opts PgQueryOpts
function M.setup(opts)
    opts = opts or {}
    if not Ensure_binary_available("pg_query_prepare") then
        error("please install `pg_query_prepare` - see 'prerequisites' in `README.md`.")
        return
    end
    M.ui = require("ui")
    M.ui_opts = opts.ui or {}
    M.db_cred_labels = opts.db_cred_labels or {}
    M.output_cmd = opts.output_cmd or "pbcopy"
    if M.db_cred_labels and M.db_cred_labels.db_name then
        M.db_name = Env_var_must(M.db_cred_labels.db_name)
    end
    local success, msg = Run_command("mkdir -p " .. Get_temp_dir())
    if not success then
        error("Could not create pg_query temp_dir: " .. msg)
    end
end

return M
