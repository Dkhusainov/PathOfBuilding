local inspect = require("inspect")
function printToFile(t)
    local filezz = io.open("log.txt", "a")
    io.output(filezz)
    io.write("\n")
    local options = {
        depth = 10,
--        process = true
    }
    local result = inspect.inspect(t, options)
    io.write(result)
    io.write("\n")
    io.close(filezz)
end