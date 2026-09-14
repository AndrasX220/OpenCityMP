# OpenCityMP

Önálló, modolható open-world multiplayer játék alapja **Godot 4.7.2 .NET + C#** technológiával. A vizuális irány szándékosan PS2-korszakú, low-poly, meleg naplementés hangulatú. A projekt nem tartalmaz GTA: San Andreas fájlokat vagy más jogvédett Rockstar asseteket.

## V0.1 – játszható prototípus

- teljesen procedurálisan felépülő 3D tesztváros;
- utcák, sávjelzések, járdák és ütközéssel rendelkező épületek;
- pálmák, tetőelemek, ablakcsíkok és low-poly parkoló autók;
- harmadik személyű C# karaktervezérlés;
- akadályokat kerülő, forgatható és zoomolható kamera;
- séta, sprint és ugrás;
- ködös, naplementés PS2/SA-hangulat;
- ENet multiplayer manager váza;
- MTA-szerű resource manifest felismerése;
- példa Lua resource a tervezett API bemutatására.

> Ez az első technikai prototípus. A járművezetés, tényleges hálózati szinkron, Lua futtatás és szerverböngésző a következő verziók feladata.

## Elindítás

1. Telepítsd a **Godot 4.7.2 .NET** kiadását és a .NET 8 SDK-t.
2. Klónozd a repót, vagy töltsd le ZIP-ként.
3. Godot Project Managerben válaszd az **Import** lehetőséget.
4. Tallózd be a `project.godot` fájlt.
5. Várd meg a C# projekt visszaállítását, majd nyomj **F6/F5**-öt.

```bash
git clone https://github.com/AndrasX220/OpenCityMP.git
cd OpenCityMP
dotnet restore
```

## Irányítás

| Művelet | Gomb |
|---|---|
| Mozgás | WASD |
| Futás | bal vagy jobb Shift |
| Ugrás | Space |
| Kamera | egér |
| Kamera távolsága | görgő |
| Kurzor elengedése | Esc |
| Kamera visszafogása | bal kattintás |

## Projektstruktúra

```text
OpenCityMP/
├── project.godot
├── OpenCityMP.csproj
├── Scenes/
│   └── Main.tscn
├── Scripts/
│   ├── Main.cs
│   ├── PlayerController.cs
│   ├── LowPolyCity.cs
│   ├── GameUi.cs
│   ├── Networking/
│   │   └── NetworkManager.cs
│   └── Modding/
│       └── ResourceManager.cs
└── resources/
    └── example_resource/
        ├── resource.json
        └── server/main.lua
```

## Tervezett mérföldkövek

- **V0.2:** vezethető autó, be-/kiszállás, dedicated server, player/vehicle sync és chat.
- **V0.3:** Lua runtime, eventek, parancsok, createVehicle/createObject és hot reload.
- **V0.4:** server browser, automatikus resource-letöltés, map editor és egyedi assetek.

Részletesebb bontás: [docs/ROADMAP_HU.md](docs/ROADMAP_HU.md)

## Licenc

A saját OpenCityMP forráskód MIT licencű. Külső modellek vagy hangok későbbi hozzáadásakor azok licence külön ellenőrzendő.
