package.path = "./lua/?.lua;" .. package.path
require("db")
dofile("./tests/t/init.lua")

local function test_Get_connection_string()
    -- everything
    local test_case = "All variables"
    local want = "postgresql://thisisauser:secret@localhost:5432/test_db"
    local db_creds = {
        db_user = "thisisauser",
        db_password = "secret",
        db_host = "localhost",
        db_port = "5432",
        db_name = "test_db",
    }
    local connection_string = Get_connection_string(db_creds)
    Assert_eq(connection_string, want, test_case)
    print("PASS: ", test_case)
    -- no db_host or port
    test_case = "No db_host or port"
    want = "postgresql://thisisauser:secret/test_db"
    db_creds = {
        db_user = "thisisauser",
        db_password = "secret",
        db_name = "test_db",
    }
    connection_string = Get_connection_string(db_creds)
    Assert_eq(connection_string, want, test_case)
    print("PASS: ", test_case)
    -- no username or password
    test_case = "No username or password"
    want = "postgresql://localhost:5432/test_db"
    db_creds = {
        db_host = "localhost",
        db_port = "5432",
        db_name = "test_db",
    }
    connection_string = Get_connection_string(db_creds)
    Assert_eq(connection_string, want, test_case)
    print("PASS: ", test_case)
    -- just db_name
    test_case = "No db_host or port"
    want = "test_db"
    db_creds = {
        db_name = "test_db",
    }
    connection_string = Get_connection_string(db_creds)
    Assert_eq(connection_string, want, test_case)
    print("PASS: ", test_case)
end

test_Get_connection_string()
