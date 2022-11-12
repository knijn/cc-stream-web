local streamURL = "http://localhost:3000"
local xSize, ySize = term.getSize()
local mainWindow = window.create(term.current(), 1, 1, xSize, ySize, true)
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


local function convertHTML(buffer)
  local html = ""
  for i,o in pairs(buffer) do
    --print(textutils.serialise(o))
    local line = "<a>" .. o[1] .. "</a>\n"
    html = html .. line
  end
  return {html}
end


local function runProgram()
  term.redirect(mainWindow)
  shell.run(program)
end

local function pollDisplay()
  while true do
    local startTime = os.epoch()
    local mainBuffer = {}
    local getLine = mainWindow.getLine
    for i=1,ySize do -- thanks 9551dev for the optimization
        local txt,fg,bg = getLine(i)
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
    if not benchmarkMode then
      http.post(streamURL,textutils.serialiseJSON(mainBuffer))
    end
    sleep(1/targetFPS - (endTime - startTime))
  end
end

if benchmarkMode then
    pollDisplay()
end

parallel.waitForAny(runProgram,pollDisplay)