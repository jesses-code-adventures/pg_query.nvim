# Contributing

Contributions to this project are welcome! Please have a read through the [scope](#Scope) and [todo](#Todo) sections of this document before making a PR, to ensure your proposed changes make sense for the project. If you're not sure, it's recommended to to create an issue before contributing.

To get setup locally to make a contribution, follow the steps in [dev installation](#dev-installation).

## Scope

This repo is designed to interact with [pg_query_utils](https://github.com/timwmillard/pg_query_utils.git), and as such support for databases outside of postgres is currently out of scope.

The problem we're aiming to solve is that of context switching between Neovim and your database query editor, so the feedback loop between editing queries and running them can be much faster. As such, adding support for `output-mode`s aside from `pbcopy` and `psql-tmux` would be considered in scope, provided the new mode is a reasonably common way to interact with databases.

## Todo

- [x] Edit command - edit the values associated with a query.
- [x] Run command - get the query with the values inserted, and output to the `output-mode`. If there are no values to insert, open up the `edit` window.
- [x] Output mode - formatted query to clipboard with `pbcopy`.
- [x] Output mode - formatted query to psql, in a new tmux window.
- [ ] Handle using the query `name` from the comment for the internal `query` field, instead of using the fingerprint. Waiting on this to be implemented in `pg_query_prepare --details`.
- [ ] Config setting to error on missing db creds vs silently fail.
- [ ] Ability to have variants for query arguments, which would be stored in their own temp files.
- [ ] Handle matching up the stored values when a query's order of args, or number of args, has changed.
- [ ] Abstract `OUTPUT_MODE`s so that they're relatively easy for anyone to add, ideally as config.
- [ ] Ability to override environment variable labels for DB creds for a project (maybe some kind of config file, or we could store some metadata in the `.git` directory more quietly).

## Dev Installation

### Dev Prerequisites

- Clone this repo - `git clone https://github.com/jesses-code-adventures/pg_query.nvim`.
- In the repo, run `make init`.

### Dev Lazy Config

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
