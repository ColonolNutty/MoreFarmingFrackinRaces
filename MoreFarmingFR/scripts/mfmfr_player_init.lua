local origInit = init;

function init()
  origInit();
  sb.logInfo("----- MFM Frackin Races player init -----");
  local metadata = root.assetJson("/_MFMFRversioning.config")
  if(metadata) then
    sb.logInfo("Running with " .. metadata.friendlyName .. " " .. metadata.version)
  end
end
