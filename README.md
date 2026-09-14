# OpenCityMP — vidéki vezetési prototípus

Godot .NET / C# projekt. A fő jelenet most egy **1200 × 1200 méteres** vidéki
vezetési tesztpályát indít: kb. 2.1 km-es négyszögletes útkör, kavicsos gyakorlóhely,
ritkás fák, út menti pihenőtető és távoli dombok. A dombok háttérdíszletek;
a vezetési terület sík. A régi város forrása megmaradt, de nem indul el.

## Mit tartalmaz?

- Saját procedurális tesztszedán, arcade vezetés, ütközés, hátramenet és fékezés.
- Forgó/kormányzott kerekek, egérrel forgatható ütközésérzékeny kamera.
- Sebességkijelző, visszaállítás és billentyűs súgó.
- Procedurális ég, melegebb napfény, árnyékok, köd és távoli látkép.
- A korábbi networking/resource vázak továbbra is a repóban vannak, de ez a jelenet offline.

**A linkelt Mercedes W210 nincs beépítve.** A jelenlegi tesztautó nem annak modellje.
A ZIP és az újraterjesztési engedély szükséges az importhoz:
[W210 import státusz](docs/W210_IMPORT_HU.md).

## Indítás

A jelenlegi csproj Godot.NET.Sdk/4.7.2 és net8.0 értékekkel maradt meg.
A .NET SDK-t külön telepíteni kell; a runtime önmagában nem elég.
A helyi Godot .NET editor és a projekt SDK-verziójának egyeznie kell.

1. Csomagold ki a ZIP-et vagy frissítsd a repót.
2. Importáld a project.godot fájlt Godot .NET-ben.
3. Build, majd F5.

## Irányítás

W: gáz; S: fék, majd hátramenet; A/D: kormány; Space: erős fék.
Egér: körbenézés; görgő: kameratávolság; C: kamera alaphelyzet;
R: autó vissza a rajthoz; Esc: kurzor és fékezés; bal kattintás: vezetés.

Az autóban kezdődik a játék. Kiszállás, motorhang, rugózás, driftfizika,
multiplayer szinkron és Lua-futtatás még nincs.

## Ellenőrzési státusz

A fájlok és GitHub feltöltés ellenőrizve. Ebben a munkamenetben nem állt
rendelkezésre Godot/.NET futtatókörnyezet, ezért a fordítás és játék közbeni
működés még **nem tesztelt**. Nem kész Windows EXE, hanem forrásprojekt.

Helyi ellenőrzés:
- dotnet restore és dotnet build
- F5: nincs hiba a Debuggerben
- W/S és A/D: előre/hátra és kormányzás
- Space: megállás; fa/pihenőtető/pályahatár: ütközés
- R: vissza a rajthoz
- Egér/görgő/C: kamera
- A kért W210 csak sikeres import és engedélyellenőrzés után kerülhet bele

## Referencia-karakter

Saját C#-ból generált, lapos felületnormálokkal épített low-poly figura:
szürke ruha, heveder, kopasz szögletes fej, napszemüveg, fejhallgató,
külön ujjak és bakancs. A referencia alapján készült közelítés, nem pontos másolat.
Nincs Skeleton3D vagy járásanimáció. Ülő/álló változat létezik.

A főpályán a rajt mellett ül egy kék kockán. Részletes ellenőrzéshez nyisd meg
a Scenes/CharacterPreview.tscn jelenetet és F6: bal egér húzása forgat, görgő zoomol.
A régi PlayerController vizuálja szintén lecserélve; a főpálya továbbra is autóval indul.
Az autóba ülés/kiszállás ezzel nem készült el.

Az EmacE Art égbolt ZIP megérkezett, de a jelenlegi eszközök nem tudják olvasni
a helyi archívumot. Az asset és licence nem lett feldolgozva, nincs integrálva.
Az eddigi égbolt maradt. Az eredeti shader/material/licenc kicsomagolt szövege
szükséges a következő lépéshez.

A karakter fordítása és vizuális egyezése Godotban még NEM tesztelt.
