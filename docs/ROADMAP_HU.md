# OpenCityMP fejlesztési ütemterv

## V0.1 – Offline vertical slice

- procedurális low-poly város;
- third-person karakter és kamera;
- HUD és alap hangulatvilágítás;
- networking és resource loader alapok.

## V0.2 – Első multiplayer

- külön headless dedicated-server indítás;
- név és közvetlen IP-s csatlakozás;
- szerverautoritatív player spawn;
- input/state snapshot;
- interpoláció és relevanciaalapú entitásküldés;
- globális és helyi chat;
- első vezethető jármű és vehicle sync;
- 10–20 játékosos helyi terhelési teszt.

## V0.3 – Modding SDK

- beágyazott Lua runtime, külön szerver- és klienskörnyezet;
- resource start, stop, restart és függőségek;
- jogosultságokkal védett API;
- event és timer rendszer;
- createVehicle, createObject, createMarker és createBlip;
- element data szerveroldali ellenőrzéssel;
- resource-onkénti fájl- és hálózati korlátozás.

## V0.4 – Platform

- szerverböngésző;
- resource fájlok hash-ellenőrzött letöltése;
- modellek, textúrák és hangok importja;
- map editor;
- ACL/admin rendszer;
- updater és crash report.

## Technikai elvek

1. A szerver a játékmenet hiteles forrása.
2. A kliens csak szükséges, közeli entitásokat kap.
3. A community Lua kód sandboxban fut.
4. A core C#, a modding API stabil és verziózott.
5. A projekt kizárólag saját vagy megfelelően licencelt asseteket terjeszt.
