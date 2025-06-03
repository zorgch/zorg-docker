# zorg Cron jobs
Mittels diversen Server-seitigen Cron jobs werden regelmässig notwendige Tasks ausgeführt.

Zum Beispiel: Daily Pic setzen, Daily Quote setzen, Gravater Userimages cachen, Stockbroker Aktienkurse aktualiseren, usw.

### Cron jobs speichern
Über das `crontab` werden die verschiedenen Cron jobs anhand deren Wiederholungsrate festgelegt:

> [!TIP]
> Die folgende Job Konfiguration führt ein PHP script innerhalb des `zorg-website` Docker Containers aus.
> Daher ist auch der `wwwroot`-Parameter "aus Sicht innerhalb des Containers" zu definieren.
> ABER: das Logfile ` >> ` aus Sicht Host OS ("lokal")

```
$ su <user>
$ crontab -e
    3 7 * * * docker exec -u www-data zorg-website /usr/local/bin/php -f /var/www/cron/tag.php "wwwroot=/var/www/html/public/" >> /var/logs/cron.log 2>&1
```

> [!NOTE]
> Zum Vergleich: im folgenden ein corontab Job der DIREKT innerhalb eines Docker Containers mit php & cron Kapazitäten ausführt.
> Auch das Logging ist hier anders: es wird an das Docker Log des Containers geschickt.

```
$ su <user>
$ docker exec -it zorg-website /bin/bash

    crontab -e
        3 7 * * * /usr/local/bin/php -f /var/www/cron/tag.php wwwroot=/var/www/html/public/ >> /proc/1/fd/1 2>&1
```

## Minutely
- `stockbroker_minute`: Stockbroker Aktienkurse aktualisieren

## Hourly
- `stunde`: Upcoming Events check, Gravatar Cache aktualisieren
- `stockbroker_stunde`: Stockbroker Tradings aktualisieren

## Daily
- `tag`: Daily Pic & Quote setzen, APOD holen, Spaceweather & BOINC Stats update, alte kompilierte Comment Templates freigeben, Addle Games älter als 15 Wochen löschen, nächsten Hunting z Zug weitergeben

## Weekly
- `woche`: Entfernen von unread Comments älter als 30 Tage
