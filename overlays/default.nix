{
  # Imports `module.nix` if present, which is expected to add to
  # the nixos configuration system.
  imports = (
    if builtins.pathExists(./module.nix) then [ ./module.nix ]
    else []
  );

  # Imports the overlay
  nixpkgs.overlays = [
    (import ./overlay.nix)
  ];
}