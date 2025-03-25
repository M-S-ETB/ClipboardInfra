# Clipboard API & Client aufsetzen


## Wichtig: alle aktionen mit containern auf dem server sollten auf dem Selben Benutzer ausgeführt werden, da podman container rootless sind (auf dem Benutzer account laufen, nicht root)
## Deshalb nach login auf dem Server einmal `cd /opt/clipboard`, dann `sudo su podman` um zu dem `podman` user zu wechseln.


## Umgebung aufsetzen

### 2024-09-27: Dies ist auf dem Aktuellen server bereits erledigt, nur für neue Server zu beachten

1. Diesen Ordner irgendwo auf dem Deployment server positionieren (z.B. `/opt/clipboard/`). Die Leeren Ordner sind für die Statistik Container relevant.
2. Alle images in docker/podman importieren:
   - `podman load -i <image-file-name>.tar`
3. Nun die `docker-compose.yaml` datei anpassen für die echte Umgebung, in der das Clipboard laufen soll.<br>
   Dazu die Konfiguration anpassen, um alle relevanten Dienste zu erreichen:
   - REDIS_HOSTNAME: Redis Hostname
   - RABBITMQ_HOSTNAME: RabbitMQ Hostname
   - DB_HOSTNAME: Datenbank Hostname (z.B. `192.168.0.212` oder `oracle.b7.intern.etb`, etc.)
   - DB_PASSWORD: Datenbank User Passwort
   - DB_USERNAME: Datenbank User Name
   - DB_NAME: Datenbank Name (z.B. xe oder bu)
   - wenn ein service auf dem host läuft; `host.docker.internal`, ansonsten den namen des service (z.B. `clipboard-message-queue`)
4. Zum Starten `clipboard-manager.sh` ausführen. Dann "Startup All" auswählen.

## Container Image bauen

schritte ein mal für API und ein mal für Client ausführen

1. Versionsnummer ändern. (optional)
   - package.json "Version" feld erhöhen
2. In einem Terminal oder IDE den node target `npm run build:container-image-release` ausführen
3. Das Container-Image ist automatisch nach `<SVN Root>/trunk/09_Deployment/clipboard_server_data/container_images/` exportiert.

## Client oder API Version ändern (Update, Downgrade)
1. Via z.B. WinSCP (SFTP, port 22) das neue container image auf den server schieben (in `/opt/clipboard/container_images/`) 
2. `clipboard-manager.sh` ausführen.
3. darin über "Select API version" und "Select Client version" das neue container image auswählen
   Das skript kümmert sich dann darum das image zu importieren, die version in docker-compose.yaml zu ändern und alles zu starten.
