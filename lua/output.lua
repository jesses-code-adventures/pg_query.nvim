---takes an sql query and a list of default params and replaces the query's placeholders with the values.
---@param query string
---@param params QueryParam[]
---@return string
function Render_inplace_placeholders(query, params)
    for _, param in ipairs(params) do
        if param.value == nil then
            param.value = "''" -- TODO: throw error when updating arguments is enabled
            -- error("expected a value for field \"" .. param.field .. "\" (argument index " .. param.index .. "), received nil.")
        end
        -- TODO: handle > single digit indexes
        local placeholder = " $" .. param.index .. ""
        query = query:gsub(placeholder, " " .. param.value .. " ")
    end
    return query
end

