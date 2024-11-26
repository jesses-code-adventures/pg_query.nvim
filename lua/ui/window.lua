local api = vim.api

local M = {}

local function create_floating_window()
    local buf = api.nvim_create_buf(false, true)
    local width = 80
    local height = vim.o.lines - 8
    local opts = {
        title = 'pg_query',
        relative = 'editor',
        width = width,
        height = height,
        border = 'single',
        row = (vim.o.lines - height) / 2,
        col = (vim.o.columns - width) / 2,
    }
    local win = api.nvim_open_win(buf, true, opts)
    vim.api.nvim_set_option_value('fillchars', 'eob: ', { win = win })
    vim.api.nvim_set_option_value('winhl', 'EndOfBuffer:None', { win = win })
    vim.api.nvim_set_option_value('wrap', true, { win = win })
    return buf, win
end

---@param buf integer
---@param query_params QueryParam[]
local function setup_keymaps(buf, query_params)
    api.nvim_buf_set_keymap(buf, 'n', '<CR>', [[<Cmd>lua require('pg_query').edit_param()<CR>]], { noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n', 'dd', '0d$', { noremap = true, silent = true })
    vim.b.query_params = query_params
    vim.cmd(string.format([[
        autocmd BufWritePre <buffer=%d> lua require('pg_query').update_query_params(%d)
    ]], buf, buf))
end

---@param buf integer
---@param query_params QueryParam[]
---@param fields_align_right boolean
local function render_query_params(buf, query_params, fields_align_right, field_separator)
    local ns_id = vim.api.nvim_create_namespace("query_params_ns")
    for i, param in ipairs(query_params) do
        local line_num = i - 1
        if vim.api.nvim_buf_line_count(buf) <= line_num then
            vim.api.nvim_buf_set_lines(buf, line_num, line_num, false, { "" })
        end
        local field_text = param.field or ""
        if field_text ~= "" then
            field_text = field_separator .. field_text
        end
        local virt_text = {{ field_text, "DiagnosticInfo" }}
        vim.api.nvim_buf_set_extmark(buf, ns_id, line_num, 0, {
            virt_text = virt_text,
            virt_text_pos = fields_align_right and "right_align" or "eol",
        })
    end
end

---@param buf integer
---@param query_params QueryParam[]
---@return QueryParam[] | nil
local function update_query_params_with_buffer_values(buf, query_params)
    print("updating query params...")
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if #lines ~= #query_params then
        error("Mismatch: Number of buffer lines does not match query_params length")
    end
    for i, line in ipairs(lines) do
        query_params[i].value = line
    end
    print("updated query params...")
    print(vim.inspect(query_params))
    return query_params
end

---@class UIOpts
---@field fields_align_right boolean
---@field field_separator string

---@param query_params QueryParam[]
---@param opts UIOpts
function M.edit_query_values(query_params, opts)
    M.params = query_params
    local buf, _ = create_floating_window()
    render_query_params(buf, M.params, opts.fields_align_right, opts.field_separator)
    setup_keymaps(buf, M.params)
    return buf
end

---@return QueryParam[]
function M.return_edited_values()
    return vim.b.query_params
end

---@param write_fn function 
function M.handle_write(write_fn)
    write_fn(M.query_file_name)
end

return M

-- function M.edit_param()
--     local cursor = api.nvim_win_get_cursor(0)
--     local line = cursor[1] local query_params = vim.b.query_params
--     if line <= #query_params then
--         query_params = edit_value(query_params, line)
--         vim.b.query_params = query_params
--     end
--     return vim.b.query_params
-- end

-- --- @param query_params QueryParam[]
-- --- @param index integer
-- --- @return QueryParam[]
-- local function edit_value(query_params, index)
--     local prompt = string.format("Edit value for %s: ", query_params[index].field)
--     vim.ui.input({ prompt = prompt, default = query_params[index].value or "" }, function(input)
--         if input then
--             query_params[index].value = input
--             return query_params
--         end
--     end)
--     return query_params
-- end
