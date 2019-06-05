return {
    app = {
        httpMethods = {
            get = true,
            post = true,
            put = true,
            delete = true
        }
    },
    router = {
        mode = {
            hash = 1,   -- static as default
            trie = 2    -- dynamic
        },
        Err404 = {
            ec = 404,
            em = "404 not found"
        }
    },
    request = {
        maxHeaders = 16,
        -- according to the actual situation to adjust the order
        contentType = {
            "application/x-www-form-urlencoded",
            "application/json"
        }
    }
}