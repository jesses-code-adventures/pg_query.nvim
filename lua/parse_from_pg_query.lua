require("utils")

---@class QueryParam
---@field index integer @The argument index in the sql query.
---@field field string @The name of the field in the query.
---@field field_type string? @The type of the field, which should be inferred from a live database. We assume we don't have access to this.
---@field value any? @The value to be used for this parameter when the query is rendered.

---@class QueryDetails @Query details parsed from pg_query_prepare --details.
---@field query string @The label of the query. 
---@field fingerprint string @The unique fingerprint of the parsed query.
---@field params QueryParam[] @The parameters of the query, including the field name, the argument index, and optionally the field type and argument values.
---@field params_variant string? @The name of the variant of this set of params, defined by the user.


--- takes an array of single key-value pairs split by a given delimiter, and returns the value for the key. 
---@param details string[]
---@param key string
---@param key_value_delimiter string
---@return string?
local function parse_field_from_details(details, key, key_value_delimiter)
    for _, part in ipairs(details) do
        local lil_parts = Split(part, key_value_delimiter)
        local k = lil_parts[1]
        local value = table.concat(lil_parts, key_value_delimiter, 2)
        if key == k and value ~= nil then
            return Trim(value)
        end
    end
    return nil
end

---@param result string
---@return string[]
local function split_details_output(result)
    local resp = {}
    local details = Split(result, " ", 4)
    if #details == 0 then
        return resp
    end
    for _, deet in ipairs(details) do
        table.insert(resp, Trim(deet))
    end
    return resp
end

---Parse the raw query params from pg_query_prepare --details. 
---This will never include arguments/the user defined parameter values (same thing).
---@return QueryParam[]
local function parse_query_params(params_str)
    local params = {}
    local param_parts = Split(params_str, ",")
    for _, param in ipairs(param_parts) do
        local ps = Split(param, ":")
        local index = ps[1]
        local field = Trim(ps[2]) or nil
        local field_type = Trim(ps[3]) or nil
        table.insert(params, {index=index, field=field, field_type=field_type})
    end
    return params
end

---Takes one postgres query as a string, and returns QueryDetails whose params have empty values.
---The response from this will always have a nil params_variant, as we know nothing about the param values here.
---@param query_string string @A postgres query, as a string, to pass to pg_query_prepare --details.
---@return QueryDetails?
function Parse_pg_query_prepare_details(query_string)
    local command = "echo '" .. query_string .. "' | pg_query_prepare --details"
    local result = Run_cli_command(command)
    local details = split_details_output(result)
    if #details == 0 then
        return nil
    end
    local query = parse_field_from_details(details, "query", "=")
    local fingerprint = parse_field_from_details(details, "fingerprint", "=")
    local params_str = parse_field_from_details(details, "params", "=")
    if params_str == nil then
        return { query = query, fingerprint = fingerprint, params = {}, params_variant = nil }
    end
    return { query = query, fingerprint = fingerprint, params = parse_query_params(params_str), params_variant = nil }
end
