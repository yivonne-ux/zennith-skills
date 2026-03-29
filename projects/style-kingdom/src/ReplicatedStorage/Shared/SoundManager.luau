--!strict
-- Style Kingdom — SoundManager
-- BGM playback, SFX for key game events, volume control

local SoundService = game:GetService("SoundService")

local SoundManager = {}

-- ============================================================
-- SOUND IDS (replace 0 with actual Roblox sound asset IDs)
-- ============================================================
local SOUNDS = {
	-- Background music
	BGM_BOUTIQUE = "rbxassetid://0", -- Chill lo-fi for shopping
	BGM_CONTEST = "rbxassetid://0", -- Upbeat runway music
	BGM_MENU = "rbxassetid://0", -- Ambient menu music

	-- SFX
	SFX_PURCHASE = "rbxassetid://0", -- Cash register ding
	SFX_LEVEL_UP = "rbxassetid://0", -- Celebration fanfare
	SFX_STAR_1 = "rbxassetid://0", -- Low satisfaction
	SFX_STAR_3 = "rbxassetid://0", -- Medium satisfaction
	SFX_STAR_5 = "rbxassetid://0", -- Perfect satisfaction
	SFX_CUSTOMER_ARRIVE = "rbxassetid://0", -- Door chime
	SFX_CUSTOMER_LEAVE = "rbxassetid://0", -- Door close
	SFX_CONTEST_ANNOUNCE = "rbxassetid://0", -- Trumpet fanfare
	SFX_VOTE = "rbxassetid://0", -- Pop/click
	SFX_PRESTIGE = "rbxassetid://0", -- Epic transformation
	SFX_EXPAND = "rbxassetid://0", -- Building upgrade
	SFX_UI_CLICK = "rbxassetid://0", -- Button tap
	SFX_UI_BACK = "rbxassetid://0", -- Back/close
	SFX_TOAST = "rbxassetid://0", -- Notification pop
	SFX_LUCKY_BOX = "rbxassetid://0", -- Gacha spin
	SFX_FUSION = "rbxassetid://0", -- Item fusion sparkle
}

-- ============================================================
-- SOUND GROUPS
-- ============================================================
local bgmGroup: SoundGroup
local sfxGroup: SoundGroup

local currentBGM: Sound? = nil
local bgmVolume: number = 0.5
local sfxVolume: number = 0.7

function SoundManager.init()
	-- Create sound groups for volume control
	bgmGroup = Instance.new("SoundGroup")
	bgmGroup.Name = "BGM"
	bgmGroup.Volume = bgmVolume
	bgmGroup.Parent = SoundService

	sfxGroup = Instance.new("SoundGroup")
	sfxGroup.Name = "SFX"
	sfxGroup.Volume = sfxVolume
	sfxGroup.Parent = SoundService
end

-- ============================================================
-- BGM CONTROL
-- ============================================================

function SoundManager.playBGM(soundKey: string)
	local soundId = SOUNDS[soundKey]
	if not soundId or soundId == "rbxassetid://0" then
		return
	end

	-- Fade out current BGM
	if currentBGM then
		local fadingOut = currentBGM
		task.spawn(function()
			for i = 1, 10 do
				fadingOut.Volume = bgmVolume * (1 - i / 10)
				task.wait(0.05)
			end
			fadingOut:Stop()
			fadingOut:Destroy()
		end)
	end

	-- Create and play new BGM
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Looped = true
	sound.Volume = 0
	sound.SoundGroup = bgmGroup
	sound.Parent = SoundService

	currentBGM = sound
	sound:Play()

	-- Fade in
	task.spawn(function()
		for i = 1, 10 do
			if currentBGM == sound then
				sound.Volume = bgmVolume * (i / 10)
			end
			task.wait(0.05)
		end
	end)
end

function SoundManager.stopBGM()
	if currentBGM then
		currentBGM:Stop()
		currentBGM:Destroy()
		currentBGM = nil
	end
end

-- ============================================================
-- SFX CONTROL
-- ============================================================

function SoundManager.playSFX(soundKey: string)
	local soundId = SOUNDS[soundKey]
	if not soundId or soundId == "rbxassetid://0" then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = sfxVolume
	sound.SoundGroup = sfxGroup
	sound.Parent = SoundService

	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

-- Convenience methods for common SFX
function SoundManager.playPurchase()
	SoundManager.playSFX("SFX_PURCHASE")
end

function SoundManager.playLevelUp()
	SoundManager.playSFX("SFX_LEVEL_UP")
end

function SoundManager.playStarRating(stars: number)
	if stars >= 5 then
		SoundManager.playSFX("SFX_STAR_5")
	elseif stars >= 3 then
		SoundManager.playSFX("SFX_STAR_3")
	else
		SoundManager.playSFX("SFX_STAR_1")
	end
end

function SoundManager.playContestAnnounce()
	SoundManager.playSFX("SFX_CONTEST_ANNOUNCE")
end

function SoundManager.playUIClick()
	SoundManager.playSFX("SFX_UI_CLICK")
end

function SoundManager.playToast()
	SoundManager.playSFX("SFX_TOAST")
end

-- ============================================================
-- VOLUME CONTROL
-- ============================================================

function SoundManager.setBGMVolume(volume: number)
	bgmVolume = math.clamp(volume, 0, 1)
	bgmGroup.Volume = bgmVolume
	if currentBGM then
		currentBGM.Volume = bgmVolume
	end
end

function SoundManager.setSFXVolume(volume: number)
	sfxVolume = math.clamp(volume, 0, 1)
	sfxGroup.Volume = sfxVolume
end

function SoundManager.getBGMVolume(): number
	return bgmVolume
end

function SoundManager.getSFXVolume(): number
	return sfxVolume
end

return SoundManager
