{ lib, ... }:
{
  boot.kernelPatches = [
    {
      name = "dell-xps-9530-audio";
      patch = ./../../patches/dell-9530-audio.patch;
    }
  ];
}
