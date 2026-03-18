{ lib, ... }:
{
  manual = {
    html.enable = lib.mkForce false;
    json.enable = lib.mkForce false;
    manpages.enable = lib.mkForce false;
  };

  programs.man.enable = lib.mkForce false;
}
