--[[
	Title: Project Fantasma (PF)
	Description:
	An API for Phantom Forces that does not require "hacking into" the Framework environment.
	
	Adapted from my original script, PNF (https://github.com/Allazeu/PublicScripts/blob/master/games/phantom%20forces/PhantomNotFunny.lua)
	All of this is original and from scratch. Anyone can use this in any way (including forks) as long as credits are given.
	
	Credits: Centurian (me), Phantom Forces? (for the script I guess)
--]]

math.randomseed(tick()); -- random aaaa

local module = { };

local version = "API 1.0.0 2020.01.05";
local PNFENABLED = true;
local volume = 1;

local cam = workspace.CurrentCamera;
local serv = {
	run = game:GetService('RunService');
	repstorage = game:GetService('ReplicatedStorage');
	repfirst = game:GetService('ReplicatedFirst');
};

-- define the rad functions

local function netrequire(uri)
	local httpget = game:HttpGet(uri);
	return loadstring(httpget)();
end

local function switch(condition, case)
	if (condition) then
		local c = case[condition];
		if (c) then
			if (typeof(c):upper() ~= 'FUNCTION') then
				c = case[c];
				if (c) then return c(); end
			else
				return c();
			end
			
		end
	elseif (condition == nil) then
		local f = case['nil'];
		if (f) then
			return f();
		end
	end
end

local function spawn(ACTION, ...)
	coroutine.resume(coroutine.create(ACTION), ...);
end

local wfc = game.WaitForChild;
local ffc = game.FindFirstChild;
local gpc = game.GetPropertyChangedSignal;

local ud2 = UDim2.new;
local v3 = Vector3.new;
local v2 = Vector2.new;

local ENUM = { };

-- import my stupid ass libraries
local Instance = netrequire("https://raw.githubusercontent.com/Allazeu/api/master/Lua/Roblox/BetterInstance.lua");
local ev = netrequire("https://raw.githubusercontent.com/Allazeu/api/master/Lua/EventModule.lua");

-- make the player class for an interface of players
local Player = { };
local PlayerService = {
	service = game:GetService('Players');
	Players = { };
};

do
	local lp = PlayerService.service.LocalPlayer;
	do
		local pservice = PlayerService.service;
		local events = {
			added = { };
			removing = { };
		};
		
		function PlayerService.Added(p, ACTION)
			events.added[p] = ACTION;
		end
		
		function PlayerService.Removing(p, ACTION)
			events.removing[p] = ACTION;
		end
		
		function PlayerService:Get(name)
			return PlayerService.Players[name];
		end
		
		function PlayerService:GetAllPlayers()
			local x = PlayerService.Players;
			x[lp.Name] = nil;
			
			return x;
		end
		
		pservice.ChildAdded:Connect(function(obj)
			if (obj:IsA('Player')) then
				ev:FireEvent('playeradded', PlayerService.Players[obj.Name]);
			end
		end);
		
		pservice.DescendantRemoving:Connect(function(obj)
			if (obj:IsA('Player')) then
				ev:FireEvent('playerleft', PlayerService.Players[obj.Name]);
			end
		end);
	end
	
	do
		local pmeta = {
			__index = function(this, i)
				local me = rawget(this, 'Player');
				local index = i:upper();
				return switch(index, {
					NAME = function()
						return me.Name;
					end;
					
					CHARACTER = function()
						return me.Character;
					end;
					
					TEAMCOLOR = function()
						return me.TeamColor;
					end;
					
					HEAD = function()
						local x = me.Character;
						if (x) then
							return x:FindFirstChild('Head');
						end
					end;
					
					DEAD = function()
						if (me.Character) then
							return (me.Character.Parent == workspace);
						end
						
						return true;
					end;
				});
			end;
			
			__eq = function(this, value)
				return this.Player == value.Player;
			end;
			
			__tostring = function(this)
				return this.name;
			end;
			
			__call = function(this, ...)
				return this.Player;
			end
		};
		
		function Player.new(me)
			local this = { Player = me };
			local events = {
				cadded = { };
				left = { };
			};
			
			this.PlayerGui = (me == lp and me:FindFirstChildOfClass('PlayerGui'));
			
			function this.CharacterAdded(ACTION)
				local tkey = tick();
				events.cadded[tkey] = ACTION;
				
				return tkey;
			end
			
			function this.Leaving(ACTION)
				local tkey = tick();
				events.left[tkey] = ACTION;
				
				return tkey;
			end
			
			function this.UnbindAction(type, id)
				switch(type:upper(), {
					L = function()
						events.left[id] = nil;
					end;
					
					A = function()
						events.cadded[id] = nil;
					end
				});
			end
			
			setmetatable(this, pmeta);
			PlayerService.Players[me.Name] = this;
			
			me.CharacterAdded:Connect(function(char)
				for _, ACTION in next, events.cadded do
					spawn(ACTION, char);
				end
			end);
			
			
			ev:AddEvent('playerleft', function(THATPLAYER)
				if (THATPLAYER == this) then
					for _, ACTION in next, events.left do
						spawn(ACTION);
					end
				end
				
			end);
			
			return this;
		end
	end
end

-- the fuckign contentprovider
local Provider = { };
do
	local cp = game:GetService('ContentProvider');
	function Provider:Preload(stuff)
		cp:PreloadAsync(stuff);
	end
end

-- define needed variables for big boys
local self = Player.new(PlayerService.service.LocalPlayer); -- LocalPlayer
for _, v in next, PlayerService.service:GetPlayers() do
	Player.new(v);
end

-- setup the bruh moment sound module
local sound = { };
do
	local soundarray = { };
	
	local basesound = Instance.new('Sound', nil, {
		Volume = 2;
		EmitterSize = 10;
	});
	
	function sound.distort(lvl, p)
		return Instance.new('DistortionSoundEffect', nil, {
			Level = lvl;
			Priority = p;
		});
	end
	
	function sound.play(name, prop)
		if (not soundarray[name]) then error(name .. " is not loaded!"); end
		if (not prop) then prop = { }; end
		local distort = prop.dt;
		local reverb = prop.rv;
		
		local mysound = Instance.clone(soundarray[name], {
			Parent = prop.par or self.PlayerGui;
			TimePosition = prop.tp or .5;
			Volume = (prop.v or 2) * volume;
			PlaybackSpeed = prop.pi or 1;
		});
		
		if (distort) then distort.Parent = mysound; end
		if (reverb) then reverb.Parent = mysound; end
		
		local function stopit()
			mysound:Destroy();
			if (prop.par) then
				prop.par:Destroy();
			end
		end
		
		spawn(function() mysound.Ended:Wait(); stopit(); end);
		
		mysound:Play();
		if (prop.ea) then
			delay(prop.ea, function()
				mysound:Stop();
				stopit();
			end);
		end
	end
	
	function sound.load(name, id)
		if (not soundarray[name]) then
			local newsound = Instance.clone(basesound, {
				SoundId = id;
			});
			
			Provider:Preload({ newsound });
			soundarray[name] = newsound;
		end
	end
end

-- define a fake pf api because we are neato burrito and i am too lazy to execute cRaZy HaCkS
local PF = { };
do
	local maingui = wfc(self.PlayerGui, "MainGui");
	local gamegui = wfc(maingui, "GameGui");
	local misc = serv.repstorage.Misc;
	
	local chatgui = wfc(self.PlayerGui, "ChatGame");
	local globalchat = wfc(chatgui, "GlobalChat");
	local version = wfc(chatgui, "Version");
		local SERVERVERSION = version.Text:match(":%s?(.+)");
	
	local killfeed = wfc(gamegui, "Killfeed");
	
	local endfr = wfc(maingui, "EndMatch")
	local quote = wfc(endfr, "Quote")
	local result = wfc(endfr, "Result")
	local gmode = wfc(endfr, "Mode")
	
	-- core stuff like uuhhhhhhh fuckin' uuuuhhhhh names
	PF.Core = { };
	do
		PF.Core.MainGui = maingui;
		PF.Core.GameGui = gamegui;
		PF.Core.Misc = misc;
		PF.Core.ServerVersion = SERVERVERSION;
		
		local setname = self.name;
		
		function PF.Core:setname(name)
			for _, v in next, maingui:GetDescendants() do
				if (v:IsA('TextLabel')) then
					if (v.Text:upper() == setname:upper()) then
						v.Text = name;
					end
				end
			end
			
			setname = name;
		end
		
		function PF.Core:revertname()
			local me = self.name;
			for _, v in next, maingui:GetDescendants() do
				if (v:IsA('TextLabel')) then
					if (v.Text:upper() == setname:upper()) then
						v.Text = me;
					end
				end
			end
			
			setname = me;
		end
		
		workspace.DeadBody.ChildAdded:Connect(function(c) -- connect to when somebody dies xd
			if (c:IsA('Model') and c.Name == 'Dead' and PNFENABLED) then
				ev:FireEvent('deadbody', c);
			end
		end);
	end
	
	
	-- chat blah blah
	PF.Chat = { };
	ENUM.CHAT = { };
	do
		local speakerpattern = "(%a+)%s?:";
		local msg = wfc(misc, "Msger");
		local chatbox = wfc(chatgui, "TextBox");
		
		PF.Chat.ChatBox = chatbox;
		PF.Chat.GlobalChat = globalchat;
		
		function PF.Chat:out(tag, message, colour)
			local mes = msg:Clone();
			mes.Name = 'MsgerMain';
			mes.Parent = globalchat;
			mes.Text = "[" .. tag .. "]: ";
			mes.TextColor3 = colour;
			mes.Msg.Text = message;
			mes.Msg.Position = ud2(0, mes.TextBounds.x, 0, 0);
		end
		
		globalchat.ChildAdded:Connect(function(mes)
			if (mes:IsA('TextLabel')) then
				wait();
				local speaker = mes.Text:match(speakerpattern);
				
				if (speaker) then
					local message = mes.Msg.Text;
					if (PNFENABLED) then
						ev:FireEvent('playerchatted', PlayerService:Get(speaker), message, mes);
					end
				end
			end
		end);
		
		chatbox.FocusLost:Connect(function(enter)
			chatbox.Active = false;
			local message = chatbox.Text;
			if (enter and message ~= "") then
				if (PNFENABLED) then
					ev:FireEvent('selfchatted', message);
				end
			end
		end);
	end
	
	-- killfeed shot you are dead
	PF.Killfeed = { };
	ENUM.KILLFEED = { };
	do
		PF.Killfeed.KillfeedFrame = killfeed;
		local distpattern = "%s?(%d+)%s?";
		local rfeed = misc.Feed;
		local hsht = misc.Headshot;
		
		--[[
			[Player] killer - the killer
			[string] victim - the victim
			[string] dist - distance of killer from victim
			[string] weapon - name of the weapon used by the killer to kill the victim
			[boolean] head - headshot or not
		--]]
		function PF.Killfeed:add(killer, killercolour, victim, victimcolour, dist, weapon, head)
			local spacing = 15;
			local newfeed = rfeed:Clone();
			newfeed.Text = killer;
			newfeed.TextColor = killercolour;
			newfeed.GunImg.Text = weapon;
			newfeed.Victim.Text = victim;
			newfeed.Victim.TextColor = victimcolour;
			newfeed.GunImg.Dist.Text = "Dist: " .. dist .. " studs";
			newfeed.Parent = killfeed;
			newfeed.GunImg.Size = UDim2.new(0, newfeed.GunImg.TextBounds.x, 0, 30);
			newfeed.GunImg.Position = UDim2.new(0, spacing + newfeed.TextBounds.x, 0, -5);
			newfeed.Victim.Position = UDim2.new(0, spacing * 2 + newfeed.TextBounds.x + newfeed.GunImg.TextBounds.x, 0, 0);
			if head then
				local headnote = hsht:Clone();
				headnote.Parent = newfeed.Victim;
				headnote.Position = ud2(0, 10 + newfeed.Victim.TextBounds.x, 0, -5);
			end
			spawn(function()
				newfeed.Visible = true;
				wait(20);
				for i = 1, 10 do
					if newfeed.Parent then
						newfeed.TextTransparency = i / 10;
						newfeed.TextStrokeTransparency = i / 10 + 0.5;
						newfeed.GunImg.TextStrokeTransparency = i / 10 + 0.5;
						newfeed.GunImg.TextTransparency = i / 10;
						newfeed.Victim.TextStrokeTransparency = i / 10 + 0.5;
						newfeed.Victim.TextTransparency = i / 10;
						wait(1 / 30);
					end
				end
				if newfeed and newfeed.Parent then
					Instance.destroy(newfeed);
				end
			end);
			local kb = killfeed:GetChildren();
			for i = 1, #kb do
				local v = kb[i];
				v:TweenPosition(ud2(0.01, 5, 1, (i - #kb) * 25 - 25), "Out", "Sine", 0.2, true);
				if #kb > 5 and #kb - i >= 5 then
					spawn(function()
						if kb[1].Name ~= "Deleted" then
							for i = 1, 10 do
								if ffc(kb[1], "Victim") then
									kb[1].TextTransparency = i / 10;
									kb[1].TextStrokeTransparency = i / 10 + 0.5;
									kb[1].Victim.TextTransparency = i / 10;
									kb[1].Victim.TextStrokeTransparency = i / 10 + 0.5;
									kb[1].Name = "Deleted";
									kb[1].GunImg.TextTransparency = i / 10;
									kb[1].GunImg.TextStrokeTransparency = i / 10 + 0.5;
									wait(1 / 30)
								end
							end
							Instance.destroy(kb[1]);
						end
					end)
				end
			end
		end
		
		killfeed.ChildAdded:Connect(function(newfeed)
			if (newfeed:IsA('TextLabel')) then
				local killer = PlayerService:Get(newfeed.Text);
				local victim = PlayerService:Get(newfeed.Victim.Text);
				local dist = string.match(newfeed.GunImg.Dist.Text, distpattern);
				local weapon = newfeed.GunImg.Text;
				local head = newfeed.Victim:FindFirstChild('Headshot');
				
				if (head) then
					head = head.Visible;
				end
				
				if (PNFENABLED) then
					ev:FireEvent('onkill', killer, victim, dist, weapon, head, newfeed);
				end
			end
		end);
	end
	
	-- round timing let's get it
	PF.Round = { };
	ENUM.ROUND = { };
	do
		PF.Round.EndFrame = endfr;
		PF.Round.Quote = quote;
		PF.Round.ResultText = result;
		PF.Round.GameMode = gmode;
		
		gpc(endfr, 'Visible'):Connect(function()
			wait(.1);
			local bool = endfr.Visible;
			if (bool) then
				local resultText = result.Text;
				local loss = (resultText:upper() == "DEFEAT");
				
				-- damn the round ended
				if (PNFENABLED) then
					ev:FireEvent('roundend', quote, loss, result, gmode);
				end
			end
		end);
	end
	
	-- weapon pew pew
	PF.Weapon = { };
	ENUM.WEAPON = { };
	do
		-- enums
		do
			ENUM.WEAPON.HUD = {
				NA_AMMO = "- - -";
				SPOT_HIDING = "Hiding from enemy...";
				SPOT_SHOWN = "Spotted by enemy!";
			};
		end
		
		local gammopattern = "(%d+)x";
		
		-- misc
		local tagfr = wfc(gamegui, "NameTag");
		local capfr = wfc(gamegui, "Capping");
		
		-- scope
		local scopefr = wfc(maingui, "ScopeFrame");
		local steady = wfc(gamegui, "Steady");
		local steadyfull = wfc(steady, "Full");
		local steadybar = wfc(steadyfull, "Bar");
		
		-- HUD
		local spotted = wfc(gamegui, "Spotted");
		local use = wfc(gamegui, "Use");
		
		-- radar
		local radar = wfc(gamegui, "Radar");
		local rme = wfc(radar, "Me");
		local rfolder = wfc(radar, "Folder");
		
		-- ammo
		local ammohud = wfc(gamegui, "AmmoHud");
		local hitmarker = wfc(gamegui, "Hitmarker");
		local ammofr = wfc(ammohud, "Frame");
		local ammotext = wfc(ammofr, "Ammo");
		local gammo = wfc(ammofr, "GAmmo");
		local magtext = wfc(ammofr, "Mag");
		local fmodetext = wfc(ammofr, "FMode");
		
		-- health
		local bloodscreen = wfc(gamegui, "BloodScreen");
		local healthtext = wfc(ammofr, "Health");
		local healthbar = wfc(ammofr, "healthbar_back");
		local healthbarFill = wfc(healthbar, "healthbar_fill");
		
		-- scope shit here
		PF.Weapon.Scope = { };
		do
			PF.Weapon.Scope.ScopeFrame = scopefr;
			PF.Weapon.Scope.SteadyText = steady;
			PF.Weapon.Scope.SteadyBar = steadybar;
			
			gpc(scopefr, 'Visible'):Connect(function()
				if (PNFENABLED) then
					ev:FireEvent('scoped', scopefr.Visible);
				end
			end);
		end
		
		-- hud crap
		PF.Weapon.HUD = { };
		do
			PF.Weapon.HUD.SpottedText = spotted;
			PF.Weapon.HUD.UseText = use;
			
			gpc(spotted, 'Visible'):Connect(function()
				if (spotted.Text == ENUM.WEAPON.HUD.SPOT_SHOWN) then
					if (PNFENABLED) then
						ev:FireEvent('spotted');
					end
				end
			end);
			
			gpc(spotted, 'Text'):Connect(function()
				if (spotted.Visible) then
					if (PNFENABLED) then
						if (spotted.Text == ENUM.WEAPON.HUD.SPOT_HIDING) then
							ev:FireEvent('spot_hide');
						else
							ev:FireEvent('spotted');
						end
					end
				end

			end);
			
			gpc(use, 'Visible'):Connect(function()
				if (PNFENABLED) then
					ev:FireEvent('useprompt', use.Visible);
				end
			end);
		end
		
		-- finally the fucking guns
		PF.Weapon.Weapons = { };
		do
			PF.Weapon.Weapons.Hitmarker = hitmarker;
			PF.Weapon.Weapons.AmmoText = ammotext;
			PF.Weapon.Weapons.GammoText = gammo;
			PF.Weapon.Weapons.MagText = magtext;
			
			PF.Weapon.Weapons.CURRENTWEAPON = {
				ammo = 0;
				mag = 0;
			};
			
			gpc(hitmarker, 'Visible'):Connect(function()
				if (not PNFENABLED) then return; end
				ev:FireEvent('bullethit', hitmarker.Visible);
			end);
			
			gpc(ammotext, 'Text'):Connect(function()
				local ammo = ammotext.Text;
				if (PNFENABLED) then
					if (ammo == ENUM.WEAPON.HUD.NA_AMMO) then
						-- non-school-shooter weapons (grenades and knives)
						ev:FireEvent('na_ammo', ammo);
					else
						-- school shooter firearms
						PF.Weapon.Weapons.CURRENTWEAPON.ammo = ammo;
						ev:FireEvent('clipchanged', ammo);
					end
				end
			end);
			
			gpc(gammo, 'Text'):Connect(function()
				local ammo = string.match(gammo.Text, gammopattern);
				
				-- the boom booms
				if (not PNFENABLED) then return; end
				ev:FireEvent('gammochanged', ammo);
			end);
			
			gpc(magtext, 'Text'):Connect(function()
				local mag = magtext.Text;
				if (mag ~= ENUM.WEAPON.HUD.NA_AMMO and PNFENABLED) then
					-- school shooter firearms
					PF.Weapon.Weapons.CURRENTWEAPON.mag = mag;
					ev:FireEvent('magchanged', mag);
				end
			end);
		end
	end
end

-- let us put on our big boy pants and start the script
do
	local function switchindex(this, i, t)
		if (i == nil) then i = ""; end
		return switch(tostring(i):upper(), t);
	end
	
	local index = {
		APIVERSION = function()
			return version;
		end;
		
		API = function()
			return PF;
		end;
		
		SELF = function()
			return self;
		end;
		
		PLAYERSERVICE = function()
			return PlayerService;
		end;
		
		PLAYER = function()
			return Player;
		end;
		
		SOUND = function()
			return sound;
		end;
		
		CAMERA = function()
			return cam;
		end;
		
		ENABLED = function()
			return PNFENABLED
		end;
		
		INSTANCE = function()
			return Instance;
		end;
	};
	
	setmetatable(module, {
		__index = function(this, i)
			switchindex(i, index);
		end;
		
		__newindex = function(this, i, v)
			switchindex(i, {
				ENABLED = function()
					PNFENABLED = not(not(v));
				end;
			});
		end;
	});
	
	warn("Project Fantasma (PF API) by Centurian has been loaded. Current version: " .. version);
end

return module;
