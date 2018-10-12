getmetatable("").__mod = function(a, b)
  if not b then
    return a
  elseif type(b) == "table" then
    return string.format(a, unpack(b))
  else
    return string.format(a, b)
  end
end

function menu_draw()
  local y = menuY

  love.graphics.setBackgroundColor(0, 0, 0)
  love.graphics.draw(title, 0, winH - 70)

  -----

  text = {
    "Grid width: %d" % gridW,
    "Grid height: %d" % gridH,
    "Mine density: %d%%" % percent
  }
  for i = 1, 3 do
    local x = menuX
    love.graphics.draw(scroller, x, y)
    x = x + 25
    love.graphics.print(text[i], x, y)
    y = y + 25
  end

  -----

  love.graphics.print("Press ENTER to start", winW - 200, winH - 25)
end

function menu_cick(x, y, button)
  if button == 1 then
    if x < menuX or y < menuY or x >= menuX + 20 then return end
    if y < menuY + 10 then gridW = gridW + 2
    elseif y >= menuY + 10 and y < menuY + 20 then gridW = gridW - 2
    elseif y >= menuY + 25 and y < menuY + 35 then gridH = gridH + 2
    elseif y >= menuY + 35 and y < menuY + 45 then gridH = gridH - 2
    elseif y >= menuY + 50 and y < menuY + 60 then percent = percent + 1
    elseif y >= menuY + 60 and y < menuY + 70 then percent = percent - 1
    end
  end
end

function menu_enter(key)
  if key ~= 'return' then return end
  gameX = math.floor(winW / 2 - (gridW * 25 - 5) / 2)
  gameY = math.floor(winH / 2 - (gridH * 25 - 5) / 2)
  grid = {}
  for r = 0, gridH - 1 do
    grid[r] = {}
    for c = 0, gridW - 1 do
      grid[r][c] = 10
    end
  end
  message = "Click anywhere to start"

    -----

  love.draw = game_draw
  love.mousepressed = nil
  love.keypressed = gen_grid
end

function gen_grid(key)
  if key ~= 'd' then return end

  -----

  local x, y = love.mouse.getPosition()
  if x < gameX or y < gameY or
     x >= gameX + gridW * 25 or
     y >= gameY + gridH * 25 then
    return
  end
  x = x - gameX
  y = y - gameY
  if x % 25 >= 20 or y % 25 >= 20 then
    return
  end
  x = math.floor(x / 25)
  y = math.floor(y / 25)

  -----

  local boxes = gridW * gridH
  bombs = math.floor(boxes * percent / 100)
  local i = bombs
  while i > 0 do
    local r, c
    repeat
      r = math.random(0, gridH - 1)
      c = math.random(0, gridW - 1)
    until grid[r][c] == 10 and (r < y - 1 or c < x - 1 or r > y + 1 or c > x + 1)
    grid[r][c] = 19
    for roff = -1, 1 do
      for coff = -1, 1 do
        if roff ~= 0 or coff ~= 0 then
          local rt = r + roff
          local ct = c + coff
          if rt >= 0 and rt < gridH and ct >= 0 and ct < gridW then
            if grid[rt][ct] < 20 then
              grid[rt][ct] = grid[rt][ct] + 1
            end
          end
        end
      end
    end
    i = i - 1
  end
  open_box(y, x, true)
  message = "Bombs left: %d" % bombs
  love.keypressed = game_keypressed
end

function open_box(r, c, first)
  if r < 0 or r >= gridW or c < 0 or c >= gridH then
    return
  end
  local val = grid[r][c]
  if val >= 10 and val < 19 then
    grid[r][c] = val - 10
    if val ~= 10 then
      return
    end
  elseif val == 19 then
    for r = 0, gridH - 1 do
      for c = 0, gridW - 1 do
        local val = grid[r][c]
        if val > 19 then
          grid[r][c] = val - 20
        elseif val > 9 then
          grid[r][c] = val - 10
        end
      end
    end
    message = "You lost ! Press enter to restart"
    love.keypressed = game_restart
  elseif val > 9 or not first then
    return
  else
    local flags = 0
    for roff = -1, 1 do
      for coff = -1, 1 do
        if roff ~= 0 or coff ~= 0 then
          if grid[r + roff] ~= nil and grid[r + roff][c + coff] ~= nil and
             grid[r + roff][c + coff] >= 20 then
            flags = flags + 1
          end
        end
      end
    end
    if val ~= flags then
      return
    end
  end

  -----

  for roff = -1, 1 do
    for coff = -1, 1 do
      if roff ~= 0 or coff ~= 0 then
        open_box(r + roff, c + coff, false)
      end
    end
  end
end

function game_restart(key)
  if key ~= 'return' then return end

    -----

  love.draw = menu_draw
  love.mousepressed = menu_cick
  love.keypressed = menu_enter
end

function check_win()
  for r = 0, gridH - 1 do
    for c = 0, gridW - 1 do
      if grid[r][c] == 19 then
        return false
      end
    end
  end
  return true
end

function game_keypressed(key)
  local x, y = love.mouse.getPosition()
  if x < gameX or y < gameY or
     x >= gameX + gridW * 25 or
     y >= gameY + gridH * 25 then
    return
  end
  x = x - gameX
  y = y - gameY
  if x % 25 >= 20 or y % 25 >= 20 then
    return
  end
  x = math.floor(x / 25)
  y = math.floor(y / 25)

  -----

  if key == 'd' then
    open_box(y, x, true)
  elseif key == 's' then
    local val = grid[y][x]
    if val >= 20 then
      grid[y][x] = val - 10
      bombs = bombs + 1
    elseif val >= 10 then
      grid[y][x] = val + 10
      bombs = bombs - 1
    end
    if bombs == 0 and check_win() then
      message = "You won ! Press enter to restart"
      love.keypressed = game_restart
    else
      message = "Bombs left: %d" % bombs
    end
  end
end

function game_draw()
  love.graphics.setBackgroundColor(0, 0, 0)
  love.graphics.draw(title, 0, winH - 70)

  -----

  local y = gameY
  for r = 0, gridW - 1 do
    local x = gameX
    for c = 0, gridH - 1 do
      love.graphics.draw(box[grid[r][c]], x, y)
      x = x + 25
    end
    y = y + 25
  end

  -----

  love.graphics.print(message, winW - (10 * #message), winH -25)
end

function love.load()
  title = love.graphics.newImage("assets/title.png")
  scroller = love.graphics.newImage("assets/scroller.png")
  gridH = 16
  gridW = 16
  percent = 18

  -----

  local closed = love.graphics.newImage("assets/box.png")
  local flagged = love.graphics.newImage("assets/flag.png")
  box = {}
  for i = 0, 9 do box[i] = love.graphics.newImage("assets/" .. i .. ".png") end
  for i = 10, 19 do box[i] = closed end
  for i = 20, 29 do box[i] = flagged end

  -----

  love.draw = menu_draw
  love.mousepressed = menu_cick
  love.keypressed = menu_enter

  -----

  love.graphics.setFont(love.graphics.newFont(18))
  love.window.setFullscreen(true, "desktop")
  winW, winH = love.graphics.getDimensions()
  menuX = math.floor(winW * 2 / 5)
  menuY = math.floor(winH / 2 - (3 * 25 - 5) / 2)
end