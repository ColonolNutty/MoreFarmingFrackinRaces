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

function isFoodSafeToEat()
  if isCarnivoreFood() then
    return (isCarnivore() or isRadien() or isMantizi()) or (isCarnivore() and isOmnivore())
  elseif isCarnivoreFoodCooked() then
    return isCarnivore() or isOmnivore() or isRadien() or isMantizi()
  elseif isCarnivoreFoodFish() then
    return isCarnivore() or isOmnivore() or isRadien() or isMantizi()
  elseif isCarnivoreFoodNoPoison() then
    return isCarnivore() or isOmnivore() or isRadien() or isMantizi()
  elseif isHerbivoreFood() then
     return (isHerbivore() or isOmnivore() or isRadien() or isMantizi() or (isCarnivore() and isOmnivore())) or (isSugar() and isSugarFood())
  elseif isRadioactiveFood() then
    return isRadienSpecies() or isNovakidSpecies() or isRadien()
  elseif isRobotFood() then
    return isRobot() or isRadien() or isMantizi()
  end
  return false;
end

function init()
  self.foodType = config.getParameter("foodType", nil)
  self.species = world.entitySpecies(entity.id())
  self.hasAppliedEffects = false;
  self.durations = nil;
end

function update(dt)
  if self.hasAppliedEffects then
    return;
  end
  local positiveEffects = discoverPositiveEffects(dt)
  if positiveEffects == nil then
    return;
  end
  for idx, positiveEffect in ipairs(positiveEffects) do
    status.removeEphemeralEffect(positiveEffect.effect);
  end
  for idx, negative_effect in ipairs(NEGATIVE_EFFECTS) do
    status.removeEphemeralEffect(negative_effect);
  end
  if isFoodSafeToEat() then
    applyEffects(positiveEffects)
  else
    applyEffects(NEGATIVE_EFFECTS)
  end
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
  status.addEphemeralEffects({self.foodType}, entity.id())
end

function contains_value(tab, val)
  for index, value in ipairs(tab) do
    if value == val then
        return true
    end
  end
  return false
end

function isCarnivoreFood()
  return self.foodType == "carnivorefood"
end

function isCarnivoreFoodCooked()
  return self.foodType == "carnivorefoodcooked"
end

function isCarnivoreFoodFish()
  return self.foodType == "carnivorefoodfish"
end

function isCarnivoreFoodNoPoison()
  return self.foodType == "carnivorefoodnopoison"
end

function isHerbivoreFood()
  return self.foodType == "herbivorefood"
end

function isRobotFood()
  return self.foodType == "robofood"
end

function isSugarFood()
  return self.foodType == "sugarfood"
end

function isRadioactiveFood()
  return self.foodType == "radioactive"
end

function isRadienSpecies()
  return self.species == "radien"
end

function isNovakidSpecies()
  return self.species == "novakid"
end

function isMantiziSpecies()
  return self.species == "mantizi"
end

function isRadien()
  return status.statPositive("isRadien")
end

function isMantizi()
  return status.statPositive("isMantizi")
end

function isCarnivore()
  return status.statPositive("isCarnivore")
end

function isOmnivore()
  return status.statPositive("isOmnivore")
end

function isHerbivore()
  return status.statPositive("isHerbivore")
end

function isRobot()
  return status.statPositive("isRobot")
end

function isSugar()
  return status.statPositive("isSugar")
end
