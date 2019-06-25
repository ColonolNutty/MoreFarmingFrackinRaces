OVERRIDE_EFFECTS = {
  "maxenergyscalingboost",
  "maxenergyscalingboostfood",
  "maxhealthscalingboostfood",
  "energyregen",
  "runboostfood",
  "jumpboostfood",
  "swimboost",
  "regeneration1",
  "regeneration2",
  "regeneration3",
  "camouflage25",
  "poisonblock",
  "iceblock",
  "electricblock",
  "fireblock",
  "nova",
  "rage",
  "ragefood",
  "antidote",
  "burning",
  "glow",
  "thorns",
  "lowgrav",
  "ghostlyglow",
  "mudslow"
};

NEGATIVE_EFFECTS = {
  "foodpoison"
};

function init()
  self.debugEnabled = false;
	self.foodTypes = config.getParameter("foodTypes");
  self.statusEffect = config.getParameter("statusEffect", nil);
	self.dietConfig = root.assetJson("/scripts/fr_diets.config");
	self.species = world.entitySpecies(entity.id());
	local success
	if self.species then
		success, self.speciesConfig = pcall(
			function ()
				return root.assetJson(string.format("/species/%s.raceeffect", self.species));
			end
		)
	end
	if not success then self.speciesConfig = {} end
	self.diet = self.speciesConfig.diet;
	if self.diet == nil then self.diet = "omnivore" end -- Treat races without diets as omnivores

	-- Grab premade diet
	if type(self.diet) == "string" then
		self.diet = self.dietConfig.diets[self.diet];
	end
	self.whitelist = self.diet[1] or {};
	self.blacklist = self.diet[2] or {};

  printTable(self.diet, "diet");
  printTable(self.whitelist, "whitelist");
  printTable(self.blacklist, "blacklist");

  self.foodIsBad = isFoodBad();
  self.hasAppliedEffects = false;
  self.durations = nil;
end

function isFoodBad()
  self.foodChecks = {};
  for _,foodType in pairs(self.foodTypes) do
    logInfo("Checking foodType " .. foodType)
    self.foodChecks[foodType] = checkFood(self.whitelist, self.blacklist, foodType);
    if self.foodChecks[foodType] == false then
      logInfo("Food is bad " .. foodType)
      return true
    end
  end
  logInfo("Food is good")
  return false;
end

function checkFood(whitelist, blacklist, foodType)
	local parent = self.dietConfig.groups[foodType]
  logInfo("Checking food type " .. foodType)
  printTable(whitelist, "whitelist 2")
  printTable(blacklist, "blacklist 2")
	-- If the type is in the whitelist (can eat)
	if whitelist[foodType] ~= nil then
    logInfo("Food in whitelist")
		return true
	-- If the type is in the blacklist (can't eat)
	elseif blacklist[foodType] then
    logInfo("Food in blacklist")
		return false
	-- If the type wasn't found, but there is a parent, check the parent
	elseif parent then
    logInfo("Has Parent")
    printTable(parent, "parent")
		-- Handling for multiple parenting (weird shit, but yeah)
		-- Checks ALL parents, but only needs ONE to succeed
		if type(parent) == "table" then
			local result = false
			for _,par in pairs(parent) do
				result = checkFood(whitelist, blacklist, par)
				if result then break end
      end
      logInfo("Table worked")
			return result
		end
		return checkFood(whitelist, blacklist, parent)
  end
  logInfo("Checked food and nothing matched! Assuming is bad.")
	return false
end

function update(dt)
  logInfo("Updating");
  if self.hasAppliedEffects then
    logInfo("Already Applied Effects");
    return;
  end
  local positiveEffects = discoverPositiveEffects(dt)
  if positiveEffects == nil then
    logInfo("No positive effects found");
    return;
  end
  logInfo("Removing positive effects");
  for idx, positiveEffect in ipairs(positiveEffects) do
    status.removeEphemeralEffect(positiveEffect.effect);
  end
  logInfo("Removing negative effects");
  for idx, negative_effect in ipairs(NEGATIVE_EFFECTS) do
    status.removeEphemeralEffect(negative_effect);
  end
  if self.foodIsBad then
    logInfo("Food is bad!");
  end

  if not self.foodIsBad then
    logInfo("Applying positive effects");
    applyEffects(positiveEffects);
  else
    logInfo("Applying negative effects");
    applyEffects(NEGATIVE_EFFECTS);
  end
  logInfo("Effects applied");
  self.hasAppliedEffects = true;
end

function uninit()
end

function discoverPositiveEffects(dt)
  local effects = status.activeUniqueStatusEffectSummary()
  if (#effects <= 0) then
    return nil;
  end
  if self.durations == nil then
    self.durations = {};
    for i = 1, #effects do
      local effectName = effects[i][1];
      if contains_value(OVERRIDE_EFFECTS, effectName) then
        local effectData = {};
        local duration = effects[i][2];
        if duration >= 1.0 then
          self.durations = nil;
          return nil;
        end
        effectData["previousDurationPercentage"] = duration;
        self.durations[effectName] = effectData;
      end
    end
    return nil;
  end

  local positiveEffects = {}
  for i = 1, #effects do
    local effectName = effects[i][1]
    local effectData = self.durations[effectName]
    if effectData then
      local currentDurationPercentage = effects[i][2]
      local previousDurationPercentage = effectData["previousDurationPercentage"]
      local differenceSinceLastTick = previousDurationPercentage - currentDurationPercentage
      local totalDuration = dt/differenceSinceLastTick
      table.insert(positiveEffects, {effect = effectName, duration = totalDuration})
    end
  end
  return positiveEffects
end

function applyEffects(effects)
  status.addEphemeralEffects(effects, entity.id())
  if self.statusEffect ~= nil then
    status.addEphemeralEffects({self.statusEffect}, entity.id())
  end
end

function contains_value(arr, val)
  for index, value in ipairs(arr) do
    if value == val then
        return true
    end
  end
  return false
end

function printTable(tabVal, previousName)
  if not self.debugEnabled then
    return
  end
  if(tabVal == nil) then
    logInfo("tabVal is nil for '" .. previousName .. "'. Nothing to print");
    return;
  end
  local prevName = previousName or "";
  if(tabVal[1] ~= nil) then
    logInfo("Printing array");
    for idx,val in ipairs(tabVal) do
      if(type(val) == "function") then
        logInfo("'" .. prevName .. "' - table '" .. idx .. "'");
      elseif(type(val) == "table") then
        printTable(val, "'" .. prevName .. "' - table '" .. idx .. "'");
      else
        printValue(val, "'" .. prevName .. "' - '" .. idx .. "'");
      end
    end
  elseif(type(tabVal) == "table") then
    logInfo("Printing table");
    if(#tabVal == 0) then
      logInfo("table was empty");
    end
    for name,val in pairs(tabVal) do
      if(type(val) == "function") then
        logInfo("'" .. prevName .. "' - table '" .. name .. "'");
      elseif(type(val) == "table") then
        printTable(val, "'" .. prevName .. "' - table '" .. name .. "'");
      else
        printValue(val, "'" .. prevName .. "' - '" .. name .. "'");
      end
    end
  else
    logInfo("Printing value");
    printValue(tabVal, "'" .. previousName .. "'")
  end
end

function printValue(val, previousName)
  if not self.debugEnabled then
    return
  end
  if (val == true) then
    logInfo(" Name " .. previousName .. " val true")
  elseif (val == false) then
    logInfo(" Name " .. previousName .. " val false")
  else
    logInfo(" Name " .. previousName .. " val " .. val)
  end
end


function logInfo(message)
  if not self.debugEnabled then
    return
  end
  sb.logInfo(message)
end