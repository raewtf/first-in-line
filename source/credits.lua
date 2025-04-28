import 'settings'

-- Setting up consts
local pd <const> = playdate
local gfx <const> = pd.graphics
local smp <const> = pd.sound.sampleplayer
local fle <const> = pd.sound.fileplayer
local text <const> = gfx.getLocalizedText

class('credits').extends(gfx.sprite) -- Create the scene's class
function credits:init(...)
	credits.super.init(self)
	local args = {...} -- Arguments passed in through the scene management will arrive here
	gfx.sprite.setAlwaysRedraw(false)

	function pd.gameWillPause() -- When the game's paused...
		local menu = pd.getSystemMenu()
		menu:removeAllMenuItems()
		menu:addMenuItem(text('slidesettings'), function()
			if save.sfx then assets.click:play() end
			scenemanager:switchscene(settings)
		end)
	end

	assets = { -- All assets go here. Images, sounds, fonts, etc.
		image_bg = gfx.image.new('images/bg'),
		sasser = gfx.font.new('fonts/sasser'),
		small = gfx.font.new('fonts/small'),
		spotlight = smp.new('audio/sfx/spotlight'),
		click = smp.new('audio/sfx/click'),
	}

	vars = { -- All variables go here. Args passed in from earlier, scene variables, etc.
		showtime = false,
	}
	vars.creditsHandlers = {
		BButtonDown = function()
			scenemanager:switchscene(settings)
			if save.sfx then assets.click:play() end
		end,
	}

	gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height) -- Background drawing
		if vars.showtime then
			assets.image_bg:draw(0, 0)
		end
		assets.sasser:drawTextAligned(text('credits'), 200, 10, kTextAlignment.center)
		assets.small:drawTextAligned(text('creditsartcode'), 200, 40, kTextAlignment.center)
		assets.small:drawTextAligned(text('creditsmusic'), 200, 55, kTextAlignment.center)
		assets.small:drawTextAligned(text('creditssfx'), 200, 70, kTextAlignment.center)
		assets.small:drawTextAligned(text('creditsfont'), 200, 85, kTextAlignment.center)
		assets.small:drawTextAligned(text('creditstanuk'), 200, 100, kTextAlignment.center)
		assets.small:drawTextAligned(text('creditsshaker'), 200, 115, kTextAlignment.center)
		assets.small:drawTextAligned(text('creditscheevos'), 200, 130, kTextAlignment.center)
		assets.small:drawTextAligned(text('creditsthanx'), 200, 145, kTextAlignment.center)
		assets.small:drawTextAligned(text('creditsthanx2'), 200, 160, kTextAlignment.center)
		assets.small:drawTextAligned(text('creditsrae'), 200, 185, kTextAlignment.center)
		assets.small:drawTextAligned(text('creditsyou'), 200, 200, kTextAlignment.center)
		assets.small:drawTextAligned(text('back'), 370, 220, kTextAlignment.right)
	end)

	pd.timer.performAfterDelay(500, function()
		vars.showtime = true
		pd.inputHandlers.push(vars.creditsHandlers)
		gfx.sprite.redrawBackground()
		if save.sfx then assets.spotlight:play() end
	end)

	-- Set the sprites
	self:add()
end