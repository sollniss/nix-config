{
  inputs,
  osConfig,
  ...
}:
{
  imports = [
    inputs.self.prefs
  ];
  config = {
    prefs = osConfig.prefs;
  };
}
