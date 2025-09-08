print("^2[Killfeed] ^7Client démarré")

-- Pistolet
GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_PISTOL"), 250, false, true)

-- Fusil de précision
GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_SNIPERRIFLE"), 250, false, true)

-- Fusil à pompe
GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_PUMPSHOTGUN"), 250, false, true)

-- Mitraillette
GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_MICROSMG"), 250, false, true)

print("^2[Killfeed] ^7Armes données au joueur pour test")