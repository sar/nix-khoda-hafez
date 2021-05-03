self: super:

let
  callPackage = super.callPackage;
in
{
  # package-name = callPackage ./pkgs/pathtopackage { };
  i40e = callPackage ./pkgs/i40e { };  
}