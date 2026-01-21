{lib, ...}: {
  documentation = {
    enable = lib.mkForce false;
    dev.enable = lib.mkForce false;
    doc.enable = lib.mkForce false;
    info.enable = lib.mkForce false;
    nixos.enable = lib.mkForce false;

    man = {
      enable = lib.mkForce false;
      generateCaches = lib.mkForce false;
      man-db.enable = lib.mkForce false;
      mandoc.enable = lib.mkForce false;
    };
  };
}
