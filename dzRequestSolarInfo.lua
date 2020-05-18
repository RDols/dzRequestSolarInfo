--------------------------------------------------------------------------------
local function MakeCleanNumber(dirtyNumber)
    local isDecimalComma = true
    
    if isDecimalComma then
        local value = dirtyNumber:gsub("%.", "")
        value = value:gsub(",", ".")
        return tonumber(value)
    else
        local value = dirtyNumber:gsub(",", "")
        return tonumber(value)
    end
end
--------------------------------------------------------------------------------
local function AddReportData(json, component)
    local id = tostring(component.id)
    component.DayEnergy = 0
    if json.reportersData[id] then
        component.DayEnergy = json.reportersData[id].unscaledEnergy or 0
    end
end
--------------------------------------------------------------------------------
local function AddReportInfo(json, component)
    local id = tostring(component.id)
    data = json.reportersInfo[id]
    if data then
        --component.LastMeasurement = data.lastMeasurement --Not updated by website, useless
        component.Name = data.name
        for k, v in pairs(data.localizedMeasurements or {}) do
            if string.match(k, "%[W%]") then
                component.CurrentPower = MakeCleanNumber(v)
            end
        end
    end
end
--------------------------------------------------------------------------------
local function GetOptimizerData(json, component)
    if component.data and component.data.type == "POWER_BOX" then
        local optimizer = component.data
        AddReportData(json, optimizer)
        AddReportInfo(json, optimizer)
        return optimizer
    end
end
--------------------------------------------------------------------------------
local function GetStringData(json, info, component)
    if component.data and component.data.type == "STRING" then
        local powerstring = component.data
        AddReportData(json, powerstring)
        AddReportInfo(json, powerstring)
        powerstring.Optimizers = {}
        for _, child in pairs(component.children) do
            local optimizer = GetOptimizerData(json, child)
            if optimizer then
                table.insert(powerstring.Optimizers, optimizer)
                table.insert(info.Optimizers, optimizer)
            end
        end
        return powerstring
    end
end
--------------------------------------------------------------------------------
local function GetInverterData(json, info, component)
    if component.data and component.data.type == "INVERTER" then
        local inverter = component.data
        AddReportData(json, inverter)
        AddReportInfo(json, inverter)
        inverter.Strings = {}
        for _, child in pairs(component.children) do
            local string = GetStringData(json, info, child)
            if string then
                table.insert(inverter.Strings, string)
                table.insert(info.Strings, string)
            end
        end
        return inverter
    end
end
--------------------------------------------------------------------------------
local function RequestSolardEdge(domoticz)
    local username = "your@email.com"
    local password = "password"
    local siteID = "0000000"
    
    local authorization = string.format("%s:%s", username, password)
    authorization = string.format("Basic %s", domoticz.utils.toBase64(authorization))

    local url = string.format("https://monitoring.solaredge.com/solaredge-apigw/api/sites/%s/layout/logical", siteID)
    local headers = { ['Authorization'] = authorization }
    
    domoticz.openURL(
    {
        url = url,
        method = 'GET',
        headers = headers,
        callback = 'SolarEdgeWebRespondse'
    })
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
return 
{
--------------------------------------------------------------------------------
	active = true,
--------------------------------------------------------------------------------
    on = 
	{
		timer = 
		{
		    'every 1 minutes' 
		},
	    httpResponses = 
	    { 
	        'SolarEdgeWebRespondse' 
	    }
	},
--------------------------------------------------------------------------------
    data = 
	{
    },
--------------------------------------------------------------------------------
    execute = function(domoticz, item)
--------------------------------------------------------------------------------
        
	    --print("dzRequestSolarInfo : -=[ Start ]===================================================")

        if (item.isTimer) then
            RequestSolardEdge(domoticz)
        elseif (item.isHTTPResponse) then
            if (item.ok) then
                
                --print("dzRequestSolarInfo : Response OK")
                local info = { Inverters = {}, Strings = {}, Optimizers = {} }
                for _, child in pairs(item.json.logicalTree.children) do
                    local inverter = GetInverterData(item.json, info, child)
                    if inverter then
                        table.insert(info.Inverters, inverter)
                    end
                end
                
                local utils = domoticz.utils
                for _, v in ipairs(info.Inverters) do
                    --print(string.format("dzRequestSolarInfo : Inverter %s = %0.2f Wh", v.Name, v.DayEnergy or 0))
                    if utils.deviceExists(v.Name) then
                        domoticz.devices(v.Name).updateElectricity(v.CurrentPower, v.DayEnergy)
                    end
                end
                for _, v in ipairs(info.Strings) do
                    --print(string.format("dzRequestSolarInfo : String %s = %0.2f Wh", v.Name, v.DayEnergy or 0))
                    if utils.deviceExists(v.Name) then
                        domoticz.devices(v.Name).updateElectricity(v.CurrentPower, v.DayEnergy)
                    end
                end
                for _, v in ipairs(info.Optimizers) do
                    --print(string.format("dzRequestSolarInfo : Optimizer %s = %0.2f Wh", v.Name, v.DayEnergy or 0))
                    if utils.deviceExists(v.Name) then
                        domoticz.devices(v.Name).updateElectricity(v.CurrentPower, v.DayEnergy)
                    end
                end
            end
        end
  
	    --print("dzRequestSolarInfo : -=[ End ]=====================================================")
         
 	end
}
