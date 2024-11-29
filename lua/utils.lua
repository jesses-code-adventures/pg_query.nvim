TEMP_FILE_SEPARATOR = "-_-_-"

---@param file_path string
---@param mode string?
---@return file*
function Open_or_error(file_path, mode)
    local file = io.open(file_path, mode)
    if not file then
        error("Failed to open file: " .. file_path)
    end
    return file
end

---@param command string
---@return any
function Run_cli_command(command)
    local handle = io.popen(command)
    if not handle then
        error("couldn't get a handle for the attempted command: " .. command)
    end
    local result = handle:read("*a")
    handle:close()
    return result
end

---@param file_path string
---@return boolean
function Exists(file_path)
    local file = io.open(file_path, "r")
    if file then
        io.close(file)
        return true
    else
        return false
    end
end

---@return string
function Get_temp_dir()
    return vim.fn.stdpath("data") .. "/pg_query/"
end

---@param label string
---@return string
function Get_query_temp_path(label)
    return Get_temp_dir() .. label
end


---@param s string 
---@return string
function Trim(s)
    if not s then
        return s
    end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end


---@param value string
---@param delim string
---@param max_occurances number?
---@return string[]
function Split(value, delim, max_occurances)
    local parts = {}
    local pattern = "([^" .. delim .. "]+)"
    local idx = 1
    local matched = value:gmatch(pattern)
    for part in matched do
      table.insert(parts, part)
      idx = idx + 1
      if max_occurances ~= nil and idx > max_occurances then
          -- TODO: could be improved, will break on lists where multiple keys have the same value which shouldn't happen but who knows
          local found = value:find(part)
          if found == nil then
              error("this should never happen")
          end
          local remaining = value:sub(found)
          parts[max_occurances] = table.concat({parts[max_occurances], remaining}, delim)
          return parts
      end
    end
    return parts
end

---@param command string
---@param mode string?
---@return boolean, string|"exit"|"signal"?
function Run_command(command, mode)
    local handle = io.popen(command, mode)
    if handle then
        local result = handle:read("*a")
        local success, reason, exit_code = handle:close()
        if success then
            return true, result
        else
            print("Command failed: " .. (reason or "unknown") .. "\nexit code: " .. exit_code)
            return false, reason
        end
    else
        print("Failed to start command " .. command)
        return false, nil
    end
end

---@param binary_name string
---@return boolean
function Ensure_binary_available(binary_name)
    local success, _ = Run_command("which ".. binary_name)
    if not success then
        error(binary_name .. " not available, install " .. " or add it to your PATH")
    end
    return success
end

---@param query_details QueryDetails
---@return string
function Query_file_path(query_details)
    -- TODO: add fingerprint if we want it, so we can match against `query` and invalidate if `fingerprint` doesn't match
    return Get_query_temp_path(query_details.query)
end

---@param query_details QueryDetails
---@return string
function Values_file_path(query_details)
    local fallback = "__PG_QUERY_UTILS_ARGS_FALLBACK__"
    -- TODO: add fingerprint if we want it, so we can match against `query` and invalidate if `fingerprint` doesn't match
    if query_details.params_variant then
        return Get_query_temp_path(query_details.query) .. TEMP_FILE_SEPARATOR .. query_details.params_variant
    end
    return Get_query_temp_path(query_details.query .. TEMP_FILE_SEPARATOR .. fallback)
end

---@param var string
---@return string
function Env_var_must(var)
    local val = os.getenv(var)
    if not val then
        error("Missing expected environment variable for [" .. var .. "].")
    end
    return val
end
