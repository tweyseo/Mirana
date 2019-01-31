return {
    TCP_CLIENT = {
        maxIdleTimeout = 2 * 60 * 1000, -- ms
        poolSize = 200,
        connectTimeout = 5 * 1000, -- ms
        sendTimeout = 30 * 1000, -- ms
        readTimeout = 30 * 1000, -- ms
        addr = "192.25.106.105",
        port = 19527,
        pattern = "\r\n" -- use "\r\n" as defult message boundary
    },
    TCP_SERVER = {
        connectTimeout = 5 * 1000, -- ms
        sendTimeout = 30 * 1000, -- ms
        readTimeout = 30 * 1000, -- ms
        pattern = "\r\n" -- use "\r\n" as defult message boundary
    },
    HTTP_CLIENT = {
        maxIdleTimeout = 2 * 60 * 1000, -- ms
        poolSize = 200,
        connectTimeout = 5 * 1000, -- ms
        sendTimeout = 30 * 1000, -- ms
        readTimeout = 30 * 1000, -- ms
        addr = "192.25.106.105",
        port = 29527,
        defaultContentType = "application/json",
    }
}