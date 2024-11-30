# pg_query.nvim

Neovim wrapper for [pg_query_utils](https://github.com/timwmillard/pg_query_utils.git).

![initial usage jif](https://github.com/user-attachments/assets/3482472f-909f-44dd-83e0-549ba6496f60)

## Prerequisites

Install [pg_query_utils](https://github.com/timwmillard/pg_query_utils.git) by running this script, then call `which pg_query_prepare` to make sure it was successful.

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

## Installation

### Lazy

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
            -- we default to putting the rendered query into your system clipboard. also available is `psql-tmux`, allowing you to run the query in psql, in a new tmux window.
            output_mode='pbcopy',
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

## Contributing

Contributions to this project are welcome, please read [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.
