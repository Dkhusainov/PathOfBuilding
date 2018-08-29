local inspect = require("inspect")
function printToFile(t, name, depth)
    local file = io.open("debug/"..name..depth..".txt", "w")
    io.output(file)
    io.write("\n")
    local options = {
        depth = depth,
        --        process = true
    }
    local result = inspect.inspect(t, options)
    io.write(result)
    io.write("\n")
    io.close(file)
end