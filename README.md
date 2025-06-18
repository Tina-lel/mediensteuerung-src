# mediensteuerung-src
Quellcode unserer Höchstprofessionellen Mediensteuerung. Vorgesehen für das CompanionPi betriebsystem.

### Notiz:
**Der Quellcode wird nur benötigt, um eine eigene Version des Mediensteuerungs-System zu erstellen. Falls sie lediglich nur ein fertiges Abbild benötigen, so können sie sich dieses hier in dem "Releases"-Tab des GitHub repositories herunterladen.**

# Vorbereitung

Verwendete Programme (Dependencies):
- bash
- python
- socat
- bluez
    - dbus
    - python-dbus

# Installation

Zunächst wird dieses Github Repository ge-cloned:

```
$ git clone https://github.com/Tina-lel/mediensteuerung-src/
$ cd mediensteuerung-src
```

Nun muss das Backend im System installiert werden. Hierfür muss der "BACKEND" Ordner in den /usr Ordner, sowie die SystemD service Datei in den /etc/systemd/system ordner, kopiert werden (hierfür werden root Berechtigungen benötigt):

```
# cp -r BACKEND /usr/
# cp backend.service /etc/systemd/system/
```

Das Backend ist nun installiert, und kann durch den SystemD Service aktiviert werden:

```
# systemctl enable --now backend
```

### Bluetooth

Um einen eigenen Namen für das Bluetooth Gerät zu setzen, muss dieser in /etc/machine-info festgesetzt werden (hierfür werden root Berechtigungen benötigt):

```
# nano /etc/machine-info
```

Diese Datei muss wie folgt geschrieben werden:

PRETTY_HOSTNAME=meinKlassenZimmer
