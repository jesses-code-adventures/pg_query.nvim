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
    M.buf = M.ui.open_edit_window({fields_align_right=M.fields_align_right, field_separator=M.field_separator, details=details, file_path=values_file_path})
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

---@class PgQueryOpts
---@field output_cmd string @The CLI program to pipe your SQL queries into. Defaults to 'pbcopy'.
---@field field_separator string @The string separating the query values you're editing and the field name. Defaults to ' ✦ '.
---@field fields_align_right boolean @In the edit buffer, align the field names to the right of the buffer. Defaults to false.
---@field env_db_name string? @Optional name of the environment variable to source the DB_NAME.

---@param opts PgQueryOpts
function M.setup(opts)
    opts = opts or {}
    M.ui = require("ui")
    M.output_cmd = opts.output_cmd or "pbcopy"
    M.field_separator = opts.field_separator or " ✦ "
    M.fields_align_right = opts.fields_align_right or false
    M.db_name = nil
    if opts.env_db_name then
        M.db_name = Env_var_must(opts.env_db_name)
    end
    if not Ensure_binary_available("pg_query_prepare") then
        return
    end
    local success, msg = Run_command("mkdir -p " .. Get_temp_dir())
    if not success then
        error("Could not create pg_query temp_dir: " .. msg)
    end
end

return M
