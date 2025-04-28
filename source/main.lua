-- Importing things
import 'CoreLibs/math'
import 'CoreLibs/timer'
import 'CoreLibs/object'
import 'CoreLibs/sprites'
import 'CoreLibs/graphics'
import 'CoreLibs/animation'
import 'achievements'
import 'scenemanager'
import 'cheevos'
import 'title'
scenemanager = scenemanager()

-- Setting up basic SDK params
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local fle <const> = pd.sound.fileplayer
local text <const> = gfx.getLocalizedText

pd.display.setRefreshRate(30)
gfx.setLineWidth(2)
gfx.setBackgroundColor(gfx.kColorBlack)
pd.setMenuImage(gfx.image.new('images/pause'))

mode = "arcade"
p1 = true
easy = true
backtotitleopen = false

catalog = false
if pd.metadata.bundleID == "wtf.rae.firstinline" then
    catalog = true
end

-- Save check
function savecheck()
    save = pd.datastore.read()
    if save == nil then save = {} end
    if save.music == nil then save.music = true end
    if save.hard == nil then save.hard = false end
    if save.sfx == nil then save.sfx = true end
    if save.crank == nil then save.crank = true end
    if save.shaking == nil then save.shaking = false end
    if save.mic == nil then save.mic = false end
    save.score_arcade_easy = save.score_arcade_easy or 0
    save.score_arcade_hard = save.score_arcade_hard or 0
    save.score_oneshot_easy = save.score_oneshot_easy or 0
    save.score_oneshot_hard = save.score_oneshot_hard or 0
    save.score_timed_easy = save.score_timed_easy or 0
    save.score_timed_hard = save.score_timed_hard or 0
    save.arcade_plays = save.arcade_plays or 0
    save.oneshot_plays = save.oneshot_plays or 0
    save.timed_plays = save.timed_plays or 0
    save.multi_plays = save.multi_plays or 0
    save.misses = save.misses or 0
    save.hints = save.hints or 0
    save.heckles = save.heckles or 0
end

-- ... now we run that!
savecheck()

-- Hard mode sanity check.
if save.score_arcade_easy >= 21 then
    save.hard = true
end

achievements.initialize(achievementData, true)

function updatecheevos()
	achievements.advanceTo("act5", save.score_arcade_easy + 1)
	achievements.advanceTo("act10", save.score_arcade_easy + 1)
	achievements.advanceTo("act25", save.score_arcade_easy + 1)
	achievements.advanceTo("act50", save.score_arcade_easy + 1)
	if save.score_arcade_easy >= 21 then achievements.grant("hard") end
	if save.arcade_plays >= 5 then achievements.grant("oneshot") end
	if save.arcade_plays >= 10 then achievements.grant("timed") end
	if save.multi_plays > 0 then achievements.grant("multi") end
	if save.heckles > 0 then achievements.grant("heckled") end
	achievements.save()
end

updatecheevos()

-- When the game closes...
function pd.gameWillTerminate()
	updatecheevos()
    pd.datastore.write(save)
    if pd.isSimulator ~= 1 then
        local img = gfx.getDisplayImage()
        local sound = smp.new('audio/sfx/launch')
        if save.sfx then sound:play() end
        local byebye = gfx.imagetable.new('images/byebye')
        local byebyeanim = gfx.animator.new(2200, 1, #byebye)
        gfx.setDrawOffset(0, 0)
        while not byebyeanim:ended() do
            img:draw(0, 0)
            byebye:drawImage(math.floor(byebyeanim:currentValue()), 0, 0)
            pd.display.flush()
        end
    end
end

function pd.deviceWillSleep()
	updatecheevos()
    pd.datastore.write(save)
end

-- Setting up music
music = nil

-- Fades the music out, and trashes it when finished. Should be called alongside a scene change, only if the music is expected to change. Delay can set the delay (in seconds) of the fade
function fademusic(delay)
    delay = delay or 749
    if music ~= nil then
        music:setVolume(0, 0, delay/1000, function()
            music:stop()
            music = nil
        end)
    end
end

-- New music track. This should be called in a scene's init, only if there's no track leading into it. File is a path to an audio file in the PDX. Loop, if true, will loop the audio file. Range will set the loop's starting range.
function newmusic(file, loop, range)
    if save.music and music == nil then -- If a music file isn't actively playing...then go ahead and set a new one.
        music = fle.new(file)
        if loop then -- If set to loop, then ... loop it!
            music:setLoopRange(range or 0)
            music:play(0)
        else
            music:play()
            music:setFinishCallback(function()
                music = nil
            end)
        end
    end
end

function pd.timer:resetnew(duration, startValue, endValue, easingFunction)
    self.duration = duration
    if startValue ~= nil then
        self._startValue = startValue
        self.originalValues.startValue = startValue
        self._endValue = endValue or 0
        self.originalValues.endValue = endValue or 0
        self._easingFunction = easingFunction or pd.easingFunctions.linear
        self.originalValues.easingFunction = easingFunction or pd.easingFunctions.linear
        self._currentTime = 0
        self.value = self._startValue
    end
    self._lastTime = nil
    self.active = true
    self.hasReversed = false
    self.reverses = false
    self.repeats = false
    self.remainingDelay = self.delay
    self._calledOnRepeat = nil
    self.discardOnCompletion = false
    self.paused = false
    self.timerEndedCallback = self.timerEndedCallback
end

-- This function returns the inputted number, with the ordinal suffix tacked on at the end (as a string)
function ordinal(num)
    local m10 = num % 10 -- This is the number, modulo'd by 10.
    local m100 = num % 100 -- This is the number, modulo'd by 100.
    if m10 == 1 and m100 ~= 11 then -- If the number ends in 1 but NOT 11...
        return tostring(num) .. gfx.getLocalizedText("st") -- add "st" on.
    elseif m10 == 2 and m100 ~= 12 then -- If the number ends in 2 but NOT 12...
        return tostring(num) .. gfx.getLocalizedText("nd") -- add "nd" on,
    elseif m10 == 3 and m100 ~= 13 then -- and if the number ends in 3 but NOT 13...
        return tostring(num) .. gfx.getLocalizedText("rd") -- add "rd" on.
    else -- If all those checks passed us by,
        return tostring(num) .. gfx.getLocalizedText("th") -- then it ends in "th".
    end
end

function backtotitle(bcallback, acallback)
    local image = gfx.image.new(400, 240)
    local sasser = gfx.font.new('fonts/sasser')
    local small = gfx.font.new('fonts/small')
    local click = smp.new('audio/sfx/click')
    if mode == "timed" then
        timed_sprite:setZIndex(998)
        timed_timer:pause()
    end
    backtotitleopen = true
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(10, 10, 380, 220)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(13, 13, 374, 214)
        sasser:drawTextAligned(text('returnhead'), 200, 25, kTextAlignment.center)
        small:drawTextAligned(text('returntext'), 200, 80, kTextAlignment.center)
        small:drawTextAligned(text('returnprompts'), 200, 200, kTextAlignment.center)
    gfx.popContext(image)
    local sprite = gfx.sprite.new(image)
    sprite:setCenter(0, 0)
    sprite:moveTo(0, 0)
    sprite:setZIndex(999)
    sprite:setIgnoresDrawOffset(true)
    sprite:add()
    local backHandlers = {
        AButtonDown = function()
            pd.inputHandlers.pop()
            sprite:remove()
            if save.sfx then click:play() end
            click = nil
            sprite = nil
            backHandlers = nil
            backtotitleopen = false
            if mode == "timed" then
                pd.timer.performAfterDelay(700, function()
                    timed_sprite:remove()
                    timed_sprite = nil
                    timed_timer = nil
                    timer_end = nil
                    timer_progress = nil
                end)
            end
            scenemanager:transitionscene(title)
            if acallback ~= nil then
                acallback()
            end
        end,

        BButtonDown = function()
            pd.inputHandlers.pop()
            sprite:remove()
            if mode == "timed" then
                timed_sprite:setZIndex(26001)
                timed_timer:start()
            end
            if save.sfx then click:play() end
            click = nil
            sprite = nil
            backHandlers = nil
            backtotitleopen = false
            scenemanager:transitionscenequeued()
            if bcallback ~= nil then
                bcallback()
            end
        end,
    }
    pd.inputHandlers.push(backHandlers, true)
    image = nil
    sasser = nil
    small = nil
end

scenemanager:switchscene(title)

function pd.update()
    -- Catch-all stuff ...
    gfx.sprite.update()
    pd.timer.updateTimers()
    if timer_progress ~= nil and not backtotitleopen then
        timer_progress += 0.001
    end
end