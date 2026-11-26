# Hyperion na TrueNAS

Obraz uruchamia Hyperion 2.2.1 na Debianie Bookworm z pakietu z podpisanego repozytorium APT projektu. Proces działa jako `568:568`, zapisuje konfigurację w `/config` i wysyła logi konsolowe do Dockera. [Instrukcja instalacji Hyperiona na Linuksie](https://docs.hyperion-project.org/user/gettingstarted/Linux.html)

## Budowa i publikacja

Na komputerze z Dockerem i architekturą zgodną z hostem docelowym wykonaj polecenia w katalogu repozytorium. Publikacja wymaga zalogowania się do rejestru z uprawnieniem zapisu do pakietu. [Dokumentacja GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

```sh
docker build -t ghcr.io/pjamroziak/hyperion-docker:2.2.1 .
docker login ghcr.io -u pjamroziak
docker push ghcr.io/pjamroziak/hyperion-docker:2.2.1
```

Jeśli pakiet jest prywatny, TrueNAS potrzebuje uprawnień do jego pobrania. Możesz też zbudować obraz bezpośrednio na docelowym hoście albo przenieść go przez `docker save` i `docker load`. Compose może użyć lokalnego obrazu o tej samej nazwie i tagu.

## Instalacja na TrueNAS

1. Na TrueNAS SCALE 24.10 lub nowszym utwórz dataset na konfigurację. W przykładzie jest to `/mnt/tank/apps/hyperion`. W uprawnieniach datasetu zapewnij UID/GID `568:568` odczyt, zapis i dostęp do katalogu. W przypadku migracji upewnij się, że istniejąca baza także jest zapisywalna.
2. Otwórz **Apps → Discover Apps → ⋮ → Install via YAML**. Nadaj aplikacji nazwę `hyperion` i wklej zawartość `truenas-compose.yaml`. Jeśli Twój dataset ma inną ścieżkę, zmień `source:`. [Instrukcja instalacji własnej aplikacji](https://apps.truenas.com/managing-apps/installing-custom-apps/)
3. Otwórz portal **Web UI** albo przejdź na `http://IP_TRUENAS:8090`. Pole `x-portals` podaje TrueNAS adres portalu. Jeżeli port hosta `8090` jest zajęty, zmień lewą stronę mapowania `8090:8090/tcp` i port portalu. Test HTTP nadal korzysta z portu wewnętrznego `8090`.

## Logi i status

- **TrueNAS → Apps → hyperion → Workloads → Logs** pokazuje start, ostrzeżenia i błędy kontenera. Poziom `Info` jest ustawiony domyślnie. Aby chwilowo włączyć `Debug`, dodaj `command: ["--debug"]` pod usługą `hyperion`, a po diagnostyce usuń ten wpis. [Logi w TrueNAS](https://apps.truenas.com/managing-apps/managing-installed-apps/), [Opcje Hyperiona](https://docs.hyperion-project.org/user/advanced/CLI.html)
- Docker rotuje logi według limitu trzech segmentów po 10 MB na kontener. Odtworzenie kontenera rozpoczyna nową historię logów. Katalog `/config` zachowuje bazę ustawień i pozostałe dane użytkownika. [Sterownik logów `local`](https://docs.docker.com/engine/logging/drivers/local/)
- Kontrola stanu odpytuje panel WWW wewnątrz kontenera. Po uruchomieniu sprawdź urządzenia i wejścia obrazu w **Hyperion → System → Log**. [Diagnostyka Hyperiona](https://docs.hyperion-project.org/user/advanced/Support.html)

## Urządzenia i sieć

- **WLED po IP** działa w konfiguracji `bridge`, jeśli NAS ma dostęp do sterownika. Wprowadź adres WLED w panelu Hyperiona. Jeśli zależy Ci na wykrywaniu przez mDNS, możesz wypróbować `network_mode: host`, usuwając `ports:`. Sprawdź wtedy dostępność portów Hyperiona bezpośrednio na NAS-ie. [Konfiguracja WLED](https://docs.hyperion-project.org/user/leddevices/network/wled.html), [Sieć hosta w Dockerze](https://docs.docker.com/engine/network/drivers/host/)
- **Grabber USB lub sterownik szeregowy** wymaga przekazania właściwego urządzenia w `devices:`, np. `/dev/video0:/dev/video0` albo `/dev/ttyUSB0:/dev/ttyUSB0`. Dopisz w `group_add:` numeryczny GID grupy urządzenia z NAS-a. Jeżeli grabber ma stabilną ścieżkę w `/dev/v4l/by-id/`, użyj jej po stronie hosta.
- **Zewnętrzne źródło obrazu lub klient API** może potrzebować dodatkowego portu. Dodaj mapowanie dla protokołu podanego przez klienta. Panel WWW i WebSocket współdzielą port `8090`, surowe API JSON domyślnie używa `19444/tcp`. [Protokoły i porty Hyperiona](https://api.hyperion-project.org/connect-to-hyperion-1027155m0)
