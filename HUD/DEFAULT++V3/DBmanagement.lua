--Data:init(tag,value)
--Data:setData(tag,value)
--Data:getData(tag,value)
--Data:ResetAll
--Data:serialize(value)
--Data:deserialize(string)
---------------------------------------------------------------------
-- Add in script unit start with a databank connected named DB:
--if DB then 
--    require "autoconf.custom.DEFAULT++.Databank"  -- change to the location of the file
--    Data = Databank.new(DB)
--end
----------------------------------------------------------------------
Databank = {}
Databank.__index = Databank;

function Databank.new(bank)
    local self = setmetatable({}, Databank)
    self.DB = bank
    self.concat = table.concat
    return self
end

function Databank.clearKey(self,key)
    return self.DB.clearValue(key)
end

function Databank.hasKey(self,key)
    return self.DB.hasKey(key)
end

function Databank.getString(self,tag)
    return self.DB.getStringValue(tag)
end

function Databank.setString(self,tag,value)
    self.DB.setStringValue(tag,value)
end

function Databank.setData(self,tag,value)
    local str = self:serialize(value)
    self.DB.setStringValue(tag,str)
end

function Databank.getData(self,tag)
    local str = self:deserialize(self.DB.getStringValue(tag))
    --if str == "" or #str == 0 then return nil end
    return str
end

function Databank.ResetAll(self)
    self.DB.clear()
end


function Databank.internalSerialize(self,table, tC, t)
    t[tC] = "{"
    tC = tC + 1
    if #table == 0 then
        local hasValue = false
        for key, value in pairs(table) do
            hasValue = true
            local keyType = type(key)
            if keyType == "string" then
                t[tC] = key .. "="
            elseif keyType == "number" then
                t[tC] = "[" .. key .. "]="
            elseif keyType == "boolean" then
                t[tC] = "[" .. tostring(key) .. "]="
            else
                t[tC] = "notsupported="
            end
            tC = tC + 1
            local check = type(value)
            if check == "table" then
                tC = self:internalSerialize(value, tC, t)
            elseif check == "string" then
                t[tC] = '"' .. value .. '"'
            elseif check == "number" then
                t[tC] = value
            elseif check == "boolean" then
                t[tC] = tostring(value)
            else
                t[tC] = '"Not Supported by Deserializer"'
            end
            t[tC + 1] = ","
            tC = tC + 2
        end
        if hasValue then
            tC = tC - 1
        end
    else
        for i = 1, #table do
            local value = table[i]
            local check = type(value)
            if check == "table" then
                tC = self:internalSerialize(value, tC, t)
            elseif check == "string" then
                t[tC] = '"' .. value .. '"'
            elseif check == "number" then
                t[tC] = value
            elseif check == "boolean" then
                t[tC] = tostring(value)
            else
                t[tC] = '"Not Supported by Deserializer"'
            end
            t[tC + 1] = ","
            tC = tC + 2
        end
        tC = tC - 1
    end
    t[tC] = "}"
    return tC
end

function Databank.serialize(self,value)
    local t = {}
    local check = type(value)
    
    if check == "table" then
        self:internalSerialize(value, 1, t)
    elseif check == "string" then
        return '"' .. value .. '"'
    elseif check == "number" then
        return value
    elseif check == "boolean" then
        return tostring(value)
    else
        return '"Not Supported by Deserializer"'
    end
    return self.concat(t)
end

function Databank.deserialize(self,s)
    return load("return " .. s)()
end