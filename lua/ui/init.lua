local M = {}

---@param file_path string @Path to the file to open or create.
---@param num_params number @Number of empty lines to add if the file doesn't exist.
---@param query_name string? @Query name for display purposes.
local function floating_bufwin_from_path(file_path, num_params, query_name)
    local buf = vim.api.nvim_create_buf(false, true)
    if vim.fn.filereadable(file_path) == 1 then
        vim.api.nvim_buf_call(buf, function()
            vim.cmd("silent! edit " .. vim.fn.fnameescape(file_path))
        end)
    else
        local empty_lines = {}
        for _ = 1, num_params do
            table.insert(empty_lines, "")
        end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, empty_lines)
        vim.api.nvim_buf_call(buf, function()
            vim.cmd("silent! write " .. vim.fn.fnameescape(file_path))
        end)
    end
    local width = 80
    local height = vim.o.lines - 8
    local title = 'pg_query'
    if query_name then
        title = title .. ' - ' .. query_name
    end
    local opts = {
        title = title,
        relative = 'editor',
        width = width,
        height = height,
        border = 'single',
        row = (vim.o.lines - height) / 2,
        col = (vim.o.columns - width) / 2,
    }
    local win = vim.api.nvim_open_win(buf, true, opts)
    vim.api.nvim_set_option_value('fillchars', 'eob: ', { win = win })
    vim.api.nvim_set_option_value('winhl', 'EndOfBuffer:None', { win = win })
    vim.api.nvim_set_option_value('wrap', true, { win = win })
    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_set_option_value('modified', false, { buf = buf })
    vim.api.nvim_set_option_value('buftype', '', { buf = buf })
    return buf, win
end

---@param buf integer
---@param query_params QueryParam[]
---@param fields_align_right boolean
---@param field_separator string
local function render_field_names(buf, query_params, fields_align_right, field_separator)
    local ns_id = vim.api.nvim_create_namespace("field_names_ns")
    for i, param in ipairs(query_params) do
        local line_num = i - 1
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

---@class UIOpts
---@field fields_align_right boolean
---@field field_separator string
---@field query_details QueryDetails
---@field file_path string?

---@param opts UIOpts
function M.edit_query_values(opts)
    M.params = opts.query_details.params
    local buf, _ = floating_bufwin_from_path(opts.file_path, #opts.query_details.params or 0, opts.query_details.query)
    render_field_names(buf, M.params, opts.fields_align_right, opts.field_separator)
    return buf
end

---@param write_fn function 
function M.handle_write(write_fn)
    write_fn(M.query_file_name)
end

return M
