{ noctalia, ...}:
{
  imports =
    [
      noctalia.nixosModules.default
    ];
  
  services.noctalia-shell.enable = true;
}
