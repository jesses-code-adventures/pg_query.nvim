# pg_query.nvim

neovim wrapper for [pg_query_utils](https://github.com/timwmillard/pg_query_utils.git).

## prerequisites -normal use

Install [pg_query_utils](https://github.com/timwmillard/pg_query_utils.git) by running this script, then call
`which pg_query_prepare` to make sure it was successful.

```bash
git clone --recurse-submodules --depth 1 https://github.com/timwmillard/pg_query_utils.git && \
    cd pg_query_utils && \
    sed -i '' '/^all:/s/pg_describe_query.*//;' Makefile && \
    make && \
    mkdir -p "$$HOME/.local/bin" && \
    cp pg_query_prepare "$$HOME/.local/bin" && \
    cp pg_query_json "$$HOME/.local/bin" && \
    cp pg_query_fingerprint "$$HOME/.local/bin" && \
    cd .. && \
    rm -rf pg_query_utils;
```

## installation

### lazy

```lua
return {
    {
        "jesses-code-adventures/pg_query.nvim",
        keys = {
            { "<leader>pe", function() require("pg_query").edit(); end, mode = "n", desc = "Edit default param values for the query under the cursor." },
            { "<leader>pr", function() require("pg_query").run(); end, mode = "n", desc = "Render postgres query with values, and pipe into output_cmd. Opens an edit window if values don't exist." },
        },
        -- these are the default values. if you're happy with them, you can just pass an empty table to opts.
        opts = {
            output_cmd='pbcopy', -- when rendering your query with values (ie calling render()), the rendered sql command will be piped into this command line program.
            -- we have db_cred_labels so you can pass as flags to psql, etc
            db_cred_labels={
                db_name=nil, -- name of the environment variable pg_query should search for to get the `DB_NAME`.
                db_user=nil, -- name of the environment variable pg_query should search for to get the `DB_USER`.
                db_password=nil, -- name of the environment variable pg_query should search for to get the `DB_PASSWORD`.
                db_port=nil, -- name of the environment variable pg_query should search for to get the `DB_PORT`.
                db_host=nil, -- name of the environment variable pg_query should search for to get the `DB_HOST`.
            },
            ui = {
                field_separator=' ✦ ', -- in the edit buffer, the string that separates the field label from the input text.
                fields_align_right=false, -- in the edit buffer, choose to align the field names to the right of the buffer.
            }
        }
    }
}
```

## dev installation

### dev prerequisites

- Clone this repo.
- In the repo, run `make init`.

### dev lazy config

```lua
local dev = true
local path = vim.fn.expand("~/wherever/you/cloned/pg_query.nvim")

if not vim.loop.fs_stat(path) then
    return {}
end

return {
    {
        "jesses-code-adventures/pg_query.nvim",
        dir = dev and path or nil,
        dev = dev,
        enabled = true,
        keys = {
            { "<leader>pe", function() require("pg_query").edit(); end, mode = "n", desc = "Edit default param values for the query under the cursor." },
            { "<leader>pr", function() require("pg_query").run(); end, mode = "n", desc = "Render postgres query with values, and pipe into output_cmd. Opens an edit window if values don't exist." },
        },
        -- these are the default values. if you're happy with them, you can just pass an empty table to opts.
        opts = {
            output_cmd='pbcopy', -- when rendering your query with values (ie calling render()), the rendered sql command will be piped into this command line program.
            -- we have db_cred_labels so you can pass as flags to psql, etc
            db_cred_labels={
                db_name=nil, -- name of the environment variable pg_query should search for to get the `DB_NAME`.
                db_user=nil, -- name of the environment variable pg_query should search for to get the `DB_USER`.
                db_password=nil, -- name of the environment variable pg_query should search for to get the `DB_PASSWORD`.
                db_port=nil, -- name of the environment variable pg_query should search for to get the `DB_PORT`.
                db_host=nil, -- name of the environment variable pg_query should search for to get the `DB_HOST`.
            },
            ui = {
                field_separator=' ✦ ', -- in the edit buffer, the string that separates the field label from the input text.
                fields_align_right=false, -- in the edit buffer, choose to align the field names to the right of the buffer.
            }
        }
    }
}
```

### todo

- [x] cache queries as fingerprints in XDG_HOME (`vim.fn.stdpath("data")`) with their default values.
- [x] have a write() command that allows you to update the default values. Should be done with a floating window.
- [x] have a render() command that allows you to output the query with the literal values.
- [ ] have a render_prepare() command that allows you to output the query as a prepare statement.
- [x] ability to have an output_cmd config option, which the query can be piped to. defaults to `pbcopy`.
