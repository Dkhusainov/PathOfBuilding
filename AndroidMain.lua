--
-- Created by IntelliJ IDEA.
-- User: mole
-- Date: 21.06.2017
-- Time: 21:48
-- To change this template use File | Settings | File Templates.
--

-- all the hacks for luaj to work
bit = bit32
function LoadModule(name, ...)
    print("Loading " .. name .. "...")
    local a = assert(loadfile(name..".lua"))
    local result = a(...)
    print("Loaded  " .. name .. ".")
    return result
end

function ConPrintf(text, ...)
    local t = string.format(text, ...)
    print(t)
end

function MakeDir(a) end

--[[
--
-- Luaj unpack(table) - attempt to call nil
-- Luaj table.unpack() - attempt to call nil
--
-- Great api (:
-- ]]
function unpack(t)
    local pairs = pairs
    local c = 0
    for _, _ in pairs(t) do
        c = c + 1
    end
    if c == 0 then
        return
    elseif c == 1 then return t[1]
    elseif c == 2 then return t[1],t[2]
    elseif c == 3 then return t[1],t[2],t[3]
    elseif c == 4 then return t[1],t[2],t[3],t[4]
    elseif c == 5 then return t[1],t[2],t[3],t[4],t[5]
    elseif c == 6 then return t[1],t[2],t[3],t[4],t[5],t[6]
    elseif c == 7 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7]
    elseif c == 8 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8]
    elseif c == 9 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9]
    elseif c == 10 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10]
    elseif c == 11 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11]
    elseif c == 12 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12]
    elseif c == 13 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13]
    elseif c == 14 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14]
    elseif c == 15 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15]
    elseif c == 16 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16]
    elseif c == 17 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17]
    elseif c == 18 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18]
    elseif c == 19 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19]
    elseif c == 20 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20]
    elseif c == 21 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21]
    elseif c == 22 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22]
    elseif c == 23 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23]
    elseif c == 24 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24]
    elseif c == 25 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25]
    elseif c == 26 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26]
    elseif c == 27 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27]
    elseif c == 28 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28]
    elseif c == 29 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29]
    elseif c == 30 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30]
    elseif c == 31 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31]
    elseif c == 32 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32]
    elseif c == 33 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33]
    elseif c == 34 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34]
    elseif c == 35 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35]
    elseif c == 36 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36]
    elseif c == 37 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37]
    elseif c == 38 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38]
    elseif c == 39 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39]
    elseif c == 40 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39],t[40]
    elseif c == 41 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39],t[40],t[41]
    elseif c == 42 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39],t[40],t[41],t[42]
    elseif c == 43 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39],t[40],t[41],t[42],t[43]
    elseif c == 44 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39],t[40],t[41],t[42],t[43],t[44]
    elseif c == 45 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39],t[40],t[41],t[42],t[43],t[44],t[45]
    elseif c == 46 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39],t[40],t[41],t[42],t[43],t[44],t[45],t[46]
    elseif c == 47 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39],t[40],t[41],t[42],t[43],t[44],t[45],t[46],t[47]
    elseif c == 48 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39],t[40],t[41],t[42],t[43],t[44],t[45],t[46],t[47],t[48]
    elseif c == 49 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39],t[40],t[41],t[42],t[43],t[44],t[45],t[46],t[47],t[48],t[49]
    elseif c == 50 then return t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[14],t[15],t[16],t[17],t[18],t[19],t[20],t[21],t[22],t[23],t[24],t[25],t[26],t[27],t[28],t[29],t[30],t[31],t[32],t[33],t[34],t[35],t[36],t[37],t[38],t[39],t[40],t[41],t[42],t[43],t[44],t[45],t[46],t[47],t[48],t[49],t[50]
    else
        error("c - " .. c)
    end
end

local launch = {
    devMode = true
}

defaultTargetVersion = "3_0"
liveTargetVersion = "3_0"
targetVersionList = { "3_0" }

LoadModule("Helper")

LoadModule("Modules/Common")
LoadModule("Modules/Data", launch)
LoadModule("Modules/ModTools", "3_0")
--LoadModule("Modules/ItemTools", launch)
LoadModule("Modules/CalcTools")
LoadModule("Modules/Calcs", "3_0")

function parseMod(line)
    return modLib.parseMod[liveTargetVersion](line)
end

function abc()

end