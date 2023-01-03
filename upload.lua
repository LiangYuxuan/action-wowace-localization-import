local config = require('babelfish_config')
local curl = require('cURL')

local CF_API_KEY = os.getenv('CF_API_KEY')
assert(CF_API_KEY, "Missing CurseForge API token.")

local curseProjectID
if arg[1] and arg[2] and arg[1] == '-p' then
    curseProjectID = arg[2]
else
    local tocFileList = io.popen('find . -name "*.toc"')
    for filename in tocFileList:lines() do
        local file = assert(io.open(filename, "r"), "Could not open " .. filename)
        local text = file:read("*all")
        file:close()

        for match in string.gmatch(text, "## X%-Curse%-Project%-ID: (%d+)") do
            curseProjectID = match
        end
    end
end
assert(curseProjectID, "Missing CurseForge project id.")

local function generateFileList(inputTable)
    local exclusion = ''
    for _, path in ipairs(inputTable.exclusion) do
        exclusion = exclusion .. ' ! -path "' .. inputTable.path .. '/' .. path .. '"'
    end
    for _, path in ipairs(config.exclusion) do
        exclusion = exclusion .. ' ! -path "' .. inputTable.path .. '/' .. path .. '"'
    end

    local fileTable = {}
    local result = io.popen('find ' .. inputTable.path .. ' -name "*.lua"' .. exclusion)
    for file in result:lines() do
        table.insert(fileTable, file)
    end

    return fileTable
end

local function parseFile(filename)
    local strings = {}
    local file = assert(io.open(filename, "r"), "Could not open " .. filename)
    local text = file:read("*all")
    file:close()

    for match in string.gmatch(text, "L%[\"(.-)\"%]") do
        strings[match] = true
    end
    return strings
end

local result = {}

for _, namespace in ipairs(config.namespaces) do
    local inputTable = config.database[namespace]

    local fileList
    if not inputTable.file and not inputTable.path then
        error("Nameplate " .. namespace .. ": One of 'file' and 'path' should be provided.")
    elseif inputTable.file and inputTable.path then
        fileList = inputTable.file
        local matchFileList = generateFileList(inputTable)
        for _, file in ipairs(matchFileList) do
            table.insert(fileList, file)
        end
    else
        fileList = inputTable.file or generateFileList(inputTable)
    end

    result[namespace] = {}
    for _, file in ipairs(fileList) do
        local strings = parseFile(file)

        local length = 0
        for key in next, strings do
            length = length + 1
            result[namespace][key] = true
        end

        print(string.format("  %d\t  %s", length, file))
    end

    local sorted = {}
    for key in pairs(result[namespace]) do
        table.insert(sorted, key)
    end
    table.sort(sorted)

    local localizations = ''
    local length = #sorted
    for _, key in pairs(sorted) do
        localizations = localizations .. 'L["' .. key .. '"] = true\n'
    end
    result[namespace] = length > 0 and localizations or nil
    print(string.format("(%d)\t%s\n", length, namespace))
end

for _, namespace in ipairs(config.namespaces) do
    local localizations = result[namespace]

    if localizations then
        io.write("Importing '" .. namespace .. "'... ")
        io.flush()

        local buffer = {}
        local request = curl.easy{
            url      = 'https://wow.curseforge.com/api/projects/' .. curseProjectID .. '/localization/import',
            post     = true,
            httpheader = {
                'X-Api-Token: ' .. CF_API_KEY,
            },
            httppost = curl.form{
                metadata = '{ language: "enUS", namespace: "' .. namespace .. '", "missing-phrase-handling": "DeletePhrase" }',
                localizations = localizations,
            },
        }

        request:setopt_writefunction(table.insert, buffer)

        local ok, err = request:perform()
        if not ok then
            error(err)
        else
            local code = request:getinfo_response_code()
            if code == 200 then
                print("success")
            else
                print("failed with status code " .. code)
                print(table.concat(buffer))
                os.exit(1)
            end
        end
    end
end
