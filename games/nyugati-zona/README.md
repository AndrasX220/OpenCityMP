# NYUGATI ZÓNA — Berekfalva 0.1

Önálló **Godot 4.7.2 / GDScript** projekt az OpenCityMP mellett.
A sima Godot editor elég, nem kell .NET SDK.
A teljes GDD egy fejlesztési irány; ez egy első működésre szánt vertical slice,
nem a teljes, 144 km²-es multiplayer játék.

## Indítás

1. Töltsd le a repót (Code → Download ZIP), majd csomagold ki.
2. A Godot projektkezelőben az **ebben a mappában található project.godot** fájlt importáld.
3. F5, majd **Új túlélő**.
4. A buszmegálló ládájában van víz, étel, hátizsák és térkép.
5. A közeli erdészládában van a balta. A műhely a piros autó mögött van.

Godot: https://godotengine.org/download/windows/

## Megvalósított prototípus-rendszerek

- 1,2 × 1,2 km-es sík tesztterület; 16 falusi ház és műhely/erdészet/rendőrőrs.
- Bejárható házak, CRT-tévé, PB-palack, szekrény, asztal, táblák.
- Templom, panelházak, régi busz, traktor, erdő, nádas tó, farm, ellenőrzőpont.
- Saját procedurális low-poly modellek: Duna S13, szedán, busz, traktor, karakterek.
- Blokkos, mozgó felhőzetet rajzoló sky shader, napszak, nap- és holdfény.
- Kameraütközés, első/harmadik személy, sprint, guggolás, ugrás, zseblámpa.
- 40 fertőzött; látásraycast, hallás, kültéri A* és egyszerű akadálykerülés.
- Éhség, szomjúság, állóképesség, vérzés, fogyasztható étel/víz/kötés, halál.
- Tárgydefiníciók, tömegkorlát, hátizsák, ládából felvétel, tárolóládába lerakás.
- Saját, kódból rajzolt tárgyikonok. Ez még nem teljes térbeli inventory-grid.
- Ököl, balta, P63, M65; raycast találat, tár, újratöltés, lőszerfogyás.
- Vágható fák, kidőlési animáció, cipelhető rönk, munkapadnál fűrészelés.
- 6 craftrecept, munkapadhoz kötött javítókit, generátor és lámpa.
- 10 építhető elem; 0,5 m snap, 45° forgatás, alap támasz-/ütközésellenőrzés.
- Vezethető kisautó és szedán, beszállás/kiszállás, akku, javítás, fogyó benzin.
- Működtethető generátor, 12 m sugarú egyszerű táphálózat, túlterhelés, lámpa/pumpa.
- Benzinkútkészlet fogyása, csak árammal használható pumpák.
- JSON világmentés, automatikus mentés, biztonsági másolat, visszatöltés.
- Kísérleti ENet LAN co-op maximum 8 résztvevővel; lásd alább.

## Grafika

A projekt alapból **Compatibility** renderelővel indul a szélesebb hardvertámogatásért.
Napárnyék és egyedi ég ebben is van.
A részletesebb képhez az editor jobb felső renderelőválasztójában **Forward+**,
majd újraindítás; vagy a START-FORWARD-PLUS.bat használható, ha godot.exe a PATH-ban van.

Menü → Grafika:
Alacsony / Közepes / Magas / Ultra, árnyék, köd, MSAA, felbontásskála,
látótávolság, FOV, egér, teljes képernyő, V-Sync, FPS-limit, hangerő,
napszak és felhőzet. Forward+ Magas: SSAO; Ultra: térfogati köd.
A beállítások user://settings.cfg fájlba mentődnek.

## Irányítás

| Gomb | Művelet |
|---|---|
| WASD, egér | Mozgás / vezetés, körbenézés |
| Shift / Ctrl / Space | Sprint / guggolás / ugrás; autóban fék |
| V / F | Kamera / zseblámpa |
| E | Interakció; járműmenü; kiszállás |
| Bal / jobb egér | Támadás / célzás |
| 1 / 2 / 3 / 4 | Ököl / balta / pisztoly / karabély |
| R | Újratöltés |
| Tab / C / M | Felszerelés / craft / fizikai térkép |
| B / Q / T | Építési mód / elemváltás / 45° forgatás |
| G | Rönk lerakása |
| F5 / Esc | Mentés / menü |

Építéshez menj szabad területre; az úton és a középületek közelében nem lehet építeni.
A falhoz alap, a tetőhöz közeli fal kell. Az első generátort a benzinkútnál
egy kanna benzinnel be lehet indítani. A pumpa E-re 5 literes játékitemet ad.

## LAN co-op — kísérleti

A fogadó gépen: Barátokkal → Új világ fogadása.
A másik gépen: Barátokkal → fogadó gép helyi IP-címe → Csatlakozás.
Azonos verzió, UDP 27808 és a fogadó gépen engedélyezett bejövő forgalom szükséges.

A host kezeli a lootot, craftot, sérülést, járművet, üzemanyagot és építményeket.
A kliens csak a saját mozgását jósolja; a szerver mozgástávolságot és akciótávolságot
ellenőriz. A falon áthaladást ez még nem ellenőrzi teljesen.
**Nem internetes, csalásbiztos vagy 24–32 főre hitelesített szerver.**
Nincs PvP, raid, szerverböngésző, fiók, voice chat vagy hitelesített újracsatlakozási identitás.
A mentés a fogadó gépé. A kétgépes teszt külön, kézi ellenőrzést igényel.

## Ami még hiányzik a GDD-ből

A teljes 12×12 km, cellastreaming, teljes járműflotta vezethetősége, karakterkészítő,
Skeleton3D animációk, komplex járműfizika, utánfutó, moduláris páncél, farming,
betonépítés, foglalási jogok, raid, 24–64 fő, összetett betegségek, nagy hordák,
teljes auditált lootgazdaság, időzített craft és magas minőségű hangkészlet.

A busz és a traktor most díszlet. A hátizsák felszerelése megjelenik a karakteren;
a rajta levő további eszközök jelenleg vizuális kellékek.
A benzinkút 5 L itemje absztrakt kanna, nem külön üreskanna-szimuláció.
A fegyvermodell részletessége és az ég a csatolt kép irányát követi,
de a renderelt vizuális egyezés még külön szemrevételezést igényel.
A korábban feltöltött külső égbolt- és autóarchívum nem része ennek;
minden mostani geometria és shader saját forrásból jön.

## Ellenőrzés

`python3 tools/validate.py /abszolut/ut/Godot`

A GitHub Actions workflow hivatalos 4.7.2 Godottal importál és headless smoke-tesztet futtat.
A headless teszt nem helyettesít grafikai vagy többgépes ellenőrzést.
Az aktuális ellenőrzési eredményt mindig a GitHub Actions futása mutatja.

## Felépítés

scripts/art.gd: mesh kit és statikus összevonás.
scripts/world.gd: determinisztikus világ és kültéri navigáció.
scripts/game.gd: autoritatív műveletek, építés, energia, mentés.
scripts/player.gd, vehicle.gd, zombie.gd: szereplők.
scripts/network.gd: LAN protokoll.
scripts/ui.gd, item_icon.gd, map_ui.gd: kezelőfelület.
scripts/atmosphere.gd, shaders/sky.gdshader: világítás, ég.
scripts/data.gd: adatvezérelt tárgyak, receptek.
