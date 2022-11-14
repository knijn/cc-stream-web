local streamURL = "http://localhost:3000"
local xSize, ySize = term.getSize()
local mainWindow = window.create(term.current(), 1, 1, xSize, ySize - 1, true)
local targetFPS = 30

local args = {...}
if not args then error("You should supply a program to run when streaming") end
local benchmarkMode = false
local program
if args[1] == "benchmark" then 
    benchmarkMode = true
else
    program = shell.resolve(args[1])
end

local mainTerm = term.current()

local function convertHTML(tbl)
  -- convert to chars per pixel
  local charTable = {}
  for i,line in pairs(tbl) do -- loop over lines
    local buffer = {}
    for charI=1, #line[1] do
        table.insert(buffer,{line[1]:sub(charI,charI),line[2]:sub(charI,charI),line[3]:sub(charI,charI)})
    end
    table.insert(charTable,buffer)
  end
  tbl = charTable
  -- convert to same color chunks
  local fragLines = {}
  for il, line in pairs(tbl) do
    local fragChunks = {}
    local currentChunk = {}
    for ip, pixel in pairs(line) do 
        if not currentChunk[#currentChunk] then
        elseif pixel[2] ~= currentChunk[#currentChunk][2] then
            table.insert(fragChunks,currentChunk)
            currentChunk = {}
        elseif pixel[3] ~= currentChunk[#currentChunk][3] then
            table.insert(fragChunks, currentChunk)
            currentChunk = {}
        end
        table.insert(currentChunk,{pixel[1],pixel[2],pixel[3]})
        --print(currentChunk[#currentChunk][1])
    end
    table.insert(fragLines,fragChunks)
    --print(textutils.serialise(fragChunks))
  end
  
  -- group similar strings
  local lines = {}
  for il, line in pairs(fragLines) do
    local currentLine = {}
    for ic, chunk in pairs(line) do
        local collectiveTXT = ""
        for isc, subChunk in pairs(chunk) do
            collectiveTXT = collectiveTXT .. subChunk[1]
        end
        table.insert(currentLine,{collectiveTXT,chunk[1][2],chunk[1][2]})
    end
    table.insert(lines,currentLine)
  end

  -- convert to html
  local html = "<link href=\"" .. streamURL .. "/stream.css\" type=\"text/css\" rel=\"stylesheet\"/>  <meta http-equiv=\"refresh\" content=\"1\" />"
  for i,line in pairs(lines) do -- loop over lines
    local htmlChunk = "<div> "
    for ic, chunk in pairs(line) do
        htmlChunk = htmlChunk .. "<pre class=\"fg" .. chunk[2] .. "\" class=\"bg" .. chunk[3] .. "\"> " .. chunk[1] .. "</pre>"
    end
    if htmlChunk == "<div> " then
        htmlChunk = htmlChunk .. "<p></p>"
    end
    htmlChunk = htmlChunk .. "</div>"
    html = html .. htmlChunk 
  end
  return html
end

local realFPS = 0

local function drawStatus()
    local oldX, oldY = mainTerm.getCursorPos()
    mainTerm.setCursorPos(1,ySize)
    mainTerm.write(realFPS .. " / " .. targetFPS .. " " .. os.time())
    mainTerm.setCursorPos(xSize - #"LIVE",ySize)
    mainTerm.write("LIVE")
    mainTerm.setCursorPos(oldX,oldY)
end

local function runProgram()
  term.redirect(mainWindow)
  shell.run(program)
  mainTerm.clear()
  mainTerm.setCursorPos(1,1)
end

local function pollDisplay()
    local startTime = os.epoch()
    local mainBuffer = {}
    local _,ySize = mainWindow.getSize()
    for i=1,ySize do -- thanks 9551dev for the optimization
        local txt,fg,bg = mainWindow.getLine(i)
        mainBuffer[i] = {
            txt,fg,bg
        }
    end
    local endTime = os.epoch()
    if benchmarkMode then
        local xPos, yPos = mainWindow.getCursorPos()
        mainWindow.setCursorPos(1,1)
        term.clearLine()
        term.write("Frame took " .. endTime - startTime .. "ms, that is " .. math.floor(1/(endTime / 1000 - startTime / 1000)) .. " fps")
        mainWindow.setCursorPos(xPos, yPos)
    end
    realFPS = math.floor(1/(endTime / 1000 - startTime / 1000))

    if not benchmarkMode then
      drawStatus()
      local err, msg = http.post(streamURL,convertHTML(mainBuffer),{["Content-Type"] = "text/html"})
      --convertHTML(mainBuffer)
      if err then error(msg) end
    end
end

local function displayLoop()
    while true do
        pollDisplay()
        sleep(0.1)
    end
end

local function buttons()
    local _, key, is_held = os.pullEvent("key")
    pollDisplay()
    buttons() -- this **will** break someday
end

if benchmarkMode then
    pollDisplay()
end

parallel.waitForAny(runProgram,displayLoop, buttons)