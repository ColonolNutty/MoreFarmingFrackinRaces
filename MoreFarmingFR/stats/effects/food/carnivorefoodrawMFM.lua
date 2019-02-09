function init()
  self.overrideFoodEffects = {
    "maxenergyscalingboostfood",
    "energyregen",
    "maxhealthscalingboostfood"
  };
  self.name = config.getParameter("name", nil)
  script.setUpdateDelta(5)
  self.species = world.entitySpecies(entity.id())
  if (status.statPositive("isHerbivore") or status.statPositive("isRobot") or status.statPositive("isOmnivore") or status.statPositive("isSugar")) and not(status.statPositive("isOmnivore")) then
    world.sendEntityMessage(entity.id(), "queueRadioMessage", "foodtype")
  end
  status.clearPersistentEffects("glitchpower1")
  status.clearPersistentEffects("veggiepower")
  self.appliedEffects = false;
  self.overrodeEffects = false;
  self.durations = nil;
  self.positiveEffects = nil;
  self.foundTotalDurations = false;
end

function update(dt)
  if self.appliedEffects then
    return;
  end
  if self.overrodeEffects then
    if status.statPositive("isCarnivore") or status.statPositive("isRadien") or status.statPositive("isMantizi") then
      applyEffects()
      self.appliedEffects = true;
    elseif status.statPositive("isCarnivore") and status.statPositive("isOmnivore") then
      applyEffects()
      self.appliedEffects = true;
    elseif status.statPositive("isHerbivore") or status.statPositive("isRobot") or status.statPositive("isOmnivore") or status.statPositive("isSugar") then
      applyPenalty()
      self.appliedEffects = true;
    end
    return;
  end
  discoverStatusDurations(dt)
  if self.positiveEffects == nil then
    return;
  end
  for idx, positiveEffect in ipairs(self.positiveEffects) do
    status.removeEphemeralEffect(positiveEffect.effect);
  end
  status.removeEphemeralEffect("foodpoison")
  self.overrodeEffects = true;
end

function discoverStatusDurations(dt)
  if self.durations == nil then
    self.durations = {};
    local effects = status.activeUniqueStatusEffectSummary()
    if (#effects > 0) then
      for i = 1, #effects do
        local effectName = effects[i][1]
        if contains_value(self.overrideFoodEffects, effectName) then
          local effectData = {}
          effectData["previousDurationPercentage"] = effects[i][2]
          self.durations[effectName] = effectData
        end
      end
    end
    return
  end
  if not(self.foundTotalDurations) then
    self.foundTotalDurations = true
    self.positiveEffects = {}
    local effects = status.activeUniqueStatusEffectSummary()
    if (#effects > 0) then
      for i = 1, #effects do
        local effectName = effects[i][1]
        local effectData = self.durations[effectName]
        if effectData then
          local previousDurationPercentage = effectData["previousDurationPercentage"]
          local currentDurationPerecentage = effects[i][2]
          local differenceSinceLastTick = previousDurationPercentage - currentDurationPerecentage
          local totalDuration = dt/differenceSinceLastTick
          table.insert(self.positiveEffects, {effect = effectName, duration = totalDuration})
        end
      end
    end
  end
end

function applyPenalty()
  status.addEphemeralEffects({"foodpoison"}, entity.id())
  mcontroller.controlModifiers({ airJumpModifier = 0.08, speedModifier = 0.08 })
  status.removeEphemeralEffect("wellfed")
  if status.resourcePercentage("food") > 0.85 then
    status.setResourcePercentage("food", 0.85)
  end
end

function applyEffects()
  status.addEphemeralEffects(self.positiveEffects)
end

function uninit()
  status.clearPersistentEffects("floranpower1")
end

function contains_value(tab, val)
  for index, value in ipairs(tab) do
    if value == val then
        return true
    end
  end
  return false
end