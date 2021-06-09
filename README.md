# Evanescence router
### Redundant virtualized pfSense routers sitting on a NixOS host. 

---

### Laws of this project:
* If I click a button that should not effect service, it does not effect service
* If I click a button that should effect service, it does not effect service
* Scale up and down number of vms easily
* Scale up and down number of routers easily
* Updating host OS and kernel does not effect service
* Updating guest OS does not effect serivce
* Drop-in replacement for home router (its in a mini-itx chassis)
* Guest OS and host OS must be accessable without a network
* All OSes should be configured in a declaritive manner where possible
* Will not store sensitive data
* As secure as someone without training (me) can possibly make it -- if there's a place to add a certificate/encryption, it will be added

I'm essentially stating things I hate about certain softwares. Going to stop now before this list gets too long.

### Things I am deliberately not considering
* If it makes sense to use it as a home router
* Minimum required hardware

---
    
### What I think the Nix files here need to do is:
1. Download ISO & sha256
    - This is done
2. Check it against the provided sha256 file
    - This is done
3. Extract ISO
    - This is done
4. Create a raw image of specified size inside specified directory using qemu-img
    - This is operational, but not scalable yet
      - One must write a service with the nix function for each VM
5. Create libvirt xml [configuration file](https://github.com/brodyck/nix-khoda-hafez/blob/2eff391b877adc2cd1a2e9803b8884c910067a2f/cfg/virtualisation/vms/pfsense.xml)
    - This is done
6. Create the VMs
    - This is operational, but not scalable yet
      - One must write a service with the nix function for each VM
7. Create containers for databases
    - Redundant database will be to protect against runtime issues and data integrity, not for long-term storage
    - Ephemeral
      - Doesn't matter if the DB is completely wiped out
      	- The data being wiped is a feature
    - 1 DB container per VM
    - Undecided on container management yet;
      - NixOS makes systemd containers very tempting -- Haven't read enough 
      - CRI-O type makes the most sense, due to the ubiquity and ephemeral nature
      - I prefer and am familiar with LXC/LXD -- I've used LXC extensively, and LXD is very nice as well
      	- LXD can control libvirtd, and virsh can control LXC -- the fexibility is nice
8. Pre-seed the pfSense installs to avoid going through initial setup
    - Ideally not going to have to learn to roll my own pfSense iso
9. Use a direct console (not IP) to run commands on the VM guests
    - Console will likely be a wrapper for virsh commands, if not the API
    - Have to figure out what exactly can be done from CLI in pfsense, and how
    - There's an API being made, but there's never a lot of official talk on this. OPNSense has an API, though.
10. Install Nix from FreeBSD ports
    - Not sure of the other commands needed just yet
11. Isolate cpu cores for network performance
    - 4 x cores per VM
    - Less context switching decreases latency, always
12. Hugepages for the VM to take advantage of memory not moving around
13. Create BSD based nix binary cache as I'm only affording the VM 4 of the 16 cores
    - Nix expressions and things will be set up on the more powerful host, then copied over to the VM
14. Create a way on the host that I can deploy Nix to pfSense
    - Looking for options for now
      - Considering a sync'd local git repo with a service that checks it for changes if I can't find anything
      - I think pfSense has a Rest API (or there is one in development) which I could wrap
15. Backup pfSense config using one of the supported options, but configured through the NixOS host  

   Lots is still to be determined.
  
---
### My setup currently looks like this:
1. 16 core 1700x
2. 16GB RAM
3. The setup is 2 SSDs in a ZFS pool mirror config, both set up with bootable UEFI partitions that also mirror each other
4. The root and all config/running/vm data is in an encrypted ZFS store, for which the key is in 2 USB flash sticks plugged in on the internal motherboard header
5. The Nix Store is in an unencrypted portion of the root pool  

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
