-- particle manager id
local OM_OBJECT, OM_MYBULLET, OM_FX, OM_MENU = 0, 1, 2, 3

-- font size
local CHW,CHH = 16,32
local font = Resource.GetTexId('font16x32')

-- sprite res id
local bullet = Resource.GetSpriteId('bullet')
local mybullet = Resource.GetSpriteId('mybullet')
local plane = Resource.GetSpriteId('plane')
local donuts_green = Resource.GetSpriteId('donuts-green')
local donuts_small1 = Resource.GetSpriteId('donuts-small1')
local donuts_small2 = Resource.GetSpriteId('donuts-small2')
local donuts_cone = Resource.GetSpriteId('donuts-cone')
local donuts_circle = Resource.GetSpriteId('donuts-circle')
local fragment = Resource.GetSpriteId('fragment')
local cursor = Resource.GetSpriteId('cursor')
local bomb = Resource.GetSpriteId('bomb')

-- sound res id
local sndHit = Resource.GetSoundId('hit')
local sndCursor = Resource.GetSoundId('cursor')
local sndDestroy = Resource.GetSoundId('destroy')
local sndBomb = Resource.GetSoundId('bomb')
local sndBgm = Resource.GetSoundId('bgm')

-- object type
local BULLETS, MYBULLETS, EFFECTS, FRAGMENTS, MOVEEFFECTS, BOMBS, OBJECTS, CHARS, MENUCURSOR = 0, 100, 200, 201, 202, 203, 300, 400, 500
local BOSS = 1000

-- global
local ShowMenu = false
local iMenu, iMaxMenu
local objCursor = -1
local curTargetX, curTargetY
local curTimeX = 0

local idBoss = -1 -- particle id
local idBossHp1, idBossHp2 = -1, -1 -- color bg
local hpBoss, hpBossMax

local myhp, tHealHp
local objMyHp = {}

local MAX_HP = 5
local TIME_HEAL = 10 * 60

local SCREEN_W, SCREEN_H = Good.GetWindowSize()

local idToggleSnd = 33
local bgm_id = -1
local enableSnd = true

function PlaySound(id)
  if (enableSnd) then
    return Sound.PlaySound(id)
  end
  return -1
end

function animMenuCursor()
  if (-1 == objCursor) then
    return
  end

  -- update timer
  curTimeX = curTimeX + 1
  if (180 < curTimeX) then -- animation period 3 seconds
    curTimeX = 0
  end

  -- animate cursor
  local x,y = Good.GetPos(objCursor)
  x = curTargetX + 6 + 20 * math.sin(math.pi * curTimeX / 180)

  if (y > curTargetY) then
    y = y - (y - curTargetY) / (60 * 0.15)
    if (y < curTargetY) then
      y = curTargetY
    end
  elseif (y < curTargetY) then
    y = y + (curTargetY - y) / (60 * 0.15)
    if (y > curTargetY) then
      y = curTargetY
    end
  end

  Good.SetPos(objCursor, x,y)
end

function handleMoveCursor()
  if (-1 == objCursor) then
    return
  end

  if (Input.IsKeyPushed(Input.DOWN)) then
    if (iMaxMenu - 1 > iMenu) then
      iMenu = iMenu + 1
      curTargetY = curTargetY + 30
      PlaySound(sndCursor)
    end
  elseif (Input.IsKeyPushed(Input.UP)) then
    if (0 < iMenu) then
      iMenu = iMenu - 1
      curTargetY = curTargetY - 30
      PlaySound(sndCursor)
    end
  end

  if (Input.IsKeyPushed(Input.LBUTTON)) then
    local cx,cy = Good.GetPos(objCursor)
    local x,y = Input.GetMousePos()
    if (PtInRect(x,y, cx, curTargetY - 30, cx + 200, curTargetY)) then
      if (0 < iMenu) then
        iMenu = iMenu - 1
        curTargetY = curTargetY - 30
        PlaySound(sndCursor)
      end
    elseif (PtInRect(x,y, cx, curTargetY - 60, cx + 200, curTargetY - 30)) then
      if (1 < iMenu) then
        iMenu = iMenu - 2
        curTargetY = curTargetY - 60
        PlaySound(sndCursor)
      end
    elseif (PtInRect(x,y, cx, curTargetY - 90, cx + 200, curTargetY - 60)) then
      if (2 < iMenu) then
        iMenu = iMenu - 3
        curTargetY = curTargetY - 90
        PlaySound(sndCursor)
      end
    elseif (PtInRect(x,y, cx, curTargetY + 30, cx + 200, curTargetY + 60)) then
      if (iMaxMenu - 1 > iMenu) then
        iMenu = iMenu + 1
        curTargetY = curTargetY + 30
        PlaySound(sndCursor)
      end
    elseif (PtInRect(x,y, cx, curTargetY + 60, cx + 200, curTargetY + 90)) then
      if (iMaxMenu - 2 > iMenu) then
        iMenu = iMenu + 2
        curTargetY = curTargetY + 60
        PlaySound(sndCursor)
      end
    elseif (PtInRect(x,y, cx, curTargetY + 90, cx + 200, curTargetY + 120)) then
      if (iMaxMenu - 3 > iMenu) then
        iMenu = iMenu + 3
        curTargetY = curTargetY + 90
        PlaySound(sndCursor)
      end
    end
  end
end

function vscroll(id, spd)
  local x,y = Good.GetPos(id)
  y = y + spd
  Good.SetPos(id, x,y)
end

function scrollBkgnd(param)
  vscroll(param.bk1, 1)
  vscroll(param.cloud1, 0.08)
  vscroll(param.cloud2, 0.08)
end

function setMgrActive(active)
  for iMgr = 0, 2 do
    local n = Stge.GetParticleCount(iMgr)
    local id = Stge.GetFirstParticle(iMgr)
    for i = 1, n do
      if (0 == active) then
        Good.PauseAnim(Stge.GetParticleBind(id, iMgr))
      else
        Good.PlayAnim(Stge.GetParticleBind(id, iMgr))
      end
      id = Stge.GetNextParticle(id, iMgr)
    end
    Stge.SetActive(active, iMgr)
  end
end

function doShowMenu(name, maxitem)
  ShowMenu = true
  iMenu = 0
  iMaxMenu = maxitem
  setMgrActive(0)
  Stge.RunScript(name, 0, 0, OM_MENU)
  PlaySound(sndCursor)
  Good.SetVisible(idToggleSnd, Good.VISIBLE)
end

function doHideMenu()
  ShowMenu = false
  setMgrActive(1)
  Stge.KillAllParticle(OM_MENU)
  Good.SetVisible(idToggleSnd, Good.INVISIBLE)
end

function sInit(param)
  resetAll(param)
  if (400 == SCREEN_W) then
    doShowMenu('main_menu_m', 3)
  else
    doShowMenu('main_menu_f', 3)
  end
  param.stage = sMainMenu
end

function resetAll(param)
  for i = 0, 2 do
    Stge.KillAllParticle(i)
    Stge.KillAllTask(i)
    Stge.SetActive(1,i)
  end
  Good.KillObj(param.player)
  ShowMenu = false
  objCursor = -1
  Good.KillObj(idBossHp2)
  idBossHp1, idBossHp2 = -1, -1
  idBoss = -1
  for i = 1, MAX_HP do
    local o = objMyHp[i]
    Good.SetDim(o, 0, 0, 0, 4)
  end
end

function resetHp()
  myhp = MAX_HP
  tHealHp = 0
  for i = 1, MAX_HP do
    local o = objMyHp[i]
    Good.SetDim(o, 0, 0, 14, 4)
  end
end

function hideHp()
  for i = 1, MAX_HP do
    local o = objMyHp[i]
    Good.SetDim(o, 0, 0, 0, 4)
  end
end

function newGame(param)
  -- set player controller script and set color to red
  param.player = Good.GenObj(-1, plane, 'Player')

  -- init hp
  resetHp()

  -- start script
  param.task = Stge.RunScript('stage1')
end

function applySelMenuFx()
  local nc = Stge.GetParticleCount(OM_MENU)
  local p = Stge.GetFirstParticle(OM_MENU)
  for i = 1, nc do
    local x,y = Stge.GetPos(p, OM_MENU)
    Stge.RunScript('fx_hit', x,y, OM_MENU)
    p = Stge.GetNextParticle(p, OM_MENU)
  end
  Stge.KillAllParticle(OM_MENU)
end

function sWaitMenuFx(param)
  if (0 == Stge.GetParticleCount(OM_MENU)) then
    param.stage = param.nextStage
  end
end

function selectMenuItem(param, nextStage)
  applySelMenuFx()
  param.nextStage = nextStage
  param.stage = sWaitMenuFx
  Good.SetVisible(idToggleSnd, Good.INVISIBLE)
end

function sQuit(param)
  Good.Exit()
end

function HandleToggleSound()
  -- toggle snd
  if (Input.IsKeyPushed(Input.LBUTTON)) then
    local x,y = Input.GetMousePos()
    if (PtInObj(x, y, idToggleSnd)) then
      if (enableSnd) then
        enableSnd = false
        Good.SetBgColor(idToggleSnd, 0x80ffffff)
        if (-1 ~= bgm_id) then
          Sound.KillSound(bgm_id)
          bgm_id = -1
        end
      else
        enableSnd = true
        Good.SetBgColor(idToggleSnd, 0xffffffff)
        bgm_id = Sound.PlaySound(sndBgm)
      end
    end
  end
end

function sMainMenu(param)
  -- animate menu cursor
  animMenuCursor()

  HandleToggleSound()

  local cx,cy = Good.GetPos(objCursor)
  local x,y = Input.GetMousePos()

  -- handle selection
  if (Input.IsKeyPushed(Input.BTN_A + Input.RETURN) or
      (Input.IsKeyPushed(Input.LBUTTON) and PtInRect(x,y, cx, curTargetY, cx + 200, curTargetY + 30))) then
    if (0 == iMenu) then -- start game
      selectMenuItem(param, sNewGame)
    elseif (1 == iMenu) then -- goto homepage
      Good.FireUserIntEvent(1)
    else
      selectMenuItem(param, sQuit)
    end
    PlaySound(sndDestroy)
  end

  handleMoveCursor()
end

function sGame(param)
  -- esc key to show menu
  if (Input.IsKeyPushed(Input.ESCAPE)) then
    doShowMenu('game_menu', 4)
    objCursor = -1
    param.stage = sGameMenu
  end

  -- scroll bkgnd
  scrollBkgnd(param)

  -- Update particles.
  if (not ShowMenu) then
    local p = Stge.GetFirstParticle(OM_OBJECT)
    while (-1 ~= p) do
      local nextp = Stge.GetNextParticle(p, OM_OBJECT)
      OnUpdateParticle(param, p)
      p = nextp
    end
  end

  -- update boss hp bar
  if (-1 == idBoss) then
    return
  end

  local hp = Stge.GetUserData(idBoss, 1) -- current value
  if (hp ~= hpBoss ) then
    local l,t,w,h = Good.GetDim(idBossHp1)
    local v = math.floor((SCREEN_W - 20) * hp / hpBossMax)
    if (v > w) then
      w = w + 2
      if (SCREEN_W - 20 < w) then
        w = SCREEN_W - 20
      end
      Good.SetDim(idBossHp1, l, t, w, h)
    elseif (v < w) then
      w = w - 2
      if (0 > w) then
        w = 0
      end
      Good.SetDim(idBossHp1, l, t, w, h)
    end
  end

  -- destroy?
  if (0 == hp) then
    Good.KillObj(idBossHp2)
    idBossHp1, idBossHp2 = -1, -1
    curTimeX = 2 * 60
    param.stage = sBossDestroy
    hideHp()
    ShowMenu = true
  end
end

function sResumeGame(param)
  ShowMenu = false
  setMgrActive(1)
  param.stage = sGame
end

function sNewGame(param)
  resetAll(param)
  newGame(param)
  param.stage = sGame
end

function sGameMenu(param)
  -- animate menu cursor
  animMenuCursor()

  HandleToggleSound()

  local cx,cy = Good.GetPos(objCursor)
  local x,y = Input.GetMousePos()

  -- handle keys
  if (Input.IsKeyPushed(Input.ESCAPE)) then
    doHideMenu()
    param.stage = sGame
    PlaySound(sndCursor)
  elseif (Input.IsKeyPushed(Input.BTN_A + Input.RETURN) or
      (Input.IsKeyPushed(Input.LBUTTON) and PtInRect(x,y, cx, curTargetY, cx + 200, curTargetY + 30))) then
    if (0 == iMenu) then -- resume
      selectMenuItem(param, sResumeGame)
    elseif (1 == iMenu) then -- new game
      selectMenuItem(param, sNewGame)
    elseif (2 == iMenu) then -- main menu
      selectMenuItem(param, sInit)
    else -- quit
      selectMenuItem(param, sQuit)
    end
    PlaySound(sndDestroy)
  end

  handleMoveCursor()
end

function sGameOver(param)
  -- animate menu cursor
  animMenuCursor()

  HandleToggleSound()

  local cx,cy = Good.GetPos(objCursor)
  local x,y = Input.GetMousePos()

  -- handle keys
  if (Input.IsKeyPushed(Input.BTN_A + Input.RETURN) or
      (Input.IsKeyPushed(Input.LBUTTON) and PtInRect(x,y, cx, curTargetY, cx + 200, curTargetY + 30))) then
    if (0 == iMenu) then -- new game
      selectMenuItem(param, sNewGame)
    elseif (1 == iMenu) then -- main menu
      selectMenuItem(param, sInit)
    else -- quit
      selectMenuItem(param, sQuit)
    end
    PlaySound(sndDestroy)
  end

  handleMoveCursor()
end

function sAllClear(param)
  -- scroll bkgnd
  scrollBkgnd(param)

  -- move player out
  if (-1 ~= param.player) then
    local x,y = Good.GetPos(param.player)
    y = y - 2.5
    if (-32 < y) then
      Good.SetPos(param.player, x,y)
    else
      Good.KillObj(param.player)
      param.player = -1
    end
  end

  -- end?
  if (0 == Stge.GetTaskCount(OM_MENU)) then
    param.stage = sInit
  end
end

function sBossDestroy(param)
  if (0 ~= curTimeX) then
    curTimeX = curTimeX - 1
    return
  end

  Stge.RunScript('all_clear', 0,0, OM_MENU)
  param.stage = sAllClear
  ShowMenu = true

  local pp = Good.GetParam(param.player)
  if (-1 ~= pp.movefx) then
    Stge.KillTask(pp.movefx, OM_FX)
  end
  if (-1 ~= pp.fire) then
    Stge.KillTask(pp.fire, OM_MYBULLET)
  end
end

Game = {}

Game.OnCreate = function(param)
  local id = param._id

  -- save id of bkgnd
  param.bk1 = Good.FindChild(id, 'bk1')

  -- set cloud transparent
  param.cloud1 = Good.FindChild(id, 'cloud1')
  Good.SetBgColor(param.cloud1, 0xaaffffff)
  param.cloud2 = Good.FindChild(id, 'cloud2')
  Good.SetBgColor(param.cloud2, 0xaaffffff)

  -- create hp obj
  for i = 1, MAX_HP do
    local o = Good.GenObj(-1, -1)
    Good.SetDim(o, 0, 0, 0, 4)
    Good.SetPos(o, 16 * i, SCREEN_H - 20)
    Good.SetBgColor(o, 0xffff0000)
    objMyHp[i] = o
  end

  -- init stage
  param.player = -1
  param.stage = sInit

  -- startup bgm
  bgm_id = PlaySound(sndBgm)
end

Game.OnStep = function(param)
  -- trigger game
  param.stage(param)

  -- handle hp
  if (sGame == param.stage and MAX_HP > myhp) then
    tHealHp = tHealHp + 1
    local o = objMyHp[myhp + 1]
    local w = math.floor(14.0 * tHealHp / TIME_HEAL)
    Good.SetDim(o, 0, 0, w, 4)
    if (TIME_HEAL == tHealHp) then -- every 10 seconds, inc 1 hp
      tHealHp = 0
      myhp = myhp + 1
    end
  end

  -- eat, avoid quit app
  if (Input.IsKeyPushed(Input.ESCAPE)) then
    -- NOP
  end
end

local bcolor = {0xffff0000,0xff00ff00,0xffffff00,0xff0000ff,0xff00ffff,0xffff00ff}

Game.OnNewParticle = function(param, particle, iMgr)
  local obj = -1
  local t = Stge.GetUserData(particle, 0, iMgr)
  if (MYBULLETS == t) then -- mybullet
    obj = Good.GenObj(-1, mybullet)
  elseif (BULLETS == t) then -- enemy bullet
    local t1 = Stge.GetUserData(particle, 1, iMgr)
    if (1 == t1) then                   -- Lazer.
      obj = GenColorObj(-1, 64, 8, 0xffffffff)
      Good.SetRot(obj, Stge.GetDirection(particle))
    else
      obj = Good.GenObj(-1, bullet)
      local c = math.floor(Stge.GetUserData(particle, 2, iMgr))
      if (0 ~= c) then
        Good.SetBgColor(obj, bcolor[c])
      end
    end
  elseif (OBJECTS == t) then -- objects
    local t2 = Stge.GetUserData(particle, 2, iMgr)
    if (BOSS == t2) then -- boss
      obj = Good.GenObj(-1, donuts_circle)
      idBoss = particle
      idBossHp2 = Good.GenObj(-1, -1)
      Good.SetDim(idBossHp2, 0, 0, SCREEN_W - 20, 4)
      Good.SetPos(idBossHp2, 10, 13)
      Good.SetBgColor(idBossHp2, 0x88ffffff)
      idBossHp1 = Good.GenObj(idBossHp2, -1)
      Good.SetDim(idBossHp1, 0, 0, 0, 8)
      Good.SetPos(idBossHp1, 0, -2)
      Good.SetBgColor(idBossHp1, 0xffff0000)
      hpBoss = 0
      hpBossMax = Stge.GetUserData(particle, 1, iMgr)
    elseif (2 == t2) then
      obj = Good.GenObj(-1, donuts_cone)
    elseif (3 == t2) then
      obj = Good.GenObj(-1, donuts_small1)
    elseif (4 == t2) then
      obj = Good.GenObj(-1, donuts_small2)
    else
      obj = Good.GenObj(-1, donuts_green)
    end
  elseif (EFFECTS == t) then -- hit effect
    obj = Good.GenObj(-1, -1)
    Good.SetDim(obj, 0,0, 3, 3)
    Good.SetBgColor(obj, bcolor[math.random(3)])
  elseif (FRAGMENTS == t) then -- fragment
    obj = Good.GenObj(-1, fragment)
    Good.SetBgColor(obj, bcolor[math.random(3)])
  elseif (MOVEEFFECTS == t) then -- move effect
    obj = Good.GenObj(-1, -1)
    Good.SetDim(obj, 0,0, 3, 3)
    Good.SetBgColor(obj, 0xffff0000)
  elseif (BOMBS == t) then -- bomb
    obj = Good.GenObj(-1, bomb)
    PlaySound(sndBomb)
  elseif (CHARS == t) then -- char
    obj = Good.GenObj(-1, font)
    local ch = Stge.GetUserData(particle, 1, iMgr)
    ch = ch - 32
    Good.SetDim(obj, CHW * math.floor(ch % 15), CHH * math.floor(ch / 15), CHW,CHH)
    Good.SetBgColor(obj, 0xffff0000)
  elseif (MENUCURSOR == t) then -- menu cursor
    obj = Good.GenObj(-1, cursor)
    objCursor = obj
    curTargetX,curTargetY = Stge.GetPos(particle, iMgr)
  end
  Stge.BindParticle(particle, obj, iMgr)
end

Game.OnKillParticle = function(param, particle, iMgr)
  Good.KillObj(Stge.GetParticleBind(particle, iMgr))
end

function ptInRect(x, y, left, top, right, bottom)
  if (left <= x and right > x and top <= y and bottom > y) then
    return true
  else
    return false
  end
end

function OnUpdateParticle(param, particle)
  -- emeny bullet
  local t = Stge.GetUserData(particle, 0)
  local t2 = Stge.GetUserData(particle, 2)
  if (BULLETS == t or BOSS == t2) then
    local x,y = Good.GetPos(param.player)
    local id = Stge.GetParticleBind(particle)
    local ox,oy = Good.GetPos(id)
    if (ptInRect(ox,oy, x - 3, y - 3, x + 3, y + 3)) then -- hit my plane?
      PlaySound(sndHit)
      Stge.RunScript('fx_hit', x,y, OM_FX)
      if (MAX_HP ~= myhp) then
        Good.SetDim(objMyHp[myhp + 1], 0, 0, 0, 4)
      end
      Good.SetDim(objMyHp[myhp], 0, 0, 0, 4)
      tHealHp = 0
      myhp = myhp - 1
      if (0 < myhp) then -- kill all bullet
        local p = Stge.GetFirstParticle(OM_OBJECT)
        while (-1 ~= p) do
          local nextp = Stge.GetNextParticle(p, OM_OBJECT)
          if (BULLETS == Stge.GetUserData(p, 0)) then -- this is a bullet
            Stge.KillParticle(p, OM_OBJECT)
          end
          p = nextp
        end
      else -- game over
        param.stage = sGameOver
        doShowMenu('game_over', 3)
      end
      return
    end
  end

  -- emeny objects
  if (OBJECTS == t) then
    local hp = Stge.GetUserData(particle, 1)
    local id = Stge.GetParticleBind(particle)
    local ox,oy = Good.GetPos(id)

    -- check collision with my bullet
    local nc = Stge.GetParticleCount(OM_MYBULLET)
    local mb = Stge.GetFirstParticle(OM_MYBULLET)
    for i = 1, nc do
      local obj = Stge.GetParticleBind(mb, OM_MYBULLET)
      local x,y = Good.GetPos(obj)
      if (ptInRect(x,y, ox - 6, oy - 6, ox + 6, oy + 6)) then
        Stge.KillParticle(mb, OM_MYBULLET)
        hp = hp - 1
        if (0 >= hp) then
          if (BOSS == t2) then
            Stge.RunScript('fx_boss_destroy', ox, oy, OM_FX)
          else
            Stge.RunScript('fx_destroy', ox, oy, OM_FX)
          end
          Stge.KillParticle(particle)
          PlaySound(sndDestroy)
        else
          Stge.RunScript('fx_hit', ox, oy, OM_FX)
          Stge.SetUserData(particle, 1, hp)
          PlaySound(sndHit)
        end
        return
      end
      mb = Stge.GetNextParticle(mb, OM_MYBULLET)
    end
  end
end

Player = {}

Player.OnCreate = function(param)
  local id = param._id
  Good.SetPos(id, SCREEN_W/2, SCREEN_H * 3/4)

  param.fire = -1
  param.movefx = -1

  local l,t,w,h = Good.GetDim(id)

  param.dummy = Good.GenDummy(id) -- to link weapon
  Good.SetPos(param.dummy, 0,- h/2)

  param.dummy2 = Good.GenDummy(id) -- to link moving effects
  Good.SetPos(param.dummy2, 0, h/3)

  Stge.SetPlayer(id)
end

Player.OnStep = function(param)
  if (ShowMenu) then
    return
  end

  local id = param._id
  local x,y = Good.GetPos(id)
  local l,t,w,h = Good.GetDim(id)

  -- move plane
  if (Input.IsKeyDown(Input.LBUTTON)) then
    if (Input.IsKeyPushed(Input.LBUTTON)) then
      param.xDown, param.yDown = Input.GetMousePos()
    end
    local xDown, yDown = Input.GetMousePos()
    x = x + xDown - param.xDown
    y = y + yDown - param.yDown
    param.xDown = xDown
    param.yDown = yDown
  else
    local sx,sy = 0, 0 -- move speed
    if (Input.IsKeyDown(Input.LEFT)) then
      sx = -2
    elseif (Input.IsKeyDown(Input.RIGHT)) then
      sx = 2
    end
    if (Input.IsKeyDown(Input.UP)) then
      sy = -2
    elseif (Input.IsKeyDown(Input.DOWN)) then
      sy = 2
    end
    if (Input.IsKeyDown(Input.LEFT + Input.RIGHT) and Input.IsKeyDown(Input.UP + Input.DOWN)) then
      sx = sx * 0.707
      sy = sy * 0.707
    end
    x = x + sx
    y = y + sy
    if (w/2 > x) then
      x = w/2
    elseif (SCREEN_W - w/2 < x) then
      x = SCREEN_W - w/2
    end
    if (h/2 > y) then
      y = h/2
    elseif (SCREEN_H - h/2 < y) then
      y = SCREEN_H - h/2
    end
  end

  Good.SetPos(id, x,y)

  -- move effect
  if (Input.IsKeyDown(Input.UP + Input.DOWN + Input.LEFT + Input.RIGHT)) then
    if (-1 == param.movefx) then
      param.movefx = Stge.RunScript("pennn", x, y, OM_FX)
      Stge.BindTask(param.movefx, param.dummy2, OM_FX)
    end
    if (-1 ~= param.movefx) then
      local dir = 0 -- default right
      if (Input.IsKeyDown(Input.UP)) then
        dir = 270
      elseif (Input.IsKeyDown(Input.DOWN)) then
        dir = 90
      elseif (Input.IsKeyDown(Input.LEFT)) then
        dir = 180
      end
      Stge.SetTaskDirection(param.movefx, dir + 180, OM_FX)
    end
  elseif (-1 ~= param.movefx) then
    Stge.KillTask(param.movefx, OM_FX)
    param.movefx = -1
  end

  -- fire bullet
  if (Input.IsKeyDown(Input.BTN_A + Input.LBUTTON)) then
    if (-1 == param.fire) then
      param.fire = Stge.RunScript('weapon_1', 0, 0, OM_MYBULLET)
      Stge.BindTask(param.fire, param.dummy, OM_MYBULLET)
    end
  elseif (-1 ~= param.fire) then
    Stge.KillTask(param.fire, OM_MYBULLET)
    param.fire = -1
  end
end
