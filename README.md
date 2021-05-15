# Virtualized pfSense router sitting on a NixOS host. 

   pfSense VM that handles WAN + LAN traffic, configurable from a NixOS host. This will eventually be runable from the NixOS installation USB.  

---
    
### What I think the Nix files here need to do is:
1. [Download pfsense](https://github.com/brodyck/nix-khoda-hafez/blob/2eff391b877adc2cd1a2e9803b8884c910067a2f/cfg/virtualisation/vms/pfsense.nix#L32)
2. Check it against the provided sha256 file
3. Create a raw image of specified size inside specified directory
4. [Create libvirt](https://github.com/brodyck/nix-khoda-hafez/blob/2eff391b877adc2cd1a2e9803b8884c910067a2f/cfg/virtualisation/vms/pfsense.nix#L50) xml [configuration file](https://github.com/brodyck/nix-khoda-hafez/blob/2eff391b877adc2cd1a2e9803b8884c910067a2f/cfg/virtualisation/vms/pfsense.xml)
5. Use a direct console (not IP) to run commands on the VM host
    - Console will likely be a wrapper for virsh commands, if not the API
    - Have to figure out what exactly can be done from CLI in pfsense, and how    
6. Install Nix from ports
    - Not sure of the other commands needed just yet
7. Isolate cpu cores for network performance
    - Less context switching decreases latency, always
8. Hugepages for the VM to take advantage of memory not moving around
9. Create BSD based nix binary cache as I'm only affording the VM 4 of the 16 cores
    - Nix expressions and things will be set up on the more powerful host, then copied over to the VM
10. Create a way on the host that I can deploy Nix to pfSense
    - Looking for options for now
      - Considering a sync'd local git repo with a service that checks it for changes if I can't find anything
      - I think pfSense has a Rest API (or there is one in development) which I could wrap
11. Backup pfSense config using one of the supported options, but configured through the NixOS host  

   Lots is still to be determined.
  
---
### My setup currently looks like this:
1. The setup is 2 SSDs in a ZFS pool mirror config, both set up with bootable UEFI partitions that also mirror each other
2. The root and all config/running/vm data is in an encrypted ZFS store, for which the key is in 2 USB flash sticks plugged in on the internal motherboard header
3. The Nix Store is in an unencrypted portion of the root pool  

All of which you can see what was done in [router-setup](../master/router-setup)

---

Resources I've read but not used much of yet:
- http://blog.patapon.info/nixos-local-vm/#building-without-nixos-rebuild
- https://git.dsg.is/david/nixpkgs/-/blob/47e0ce7f1a640bc71aaaaf837a8bcf7c95c777b2/nixos/modules/virtualisation/qemu-vm.nix
- https://ww.telent.net/2017/10/20/nixos_again_declarative_vms_with_qemu
- https://nixos.wiki/wiki/Virtualization_in_NixOS#Setting_Up_the_Guests
- https://nixos.wiki/wiki/Libvirt
- https://github.com/kalbasit/soxincfg
---
SEO:
bsd freebsd ports nixos declaritive automated edge router edge-router
