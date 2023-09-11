Running `nixos-anywhere` on this flake yields the following error..

```
➜ nixc (main) ✔ nix run github:numtide/nixos-anywhere -- --flake github:multivac61/nixc#o --vm-test
warning: not writing modified lock file of flake 'github:multivac61/nixc':
• Added input 'disko':
    'github:nix-community/disko/b54e2dc988b34fbad1a1180fe68b573a9d080df5' (2023-09-11)
• Added input 'disko/nixpkgs':
    follows 'nixpkgs'
error:
       … while evaluating the attribute 'drvPath'

         at /nix/store/0yzh1r9mhsr4vp5w96y3i0jgz3m2qzv6-source/lib/customisation.nix:228:7:

          227|     in commonAttrs // {
          228|       drvPath = assert condition; drv.drvPath;
             |       ^
          229|       outPath = assert condition; drv.outPath;

       … while calling the 'derivationStrict' builtin

         at /builtin/derivation.nix:9:12: (source not available)

       (stack trace truncated; use '--show-trace' to show the full trace)

       error: The option `disko.devices.disk."/dev/sda".content.partitions."[definition 1-entry 2]".content._pkgs' is read-only, but it's set multiple times. Definition values:
       - In `/nix/store/1j2jgap8jbvkg8xiysmr8c1mc69s6j15-source/lib/types/mdraid.nix': <function>
       - In `<unknown-file>': <function>
```
