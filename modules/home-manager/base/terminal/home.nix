{vars, ...}: {
  home = {
    username = vars.username;
    homeDirectory = "/home/${vars.username}";
  };
}
