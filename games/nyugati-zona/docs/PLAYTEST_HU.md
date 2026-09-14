# Első túlélési kör

Ez a forrás egy tesztelhető vertical slice. A teljes GDD további fejlesztési irány.

1. **Importálás:** games/nyugati-zona/project.godot, Godot 4.7.2, F5.
2. **Kezdés:** Új túlélő. A jobb oldali buszmegállónál E a ládán.
   A hátizsák növeli a teherbírást 14-ről 35 kg-ra.
3. **Eszközök:** az erdészládából balta, deszka és szög. 2-vel felszereled a baltát.
4. **Túlélés:** Tab, kattintás a vízen / ételen / kötésen.
5. **Műhely:** a piros kisautótól keletre van a garázs; hátulról megközelíthető
   az ajtónyílás. Munkapad és alkatrészes ládák várnak.
6. **Autó:** E a Duna S13-on → akku beszerelése → tankolás → beszállás.
   WASD, Space fék, álló járműnél E kiszállás.
7. **Benzinkút:** a falutól északra, a főút jobb oldalán. A generátorhoz egy 5 L
   benzinitem kell. E elindítja; utána a pumpa is használható.
8. **Építés:** szabad területen B; Q elemet vált, T 45°-kal forgat.
   Először alap, aztán rá/tőle 1,5 méteren belül fal. Piros = nem építhető.
9. **Fa:** nézz közelről egy vágható fa törzsére, balta + bal egér.
   Négy találat után kidől. E a rönkön, majd E a munkapadnál: 4 deszka.
10. **Fegyver:** a rendőrőrs ládájában pisztoly és lőszer. 3 → R → célzás/lövés.
11. **Mentés:** F5. A Folytatás visszaállítja a világállapotot és a készleteket.
12. **Co-op:** egyik példány Fogadás; másik a fogadó helyi IP-címére csatlakozik.
    Az automatizált teszt két külön Godot-folyamattal, loopback kapcsolaton ellenőrzi ezt.

## Kézi ellenőrzést igényel

- Saját PC-n FPS és videokártya-kompatibilitás.
- Forward+ profilok látványa és teljesítménye.
- Két külön számítógép közötti hálózat és hosszabb co-op játék.
- AI-követés minden szűk helyen; az alap A* kültéri útvonalakra készült.
- Különböző ablakarányok, billentyűzetkiosztások, hosszan futó szerverek.
- A képhez viszonyított végleges művészeti kidolgozás és későbbi csereassetek.

## Automatizált ellenőrzés

A GitHub Actions workflow:
- importálja a projektet;
- valódi műveletekkel ellenőrzi az alapanyag-, lőszer- és üzemanyag-fogyást;
- ellenőrzi a craftot, kötést, autóakkumulátort, támogatott építést;
- ellenőrzi a generátor → pumpa és fa → rönk → deszka láncot;
- JSON- és lemezes mentés/visszatöltés próbát végez;
- két Godot-folyamattal közös lootátvételt ellenőriz;
- Xvfb és szoftveres OpenGL alatt rendereli a játékot és a menüket.

Az ebből származó FPS **nem játékos PC-s teljesítménymérés**.
A képek tényleges Godot-képkockák, nem promóillusztrációk.
