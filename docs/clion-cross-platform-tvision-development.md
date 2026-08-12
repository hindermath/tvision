# Plattformuebergreifende tvision-Entwicklung mit CLion, CMake, VS Code und Visual Studio / Cross-Platform tvision Development with CLion, CMake, VS Code, and Visual Studio

## Deutsch

### 1. Zweck und Zielgruppe

Diese Anleitung beschreibt maximal ausfuehrlich, wie der persoenliche Fork
[`hindermath/tvision`](https://github.com/hindermath/tvision) in eigenen
CMake-Programmen verwendet wird. Sie deckt JetBrains CLion, die reine
CMake-Kommandozeile und Visual Studio Code als leichtere Editorvariante unter
macOS, Windows und Linux ab. Fuer Windows wird zusaetzlich Microsoft Visual
Studio Community 2022 und 2026 als native Voll-IDE behandelt.

Die Anleitung geht von folgendem Arbeitsmodell aus:

- Der persoenliche `tvision`-Fork wird als stabile Abhaengigkeit verwendet und
  nicht funktional weiterentwickelt.
- Aenderungen am Fork entstehen nur durch bewusst uebernommene Neuerungen aus
  [`magiblot/tvision`](https://github.com/magiblot/tvision).
- macOS ist normalerweise das Develop-First-System.
- Windows und Linux bauen und pruefen denselben Stand anschliessend nativ.
- CLion ist auf allen drei Betriebssystemen die Standard-IDE.
- CMake auf der Kommandozeile ist der IDE-unabhaengige Referenzweg.
- VS Code ist die leichtere grafische Alternative fuer Systeme mit wenig RAM
  oder knappem Massenspeicher.
- Microsoft Visual Studio Community ist die optionale native Windows-Voll-IDE;
  sie ersetzt weder den gemeinsamen CMake-Vertrag noch die
  plattformuebergreifende Standardrolle von CLion.
- Das MacBook Air 2023 mit 8 GB RAM ist das konkrete Low-Resource-Beispiel;
  die Angabe 8 MB waere fuer diese Toolchain technisch nicht realistisch.
- Jedes Anwendungsprojekt bindet einen vollstaendigen, getesteten Commit des
  persoenlichen Forks ein.

Der sichere erste Schritt ist, den aktuell gewuenschten Commit des Forks zu
ermitteln und ihn in der `CMakeLists.txt` des eigenen Programms festzuschreiben.

### 2. Grundentscheidung: Quellstand verteilen, nicht Binaerdateien kopieren

`tvision` erzeugt eine statische Bibliothek. Trotzdem ist eine fertig
kompilierte Bibliothek nicht zwischen Betriebssystemen, Prozessorarchitekturen
oder beliebigen Compilern austauschbar.

| Ziel und Toolchain | Typisches Ergebnis |
|---|---|
| macOS mit AppleClang | `libtvision.a` mit Mach-O-Objekten |
| Linux mit GCC oder Clang | `libtvision.a` mit ELF-Objekten |
| Windows mit MSVC | `tvision.lib` mit COFF-Objekten |
| Windows mit MinGW | `libtvision.a` mit MinGW-kompatiblen Objekten |

Die Dateiendung `.a` allein bedeutet daher nicht, dass dieselbe Datei auf
macOS und Linux verwendet werden kann. Auch Debug/Release-Konfiguration,
Architektur, Compiler-ABI und Laufzeitbibliothek muessen zusammenpassen.

Fuer dieses persoenliche Szenario gilt deshalb:

```text
hindermath/tvision mit festem Commit
                |
                +--> CLion/macOS  --> native libtvision.a --> macOS-Programm
                |
                +--> CLion/Linux  --> native libtvision.a --> Linux-Programm
                |
                +--> CLion/Windows --> native .lib/.a     --> Windows-Programm
```

Der Quellstand ist gemeinsam und reproduzierbar. Das jeweilige Build-Ergebnis
bleibt lokal und plattformspezifisch.

### 3. Empfohlener Standard: CMake FetchContent

`FetchContent` ist fuer dieses Arbeitsmodell der empfohlene Standard:

- Das Anwendungsprojekt dokumentiert den exakten `tvision`-Stand.
- CLion und CMake bauen `tvision` automatisch mit der aktiven Toolchain.
- Es ist keine globale Installation erforderlich.
- Es muss kein plattformspezifisches Bibliotheksarchiv eingecheckt werden.
- Ein Update und ein Rollback bestehen im Wesentlichen aus dem Austausch einer
  Commit-ID.

#### 3.1 Beispielstruktur des eigenen Programms

```text
mein-programm/
|-- CMakeLists.txt
|-- src/
|   `-- main.cpp
`-- .gitignore
```

Die Buildverzeichnisse von CLion, zum Beispiel `cmake-build-debug/`,
`cmake-build-release/` oder ein projektspezifisches `build/`, gehoeren nicht in
Git.

#### 3.2 Vollstaendige CMake-Einbindung

```cmake
cmake_minimum_required(VERSION 3.15)

project(MeinProgramm LANGUAGES CXX)

include(FetchContent)

# Das Anwendungsprojekt benoetigt nur die Bibliothek.
set(TV_BUILD_EXAMPLES OFF CACHE BOOL "Build tvision examples" FORCE)
set(TV_BUILD_TESTS OFF CACHE BOOL "Build tvision tests" FORCE)

# Linux: Die optionale GPM-Abhaengigkeit wird fuer einen einheitlicheren
# Drei-Plattform-Workflow deaktiviert. ncursesw bleibt erforderlich.
set(TV_BUILD_USING_GPM OFF CACHE BOOL "Use GPM on Linux" FORCE)

FetchContent_Declare(
    tvision
    GIT_REPOSITORY https://github.com/hindermath/tvision.git
    GIT_TAG        0123456789abcdef0123456789abcdef01234567
    GIT_PROGRESS   TRUE
)

FetchContent_MakeAvailable(tvision)

add_executable(mein_programm
    src/main.cpp
)

# Das eigene Programm darf einen hoeheren C++-Standard als die Abhaengigkeit
# verwenden. Dieses Beispiel verwendet C++17.
target_compile_features(mein_programm PRIVATE cxx_std_17)

target_link_libraries(mein_programm PRIVATE tvision::tvision)
```

Die Beispiel-SHA muss durch einen realen, vollstaendigen Commit des Forks
ersetzt werden. Eine unveraenderliche Commit-ID ist einem beweglichen Branch
wie `master` vorzuziehen. Damit bleibt ein spaeterer Build reproduzierbar,
auch nachdem der Fork mit Upstream synchronisiert wurde.

Den aktuellen Commit des Remote-Branches zeigt beispielsweise dieser Befehl:

```bash
git ls-remote https://github.com/hindermath/tvision.git refs/heads/master
```

Der Befehl funktioniert in einem macOS-/Linux-Terminal und in PowerShell,
sofern Git installiert und im Suchpfad verfuegbar ist.

#### 3.3 Verwendung im Quellcode

Eine minimale Quelldatei kann so beginnen:

```cpp
#include <tvision/tv.h>

int main()
{
    return 0;
}
```

Die Include-Verzeichnisse und transitiven Linkinformationen kommen ueber das
CMake-Ziel `tvision::tvision`. Absolute Include-Pfade oder ein manuelles
`target_link_directories()` sind nicht erforderlich.

### 4. Was CLion beim ersten Laden macht

Wenn CLion die `CMakeLists.txt` laedt, geschieht konzeptionell Folgendes:

```text
CLion waehlt CMake-Profil und Toolchain
                  |
                  v
CMake konfiguriert das Anwendungsprojekt
                  |
                  v
FetchContent holt den festgelegten tvision-Commit
                  |
                  v
CMake fuegt das Ziel tvision::tvision zum Build hinzu
                  |
                  v
CLion baut zuerst die statische Bibliothek und danach das Programm
```

Im Buildverzeichnis entsteht typischerweise eine Struktur wie diese:

```text
cmake-build-debug/
|-- _deps/
|   |-- tvision-src/
|   `-- tvision-build/
|-- CMakeCache.txt
`-- ...
```

Der erste saubere Configure-Lauf benoetigt Netzwerkzugriff auf GitHub. Danach
bleibt der abgerufene Quellstand im jeweiligen Buildverzeichnis verfuegbar.
Ein geloeschtes Buildverzeichnis oder ein anderer Rechner benoetigt den Abruf
erneut.

Beim Bauen des Programmziels erkennt CMake die Zielabhaengigkeit und baut
`tvision` automatisch zuerst. Das Bibliotheksziel muss in CLion normalerweise
nicht separat gebaut werden.

### 5. Gemeinsame CLion-Grundkonfiguration

CLion trennt Toolchains und CMake-Profile:

- Die Toolchain bestimmt Compiler, Buildwerkzeug und Debugger.
- Das CMake-Profil bestimmt unter anderem Toolchain, Buildtyp,
  Buildverzeichnis und CMake-Optionen.

Die Einstellungen sind ueber
`Settings | Build, Execution, Deployment | Toolchains` beziehungsweise
`Settings | Build, Execution, Deployment | CMake` erreichbar. Auf macOS kann
der Einstellungsdialog ueber das CLion-Anwendungsmenue geoeffnet werden. Die
Aktionen lassen sich unabhaengig vom Betriebssystem auch ueber `Find Action`
finden.

Fuer jedes Betriebssystem werden mindestens zwei lokale Profile empfohlen:

| Profil | Build type | Zweck |
|---|---|---|
| Debug | `Debug` | taegliche Entwicklung und Debugging |
| Release | `Release` | optimierter Kontroll- und Auslieferungsbuild |

Jedes Profil verwendet ein eigenes Buildverzeichnis. Debug- und
Release-Artefakte oder Ergebnisse verschiedener Compiler duerfen nicht in
dasselbe Buildverzeichnis geschrieben werden.

Nach einer Aenderung der `CMakeLists.txt` oder des festgelegten
`tvision`-Commits wird das CMake-Projekt neu geladen. Falls der alte Stand trotz
korrekter Commit-ID im Cache verbleibt, ist
`Tools | CMake | Reset Cache and Reload Project` die gezielte naechste Aktion.
Das gesamte Projekt oder fremde Dateien muessen dafuer nicht geloescht werden.

Aktuelle Referenzen:

- [JetBrains: CMake profiles](https://www.jetbrains.com/help/clion/cmake-profile.html)
- [JetBrains: Toolchains](https://www.jetbrains.com/help/clion/how-to-create-toolchain-in-clion.html)
- [JetBrains: Load/reload CMake](https://www.jetbrains.com/help/clion/reloading-project.html)
- [CMake: FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html)
- [CMake: Presets](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html)
- [VS Code: CMake Tools](https://github.com/microsoft/vscode-cmake-tools/blob/main/docs/README.md)
- [VS Code: C/C++ on macOS](https://code.visualstudio.com/docs/cpp/config-clang-mac)
- [VS Code: C/C++ on Linux](https://code.visualstudio.com/docs/cpp/config-linux)
- [VS Code: Command-line interface](https://code.visualstudio.com/docs/configure/command-line)
- [VS Code C/C++: IntelliSense cache](https://code.visualstudio.com/docs/cpp/faq-cpp)
- [Microsoft: C++ Build Tools command line](https://learn.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-170)

### 6. macOS als Develop-First-System

macOS ist der normale Ausgangspunkt fuer neue Funktionen in den eigenen
Programmen. Das bedeutet nicht, dass macOS-Binaerdateien an Windows oder Linux
weitergegeben werden. Weitergegeben werden ausschliesslich die Git-Commits des
Anwendungsprojekts und die darin fixierte `tvision`-Commit-ID.

#### 6.1 Toolchain

Empfohlene lokale Zusammenstellung:

- AppleClang aus Xcode oder den Xcode Command Line Tools
- das von CLion erkannte oder gebuendelte CMake
- Ninja als Buildwerkzeug, sofern in der Toolchain ausgewaehlt
- LLDB als Debugger

CLion prueft die ausgewaehlte Toolchain und zeigt fehlende Werkzeuge in der
Toolchain-Konfiguration an.

#### 6.2 Taeglicher Ablauf

1. Das eigene Anwendungsrepository in CLion oeffnen.
2. Das Profil `Debug` waehlen.
3. Den CMake-Configure-Lauf einschliesslich FetchContent erfolgreich
   abschliessen lassen.
4. Das Anwendungsziel bauen, starten und debuggen.
5. Relevante Anwendungstests unter macOS ausfuehren.
6. Nur Quell-, CMake- und notwendige Dokumentationsdateien committen; keine
   Buildverzeichnisse oder statischen Bibliotheken.
7. Denselben Anwendungscommit anschliessend unter Windows und Linux pruefen.

#### 6.3 Release-Kontrolle auf macOS

Vor der plattformuebergreifenden Kontrolle wird zusaetzlich das CLion-Profil
`Release` gebaut. Dadurch werden Fehler sichtbar, die nur bei Optimierung oder
abweichenden Debug-Makros auftreten.

### 7. Linux als natives Kontrollsystem

#### 7.1 Toolchain

Eine typische lokale CLion-Toolchain verwendet:

- GCC oder Clang
- Ninja oder Make
- GDB oder LLDB
- CMake

Die verwendete Compilerfamilie darf pro Rechner bewusst gewaehlt werden. Ein
bereits unter macOS erzeugtes Archiv wird nicht wiederverwendet.

#### 7.2 Systemabhaengigkeit

Unter Linux benoetigt `tvision` die Wide-Character-Variante von ncurses und
deren Entwicklungsheader. Der konkrete Paketname ist distributionsabhaengig.
Fehlt die Abhaengigkeit, meldet der CMake-Configure-Lauf, dass `ncursesw` oder
die zugehoerigen Header nicht gefunden wurden.

Die Anleitung deaktiviert `TV_BUILD_USING_GPM`, weil GPM fuer dieses
einheitliche persoenliche Entwicklungsmodell optional ist. Soll GPM bewusst
verwendet werden, muss die Option nur fuer das Linux-Profil aktiviert und die
passende Entwicklungsbibliothek installiert werden.

#### 7.3 Kontrolle

1. Exakt denselben Anwendungscommit wie unter macOS auschecken.
2. Das Linux-Profil `Debug` konfigurieren und bauen.
3. Anwendung und relevante Tests in einem echten Linux-Terminal ausfuehren.
4. Anschliessend das Profil `Release` bauen.
5. Plattformabweichungen im Anwendungsrepository korrigieren; keine
   macOS-Bibliothek kopieren oder umbenennen.

### 8. Windows als natives Kontrollsystem

#### 8.1 Toolchain bewusst festlegen

CLion kann unter Windows unter anderem MSVC- und MinGW-Toolchains verwenden.
Fuer ein Projekt wird eine Variante bewusst ausgewaehlt und beibehalten:

- MSVC erzeugt typischerweise `tvision.lib`.
- MinGW erzeugt typischerweise `libtvision.a`.
- Artefakte beider Toolchains sind nicht miteinander austauschbar.

Bei einem Wechsel zwischen MSVC und MinGW wird ein neues CMake-Profil mit
eigenem Buildverzeichnis verwendet. Ein vorhandener CMake-Cache darf nicht mit
der anderen Toolchain weiterverwendet werden.

`TV_USE_STATIC_RTL` bleibt standardmaessig `OFF`. Diese Option betrifft bei
MSVC die C/C++-Laufzeitbibliothek und nicht die Frage, ob `tvision` selbst eine
statische Bibliothek ist. Sie wird nur aktiviert, wenn das gesamte
Anwendungsprojekt und alle betroffenen Abhaengigkeiten konsistent fuer die
statische MSVC-Laufzeit konfiguriert sind.

#### 8.2 Kontrolle

1. Exakt denselben Anwendungscommit wie unter macOS auschecken.
2. In CLion die festgelegte Windows-Toolchain waehlen.
3. Das Profil `Debug` konfigurieren, bauen, starten und debuggen.
4. Das Programm in einer realen Windows-Terminalumgebung pruefen.
5. Anschliessend das Profil `Release` bauen und ausfuehren.

Nach dem Linken muss keine separate `tvision.dll` neben dem Programm liegen.
Abhaengigkeiten des Betriebssystems oder der gewaehlten Compiler-Laufzeit
koennen davon unabhaengig weiterhin dynamisch sein.

### 9. Plattformuebergreifender Develop-First-Zyklus

Der empfohlene Gesamtzyklus lautet:

```text
1. macOS / CLion / Debug
   Implementieren, bauen, starten, debuggen und testen
                       |
                       v
2. macOS / CLion / Release
   Optimierten Build kontrollieren
                       |
                       v
3. Anwendungscommit erstellen
   Keine Buildartefakte aufnehmen
                       |
             +---------+---------+
             |                   |
             v                   v
4. Windows / CLion         5. Linux / CLion
   Debug + Release            Debug + Release
             |                   |
             +---------+---------+
                       v
6. Gemeinsamen Stand erst nach nativen Kontrollen als tragfaehig behandeln
```

Die drei Builds verwenden dieselbe Anwendungsquelle und dieselbe fixierte
`tvision`-Commit-ID, aber drei unabhaengige native Bibliotheksartefakte.

### 10. Upstream-Aktualisierungen des persoenlichen Forks

Der Fork wird nicht fortlaufend aus den Anwendungsprojekten heraus aktualisiert.
Eine Upstream-Uebernahme ist ein eigener, bewusster Wartungsvorgang.

#### 10.1 Sicherer Aktualisierungsablauf

1. Den bisherigen `tvision`-Commit in den Anwendungsprojekten unveraendert
   lassen.
2. Den persoenlichen Fork mit dem gewuenschten Stand von `magiblot/tvision`
   synchronisieren.
3. Den neuen Fork-Stand separat unter den vorgesehenen Betriebssystemen bauen
   und pruefen.
4. Den vollstaendigen neuen Commit des Forks ermitteln.
5. Zunaechst in einem Anwendungsprojekt auf macOS nur `GIT_TAG` aktualisieren.
6. CLion das CMake-Projekt neu laden lassen und Debug sowie Release pruefen.
7. Denselben Anwendungscommit unter Windows und Linux pruefen.
8. Erst danach weitere eigene Programme auf die neue Commit-ID umstellen.

#### 10.2 Rollback

Falls eine Upstream-Neuerung ein eigenes Programm beeintraechtigt, wird
`GIT_TAG` auf die zuvor bekannte Commit-ID zurueckgesetzt. Nach dem Zuruecksetzen
wird CMake neu geladen. Der alte Stand bleibt dadurch nachvollziehbar; es muss
kein altes Binaerarchiv gesucht werden.

#### 10.3 Warum nicht `master` verwenden?

Ein Branchname bezeichnet einen beweglichen Stand. Ein heute erfolgreicher
Build koennte nach der naechsten Fork-Synchronisierung ohne Aenderung am
Anwendungsrepository andere Quellen verwenden. Eine vollstaendige Commit-ID
bindet dagegen exakt den geprueften Inhalt.

### 11. Laufzeit und Weitergabe eigener Programme

Beim statischen Linken werden die benoetigten `tvision`-Objekte in das eigene
Programm aufgenommen. Fuer Entwicklung, erneutes Bauen und Debuggen bleiben
die Header und die lokal gebaute Bibliothek im CLion-Buildverzeichnis
notwendig. Fuer das reine Starten der fertigen Anwendung wird keine separate
`tvision`-Bibliotheksdatei mitgeliefert.

Dies macht das Programm nicht betriebssystemunabhaengig. Fuer jede Zielplattform
wird weiterhin ein eigenes Programm gebaut:

```text
mein-programm-macos
mein-programm-linux
mein-programm-windows.exe
```

Systembibliotheken, Compiler-Laufzeiten und weitere Abhaengigkeiten muessen bei
einer spaeteren Programmdistribution separat bewertet werden.

### 12. Optionale Alternative: einmalige Installation pro Rechner

Wenn sehr viele eigene Programme denselben `tvision`-Stand verwenden und die
erneute Kompilierung pro Buildverzeichnis stoert, kann der Fork auf jedem
Rechner einmal mit CMake installiert werden. Die Installation bleibt trotzdem
pro Betriebssystem, Architektur, Compiler und Konfiguration getrennt.

Das Anwendungsprojekt verwendet dann:

```cmake
find_package(tvision CONFIG REQUIRED)
target_link_libraries(mein_programm PRIVATE tvision::tvision)
```

Der lokale Installationspfad wird im jeweiligen CLion-CMake-Profil ueber
`CMAKE_PREFIX_PATH` bekannt gemacht. Diese Variante spart Builds, hat aber
mehr manuellen Wartungsaufwand:

- Jeder Rechner braucht eine passende lokale Installation.
- Nach einer Fork-Synchronisierung muss neu gebaut und installiert werden.
- Debug-, Release- und Toolchainvarianten muessen konsistent gehalten werden.
- Das Anwendungsrepository allein dokumentiert ohne Zusatzregel nicht sicher,
  welche lokale Installation verwendet wurde.

Fuer reproduzierbare persoenliche Projekte bleibt deshalb `FetchContent` mit
fester Commit-ID der Standard dieser Anleitung.

### 13. Warum vcpkg hier nicht der Standard ist

Der oeffentliche vcpkg-Port `tvision` verweist nicht automatisch auf den
persoenlichen Fork. Fuer dessen exakten Stand waere ein eigener Overlay-Port
oder eine eigene Registry erforderlich.

Das kann bei einer groesseren C++-Abhaengigkeitslandschaft und gewuenschtem
Binaercache sinnvoll sein. Fuer den hier beschriebenen Umfang erzeugt es jedoch
zusaetzliche Versions- und Wartungsflaechen, ohne den grundlegenden
Drei-Plattform-Build zu vermeiden. Auch vcpkg wuerde plattformspezifische
Artefakte pro Ziel-Triplet bauen.

### 14. Fehlerbehebung

#### 14.1 FetchContent kann den Fork nicht laden

Pruefpunkte:

1. Netzwerkzugriff auf `https://github.com/hindermath/tvision.git`.
2. Vollstaendige und existierende Commit-ID in `GIT_TAG`.
3. Git ist in der aktiven CLion-Toolchain beziehungsweise Umgebung erreichbar.
4. Die CMake-Ausgabe im CLion-CMake-Werkzeugfenster enthaelt den eigentlichen
   Git- oder TLS-Fehler.

#### 14.2 Nach einer Commit-Aenderung wird noch der alte Stand verwendet

Zuerst das CMake-Projekt neu laden. Bleibt der Cache widerspruechlich, in CLion
`Reset Cache and Reload Project` verwenden. Ein Buildverzeichnis darf als
letzte lokale Massnahme neu erzeugt werden; Quellrepository und Git-Historie
bleiben unberuehrt.

#### 14.3 Linux findet ncursesw nicht

Die ncursesw-Entwicklungsbibliothek und ihre Header ueber den Paketmanager der
verwendeten Distribution installieren. Der konkrete Paketname wird nicht in
der projektweiten `CMakeLists.txt` festgeschrieben, weil er von Distribution
und Version abhaengt.

#### 14.4 Windows meldet inkompatible Objekt- oder Bibliotheksformate

Pruefen, ob CMake-Profil und Buildverzeichnis zuvor mit einer anderen
Toolchain, insbesondere MSVC statt MinGW oder umgekehrt, verwendet wurden. Ein
neues Profil mit eigenem Buildverzeichnis anlegen und neu konfigurieren.

#### 14.5 Debug funktioniert, Release nicht

Die vollstaendige Linker-Ausgabe des Release-Profils pruefen. Debug- und
Release-Bibliotheken nicht manuell mischen. Da `FetchContent` in jedem Profil
mitbaut, sollte kein Bibliothekspfad aus einem anderen CLion-Profil eingetragen
werden.

### 15. Kurzcheckliste

- [ ] Der Fork wird nur aus dem kontrollierten Upstream aktualisiert.
- [ ] `GIT_TAG` enthaelt eine vollstaendige Commit-ID, nicht `master`.
- [ ] `TV_BUILD_EXAMPLES` und `TV_BUILD_TESTS` sind fuer die Anwendung aus.
- [ ] `TV_BUILD_USING_GPM` ist fuer den einheitlichen Standard aus.
- [ ] CLion verwendet getrennte Debug- und Release-Profile.
- [ ] Jede Toolchain besitzt ein eigenes Buildverzeichnis.
- [ ] macOS ist Develop-First, aber nicht alleiniger Plattformnachweis.
- [ ] Derselbe Anwendungscommit wird nativ unter Windows und Linux gebaut.
- [ ] Keine `.a`, `.lib`, `_deps`- oder CLion-Buildverzeichnisse werden
      eingecheckt.
- [ ] Nach einer Upstream-Uebernahme wird die neue Commit-ID erst nach den
      Plattformkontrollen in weitere Programme uebernommen.

### 16. Vollstaendiges TUI-Starterprojekt

Die bisherigen Abschnitte erklaeren die Abhaengigkeit. Dieser Abschnitt zeigt
ein vollstaendiges kleines Anwendungsrepository, das tatsaechlich einen Dialog
im Terminal oeffnet. Alle folgenden CLion-, Kommandozeilen- und
VS-Code-Ablaufe verwenden dieselbe Struktur.

#### 16.1 Verzeichnisstruktur

```text
mein-tvision-programm/
|-- .gitignore
|-- CMakeLists.txt
|-- CMakePresets.json        optional, aber empfohlen
|-- .vscode/                 optionale VS-Code-Konfiguration
|   |-- extensions.json
|   `-- settings.json
`-- src/
    `-- main.cpp
```

#### 16.2 CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.15)

project(MeinTvisionProgramm VERSION 0.1.0 LANGUAGES CXX)

include(FetchContent)

# Fuer eigene Programme wird nur die Bibliothek benoetigt. Die Beispiele und
# die tvision-interne Testsuite vergroessern Buildzeit und Speicherbedarf.
set(TV_BUILD_EXAMPLES OFF CACHE BOOL "Build tvision examples" FORCE)
set(TV_BUILD_TESTS OFF CACHE BOOL "Build tvision tests" FORCE)

# GPM ist nur unter Linux relevant und fuer den portablen Standard optional.
set(TV_BUILD_USING_GPM OFF CACHE BOOL "Use GPM on Linux" FORCE)

# Unity Builds koennen grosse Uebersetzungseinheiten und Lastspitzen erzeugen.
# Auf einem Rechner mit 8 GB RAM bleibt die Option deshalb aus.
set(TV_LIBRARY_UNITY_BUILD OFF CACHE BOOL "Use tvision unity build" FORCE)

# PCH bleibt standardmaessig an: Der erste Build benoetigt etwas Plattenplatz,
# Folgekompilierungen werden aber meist schneller. Abschnitt 26 beschreibt die
# streng speichersparende Alternative.
set(TV_OPTIMIZE_BUILD ON CACHE BOOL "Use tvision precompiled headers" FORCE)

FetchContent_Declare(
    tvision
    GIT_REPOSITORY https://github.com/hindermath/tvision.git
    GIT_TAG        0123456789abcdef0123456789abcdef01234567
    GIT_PROGRESS   TRUE
)

FetchContent_MakeAvailable(tvision)

add_executable(mein_tvision_programm
    src/main.cpp
)

target_compile_features(mein_tvision_programm PRIVATE cxx_std_17)
target_link_libraries(mein_tvision_programm PRIVATE tvision::tvision)
```

Die Beispiel-SHA wird vor dem ersten Configure-Lauf durch einen realen Commit
des persoenlichen Forks ersetzt. Der vollstaendige Hash kann im geklonten
Fork mit `git rev-parse origin/master` oder ohne lokalen Klon mit
`git ls-remote` ermittelt werden.

#### 16.3 src/main.cpp

```cpp
#define Uses_TApplication
#define Uses_TButton
#define Uses_TDeskTop
#define Uses_TDialog
#define Uses_TRect
#define Uses_TStaticText
#include <tvision/tv.h>

class Application final : public TApplication
{
public:
    Application() noexcept :
        TProgInit(
            &Application::initStatusLine,
            &Application::initMenuBar,
            &Application::initDeskTop
        )
    {
    }

    ~Application() override = default;
};

int main()
{
    Application application;

    auto *dialog = new TDialog(
        TRect(0, 0, 46, 11),
        "Mein erstes tvision-Programm"
    );

    dialog->insert(new TStaticText(
        TRect(3, 3, 43, 5),
        "Gebaut mit CMake fuer dieses Betriebssystem."
    ));

    dialog->insert(new TButton(
        TRect(16, 7, 30, 9),
        "~O~K",
        cmOK,
        bfDefault
    ));

    application.deskTop->execView(dialog);
    TObject::destroy(dialog);
    return 0;
}
```

Die `Uses_...`-Makros muessen vor `<tvision/tv.h>` stehen. Sie steuern, welche
Turbo-Vision-Deklarationen der zentrale Header einbezieht. Da Konstruktor und
Destruktor von `TApplication` geschuetzt sind, macht die kleine abgeleitete
Klasse sie fuer dieses Programm kontrolliert oeffentlich. `TProgInit` bindet
dabei die geerbten Standardfabriken fuer Statuszeile, Menueleiste und Desktop.
Der Dialog wird modal auf dem initialisierten Desktop angezeigt.
`TObject::destroy` ist die zu Turbo Vision passende Freigabe fuer das dynamisch
erzeugte View.

#### 16.4 .gitignore

```gitignore
# Gemeinsame CMake-Buildbaeume
/build/
/cmake-build-*/

# Von FetchContent in Buildbaeumen abgelegte Quellen
/_deps/

# Lokale CMake-Benutzervorgaben
/CMakeUserPresets.json

# Lokaler Zustand von Microsoft Visual Studio
/.vs/

# Plattformartefakte
*.a
*.lib
*.dll
*.dylib
*.so
*.exe
*.pdb
*.dSYM/
```

`CMakePresets.json` darf eingecheckt werden, weil es gemeinsame, portable
Buildweisen beschreibt. `CMakeUserPresets.json` bleibt lokal, wenn es absolute
Pfade, persoenliche Compiler oder andere maschinenspezifische Werte enthaelt.

#### 16.5 Vom neuen Verzeichnis zum eigenstaendigen Calculator

Die Abschnitte 3 und 16 beantworten bereits den allgemeinen Fall: Ein eigenes
Verzeichnis erhaelt ein eigenes `project()`, ein eigenes Programmziel und bindet
den tvision-Fork ueber `FetchContent` ein. Als vollstaendig ausfuehrbares
Lernbeispiel liegt zusaetzlich der
[eigenstaendige tvision-Calculator](examples/tvision-calculator/README.md) vor.
Er ist ein separates CMake-Projekt und verwendet keine internen Funktionen aus
`examples/CMakeLists.txt` des tvision-Forks.

##### 16.5.1 Leeres Projekt manuell anlegen

macOS und Linux:

```bash
mkdir -p mein-tvision-calculator/src mein-tvision-calculator/tests
cd mein-tvision-calculator
git init
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force mein-tvision-calculator/src
New-Item -ItemType Directory -Force mein-tvision-calculator/tests
Set-Location mein-tvision-calculator
git init
```

Danach werden die folgenden Dateien im neuen Verzeichnis angelegt:

```text
mein-tvision-calculator/
|-- .gitignore
|-- CMakeLists.txt
|-- CMakePresets.json
|-- README.md
|-- src/
|   |-- calculator_engine.cpp
|   |-- calculator_engine.h
|   `-- main.cpp
`-- tests/
    `-- calculator_engine_test.cpp
```

Die gleichnamigen Dateien im mitgelieferten Beispiel sind die kopierbare
Referenz. `CMakeLists.txt` definiert das eigenstaendige Projekt
`TvisionCalculator`, ruft den unveraenderlichen tvision-Commit ab und linkt nur
das Ziel `tvision_calculator` gegen `tvision::tvision`. Absolute Include- oder
Bibliothekspfade sind nicht erforderlich.

##### 16.5.2 Das fertige Geruest kopieren

Wer nicht jede Datei einzeln anlegen moechte, kopiert vom Wurzelverzeichnis des
tvision-Forks aus das vollstaendige Referenzprojekt neben den Fork.

macOS oder Linux:

```bash
cp -R docs/examples/tvision-calculator ../mein-tvision-calculator
cd ../mein-tvision-calculator
git init
```

PowerShell:

```powershell
Copy-Item -Recurse docs/examples/tvision-calculator ../mein-tvision-calculator
Set-Location ../mein-tvision-calculator
git init
```

Nach dem Kopieren ist `mein-tvision-calculator` ein eigenes Repository. Der
urspruengliche lokale tvision-Klon wird fuer normale Builds nicht verwendet;
FetchContent holt den in `GIT_TAG` festgelegten Stand in den lokalen Buildbaum
des Calculators.

##### 16.5.3 Aufbau und Bedienmodell

Die neu geschriebene `calculator::Engine` enthaelt die vier Grundrechenarten,
Ziffern, Dezimalpunkt, Gleich und Loeschen. Die tvision-Oberflaeche in
`src/main.cpp` uebersetzt Tastatur- und Schaltflaechenereignisse in diese
Engine und zeichnet deren Anzeige. Dadurch kann CTest die Rechenregeln ohne
interaktives Terminal testen.

Operationen werden wie bei einem einfachen Taschenrechner sofort von links
nach rechts ausgewertet. `2 + 3 * 4 =` ergibt daher `20`. Division durch null
zeigt `Error`; nur `C` setzt den Fehlerzustand vollstaendig zurueck. Ziffern,
`.` sowie `+`, `-`, `*`, `/`, `=` und Enter funktionieren ohne Maus. Escape
schliesst den Dialog ueber das normale Verhalten von `TDialog`.

Der Beispielcode ist vom Bedienkonzept des TVDemo-Calculators inspiriert, aber
neu implementiert. Historischer Borland-Quellcode wird nicht in das neue
Stand-alone-Projekt kopiert.

##### 16.5.4 Konfigurieren, bauen, testen und starten

macOS:

```bash
cmake --preset macos-debug
cmake --build --preset macos-debug
ctest --preset macos-debug
./build/macos-debug/tvision_calculator
```

Linux:

```bash
cmake --preset linux-debug
cmake --build --preset linux-debug
ctest --preset linux-debug
./build/linux-debug/tvision_calculator
```

Windows in einer Developer PowerShell:

```powershell
cmake --preset windows-debug
cmake --build --preset windows-debug
ctest --preset windows-debug
./build/windows-debug/Debug/tvision_calculator.exe
```

Ein Ein-Konfigurationsgenerator unter Windows kann die EXE stattdessen direkt
unter `build/windows-debug/` ablegen. Die Presets verwenden bewusst den
Standardgenerator des jeweiligen Systems und begrenzen den Build auf zwei
parallele Jobs. Deshalb ist Ninja fuer dieses Beispiel optional. Bei hohem
Speicherdruck wird mit einem direkten `cmake --build ... --parallel 1`
fortgesetzt.

##### 16.5.5 CLion, VS Code, Visual Studio und lokaler tvision-Override

In CLion wird `mein-tvision-calculator` als eigenes Projekt geoeffnet. Das
passende Host-Preset wird ausgewaehlt und `tvision_calculator` als Run-Ziel in
einem interaktiven Terminal gestartet. VS Code verwendet denselben Quellbaum:

```bash
code .
```

Danach folgen `CMake: Select Configure Preset`, `CMake: Build` und der Start im
integrierten Terminal. Ein reines Output-Panel ist fuer eine interaktive TUI
nicht ausreichend.

Unter Windows kann dasselbe Verzeichnis in Visual Studio Community mit
`File | Open | Folder` als CMake-Projekt geoeffnet werden. Die ausfuehrliche
Auswahl zwischen Community 2022/v143 und 2026/v145 steht in Abschnitt 22.

Der normale Verbraucherweg bleibt der festgelegte Remote-Commit. Nur fuer
gezielte Maintainer- und CI-Pruefungen kann CMake ohne Dateiaenderung auf einen
lokalen tvision-Checkout zeigen:

```bash
cmake -S . -B build/local-source \
  -DCMAKE_BUILD_TYPE=Debug \
  -DFETCHCONTENT_SOURCE_DIR_TVISION=/vollstaendiger/pfad/zu/tvision
cmake --build build/local-source --parallel 2
ctest --test-dir build/local-source --output-on-failure
```

Der absolute Pfad bleibt maschinenlokal und wird weder in `CMakeLists.txt` noch
in ein geteiltes Preset geschrieben.

### 17. Das CMake-Kommandozeilenmodell

CMake trennt vier Schritte, die bei der Fehlersuche nicht vermischt werden
sollten:

1. **Configure** liest `CMakeLists.txt`, waehlt Compiler und Generator, holt
   FetchContent und schreibt den Buildbaum.
2. **Generate** erzeugt Ninja-, Make-, Visual-Studio- oder andere native
   Builddateien; dieser Schritt ist Bestandteil des Configure-Aufrufs.
3. **Build** kompiliert und linkt ausgewaehlte Ziele.
4. **Run** startet das erzeugte Programm in einem Terminal.

Der Quellbaum bleibt dabei von den generierten Dateien getrennt:

```text
mein-tvision-programm/       Quellbaum, wird versioniert
`-- build/macos-debug/       Buildbaum, wird nicht versioniert
```

#### 17.1 Generatoren

Fuer einen kleinen, plattformuebergreifenden und ressourcenschonenden Ablauf
ist Ninja der bevorzugte Generator. Ninja selbst ist klein und CMake kann die
Parallelitaet kontrollieren. Alternativen bleiben moeglich:

| System | Bevorzugt | Alternative |
|---|---|---|
| macOS | Ninja | Unix Makefiles, Xcode |
| Linux | Ninja | Unix Makefiles |
| Windows/MSVC | Ninja in Developer PowerShell | Visual Studio Generator |
| Windows/MinGW | Ninja | MinGW Makefiles |

Ein Buildverzeichnis ist an seinen Generator und Compiler gebunden. Es wird
nicht nachtraeglich von Ninja zu Visual Studio, von AppleClang zu GCC oder von
MSVC zu MinGW umgeschaltet.

#### 17.2 Universelle Befehlsform

```bash
cmake -S . -B build/<plattform>-debug \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug

cmake --build build/<plattform>-debug \
  --target mein_tvision_programm \
  --parallel 2
```

`-S .` benennt den Quellbaum, `-B` den Buildbaum und `-G` den Generator.
`--target` verhindert, dass versehentlich unnoetige Ziele gebaut werden.
`--parallel 2` ist der empfohlene Ausgangswert fuer 8 GB RAM. Bei sichtbarem
Speicherdruck wird `--parallel 1` verwendet; auf einem groesseren Rechner kann
der Wert kontrolliert erhoeht werden.

#### 17.3 Diagnose vor dem ersten Build

```bash
git --version
cmake --version
ninja --version
```

Zusaetzlich wird der aktive Compiler geprueft:

```bash
clang++ --version   # macOS oder Clang/Linux
g++ --version       # GCC/Linux oder MinGW
cl                  # MSVC Developer PowerShell
```

Fehlt bereits eines dieser Werkzeuge, wird nicht mit CMake-Cache-Korrekturen
experimentiert. Zuerst wird die Toolchain vollstaendig installiert oder in der
aktiven Shell sichtbar gemacht.

#### 17.4 Buildtypen

| Buildtyp | Einsatz | Typische Auswirkung |
|---|---|---|
| `Debug` | Entwicklung und Debugger | Symbole, wenig Optimierung, groesser |
| `Release` | Auslieferungspruefung | Optimierung, weniger Debugkomfort |
| `RelWithDebInfo` | optimierte Fehlersuche | Optimierung plus Symbole |
| `MinSizeRel` | Groessenoptimierung | klein, weniger Debugkomfort |

Fuer die taegliche Arbeit genuegen Debug und Release. Auf kleinen Datentraegern
wird nicht jede Konfiguration dauerhaft aufgehoben.

### 18. Gemeinsame CMakePresets.json fuer drei Betriebssysteme

Presets machen denselben Build aus CLion, VS Code, Visual Studio und der
Kommandozeile aufrufbar. Das folgende Beispiel laesst den Generator bewusst
offen und verwendet zwei parallele Jobs. Dadurch kann jedes Betriebssystem
seinen Standardgenerator waehlen; Ninja bleibt eine optionale lokale Wahl.
Unter Windows bestimmt die aktive IDE oder Toolchain-Shell, ob MSVC oder MinGW
verwendet wird. Eine feste Auswahl zwischen Visual Studio 2022 und 2026 gehoert
in die lokale `CMakeUserPresets.json`, nicht in diesen gemeinsamen Vertrag.

```json
{
  "version": 3,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 21,
    "patch": 0
  },
  "configurePresets": [
    {
      "name": "common",
      "hidden": true,
      "binaryDir": "${sourceDir}/build/${presetName}",
      "cacheVariables": {
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    },
    {
      "name": "macos-debug",
      "displayName": "macOS Debug",
      "inherits": "common",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Darwin"
      },
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug"
      }
    },
    {
      "name": "macos-release",
      "displayName": "macOS Release",
      "inherits": "common",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Darwin"
      },
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release"
      }
    },
    {
      "name": "linux-debug",
      "displayName": "Linux Debug",
      "inherits": "common",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Linux"
      },
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug"
      }
    },
    {
      "name": "linux-release",
      "displayName": "Linux Release",
      "inherits": "common",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Linux"
      },
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release"
      }
    },
    {
      "name": "windows-debug",
      "displayName": "Windows Debug",
      "inherits": "common",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Windows"
      },
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug"
      }
    },
    {
      "name": "windows-release",
      "displayName": "Windows Release",
      "inherits": "common",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Windows"
      },
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "macos-debug",
      "configurePreset": "macos-debug",
      "configuration": "Debug",
      "jobs": 2,
      "targets": ["mein_tvision_programm"]
    },
    {
      "name": "macos-release",
      "configurePreset": "macos-release",
      "configuration": "Release",
      "jobs": 2,
      "targets": ["mein_tvision_programm"]
    },
    {
      "name": "linux-debug",
      "configurePreset": "linux-debug",
      "configuration": "Debug",
      "jobs": 2,
      "targets": ["mein_tvision_programm"]
    },
    {
      "name": "linux-release",
      "configurePreset": "linux-release",
      "configuration": "Release",
      "jobs": 2,
      "targets": ["mein_tvision_programm"]
    },
    {
      "name": "windows-debug",
      "configurePreset": "windows-debug",
      "configuration": "Debug",
      "jobs": 2,
      "targets": ["mein_tvision_programm"]
    },
    {
      "name": "windows-release",
      "configurePreset": "windows-release",
      "configuration": "Release",
      "jobs": 2,
      "targets": ["mein_tvision_programm"]
    }
  ]
}
```

Verfuegbare Presets zeigt:

```bash
cmake --list-presets
cmake --build --list-presets
```

Ein Build besteht danach nur noch aus:

```bash
cmake --preset macos-debug
cmake --build --preset macos-debug
```

Auf Linux werden die Namen `linux-debug` beziehungsweise `linux-release`
verwendet, auf Windows `windows-debug` beziehungsweise `windows-release`.

### 19. macOS: reine CMake-Kommandozeile

#### 19.1 Voraussetzungen

```bash
xcode-select -p
clang++ --version
cmake --version
ninja --version
git --version
```

Fehlen die Apple-Entwicklerwerkzeuge, werden sie mit
`xcode-select --install` ueber den offiziellen macOS-Dialog installiert. CMake
und Ninja koennen aus der bereits gepflegten lokalen Toolchain oder einem
Paketmanager stammen. Es soll nur eine bewusst gewaehlte Version im `PATH`
gewinnen.

#### 19.2 Debug konfigurieren und bauen

Mit Presets:

```bash
cmake --preset macos-debug
cmake --build --preset macos-debug
```

Ohne Presets:

```bash
cmake -S . -B build/macos-debug \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug

cmake --build build/macos-debug \
  --target mein_tvision_programm \
  --parallel 2
```

#### 19.3 Im Terminal starten

```bash
./build/macos-debug/mein_tvision_programm
```

Das Programm wird nicht aus einem Ausgabefenster ohne echtes TTY gestartet.
Terminal.app, iTerm2, das CLion-Terminal und das integrierte VS-Code-Terminal
sind geeignete Startpunkte.

#### 19.4 Release bauen

```bash
cmake --preset macos-release
cmake --build --preset macos-release
./build/macos-release/mein_tvision_programm
```

Auf dem Develop-First-Mac wird Debug waehrend der Arbeit behalten. Release
wird vor einem plattformuebergreifenden Kontrollpunkt erzeugt und kann danach
bei Platzmangel wieder entfernt werden.

### 20. Linux: reine CMake-Kommandozeile

#### 20.1 Voraussetzungen

Erforderlich sind Git, CMake, Ninja oder Make, ein C++-Compiler, ein Debugger
und die ncursesw-Entwicklungsdateien. Beispiel fuer Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install build-essential cmake ninja-build git gdb libncurses-dev
```

Beispiel fuer Fedora:

```bash
sudo dnf install gcc-c++ cmake ninja-build git gdb ncurses-devel
```

Beispiel fuer Arch Linux:

```bash
sudo pacman -S --needed base-devel cmake ninja git gdb ncurses
```

Paketnamen koennen sich mit Distribution und Version unterscheiden. Massgeblich
ist der anschliessende Werkzeug- und CMake-Check, nicht das blinde Wiederholen
eines Paketbefehls.

#### 20.2 Debug und Release

```bash
cmake --preset linux-debug
cmake --build --preset linux-debug
./build/linux-debug/mein_tvision_programm

cmake --preset linux-release
cmake --build --preset linux-release
./build/linux-release/mein_tvision_programm
```

Ohne Presets werden `build/linux-debug`, Ninja und
`-DCMAKE_BUILD_TYPE=Debug` analog zum macOS-Beispiel verwendet.

#### 20.3 Terminalumgebung pruefen

```bash
printf 'TERM=%s\n' "${TERM:-nicht-gesetzt}"
locale
```

Ein nicht gesetztes oder ungeeignetes `TERM`, eine problematische Locale oder
ein Start aus einem nicht interaktiven Ausgabekanal kann Darstellung und
Eingabe beeintraechtigen. Fuer die normale Pruefung wird ein lokales Terminal
mit UTF-8-Locale verwendet.

### 21. Windows: reine CMake-Kommandozeile

Windows benoetigt eine bewusste Entscheidung zwischen MSVC und MinGW. Beide
koennen dieselbe Quelle bauen, ihre Objektdateien und Bibliotheken werden aber
nicht gemischt.

#### 21.1 MSVC mit Developer PowerShell

Voraussetzungen sind die Microsoft C++ Build Tools beziehungsweise Visual
Studio mit dem Workload fuer Desktopentwicklung mit C++, CMake, Ninja und Git.
Der Build startet in **Developer PowerShell for Visual Studio**, damit `cl.exe`,
Linker, Windows SDK und Include-Pfade korrekt gesetzt sind.

```powershell
cl
cmake --version
ninja --version
git --version
```

Mit Presets:

```powershell
cmake --preset windows-debug
cmake --build --preset windows-debug
& .\build\windows-debug\mein_tvision_programm.exe

cmake --preset windows-release
cmake --build --preset windows-release
& .\build\windows-release\mein_tvision_programm.exe
```

Ohne Presets:

```powershell
cmake -S . -B build/windows-debug `
  -G Ninja `
  -DCMAKE_BUILD_TYPE=Debug

cmake --build build/windows-debug `
  --target mein_tvision_programm `
  --parallel 2
```

#### 21.2 MSVC mit Visual-Studio-Generator

Wenn Ninja nicht verwendet werden soll:

```powershell
cmake -S . -B build/windows-vs `
  -G "Visual Studio 17 2022" `
  -A x64

cmake --build build/windows-vs `
  --config Debug `
  --target mein_tvision_programm `
  --parallel 2

& .\build\windows-vs\Debug\mein_tvision_programm.exe
```

Der konkrete Generatorname muss zur installierten Visual-Studio-Version
passen. Visual-Studio-Generatoren sind Multi-Config-Generatoren; deshalb wird
Debug oder Release bei `cmake --build --config ...` ausgewaehlt und das
Programm liegt typischerweise in einem Konfigurationsunterverzeichnis.

#### 21.3 MinGW

In einer Shell, in der MinGW und Ninja im `PATH` liegen:

```powershell
g++ --version
cmake -S . -B build/windows-mingw-debug `
  -G Ninja `
  -DCMAKE_BUILD_TYPE=Debug

cmake --build build/windows-mingw-debug `
  --target mein_tvision_programm `
  --parallel 2

& .\build\windows-mingw-debug\mein_tvision_programm.exe
```

Ein MSVC-Buildverzeichnis wird niemals als MinGW-Buildverzeichnis
weiterverwendet. Bei einem Toolchainwechsel wird ein neuer, eindeutig benannter
Buildbaum angelegt.

### 22. Microsoft Visual Studio Community 2022 und 2026

Microsoft Visual Studio Community ist eine vollstaendige native Windows-IDE.
Sie enthaelt bei passender Workload den MSVC-Compiler, CMake-Integration,
IntelliSense, Debugger, Test Explorer und ein integriertes Terminal. In diesem
Arbeitsmodell ist sie eine weitere Oberflaeche fuer denselben eingecheckten
CMake-Vertrag; es wird kein separates Visual-Studio-Projekt gepflegt.

#### 22.1 Einordnung neben CLion und VS Code

| Werkzeug | Betriebssysteme | Rolle in diesem Arbeitsmodell |
|---|---|---|
| CLion | macOS, Linux, Windows | plattformuebergreifende Standard-IDE |
| VS Code | macOS, Linux, Windows | leichte Editor- und Terminalvariante |
| Visual Studio Community | Windows | optionale native Windows-Voll-IDE |
| CMake-Kommandozeile | macOS, Linux, Windows | IDE-unabhaengige Referenz |

Visual Studio Community aendert weder `CMakeLists.txt` noch die festgelegte
`tvision`-SHA. Eine unter Visual Studio erzeugte `.lib` bleibt genauso
Windows-, Architektur-, Toolset- und Konfigurations-spezifisch wie ein Build
aus CLion oder der Developer PowerShell.

#### 22.2 Versionen, Generatoren und Toolsets

Stand 12. August 2026 gelten fuer die beiden hier beschriebenen Generationen:

| IDE | CMake-Generator | CMake-Untergrenze fuer den Generator | Standard-Toolset |
|---|---|---:|---|
| Visual Studio Community 2022 | `Visual Studio 17 2022` | 3.21 | `v143` |
| Visual Studio Community 2026 | `Visual Studio 18 2026` | 4.2 | `v145` |

Die Generator-Untergrenze ist nicht mit der Mindestversion des
Anwendungsprojekts zu verwechseln. Das Projekt kann weiterhin
`cmake_minimum_required(VERSION 3.21)` angeben. Nur die CMake-Installation, die
den Generator `Visual Studio 18 2026` auswaehlen soll, muss mindestens Version
4.2 sein.

Visual Studio 2022 bleibt ein sinnvoller Kompatibilitaetsweg fuer `v143` und
wird in der Community Edition ueber den aktuellen 17.14-Kanal gepflegt. Visual
Studio 2026 ist der aktuelle Weg fuer `v145`. Beide koennen auf einem
unterstuetzten 64-Bit-Windows-System nebeneinander installiert sein. Jede
Installation und jeder Updatekanal benoetigt einen eindeutigen Pfad; jeder
CMake-Buildbaum bleibt genau einer Generatorinstanz und einem Toolset
zugeordnet.

Visual Studio 2026 unterstuetzt als IDE aktuelle 64-Bit-Ausgaben von Windows 11
und die in den Microsoft-Systemanforderungen genannten Windows-Server-Versionen.
Vor einer Installation auf einem aelteren Windows-System werden die aktuellen
Anforderungen der gewaehlten Visual-Studio-Version geprueft. Eine erzeugte
Anwendung kann je nach Windows SDK und Zielkonfiguration andere Windows-Ziele
unterstuetzen als die IDE selbst.

Offizielle Referenzen:

- [Visual Studio Community und Nutzung](https://visualstudio.microsoft.com/vs/community/)
- [C++-Unterstuetzung installieren](https://learn.microsoft.com/en-us/cpp/build/vscpp-step-0-installation?view=msvc-170)
- [CMake-Projekte in Visual Studio](https://learn.microsoft.com/en-us/cpp/build/cmake-projects-in-visual-studio?view=msvc-170)
- [Visual Studio 2022: Systemanforderungen](https://learn.microsoft.com/en-us/visualstudio/releases/2022/system-requirements)
- [Visual Studio 2026: Systemanforderungen](https://learn.microsoft.com/en-us/visualstudio/releases/2026/vs-system-requirements)
- [CMake-Generator fuer Visual Studio 2022](https://cmake.org/cmake/help/latest/generator/Visual%20Studio%2017%202022.html)
- [CMake-Generator fuer Visual Studio 2026](https://cmake.org/cmake/help/latest/generator/Visual%20Studio%2018%202026.html)

Die Community-Lizenz erlaubt einzelnen Entwicklerinnen und Entwicklern nach
Microsofts aktueller Beschreibung eigene kostenlose oder kostenpflichtige
Anwendungen. Fuer Nutzung innerhalb einer Organisation gelten zusaetzliche
Bedingungen; die verlinkten aktuellen Lizenzbedingungen sind verbindlich, nicht
diese technische Anleitung.

#### 22.3 Installation mit dem Visual Studio Installer

Im Visual Studio Installer wird fuer Community 2022 beziehungsweise Community
2026 mindestens die Workload **Desktop development with C++** ausgewaehlt.
Danach wird in den Installationsdetails geprueft, dass diese Bestandteile
vorhanden sind:

- das zur IDE gehoerende MSVC-x64/x86-Toolset (`v143` oder `v145`);
- ein aktuelles Windows SDK;
- die C++-CMake-Werkzeuge fuer Windows;
- CMake mit mindestens 3.21 fuer VS 2022 beziehungsweise mindestens 4.2 fuer
  den VS-2026-Generator;
- optional Ninja und Git, sofern sie nicht separat bereitstehen.

Es ist nicht erforderlich, jede optionale C++-Komponente, MFC, ATL, UWP oder
Spieleentwicklung zu installieren. Eine gezielte C++-Desktopinstallation spart
erheblich Massenspeicher. Microsoft nennt fuer typische Visual-Studio-
Installationen etwa 20 bis 50 GB, mindestens 4 GB RAM und 16 GB RAM als
Empfehlung fuer typische professionelle Loesungen. Auf einem kleinen
Windows-Rechner ist deshalb VS Code oder die reine Kommandozeile oft die
passendere Oberflaeche.

Nach der Installation wird die passende **Developer PowerShell for VS 2022**
oder **Developer PowerShell for VS 2026** einzeln geoeffnet:

```powershell
cl
cmake --version
cmake --help | Select-String 'Visual Studio 17 2022|Visual Studio 18 2026'
```

Die Ausgabe muss zum beabsichtigten Generator passen. Dass `cl` gefunden wird,
beweist nur eine aktive MSVC-Umgebung; erst `CMakeCache.txt` beweist den
tatsaechlich gewaehlten Generator, die Architektur und das Toolset.

#### 22.4 Vorhandenes CMake-Projekt direkt oeffnen

Der empfohlene IDE-Weg erzeugt keine `.sln`- oder `.vcxproj`-Dateien im
Quellbaum:

1. Visual Studio Community starten.
2. `File | Open | Folder` waehlen.
3. Den Wurzelordner des eigenen Programms oeffnen, in dem die oberste
   `CMakeLists.txt` und `CMakePresets.json` liegen.
4. Falls Visual Studio nach der Aktivierung von CMake fragt, diese fuer genau
   diesen Projektordner bestaetigen.
5. In der Konfigurationsauswahl das passende Windows-Preset waehlen.
6. Den ersten Configure-Lauf vollstaendig abschliessen lassen. FetchContent
   ruft dabei die festgelegte `tvision`-SHA ab.
7. Im Solution Explorer bei Bedarf auf **CMake Targets View** wechseln.

Visual Studio legt IDE-Zustand unter `.vs/` und Buildausgaben im vom Preset
bestimmten Verzeichnis ab. Beides bleibt ungetrackt. Fuer ein CMake-Projekt sind
`CppProperties.json` und `tasks.vs.json` nicht erforderlich. Auch eine zweite
handgeschriebene `CMakeSettings.json` wird nicht parallel zu den verbindlichen
Presets eingefuehrt.

Nach wesentlichen CMake-Aenderungen kann `Project | Configure Cache` bewusst
ausgefuehrt werden. Bei Generator-, Architektur- oder Toolsetwechsel wird ein
neuer Buildbaum verwendet; ein alter Cache wird nicht in der IDE umgedeutet.

#### 22.5 Bauen, testen, starten und debuggen

Nach erfolgreichem Configure zeigt Visual Studio die CMake-Ziele an. Fuer den
stand-alone Calculator gelten beispielsweise diese Schritte:

1. `tvision_calculator` als Build- beziehungsweise Startup-Ziel waehlen.
2. Debug oder Release in der aktiven CMake-Konfiguration auswaehlen.
3. `Build | Build All` beziehungsweise `Ctrl+Shift+B` ausfuehren.
4. Die Engine-Tests im integrierten Terminal reproduzierbar mit CTest starten.
5. Die TUI zuerst ohne Debugger in einem echten Terminal pruefen.
6. Danach `tvision_calculator` als Startup Item waehlen und mit `F5` debuggen.

Fuer einen Visual-Studio-Multi-Config-Build lauten die terminalunabhaengigen
Kontrollbefehle:

```powershell
cmake --build build/windows-debug `
  --config Debug `
  --target tvision_calculator `
  --parallel 2

ctest --test-dir build/windows-debug `
  -C Debug `
  --output-on-failure

& .\build\windows-debug\Debug\tvision_calculator.exe
```

Der genaue EXE-Pfad folgt aus `binaryDir`, Konfiguration und Generator. Eine
TUI wird nicht in einem reinen Output- oder Debug-Textfenster abgenommen.
Windows Terminal, Developer PowerShell oder das vollwertige integrierte
Terminal muessen Tastatur, Farben, Groessenaenderung und sauberes Beenden
verarbeiten koennen.

#### 22.6 Visual Studio 2022 explizit auswaehlen

Dieser reproduzierbare Befehl bindet Generator, x64-Architektur und `v143` an
einen eigenen Buildbaum:

```powershell
cmake -S . -B build/windows-vs2022 `
  -G "Visual Studio 17 2022" `
  -A x64 `
  -T v143 `
  -DBUILD_TESTING=ON

cmake --build build/windows-vs2022 `
  --config Release `
  --target tvision_calculator `
  --parallel 2

ctest --test-dir build/windows-vs2022 `
  -C Release `
  --output-on-failure

& .\build\windows-vs2022\Release\tvision_calculator.exe
```

Soll die von CMake erzeugte Solution ausnahmsweise sichtbar geoeffnet werden,
liegt sie im Buildbaum. Sie ist abgeleitet, wird nicht editiert und nicht
eingecheckt. Der kanonische IDE-Weg bleibt **Open Folder** mit den
CMake-Quelldateien.

#### 22.7 Visual Studio 2026 explizit auswaehlen

Fuer Visual Studio 2026 werden CMake 4.2 oder neuer, Generator 18 und `v145`
verwendet:

```powershell
cmake -S . -B build/windows-vs2026 `
  -G "Visual Studio 18 2026" `
  -A x64 `
  -T v145 `
  -DBUILD_TESTING=ON

cmake --build build/windows-vs2026 `
  --config Release `
  --target tvision_calculator `
  --parallel 2

ctest --test-dir build/windows-vs2026 `
  -C Release `
  --output-on-failure

& .\build\windows-vs2026\Release\tvision_calculator.exe
```

Ein Fehler `Could not create named generator Visual Studio 18 2026` bedeutet
primaer, dass die aufgerufene CMake-Version zu alt ist, die VS-2026-Instanz
nicht erkannt wird oder die erforderliche C++-Workload fehlt. Das Problem wird
nicht durch Umbenennen eines VS-2022-Buildbaums geloest.

#### 22.8 Side-by-Side-Auswahl mit CMakeUserPresets.json

Sind Community 2022 und 2026 nebeneinander installiert, bleibt
`CMakePresets.json` portabel. Die maschinenbezogene Auswahl wird lokal in der
bereits ignorierten `CMakeUserPresets.json` getroffen:

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "windows-vs2022-debug",
      "displayName": "Windows VS 2022 v143 Debug",
      "inherits": "windows-debug",
      "generator": "Visual Studio 17 2022",
      "architecture": "x64",
      "toolset": "v143",
      "binaryDir": "${sourceDir}/build/windows-vs2022-debug"
    },
    {
      "name": "windows-vs2026-debug",
      "displayName": "Windows VS 2026 v145 Debug",
      "inherits": "windows-debug",
      "generator": "Visual Studio 18 2026",
      "architecture": "x64",
      "toolset": "v145",
      "binaryDir": "${sourceDir}/build/windows-vs2026-debug"
    }
  ],
  "buildPresets": [
    {
      "name": "windows-vs2022-debug",
      "configurePreset": "windows-vs2022-debug",
      "configuration": "Debug",
      "jobs": 2
    },
    {
      "name": "windows-vs2026-debug",
      "configurePreset": "windows-vs2026-debug",
      "configuration": "Debug",
      "jobs": 2
    }
  ],
  "testPresets": [
    {
      "name": "windows-vs2022-debug",
      "configurePreset": "windows-vs2022-debug",
      "configuration": "Debug",
      "output": {"outputOnFailure": true}
    },
    {
      "name": "windows-vs2026-debug",
      "configurePreset": "windows-vs2026-debug",
      "configuration": "Debug",
      "output": {"outputOnFailure": true}
    }
  ]
}
```

Danach funktionieren IDE und Kommandozeile mit denselben Namen:

```powershell
cmake --list-presets
cmake --preset windows-vs2022-debug
cmake --build --preset windows-vs2022-debug
ctest --preset windows-vs2022-debug

cmake --preset windows-vs2026-debug
cmake --build --preset windows-vs2026-debug
ctest --preset windows-vs2026-debug
```

Release-Presets werden nach demselben Muster mit eigenem `binaryDir` und
`"configuration": "Release"` angelegt. Absolute Installationspfade oder
`CMAKE_GENERATOR_INSTANCE` werden nur dann lokal ergaenzt, wenn CMake mehrere
gleichnamige Instanzen nicht eindeutig zuordnen kann. Solche Rechnerpfade
werden nie in `CMakePresets.json` oder `CMakeLists.txt` eingecheckt.

#### 22.9 Typische Visual-Studio-Fehler

- **Preset erscheint nicht:** Projektwurzel, gueltiges JSON und aktivierte
  CMake-Unterstuetzung pruefen; danach Cache neu konfigurieren.
- **Falsche IDE-Version:** `CMAKE_GENERATOR`, `CMAKE_GENERATOR_INSTANCE` und
  `CMAKE_GENERATOR_TOOLSET` im jeweiligen `CMakeCache.txt` kontrollieren.
- **Architektur passt nicht:** Buildbaum neu mit `-A x64` konfigurieren; nicht
  einzelne Cachewerte von Win32 auf x64 editieren.
- **Toolset fehlt:** Visual Studio Installer oeffnen und `v143` oder `v145`
  innerhalb der C++-Desktopworkload nachinstallieren.
- **Linker meldet inkompatible Dateien:** MSVC-, MinGW-, Debug-, Release-, x86-
  und x64-Artefakte wurden wahrscheinlich vermischt. Einen frischen,
  eindeutig benannten Buildbaum verwenden.
- **TUI reagiert nicht:** EXE in Windows Terminal oder Developer PowerShell
  starten und nicht das reine Visual-Studio-Outputfenster als Terminal
  behandeln.
- **Zu wenig RAM oder Speicherplatz:** Nur eine Community-Version und die
  minimale C++-Desktopworkload installieren oder fuer diesen Rechner VS Code
  beziehungsweise die Kommandozeile verwenden.

### 23. VS Code als Light-Editor-Variante

VS Code ersetzt weder Compiler noch CMake. Es ist in diesem Modell ein Editor
mit integriertem Terminal und optionaler CMake-Oberflaeche. Die eigentliche
Wahrheit bleibt der identische CMake-Aufruf, der auch ausserhalb des Editors
funktioniert.

#### 23.1 Minimales VS-Code-Profil

Ein eigenes VS-Code-Profil verhindert, dass Erweiterungen fuer andere
Sprachen, Container, Datenbanken oder KI-Werkzeuge auf dem kleinen Rechner
gleichzeitig aktiviert werden.

```bash
code --profile "C++ Light" .
code --install-extension ms-vscode.cpptools --profile "C++ Light"
code --install-extension ms-vscode.cmake-tools --profile "C++ Light"
```

Installiert werden nur:

- **C/C++** von Microsoft fuer Syntax, IntelliSense und Debugadapter;
- **CMake Tools** von Microsoft fuer Presets, Configure, Build und Zielauswahl.

Nicht benoetigte Erweiterungen werden fuer dieses Profil beziehungsweise nur
fuer diesen Workspace deaktiviert. `code --disable-extensions .` ist ein
Diagnosemodus, aber nicht der normale C++-Arbeitsmodus, weil dabei auch die
beiden benoetigten Erweiterungen ausgeschaltet werden.

#### 23.2 .vscode/extensions.json

```json
{
  "recommendations": [
    "ms-vscode.cpptools",
    "ms-vscode.cmake-tools"
  ]
}
```

#### 23.3 Ressourcenschonende .vscode/settings.json

```json
{
  "cmake.useCMakePresets": "always",
  "cmake.configureOnOpen": false,
  "cmake.configureOnEdit": false,
  "cmake.automaticReconfigure": false,
  "files.watcherExclude": {
    "**/build/**": true,
    "**/cmake-build-*/**": true,
    "**/_deps/**": true
  },
  "search.exclude": {
    "**/build/**": true,
    "**/cmake-build-*/**": true,
    "**/_deps/**": true
  },
  "C_Cpp.intelliSenseCacheSize": 0
}
```

Die automatischen Configure-Laeufe sind aus, damit das Speichern einer
`CMakeLists.txt` nicht unerwartet Git-Abrufe, Neuindizierung oder Builds
ausloest. Configure wird bewusst ueber die Command Palette gestartet.

`C_Cpp.intelliSenseCacheSize: 0` deaktiviert den auf dem Datentraeger liegenden
IntelliSense-Headercache. Das spart Platz und Schreibzugriffe, kann aber mehr
Neu-Parsing und CPU-Zeit verursachen. Wenn die Interaktion dadurch zu langsam
wird, wird diese Einstellung entfernt oder mit einem bewusst begrenzten Wert
versehen. Der Build selbst wird davon nicht beeinflusst.

#### 23.4 Terminal-First-Modus

Die leichteste und transparenteste Variante verwendet VS Code nur zum Editieren
und das integrierte Terminal fuer die bereits dokumentierten Befehle:

```bash
cmake --preset macos-debug
cmake --build --preset macos-debug
./build/macos-debug/mein_tvision_programm
```

Auf Linux und Windows werden die entsprechenden Presetnamen und Startpfade
verwendet. Dieser Modus benoetigt keine `tasks.json` und vermeidet doppelte
Buildlogik.

#### 23.5 CMake-Tools-Modus

1. Workspace als vertrauenswuerdig bestaetigen, nachdem Quelle und
   `CMakeLists.txt` geprueft wurden.
2. Command Palette oeffnen.
3. `CMake: Select Configure Preset` waehlen.
4. Das zum Betriebssystem passende Debug-Preset waehlen.
5. `CMake: Configure` ausfuehren.
6. `CMake: Set Build Target` auf `mein_tvision_programm` setzen.
7. `CMake: Build` ausfuehren.
8. Das Programm im integrierten Terminal mit seinem realen Pfad starten.

Fuer TUI-Anwendungen ist der Terminalstart der Standard. Ein Debug- oder
Output-Fenster, das keine vollwertige Terminalemulation bereitstellt, ist kein
geeigneter Funktionsnachweis fuer Farben, Tastatur, Groessenaenderung und Maus.

#### 23.6 IntelliSense aus CMake beziehen

Das Preset setzt `CMAKE_EXPORT_COMPILE_COMMANDS=ON`. CMake Tools kann die
Compilerkonfiguration an die Microsoft-C/C++-Erweiterung liefern. Falls
Includes trotzdem rot markiert sind:

1. `CMake: Configure` erfolgreich abschliessen.
2. `C/C++: Change Configuration Provider` oeffnen.
3. CMake Tools als Provider waehlen.
4. Erst danach die IntelliSense-Datenbank zuruecksetzen.

Manuell rekursive Include-Pfade auf den ganzen `_deps`-Baum zu setzen ist auf
einem kleinen Rechner keine gute erste Loesung.

### 24. VS Code unter macOS, Linux und Windows

#### 24.1 macOS

1. Im Terminal des Projektordners `code --profile "C++ Light" .` starten.
2. AppleClang, CMake und Ninja im integrierten Terminal pruefen.
3. `macos-debug` konfigurieren und bauen.
4. `./build/macos-debug/mein_tvision_programm` im Terminal starten.
5. Fuer den Release-Kontrollpunkt auf `macos-release` wechseln.

Wenn VS Code aus dem Finder gestartet wurde und einen anderen `PATH` sieht als
Terminal.app, ist der Start mit `code .` aus der bereits funktionierenden Shell
der einfachste Vergleich.

#### 24.2 Linux

1. GCC/Clang, GDB/LLDB, CMake, Ninja und ncursesw-Header pruefen.
2. VS Code mit dem Profil `C++ Light` oeffnen.
3. `linux-debug` konfigurieren und bauen.
4. Die TUI in der integrierten Shell starten.
5. Darstellung zusaetzlich in einem nativen Terminal pruefen, falls die
   integrierte Terminalemulation abweicht.

#### 24.3 Windows mit MSVC

VS Code wird am zuverlaessigsten aus einer Developer PowerShell gestartet:

```powershell
code --profile "C++ Light" .
```

Dadurch erbt das integrierte Terminal die MSVC-Umgebung. Alternativ kann CMake
Tools die Visual-Studio-Entwicklungsumgebung erkennen; der Kommandozeilencheck
mit `cl` bleibt trotzdem der eindeutige Nachweis.

Danach werden `windows-debug` und `windows-release` verwendet. Die Anwendung
wird in PowerShell mit dem Call-Operator gestartet:

```powershell
& .\build\windows-debug\mein_tvision_programm.exe
```

#### 24.4 Windows mit MinGW

VS Code muss den gleichen MinGW-`PATH` sehen wie die getestete Shell. Das
Preset bleibt gleich, aber der frische Buildbaum wird mit MinGW konfiguriert.
MSVC- und MinGW-Ergebnisse bleiben in getrennten Verzeichnissen.

### 25. Debugging von TUI-Programmen

Ein TUI veraendert waehrend der Laufzeit den Terminalzustand. Haltepunkte
koennen deshalb einen scheinbar unvollstaendigen oder beschaedigten Bildschirm
hinterlassen. Das ist nicht automatisch ein Fehler in `tvision`.

Empfohlene Reihenfolge:

1. Programm zuerst ohne Debugger in einem echten Terminal starten.
2. Start, Dialog, Tastatur, Resize und sauberes Beenden pruefen.
3. Erst danach einen Debug-Build mit CLion oder VS Code starten.
4. Haltepunkte bevorzugt vor der TUI-Initialisierung oder in klaren
   Ereignisbehandlern setzen.
5. Nach einem harten Abbruch bei Bedarf ein neues Terminal oeffnen oder dessen
   Zustand zuruecksetzen.

Unter macOS wird LLDB, unter Linux typischerweise GDB oder LLDB und unter
Windows der zur Toolchain passende MSVC- oder GDB-Debugadapter verwendet. Die
Debuggerwahl darf den Compiler- und ABI-Vertrag des Buildbaums nicht
unbemerkt aendern.

### 26. 8-GB-RAM- und Small-Disk-Profil

Das MacBook Air 2023 in diesem Szenario hat 8 GB RAM. Der Build ist damit gut
moeglich, wenn IDE, Parallelitaet und Buildbaeume bewusst begrenzt werden.

#### 26.1 Verbindlicher Startwert

- maximal zwei parallele Compiler-Jobs;
- bei Swap-Druck oder gleichzeitigem Videokonferenz-/Browserbetrieb nur ein
  Job;
- `TV_BUILD_EXAMPLES=OFF`;
- `TV_BUILD_TESTS=OFF` fuer das Anwendungsprojekt;
- `TV_BUILD_USING_GPM=OFF`;
- `TV_LIBRARY_UNITY_BUILD=OFF`;
- nur Debug dauerhaft behalten;
- Release nur fuer Kontrollpunkte bauen;
- nicht CLion, VS Code und Visual Studio gleichzeitig denselben Quellbaum
  indizieren lassen.

#### 26.2 PCH-Entscheidung

`TV_OPTIMIZE_BUILD=ON` aktiviert bei geeigneter CMake-Version vorkompilierte
Header. Das beschleunigt typischerweise Wiederholungsbuilds, benoetigt aber
einen zusaetzlichen PCH-Artefaktbestand.

Fuer maximale Platzersparnis kann im eigenen `CMakeLists.txt` stehen:

```cmake
set(TV_OPTIMIZE_BUILD OFF CACHE BOOL "Use tvision precompiled headers" FORCE)
```

Danach wird ein neuer Buildbaum erzeugt. Ein bestehender PCH-Buildbaum wird
nicht als belastbarer Groessenvergleich umkonfiguriert. Die Wahl lautet:

- PCH **an**: besser fuer haeufige inkrementelle Builds;
- PCH **aus**: weniger Cache-Artefakte, aber mehr Compilerarbeit.

#### 26.3 Unity Build bewusst auslassen

Unity Build kann Compile-Overhead reduzieren, fasst aber viele Quelldateien in
groessere Uebersetzungseinheiten zusammen. Auf 8 GB RAM koennen dadurch hoehere
Speicherspitzen entstehen. Es bleibt deshalb `OFF`, solange keine Messung auf
dem konkreten Rechner einen Vorteil nachweist.

#### 26.4 Keine parallelen IDE-Indexer

Wenn CLion verwendet wird, bleibt VS Code geschlossen. Fuer einen
ressourcenschonenden VS-Code-Tag wird CLion beendet. Browser-Tabs, Container,
virtuelle Maschinen und lokale KI-Modelle koennen deutlich mehr RAM als der
eigentliche CMake-Build verbrauchen und werden bei Speicherdruck zuerst
reduziert.

#### 26.5 Build nur fuer das Anwendungsziel

```bash
cmake --build build/macos-debug \
  --target mein_tvision_programm \
  --parallel 2
```

CMake baut `tvision` transitiv. Ein separates `all`, die tvision-Demos oder
Tests werden nicht benoetigt.

#### 26.6 Lokaler Orientierungsnachweis

Das kopierbare Starterprojekt wurde auf dem aktuellen Apple-Silicon-Mac mit
8 GB RAM, AppleClang, C++17 fuer die Anwendung, Debug-Konfiguration und zwei
parallelen Jobs vollstaendig kompiliert. Der Buildbaum belegte im
Validierungsaufbau rund 73 MiB; der separate lokale `tvision`-Quellcheckout war
darin nicht enthalten. Ein unveraenderter inkrementeller Kontrollbuild dauerte
rund 1,6 Sekunden. Diese Werte sind Orientierung fuer genau diesen Rechner und
kein garantierter Grenzwert fuer andere Toolchains oder spaetere Fork-Staende.

### 27. Speicherplatz kontrollieren und sicher freigeben

#### 27.1 Belegung ansehen

macOS/Linux:

```bash
du -sh build/* 2>/dev/null
df -h .
```

PowerShell:

```powershell
Get-ChildItem .\build -Directory |
  ForEach-Object {
    $bytes = (Get-ChildItem $_.FullName -Recurse -File |
      Measure-Object Length -Sum).Sum
    [PSCustomObject]@{ Name = $_.Name; MiB = [math]::Round($bytes / 1MB, 1) }
  }
```

#### 27.2 Leichter Clean

```bash
cmake --build build/macos-debug --target clean
```

Dies entfernt viele Kompilate, behaelt aber CMake- und FetchContent-Struktur.
Der naechste Build braucht deshalb weniger Netzwerkvorbereitung, muss jedoch
neu kompilieren.

#### 27.3 Vollstaendigen einzelnen Buildbaum entfernen

Vorher Quellwurzel und Zielnamen kontrollieren. Danach kann CMake
plattformuebergreifend genau den benannten Buildbaum entfernen:

```bash
cmake -E remove_directory "build/macos-release"
```

Windows PowerShell verwendet denselben CMake-Befehl:

```powershell
cmake -E remove_directory "build/windows-release"
```

Nie `build/`, das Repository oder ein Home-Verzeichnis durch eine leere
Variable, einen unkontrollierten Platzhalter oder einen breiten rekursiven
Loeschbefehl ersetzen. Bei Platzmangel wird zuerst ein klar benannter alter
Release-Buildbaum entfernt.

#### 27.4 FetchContent nicht nach jedem Build loeschen

`build/<preset>/_deps/tvision-src` ist regenerierbar. Eine Loeschung nach jedem
Build spart kurzfristig Platz, erzwingt aber spaeter erneuten Download,
Configure und Vollbuild. Auf einem kleinen Rechner ist ein einzelner aktiver
Debug-Buildbaum meist der bessere Kompromiss.

### 28. CLI-, CLion-, VS-Code- und Visual-Studio-Paritaet

Alle vier Oberflaechen gelten nur dann als gleichwertig, wenn sie denselben
CMake-Vertrag verwenden:

| Aspekt | CLion | Kommandozeile | VS Code Light | Visual Studio Community |
|---|---|---|---|---|
| Quelle | gleicher Commit | gleicher Commit | gleicher Commit | gleicher Commit |
| tvision | gleiche SHA | gleiche SHA | gleiche SHA | gleiche SHA |
| Configure | Profil/Presets | `cmake --preset` | CMake Tools | CMake Presets |
| Build | Zielauswahl | `cmake --build` | CMake Tools | CMake Targets |
| Jobs | Profil/Buildtool | `--parallel 2` | zwei Jobs | zwei Jobs |
| TUI-Start | Terminal | natives Terminal | Terminal | Terminal |
| Buildbaum | IDE-spezifisch | `build/<preset>` | `build/<preset>` | `build/<preset>` |

Ein erfolgreicher CLion-Build rechtfertigt keine handgeschriebenen abweichenden
Compilerflags fuer VS Code. Umgekehrt ersetzt ein direkter `g++`-Einzeiler
nicht den CMake-Vertrag, weil transitive Includes, Optionen und
Systembibliotheken dann leicht auseinanderlaufen.

### 29. Vollstaendiger persoenlicher Arbeitsablauf

#### 29.1 Neues Programm auf macOS beginnen

1. Repository mit `CMakeLists.txt`, `src/main.cpp`, `.gitignore` und optionalen
   Presets anlegen.
2. Vollstaendige getestete Fork-SHA eintragen.
3. In CLion oder VS Code Light oeffnen.
4. `macos-debug` mit maximal zwei Jobs konfigurieren und bauen.
5. TUI im Terminal starten und Bedienung pruefen.
6. Anwendung entwickeln und regelmaessig inkrementell bauen.
7. `macos-release` am Kontrollpunkt bauen und starten.
8. Nur Quell- und Konfigurationsdateien committen.

#### 29.2 Auf Windows pruefen

1. Denselben Anwendungscommit auschecken.
2. MSVC oder MinGW bewusst auswaehlen; fuer MSVC optional CLion, VS Code oder
   Visual Studio Community verwenden.
3. Bei Visual Studio Community zusaetzlich VS 2022/v143 oder VS 2026/v145
   bewusst waehlen und einen frischen, versionsgebundenen Buildbaum
   konfigurieren.
4. Debug und Release mit maximal zwei Jobs bauen.
5. TUI in Windows Terminal oder im echten integrierten Terminal starten.
6. Plattformkorrekturen in der Anwendung committen.

#### 29.3 Auf Linux pruefen

1. Denselben Anwendungscommit einschliesslich Windows-Korrekturen auschecken.
2. ncursesw-Entwicklungsdateien und Toolchain pruefen.
3. Frischen Linux-Buildbaum konfigurieren.
4. Debug und Release bauen.
5. TUI in einer UTF-8-Terminalumgebung pruefen.
6. Gemeinsamen Stand erst danach als drei-plattform-faehig behandeln.

#### 29.4 Nach einer Fork-Synchronisierung

Nur die `GIT_TAG`-SHA wird zunaechst in einem Pilotprojekt geaendert. Der neue
Stand durchlaeuft macOS Debug/Release sowie die nativen Windows- und
Linux-Kontrollen. Weitere Programme uebernehmen die SHA erst danach.

### 30. Erweiterte Fehlerdiagnose fuer CMake, VS Code und Visual Studio

#### 30.1 CMake hat den falschen Compiler gewaehlt

```bash
cmake -N -L build/macos-debug | rg 'CMAKE_(C|CXX)_COMPILER'
```

Unter Windows kann alternativ die `CMakeCache.txt` kontrolliert werden. Ist der
Compiler falsch, wird nicht nur eine einzelne Cachezeile editiert. Die richtige
Toolchain-Shell wird aktiviert und ein neuer Buildbaum konfiguriert.

#### 30.2 Ninja fehlt

Wenn `ninja --version` scheitert, entweder Ninja installieren beziehungsweise
in den Toolchain-Pfad aufnehmen oder einen vorhandenen Generator bewusst
waehlen. Nur `-G Ninja` aus dem Befehl zu entfernen, waehrend ein bestehender
Ninja-Buildbaum weiterverwendet wird, ist keine gueltige Umstellung.

#### 30.3 FetchContent wiederholt den Download

Pruefen, ob jedes Configure einen neuen Buildpfad verwendet, ein Cleanup-Tool
`_deps` entfernt oder der Buildbaum auf einem fluechtigen Datentraeger liegt.
Ein stabiler Debug-Buildpfad vermeidet unnoetige Abrufe.

#### 30.4 VS Code zeigt Includes als Fehler, CMake baut aber erfolgreich

Der Compilerbuild ist kanonisch. CMake Tools als Konfigurationsprovider
waehlen, Configure abschliessen und erst danach die IntelliSense-Datenbank
zuruecksetzen. Keine produktiven Include-Pfade nur zur Beruhigung des Editors
veraendern.

#### 30.5 TUI startet und beendet sich sofort

Programm aus einem echten Terminal statt aus einem nicht interaktiven
Ausgabefenster starten. Rueckgabecode und Standardfehler pruefen. Unter Unix
`TERM` und Locale, unter Windows die aktive Konsole und Toolchain kontrollieren.

#### 30.6 Der Rechner beginnt stark zu swappen

1. Build abbrechen, ohne Buildbaum zu loeschen.
2. Parallele IDE, Browser- oder Containerlast reduzieren.
3. Mit `--parallel 1` fortsetzen.
4. Unity Build ausgeschaltet lassen.
5. Erst danach PCH aus- oder andere Buildoptionen umstellen.

#### 30.7 Der Datentraeger wird knapp

1. Groesse einzelner Buildbaeume messen.
2. Alten Release-Buildbaum entfernen.
3. Nicht mehr verwendete Toolchainvarianten entfernen.
4. VS-Code-IntelliSense-Cache begrenzen oder deaktivieren.
5. Aktiven Debug-Buildbaum als letzten Buildcache behalten.
6. vcpkg- und globale Compiler-Caches nur nach separater Zielpruefung anfassen.

#### 30.8 Visual Studio verwendet die falsche Instanz

Im betroffenen `CMakeCache.txt` die Werte `CMAKE_GENERATOR`,
`CMAKE_GENERATOR_INSTANCE`, `CMAKE_GENERATOR_PLATFORM` und
`CMAKE_GENERATOR_TOOLSET` pruefen. Danach den falschen Buildbaum nicht
umkonfigurieren, sondern das passende lokale User-Preset mit eigenem
`binaryDir` verwenden. Bei mehreren Instanzen derselben Generation darf
`CMAKE_GENERATOR_INSTANCE` nur lokal auf den eindeutigen Installationspfad
zeigen.

### 31. Dokumentationsauswirkung

- Entscheidung: `UpdateRequired`.
- Kanonische technische Quelle: `CMakeLists.txt`, `source/CMakeLists.txt` und
  die dort definierten CMake-Ziel- und Abhaengigkeitsvertraege des
  Level-2-Repositories.
- Dokumente: diese Entwickleranleitung sowie das eigenstaendige, kopierbare
  Calculator-Beispiel unter `docs/examples/tvision-calculator/`.
- Owner: Repository-Maintainer.
- Zielgruppe und Leserpfad: Entwickler startet mit Zweck und Voraussetzungen,
  bindet den festen Commit ein, waehlt CLion, CMake-Kommandozeile, VS Code Light
  oder unter Windows Visual Studio Community und fuehrt danach die nativen
  macOS-, Windows- und Linux-Kontrollen aus.
- Sprachstrategie: Deutsch primaer, inhaltlich entsprechender englischer Teil
  in derselben Datei.
- Plattformnachweis: Die dokumentierte FetchContent-Einbindung und der
  Calculator wurden lokal mit AppleClang unter macOS konfiguriert, gebaut,
  getestet und in einem interaktiven Terminal gestartet. Ein dauerhafter
  Matrixjob baut den Calculator und testet seine Engine zusaetzlich unter
  macOS, Linux und Windows. Zwei explizite Windows-Jobs weisen den
  vollstaendigen Calculator-Build mit Visual Studio 2022/v143 und Visual Studio
  2026/v145 nach.
- Repository-spezifisches Distributionsmodell: Quellcode-Abhaengigkeit ueber
  `FetchContent`; keine separate Runtime-, Installations- oder Home-Sync-Kopie.
- Navigationseinfluss: direkter Guide unter `docs/`, dessen Pfad im Handoff
  genannt wird; keine Aenderung der bestehenden englischen Upstream-README.
- Re-Evaluation-Trigger: Aenderung des `tvision`-CMake-Ziels, der
  FetchContent- oder Preset-Kompatibilitaet, der unterstuetzten Plattformen,
  der CLion-CMake-/Toolchain-Oberflaechen, der Microsoft-C/C++- und
  CMake-Tools-Erweiterungen fuer VS Code oder der Visual-Studio-/MSVC-/CMake-
  Generatorvertraege.
- Evidence: erfolgreicher lokaler FetchContent-Configure-, Build-, CTest- und
  Startnachweis unter macOS, der Drei-OS-Calculator-Matrixjob, die expliziten
  VS-2022-/VS-2026-Generatorjobs sowie der Abgleich mit den lokalen
  CMake-Ziel-, Installations- und Exportregeln und den verlinkten offiziellen
  CMake-, JetBrains-, Microsoft- und VS-Code-Referenzen.

## English

### 1. Purpose and audience

This guide explains in extensive detail how to consume the personal
[`hindermath/tvision`](https://github.com/hindermath/tvision) fork in custom
CMake applications using JetBrains CLion, the CMake command line, and Visual
Studio Code as a lighter editor on macOS, Windows, and Linux. On Windows, it
also covers Microsoft Visual Studio Community 2022 and 2026 as native full
IDEs.

It assumes the following working model:

- The personal `tvision` fork is a stable dependency and is not developed
  functionally.
- Fork changes only come from deliberately adopted updates from
  [`magiblot/tvision`](https://github.com/magiblot/tvision).
- macOS is normally the develop-first system.
- Windows and Linux subsequently build and verify the same revision natively.
- CLion is the standard IDE on all three operating systems.
- The CMake command line is the IDE-independent reference workflow.
- VS Code is the lighter graphical alternative for machines with constrained
  memory or disk space.
- Microsoft Visual Studio Community is the optional native full Windows IDE;
  it does not replace the shared CMake contract or CLion's cross-platform
  standard role.
- The MacBook Air 2023 with 8 GB RAM is the concrete low-resource example; 8 MB
  would not be realistic for this toolchain.
- Every application pins one complete, tested commit of the personal fork.

The safe first action is to identify the required fork commit and pin it in
the application's `CMakeLists.txt`.

### 2. Core decision: distribute a source revision, not copied binaries

`tvision` produces a static library. A compiled static library is nevertheless
not interchangeable across operating systems, CPU architectures, or arbitrary
compiler toolchains.

| Target and toolchain | Typical result |
|---|---|
| macOS with AppleClang | `libtvision.a` containing Mach-O objects |
| Linux with GCC or Clang | `libtvision.a` containing ELF objects |
| Windows with MSVC | `tvision.lib` containing COFF objects |
| Windows with MinGW | `libtvision.a` containing MinGW-compatible objects |

The `.a` extension alone does not make the same file usable on macOS and
Linux. Debug/Release configuration, architecture, compiler ABI, and runtime
library must match as well.

The personal distribution model is therefore:

```text
hindermath/tvision at one pinned commit
                |
                +--> CLion/macOS   --> native libtvision.a --> macOS app
                |
                +--> CLion/Linux   --> native libtvision.a --> Linux app
                |
                +--> CLion/Windows --> native .lib/.a      --> Windows app
```

The source revision is shared and reproducible. Each build result remains
local and platform-specific.

### 3. Recommended default: CMake FetchContent

`FetchContent` is the recommended default for this model because the
application records the exact dependency revision, CLion builds it with the
active native toolchain, no global installation is required, no binary archive
is committed, and update or rollback only changes a commit ID.

#### 3.1 Example application structure

```text
my-application/
|-- CMakeLists.txt
|-- src/
|   `-- main.cpp
`-- .gitignore
```

CLion build directories such as `cmake-build-debug/`,
`cmake-build-release/`, or a project-specific `build/` must not be committed.

#### 3.2 Complete CMake integration

```cmake
cmake_minimum_required(VERSION 3.15)

project(MyApplication LANGUAGES CXX)

include(FetchContent)

# The application needs the library only.
set(TV_BUILD_EXAMPLES OFF CACHE BOOL "Build tvision examples" FORCE)
set(TV_BUILD_TESTS OFF CACHE BOOL "Build tvision tests" FORCE)

# Linux: disable the optional GPM dependency for a more uniform three-platform
# workflow. ncursesw remains required.
set(TV_BUILD_USING_GPM OFF CACHE BOOL "Use GPM on Linux" FORCE)

FetchContent_Declare(
    tvision
    GIT_REPOSITORY https://github.com/hindermath/tvision.git
    GIT_TAG        0123456789abcdef0123456789abcdef01234567
    GIT_PROGRESS   TRUE
)

FetchContent_MakeAvailable(tvision)

add_executable(my_application
    src/main.cpp
)

# The application may require a higher C++ standard than the dependency.
# This example uses C++17.
target_compile_features(my_application PRIVATE cxx_std_17)

target_link_libraries(my_application PRIVATE tvision::tvision)
```

Replace the sample SHA with a real complete commit from the fork. An immutable
commit ID is preferable to a moving branch such as `master`, so later builds
remain reproducible after another upstream synchronization.

The current remote branch commit can be queried with:

```bash
git ls-remote https://github.com/hindermath/tvision.git refs/heads/master
```

This command works in macOS and Linux terminals and in PowerShell when Git is
installed and available on the search path.

#### 3.3 Source usage

```cpp
#include <tvision/tv.h>

int main()
{
    return 0;
}
```

Include paths and transitive link information are supplied by the
`tvision::tvision` CMake target. Absolute include paths and manual
`target_link_directories()` calls are unnecessary.

### 4. What CLion does on first load

```text
CLion selects a CMake profile and toolchain
                  |
                  v
CMake configures the application
                  |
                  v
FetchContent retrieves the pinned tvision commit
                  |
                  v
CMake adds the tvision::tvision target
                  |
                  v
CLion builds the static library and then the application
```

A typical build directory contains:

```text
cmake-build-debug/
|-- _deps/
|   |-- tvision-src/
|   `-- tvision-build/
|-- CMakeCache.txt
`-- ...
```

The first clean configure requires network access to GitHub. The retrieved
revision then remains available in that build directory. A deleted build
directory or a different machine requires another fetch.

Building the application target automatically builds `tvision` first. The
library target normally does not need to be built separately in CLion.

### 5. Shared CLion setup

CLion separates toolchains from CMake profiles. The toolchain selects the
compiler, build tool, and debugger. The CMake profile selects the toolchain,
build type, build directory, and CMake options.

Use `Settings | Build, Execution, Deployment | Toolchains` and
`Settings | Build, Execution, Deployment | CMake`. On macOS, open the settings
dialog from the CLion application menu. The same actions are available through
`Find Action` on every platform.

Create at least two local profiles on each operating system:

| Profile | Build type | Purpose |
|---|---|---|
| Debug | `Debug` | daily development and debugging |
| Release | `Release` | optimized verification and delivery build |

Every profile uses a separate build directory. Debug and Release artifacts or
results from different compilers must not share a build directory.

Reload the CMake project after changing `CMakeLists.txt` or the pinned commit.
If the old dependency remains in an inconsistent cache, use
`Tools | CMake | Reset Cache and Reload Project`. This does not require deleting
the source repository or unrelated files.

Current references:

- [JetBrains: CMake profiles](https://www.jetbrains.com/help/clion/cmake-profile.html)
- [JetBrains: Toolchains](https://www.jetbrains.com/help/clion/how-to-create-toolchain-in-clion.html)
- [JetBrains: Load/reload CMake](https://www.jetbrains.com/help/clion/reloading-project.html)
- [CMake: FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html)
- [CMake: Presets](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html)
- [VS Code: CMake Tools](https://github.com/microsoft/vscode-cmake-tools/blob/main/docs/README.md)
- [VS Code: C/C++ on macOS](https://code.visualstudio.com/docs/cpp/config-clang-mac)
- [VS Code: C/C++ on Linux](https://code.visualstudio.com/docs/cpp/config-linux)
- [VS Code: Command-line interface](https://code.visualstudio.com/docs/configure/command-line)
- [VS Code C/C++: IntelliSense cache](https://code.visualstudio.com/docs/cpp/faq-cpp)
- [Microsoft: C++ Build Tools command line](https://learn.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-170)

### 6. macOS as the develop-first system

macOS is the normal starting point for new functionality in custom
applications. macOS binaries are not forwarded to Windows or Linux. Only the
application's Git commits and their pinned `tvision` commit ID are shared.

#### 6.1 Toolchain

Recommended local setup:

- AppleClang from Xcode or the Xcode Command Line Tools
- CLion-detected or bundled CMake
- Ninja when selected as the build tool
- LLDB as debugger

CLion validates the selected toolchain and reports missing tools in the
toolchain settings.

#### 6.2 Daily workflow

1. Open the application repository in CLion.
2. Select the `Debug` profile.
3. Let CMake configure the project and complete FetchContent.
4. Build, run, and debug the application target.
5. Run relevant application tests on macOS.
6. Commit source, CMake, and required documentation only; do not commit build
   directories or static libraries.
7. Verify the same application commit on Windows and Linux.

#### 6.3 Release verification on macOS

Build the CLion `Release` profile before cross-platform verification. This
exposes failures caused by optimization or different debug macros.

### 7. Linux as a native verification system

#### 7.1 Toolchain

A typical local CLion toolchain uses GCC or Clang, Ninja or Make, GDB or LLDB,
and CMake. The compiler family may be chosen deliberately per machine. A macOS
archive is never reused.

#### 7.2 System dependency

On Linux, `tvision` requires the wide-character ncurses library and its
development headers. The package name depends on the distribution. If it is
missing, CMake reports that `ncursesw` or the corresponding headers cannot be
found.

This guide disables `TV_BUILD_USING_GPM` because GPM is optional for this
uniform personal workflow. Enable it only in the Linux profile when it is
explicitly required and the development library is installed.

#### 7.3 Verification

1. Check out exactly the same application commit used on macOS.
2. Configure and build the Linux `Debug` profile.
3. Run the application and relevant tests in a real Linux terminal.
4. Build the `Release` profile.
5. Correct platform differences in the application; never copy or rename the
   macOS library.

### 8. Windows as a native verification system

#### 8.1 Choose one toolchain deliberately

CLion supports MSVC and MinGW toolchains on Windows. Choose and retain one
variant for a project:

- MSVC typically produces `tvision.lib`.
- MinGW typically produces `libtvision.a`.
- The artifacts are not interchangeable.

Create a new CMake profile with its own build directory when switching between
MSVC and MinGW. Do not reuse a cache generated by the other toolchain.

Keep `TV_USE_STATIC_RTL` at its default `OFF`. This option controls the MSVC
C/C++ runtime, not whether `tvision` itself is static. Enable it only when the
whole application and every relevant dependency consistently use the static
MSVC runtime.

#### 8.2 Verification

1. Check out exactly the same application commit used on macOS.
2. Select the established Windows toolchain in CLion.
3. Configure, build, run, and debug the `Debug` profile.
4. Verify the application in a real Windows terminal environment.
5. Build and run the `Release` profile.

No separate `tvision.dll` is required next to the linked application. Operating
system libraries or the selected compiler runtime may still be dynamic.

### 9. Cross-platform develop-first cycle

```text
1. macOS / CLion / Debug
   Implement, build, run, debug, and test
                       |
                       v
2. macOS / CLion / Release
   Verify the optimized build
                       |
                       v
3. Create the application commit
   Do not include build artifacts
                       |
             +---------+---------+
             |                   |
             v                   v
4. Windows / CLion         5. Linux / CLion
   Debug + Release            Debug + Release
             |                   |
             +---------+---------+
                       v
6. Treat the shared revision as viable after native verification
```

All three builds use the same application source and pinned `tvision` commit,
but three independent native library artifacts.

### 10. Upstream updates of the personal fork

The fork is not updated automatically from application builds. Adopting an
upstream change is a separate, deliberate maintenance operation.

#### 10.1 Safe update workflow

1. Keep the existing `tvision` commit pinned in applications.
2. Synchronize the personal fork with the selected `magiblot/tvision` state.
3. Build and verify the updated fork separately on the intended platforms.
4. Obtain the complete new fork commit ID.
5. Update only `GIT_TAG` in one application on macOS first.
6. Reload CMake in CLion and verify Debug and Release.
7. Verify the same application commit on Windows and Linux.
8. Only then update additional applications to the new commit ID.

#### 10.2 Rollback

If an upstream update affects an application, restore the previously known
commit ID in `GIT_TAG` and reload CMake. The previous revision remains
traceable, with no need to locate an old binary archive.

#### 10.3 Why not use `master`?

A branch name refers to a moving revision. A build could silently consume
different sources after a later fork synchronization even if the application
repository did not change. A complete commit ID binds exactly the verified
content.

### 11. Runtime and distribution of custom applications

Static linking incorporates the required `tvision` objects into the custom
application. The headers and locally built library remain necessary for
development, rebuilding, and debugging inside the CLion build directory. A
separate `tvision` library file is not needed merely to launch the finished
application.

The application is still platform-specific and must be built independently:

```text
my-application-macos
my-application-linux
my-application-windows.exe
```

System libraries, compiler runtimes, and other dependencies require a separate
assessment when the application itself is distributed.

### 12. Optional alternative: one installation per machine

When many custom applications use the same revision and repeated compilation
is undesirable, install the fork once with CMake on each machine. The
installation remains separate per operating system, architecture, compiler,
and configuration.

Applications then use:

```cmake
find_package(tvision CONFIG REQUIRED)
target_link_libraries(my_application PRIVATE tvision::tvision)
```

Expose the local prefix through `CMAKE_PREFIX_PATH` in the platform's CLion
CMake profile. This reduces repeated builds but adds manual maintenance:

- Every machine needs a matching installation.
- An upstream synchronization requires a rebuild and reinstall.
- Debug, Release, and toolchain variants must remain consistent.
- The application repository alone no longer proves which local installation
  was consumed unless an additional version rule exists.

For reproducible personal projects, pinned FetchContent remains the default.

### 13. Why vcpkg is not the default here

The public `tvision` vcpkg port does not automatically reference the personal
fork. Pinning that fork would require a custom overlay port or registry. This
may be useful for a larger C++ dependency landscape and binary caching, but it
adds version and maintenance surfaces without eliminating native builds. vcpkg
would still produce target-specific artifacts for each triplet.

### 14. Troubleshooting

#### 14.1 FetchContent cannot retrieve the fork

Check network access to the repository, the complete `GIT_TAG` commit ID, Git
availability in the active CLion environment, and the concrete Git or TLS
error in the CLion CMake tool window.

#### 14.2 The previous revision remains after changing the commit

Reload the CMake project first. If the cache remains inconsistent, use
`Reset Cache and Reload Project`. Recreate only the affected local build
directory as a last step; leave source repositories and Git history intact.

#### 14.3 Linux cannot find ncursesw

Install the ncursesw development library and headers through the distribution's
package manager. The exact package name is intentionally not hard-coded because
it varies by distribution and version.

#### 14.4 Windows reports incompatible object or library formats

Check whether the CMake profile and build directory were previously used with
a different toolchain, especially MSVC versus MinGW. Create a new profile with
its own build directory and configure again.

#### 14.5 Debug succeeds but Release fails

Inspect the complete Release linker output and do not mix Debug and Release
libraries manually. FetchContent builds the dependency per profile, so no
library path from another CLion profile should be added.

### 15. Short checklist

- [ ] The fork only receives controlled upstream updates.
- [ ] `GIT_TAG` contains a complete commit ID, not `master`.
- [ ] `TV_BUILD_EXAMPLES` and `TV_BUILD_TESTS` are disabled for the app.
- [ ] `TV_BUILD_USING_GPM` is disabled for the uniform default.
- [ ] CLion uses separate Debug and Release profiles.
- [ ] Every toolchain has its own build directory.
- [ ] macOS is develop-first but not the only platform evidence.
- [ ] The same application commit is built natively on Windows and Linux.
- [ ] No `.a`, `.lib`, `_deps`, or CLion build directories are committed.
- [ ] A new upstream commit is adopted by other applications only after native
      platform verification.

### 16. Complete TUI starter project

The following repository creates an actual terminal dialog and is shared by
the CLion, command-line, and VS Code workflows.

#### 16.1 Directory structure

```text
my-tvision-application/
|-- .gitignore
|-- CMakeLists.txt
|-- CMakePresets.json        optional but recommended
|-- .vscode/
|   |-- extensions.json
|   `-- settings.json
`-- src/
    `-- main.cpp
```

#### 16.2 CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.15)

project(MyTvisionApplication VERSION 0.1.0 LANGUAGES CXX)

include(FetchContent)

set(TV_BUILD_EXAMPLES OFF CACHE BOOL "Build tvision examples" FORCE)
set(TV_BUILD_TESTS OFF CACHE BOOL "Build tvision tests" FORCE)
set(TV_BUILD_USING_GPM OFF CACHE BOOL "Use GPM on Linux" FORCE)
set(TV_LIBRARY_UNITY_BUILD OFF CACHE BOOL "Use tvision unity build" FORCE)
set(TV_OPTIMIZE_BUILD ON CACHE BOOL "Use tvision precompiled headers" FORCE)

FetchContent_Declare(
    tvision
    GIT_REPOSITORY https://github.com/hindermath/tvision.git
    GIT_TAG        0123456789abcdef0123456789abcdef01234567
    GIT_PROGRESS   TRUE
)

FetchContent_MakeAvailable(tvision)

add_executable(my_tvision_application
    src/main.cpp
)

target_compile_features(my_tvision_application PRIVATE cxx_std_17)
target_link_libraries(my_tvision_application PRIVATE tvision::tvision)
```

Replace the sample SHA before the first configure. Use
`git rev-parse origin/master` in a clone or `git ls-remote` to obtain the full
fork commit.

#### 16.3 src/main.cpp

```cpp
#define Uses_TApplication
#define Uses_TButton
#define Uses_TDeskTop
#define Uses_TDialog
#define Uses_TRect
#define Uses_TStaticText
#include <tvision/tv.h>

class Application final : public TApplication
{
public:
    Application() noexcept :
        TProgInit(
            &Application::initStatusLine,
            &Application::initMenuBar,
            &Application::initDeskTop
        )
    {
    }

    ~Application() override = default;
};

int main()
{
    Application application;

    auto *dialog = new TDialog(
        TRect(0, 0, 46, 11),
        "My first tvision application"
    );

    dialog->insert(new TStaticText(
        TRect(3, 3, 43, 5),
        "Built with CMake for this operating system."
    ));

    dialog->insert(new TButton(
        TRect(16, 7, 30, 9),
        "~O~K",
        cmOK,
        bfDefault
    ));

    application.deskTop->execView(dialog);
    TObject::destroy(dialog);
    return 0;
}
```

The `Uses_...` macros precede `<tvision/tv.h>` and select the declarations
included by the central header. Since the `TApplication` constructor and
destructor are protected, the small derived class exposes them in a controlled
way for this application. `TProgInit` binds the inherited default factories for
the status line, menu bar, and desktop. The modal dialog runs on the initialized
desktop; `TObject::destroy` is the matching Turbo Vision cleanup operation.

#### 16.4 .gitignore

```gitignore
/build/
/cmake-build-*/
/_deps/
/CMakeUserPresets.json
/.vs/
*.a
*.lib
*.dll
*.dylib
*.so
*.exe
*.pdb
*.dSYM/
```

Commit `CMakePresets.json` as the shared build contract. Keep
`CMakeUserPresets.json` local when it contains absolute paths or machine-local
toolchains.

#### 16.5 From a new directory to a stand-alone calculator

Sections 3 and 16 already describe the general case: a custom directory owns
its `project()`, executable target, and pinned FetchContent dependency. The
[stand-alone tvision calculator](examples/tvision-calculator/README.md) adds a
complete executable reference project. It does not depend on the internal
helper functions from the tvision examples build.

##### 16.5.1 Create or copy the project

Create `mein-tvision-calculator/src` and `mein-tvision-calculator/tests` with
the Bash or PowerShell commands from the German section, enter the new
directory, and initialize Git if it will be versioned. Create the file tree
shown there and use the matching files in the supplied example as the complete
reference.

Alternatively, copy `docs/examples/tvision-calculator` next to the tvision
fork. The copied directory is an independent repository. Normal builds no
longer depend on the original local clone: FetchContent retrieves the immutable
commit named by `GIT_TAG` into the calculator's own build tree.

##### 16.5.2 Architecture and behavior

The newly written `calculator::Engine` owns digits, one decimal point, the four
basic operations, equals, clear, display formatting, and error state. The
tvision layer translates keyboard and button events and draws the display.
CTest can therefore validate arithmetic without an interactive terminal.

Operations use immediate left-to-right execution, so `2 + 3 * 4 =` produces
`20`. Division by zero displays `Error`, and `C` resets that state. Digits,
decimal point, operators, equals, and Enter work without a mouse; Escape closes
the dialog through normal `TDialog` behavior. The interaction model is inspired
by TVDemo, but no historical Borland calculator source is copied.

##### 16.5.3 Configure, build, test, and run

Use the `macos-debug`, `linux-debug`, or `windows-debug` configure, build, and
test commands shown in the German section. The presets select the platform's
default generator and use no more than two jobs, so Ninja remains optional.
Reduce a direct build to `--parallel 1` under memory pressure. A Visual Studio
multi-configuration build normally places the Windows executable under the
`Debug` configuration subdirectory; a single-configuration generator may put
it directly in the preset build directory.

##### 16.5.4 CLion, VS Code, Visual Studio, and a local tvision override

Open the copied calculator directory itself in CLion, select the applicable
host preset, and run `tvision_calculator` in an interactive terminal. In VS
Code, open the same directory, select the CMake configure preset, build, and
launch from the integrated terminal rather than an output panel.

On Windows, Visual Studio Community opens the same directory through
`File | Open | Folder` as a CMake project. Section 22 describes the explicit
Community 2022/v143 and 2026/v145 choices.

Normal consumers keep the pinned remote commit. Maintainers and CI may set
`FETCHCONTENT_SOURCE_DIR_TVISION` to an absolute checkout for a focused local
integration test. That machine-local path must never be committed to the
shared CMake files or presets.

### 17. CMake command-line model

CMake separates configure/generate, build, and run. The source tree is tracked;
the build tree is local:

```text
my-tvision-application/       tracked source tree
`-- build/macos-debug/        untracked build tree
```

#### 17.1 Generators

Ninja is preferred for a small cross-platform workflow. Unix Makefiles are an
alternative on macOS/Linux; Visual Studio and MinGW Makefiles are alternatives
on Windows. A build tree remains bound to one generator and compiler.

| System | Preferred | Alternative |
|---|---|---|
| macOS | Ninja | Unix Makefiles, Xcode |
| Linux | Ninja | Unix Makefiles |
| Windows/MSVC | Ninja in Developer PowerShell | Visual Studio generator |
| Windows/MinGW | Ninja | MinGW Makefiles |

#### 17.2 Universal command form

```bash
cmake -S . -B build/<platform>-debug \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug

cmake --build build/<platform>-debug \
  --target my_tvision_application \
  --parallel 2
```

Two jobs are the starting point for 8 GB RAM. Reduce to one under memory
pressure and increase only after measurement on a larger machine.

#### 17.3 Preflight

```bash
git --version
cmake --version
ninja --version
clang++ --version   # AppleClang or Clang
g++ --version       # GCC or MinGW
cl                  # MSVC Developer PowerShell
```

Repair a missing toolchain before editing CMake caches.

#### 17.4 Build types

Use Debug for daily development and Release for delivery verification.
RelWithDebInfo is useful for optimized debugging and MinSizeRel for deliberate
size optimization. A small disk does not need to retain every configuration.

### 18. Shared CMakePresets.json for three operating systems

Presets provide the same entry points to CLion, VS Code, Visual Studio, and the
shell. The following file deliberately leaves the generator open and limits
builds to two jobs. Each operating system can therefore use its default
generator, while Ninja remains an optional local choice. On Windows, the IDE
or active toolchain shell selects MSVC or MinGW. Pin Visual Studio 2022 or 2026
in a local `CMakeUserPresets.json`, not in this shared contract.

```json
{
  "version": 3,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 21,
    "patch": 0
  },
  "configurePresets": [
    {
      "name": "common",
      "hidden": true,
      "binaryDir": "${sourceDir}/build/${presetName}",
      "cacheVariables": {
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    },
    {
      "name": "macos-debug",
      "inherits": "common",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Darwin"
      },
      "cacheVariables": {"CMAKE_BUILD_TYPE": "Debug"}
    },
    {
      "name": "macos-release",
      "inherits": "common",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Darwin"
      },
      "cacheVariables": {"CMAKE_BUILD_TYPE": "Release"}
    },
    {
      "name": "linux-debug",
      "inherits": "common",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Linux"
      },
      "cacheVariables": {"CMAKE_BUILD_TYPE": "Debug"}
    },
    {
      "name": "linux-release",
      "inherits": "common",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Linux"
      },
      "cacheVariables": {"CMAKE_BUILD_TYPE": "Release"}
    },
    {
      "name": "windows-debug",
      "inherits": "common",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Windows"
      },
      "cacheVariables": {"CMAKE_BUILD_TYPE": "Debug"}
    },
    {
      "name": "windows-release",
      "inherits": "common",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Windows"
      },
      "cacheVariables": {"CMAKE_BUILD_TYPE": "Release"}
    }
  ],
  "buildPresets": [
    {
      "name": "macos-debug",
      "configurePreset": "macos-debug",
      "configuration": "Debug",
      "jobs": 2,
      "targets": ["my_tvision_application"]
    },
    {
      "name": "macos-release",
      "configurePreset": "macos-release",
      "configuration": "Release",
      "jobs": 2,
      "targets": ["my_tvision_application"]
    },
    {
      "name": "linux-debug",
      "configurePreset": "linux-debug",
      "configuration": "Debug",
      "jobs": 2,
      "targets": ["my_tvision_application"]
    },
    {
      "name": "linux-release",
      "configurePreset": "linux-release",
      "configuration": "Release",
      "jobs": 2,
      "targets": ["my_tvision_application"]
    },
    {
      "name": "windows-debug",
      "configurePreset": "windows-debug",
      "configuration": "Debug",
      "jobs": 2,
      "targets": ["my_tvision_application"]
    },
    {
      "name": "windows-release",
      "configurePreset": "windows-release",
      "configuration": "Release",
      "jobs": 2,
      "targets": ["my_tvision_application"]
    }
  ]
}
```

```bash
cmake --list-presets
cmake --build --list-presets
cmake --preset macos-debug
cmake --build --preset macos-debug
```

Use `linux-*` and `windows-*` on the corresponding hosts.

### 19. macOS command line

Verify `xcode-select -p`, AppleClang, CMake, Ninja, and Git. If the Apple
developer tools are absent, use the official `xcode-select --install` dialog.

```bash
cmake --preset macos-debug
cmake --build --preset macos-debug
./build/macos-debug/my_tvision_application

cmake --preset macos-release
cmake --build --preset macos-release
./build/macos-release/my_tvision_application
```

Run the TUI in Terminal.app, iTerm2, or an actual CLion/VS Code terminal, not a
plain output panel without a TTY. Keep Debug during daily work; remove Release
after the cross-platform checkpoint if disk space is constrained.

### 20. Linux command line

Install Git, CMake, Ninja/Make, GCC or Clang, a debugger, and ncursesw
development headers. Typical examples are:

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install build-essential cmake ninja-build git gdb libncurses-dev

# Fedora
sudo dnf install gcc-c++ cmake ninja-build git gdb ncurses-devel

# Arch Linux
sudo pacman -S --needed base-devel cmake ninja git gdb ncurses
```

Package names may vary. Confirm the tools and let CMake prove whether ncursesw
and its headers are visible.

```bash
cmake --preset linux-debug
cmake --build --preset linux-debug
./build/linux-debug/my_tvision_application

cmake --preset linux-release
cmake --build --preset linux-release
./build/linux-release/my_tvision_application
```

Check `TERM` and `locale` when terminal input or rendering differs.

### 21. Windows command line

Choose MSVC or MinGW and never mix their build trees.

#### 21.1 MSVC and Developer PowerShell

Install the Microsoft C++ Build Tools/Visual Studio C++ desktop workload,
CMake, Ninja, and Git. Start Developer PowerShell and verify `cl`, `cmake`,
`ninja`, and `git`.

```powershell
cmake --preset windows-debug
cmake --build --preset windows-debug
& .\build\windows-debug\my_tvision_application.exe

cmake --preset windows-release
cmake --build --preset windows-release
& .\build\windows-release\my_tvision_application.exe
```

#### 21.2 Visual Studio generator alternative

```powershell
cmake -S . -B build/windows-vs `
  -G "Visual Studio 17 2022" `
  -A x64

cmake --build build/windows-vs `
  --config Debug `
  --target my_tvision_application `
  --parallel 2

& .\build\windows-vs\Debug\my_tvision_application.exe
```

Match the generator name to the installed Visual Studio version. Multi-config
generators select Debug/Release at build time.

#### 21.3 MinGW

```powershell
g++ --version
cmake -S . -B build/windows-mingw-debug `
  -G Ninja `
  -DCMAKE_BUILD_TYPE=Debug
cmake --build build/windows-mingw-debug `
  --target my_tvision_application `
  --parallel 2
& .\build\windows-mingw-debug\my_tvision_application.exe
```

### 22. Microsoft Visual Studio Community 2022 and 2026

Microsoft Visual Studio Community is a complete native Windows IDE. With the
appropriate workload it provides MSVC, CMake integration, IntelliSense, a
debugger, Test Explorer, and an integrated terminal. It is another interface
to the checked-in CMake contract in this working model; the repository does
not maintain a separate Visual Studio project.

#### 22.1 Position beside CLion and VS Code

| Tool | Operating systems | Role in this working model |
|---|---|---|
| CLion | macOS, Linux, Windows | cross-platform standard IDE |
| VS Code | macOS, Linux, Windows | light editor and terminal option |
| Visual Studio Community | Windows | optional native full Windows IDE |
| CMake command line | macOS, Linux, Windows | IDE-independent reference |

Visual Studio does not change `CMakeLists.txt` or the pinned `tvision` SHA. A
generated `.lib` remains specific to Windows, architecture, toolset, and build
configuration, just like an MSVC build produced by CLion or Developer
PowerShell.

#### 22.2 Versions, generators, and toolsets

As of August 12, 2026, the relevant version contract is:

| IDE | CMake generator | Generator requires CMake | Default toolset |
|---|---|---:|---|
| Visual Studio Community 2022 | `Visual Studio 17 2022` | 3.21 | `v143` |
| Visual Studio Community 2026 | `Visual Studio 18 2026` | 4.2 | `v145` |

The generator requirement does not force the application to raise its
`cmake_minimum_required(VERSION 3.21)`. Only the CMake executable selecting the
VS 2026 generator must be version 4.2 or newer.

Visual Studio 2022 remains the compatibility path for `v143`; Community uses
the current 17.14 servicing channel. Visual Studio 2026 is the current `v145`
path. Supported versions can be installed side by side, but each installation
and channel needs a unique location. Every build tree remains bound to exactly
one generator instance and toolset.

Visual Studio 2026 itself currently supports the documented 64-bit Windows 11
and Windows Server versions. Check the current system requirements before
installing either IDE on an older Windows host. The operating systems targeted
by a compiled application also depend on its Windows SDK and target settings;
they are not identical to the IDE host requirements.

Official references:

- [Visual Studio Community and usage](https://visualstudio.microsoft.com/vs/community/)
- [Install C++ support](https://learn.microsoft.com/en-us/cpp/build/vscpp-step-0-installation?view=msvc-170)
- [CMake projects in Visual Studio](https://learn.microsoft.com/en-us/cpp/build/cmake-projects-in-visual-studio?view=msvc-170)
- [Visual Studio 2022 system requirements](https://learn.microsoft.com/en-us/visualstudio/releases/2022/system-requirements)
- [Visual Studio 2026 system requirements](https://learn.microsoft.com/en-us/visualstudio/releases/2026/vs-system-requirements)
- [Visual Studio 2022 CMake generator](https://cmake.org/cmake/help/latest/generator/Visual%20Studio%2017%202022.html)
- [Visual Studio 2026 CMake generator](https://cmake.org/cmake/help/latest/generator/Visual%20Studio%2018%202026.html)

Microsoft's current Community description permits individual developers to
create their own free or paid applications. Additional terms apply to use in
organizations. The linked current license terms are authoritative, not this
technical guide.

#### 22.3 Install through Visual Studio Installer

Select at least the **Desktop development with C++** workload for Community
2022 or Community 2026. In Installation details, verify:

- the matching MSVC x64/x86 toolset (`v143` or `v145`);
- a current Windows SDK;
- C++ CMake tools for Windows;
- CMake 3.21 or newer for VS 2022, and 4.2 or newer for the VS 2026 generator;
- optionally Ninja and Git when they are not provided separately.

MFC, ATL, UWP, game-development, and every optional C++ component are not
required for this calculator. A focused desktop C++ installation saves disk
space. Microsoft describes typical Visual Studio installations as roughly
20-50 GB, with 4 GB RAM as the minimum and 16 GB recommended for typical
professional solutions. Prefer VS Code or the command line on a constrained
Windows machine.

Open **Developer PowerShell for VS 2022** and/or **Developer PowerShell for VS
2026** separately after installation:

```powershell
cl
cmake --version
cmake --help | Select-String 'Visual Studio 17 2022|Visual Studio 18 2026'
```

Finding `cl` proves that an MSVC environment is active. The generated
`CMakeCache.txt` is the evidence for the selected generator, architecture, and
toolset.

#### 22.4 Open the existing CMake project

The recommended IDE workflow does not create `.sln` or `.vcxproj` files in the
source tree:

1. Start Visual Studio Community.
2. Select `File | Open | Folder`.
3. Open the application root containing the top-level `CMakeLists.txt` and
   `CMakePresets.json`.
4. Enable CMake for that project folder if Visual Studio prompts for it.
5. Select the appropriate Windows preset from the configuration control.
6. Let the first configure finish; FetchContent retrieves the pinned `tvision`
   revision.
7. Switch Solution Explorer to **CMake Targets View** when useful.

Visual Studio stores IDE state under `.vs/` and build output in the preset's
binary directory. Both remain untracked. CMake projects do not require
`CppProperties.json` or `tasks.vs.json`, and this workflow does not introduce a
parallel hand-written `CMakeSettings.json`.

Use `Project | Configure Cache` after material CMake changes. Select a new
build tree when changing generator, architecture, or toolset; do not reinterpret
an existing cache in the IDE.

#### 22.5 Build, test, run, and debug

After configure, Visual Studio shows the CMake targets. For the stand-alone
calculator:

1. Select `tvision_calculator` as the build/startup target.
2. Select Debug or Release in the active CMake configuration.
3. Run `Build | Build All` or `Ctrl+Shift+B`.
4. Run the engine tests reproducibly with CTest in the integrated terminal.
5. Verify the TUI without a debugger in a real terminal first.
6. Select the calculator as Startup Item and press `F5` for debugging.

The IDE-independent commands for a Visual Studio multi-config tree are:

```powershell
cmake --build build/windows-debug `
  --config Debug `
  --target tvision_calculator `
  --parallel 2

ctest --test-dir build/windows-debug `
  -C Debug `
  --output-on-failure

& .\build\windows-debug\Debug\tvision_calculator.exe
```

The exact executable path follows from `binaryDir`, configuration, and
generator. Do not accept a TUI in a plain Output or Debug text pane. Windows
Terminal, Developer PowerShell, or a full integrated terminal must support
keyboard input, colors, resizing, and clean shutdown.

#### 22.6 Select Visual Studio 2022 explicitly

Bind the generator, x64 architecture, and `v143` to a dedicated tree:

```powershell
cmake -S . -B build/windows-vs2022 `
  -G "Visual Studio 17 2022" `
  -A x64 `
  -T v143 `
  -DBUILD_TESTING=ON

cmake --build build/windows-vs2022 `
  --config Release `
  --target tvision_calculator `
  --parallel 2

ctest --test-dir build/windows-vs2022 `
  -C Release `
  --output-on-failure

& .\build\windows-vs2022\Release\tvision_calculator.exe
```

A generated solution may be opened from the build tree for inspection. It is
derived, not edited or committed. **Open Folder** with the CMake source files
remains the canonical IDE workflow.

#### 22.7 Select Visual Studio 2026 explicitly

Visual Studio 2026 uses CMake 4.2 or newer, generator 18, and `v145`:

```powershell
cmake -S . -B build/windows-vs2026 `
  -G "Visual Studio 18 2026" `
  -A x64 `
  -T v145 `
  -DBUILD_TESTING=ON

cmake --build build/windows-vs2026 `
  --config Release `
  --target tvision_calculator `
  --parallel 2

ctest --test-dir build/windows-vs2026 `
  -C Release `
  --output-on-failure

& .\build\windows-vs2026\Release\tvision_calculator.exe
```

`Could not create named generator Visual Studio 18 2026` normally means that
the invoked CMake is too old, the VS 2026 instance is not detected, or its C++
workload is missing. Renaming a VS 2022 build directory cannot fix it.

#### 22.8 Side-by-side selection with CMakeUserPresets.json

Keep `CMakePresets.json` portable when Community 2022 and 2026 are installed
side by side. Put the machine-specific choice into the already ignored local
`CMakeUserPresets.json`:

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "windows-vs2022-debug",
      "inherits": "windows-debug",
      "generator": "Visual Studio 17 2022",
      "architecture": "x64",
      "toolset": "v143",
      "binaryDir": "${sourceDir}/build/windows-vs2022-debug"
    },
    {
      "name": "windows-vs2026-debug",
      "inherits": "windows-debug",
      "generator": "Visual Studio 18 2026",
      "architecture": "x64",
      "toolset": "v145",
      "binaryDir": "${sourceDir}/build/windows-vs2026-debug"
    }
  ],
  "buildPresets": [
    {
      "name": "windows-vs2022-debug",
      "configurePreset": "windows-vs2022-debug",
      "configuration": "Debug",
      "jobs": 2
    },
    {
      "name": "windows-vs2026-debug",
      "configurePreset": "windows-vs2026-debug",
      "configuration": "Debug",
      "jobs": 2
    }
  ],
  "testPresets": [
    {
      "name": "windows-vs2022-debug",
      "configurePreset": "windows-vs2022-debug",
      "configuration": "Debug",
      "output": {"outputOnFailure": true}
    },
    {
      "name": "windows-vs2026-debug",
      "configurePreset": "windows-vs2026-debug",
      "configuration": "Debug",
      "output": {"outputOnFailure": true}
    }
  ]
}
```

The IDE and shell then share the preset names:

```powershell
cmake --preset windows-vs2022-debug
cmake --build --preset windows-vs2022-debug
ctest --preset windows-vs2022-debug

cmake --preset windows-vs2026-debug
cmake --build --preset windows-vs2026-debug
ctest --preset windows-vs2026-debug
```

Create Release presets with distinct binary directories and
`"configuration": "Release"`. Add absolute installation paths or
`CMAKE_GENERATOR_INSTANCE` locally only when CMake cannot disambiguate multiple
instances. Never commit those machine paths to `CMakePresets.json` or
`CMakeLists.txt`.

#### 22.9 Common Visual Studio failures

- **Preset missing:** verify project root, valid JSON, and enabled CMake support,
  then configure the cache again.
- **Wrong IDE version:** inspect `CMAKE_GENERATOR`,
  `CMAKE_GENERATOR_INSTANCE`, and `CMAKE_GENERATOR_TOOLSET` in that tree's
  `CMakeCache.txt`.
- **Wrong architecture:** create a fresh `-A x64` tree instead of editing Win32
  cache values.
- **Toolset missing:** add `v143` or `v145` through Visual Studio Installer's
  desktop C++ workload.
- **Incompatible linker input:** do not mix MSVC, MinGW, Debug, Release, x86,
  and x64 artifacts.
- **TUI does not respond:** use Windows Terminal or Developer PowerShell, not
  the Visual Studio Output pane.
- **Insufficient RAM or disk:** install one Community version with only the
  required C++ workload, or use VS Code/the command line on that machine.

### 23. VS Code as the light editor

VS Code remains an editor with an integrated terminal. Compiler and CMake stay
external and authoritative.

#### 23.1 Minimal profile and extensions

```bash
code --profile "C++ Light" .
code --install-extension ms-vscode.cpptools --profile "C++ Light"
code --install-extension ms-vscode.cmake-tools --profile "C++ Light"
```

Enable only Microsoft's C/C++ and CMake Tools extensions in this profile.
Disable unrelated extensions for the workspace. `code --disable-extensions .`
is a diagnostic mode, not the normal C++ mode.

#### 23.2 Extension recommendations

```json
{
  "recommendations": [
    "ms-vscode.cpptools",
    "ms-vscode.cmake-tools"
  ]
}
```

#### 23.3 Resource-conscious settings

```json
{
  "cmake.useCMakePresets": "always",
  "cmake.configureOnOpen": false,
  "cmake.configureOnEdit": false,
  "cmake.automaticReconfigure": false,
  "files.watcherExclude": {
    "**/build/**": true,
    "**/cmake-build-*/**": true,
    "**/_deps/**": true
  },
  "search.exclude": {
    "**/build/**": true,
    "**/cmake-build-*/**": true,
    "**/_deps/**": true
  },
  "C_Cpp.intelliSenseCacheSize": 0
}
```

Manual configure avoids unexpected fetches and indexing. Disabling the
IntelliSense disk cache saves space and writes but may increase parsing CPU;
remove or revise the setting if interaction becomes too slow.

#### 23.4 Terminal-first mode

Edit in VS Code and run the exact preset commands in its terminal. This needs
no duplicate `tasks.json` build logic.

#### 23.5 CMake Tools mode

Select the operating-system configure preset, run `CMake: Configure`, select
`my_tvision_application` as build target, and run `CMake: Build`. Launch the TUI
from the integrated terminal so it receives a real TTY.

#### 23.6 IntelliSense provider

The presets export compile commands. Let CMake Tools provide configuration to
the C/C++ extension. Configure successfully before resetting IntelliSense, and
do not recursively add the whole `_deps` tree as a manual include workaround.

### 24. VS Code per operating system

On macOS, start `code --profile "C++ Light" .` from the shell whose AppleClang,
CMake, and Ninja checks succeed. Build `macos-debug` and run the executable in
the integrated terminal.

On Linux, verify the compiler, debugger, CMake, Ninja, and ncursesw headers;
build `linux-debug` and compare rendering in a native terminal if required.

On Windows/MSVC, start VS Code from Developer PowerShell so its integrated
terminal inherits the toolchain. Build `windows-debug` and launch with:

```powershell
& .\build\windows-debug\my_tvision_application.exe
```

For MinGW, ensure VS Code sees the same MinGW `PATH` as the proven shell and
use a separate fresh build tree.

### 25. Debugging TUI applications

A TUI changes terminal state. A breakpoint may therefore leave an incomplete
screen without proving a tvision defect. Run without a debugger first, verify
dialog, keyboard, resize, and clean exit, then debug. Prefer breakpoints before
terminal initialization or in clear event handlers. Use LLDB on macOS,
GDB/LLDB on Linux, and the debugger matching MSVC or MinGW on Windows.

### 26. 8 GB RAM and small-disk profile

The concrete MacBook Air 2023 has 8 GB RAM. Start with:

- at most two compiler jobs, one under swap pressure;
- examples, dependency tests, GPM, and unity build disabled;
- Debug retained, Release created only for checkpoints;
- only one IDE indexing the tree;
- only the application target built.

PCH remains enabled for faster incremental builds. For maximum disk savings:

```cmake
set(TV_OPTIMIZE_BUILD OFF CACHE BOOL "Use tvision precompiled headers" FORCE)
```

Use a fresh build tree after changing this. PCH favors repeated builds; no PCH
favors fewer cache artifacts. Unity build remains off because larger
translation units can create memory peaks.

#### 26.1 Local orientation evidence

The copyable starter project was fully compiled on the current Apple Silicon
Mac with 8 GB RAM, AppleClang, C++17 for the application, Debug configuration,
and two parallel jobs. The validation build tree used approximately 73 MiB;
the separate local `tvision` source checkout was not included. An unchanged
incremental verification build took about 1.6 seconds. These values describe
this machine only and are not guaranteed limits for other toolchains or later
fork revisions.

### 27. Measure and release disk space safely

```bash
du -sh build/* 2>/dev/null
df -h .
cmake --build build/macos-debug --target clean
cmake -E remove_directory "build/macos-release"
```

PowerShell can use the same final CMake removal command with a precise Windows
build path. Verify the repository root and exact target first. Never replace a
specific build directory with an empty variable, wildcard, home directory, or
broad recursive deletion.

Keep one active Debug `_deps` tree when possible. Deleting it after every build
saves temporary space but forces another download, configure, and full build.

### 28. CLI, CLion, VS Code, and Visual Studio parity

| Aspect | CLion | Command line | VS Code Light | Visual Studio Community |
|---|---|---|---|---|
| source | same commit | same commit | same commit | same commit |
| tvision | same SHA | same SHA | same SHA | same SHA |
| configure | profile/preset | `cmake --preset` | CMake Tools | CMake Presets |
| build | target | `cmake --build` | CMake Tools | CMake Targets |
| jobs | build tool | `--parallel 2` | two jobs | two jobs |
| TUI run | terminal | native terminal | terminal | terminal |

Do not replace this contract with IDE-specific compiler flags or a direct
one-line compiler invocation.

### 29. Complete personal workflow

Start on macOS with the pinned fork SHA, Debug, two jobs, and terminal runtime
checks. Build macOS Release at a checkpoint and commit only source/configuration.
Check out the same application commit on Windows, select MSVC or MinGW, and run
native Debug/Release checks. With MSVC, optionally use CLion, VS Code, or Visual
Studio Community; select VS 2022/v143 or VS 2026/v145 explicitly and keep a
separate build tree. Then repeat on Linux with ncursesw and a UTF-8 terminal.
Treat the revision as three-platform capable only after all native checks.

After syncing the fork, change `GIT_TAG` in one pilot application first. Repeat
macOS, Windows, and Linux checks before updating other applications.

### 30. Extended CMake, VS Code, and Visual Studio diagnostics

- Wrong compiler: inspect the CMake cache, activate the correct toolchain shell,
  and configure a new build tree rather than editing one cache line.
- Missing Ninja: install/expose Ninja or deliberately select another generator;
  never reuse a Ninja tree with a different generator.
- Repeated downloads: keep one stable Debug build path and find cleanup tools
  that remove `_deps`.
- Editor include errors with a successful build: use CMake Tools as provider;
  the compiler build remains canonical.
- TUI exits immediately: launch from a real terminal and inspect exit status,
  `TERM`, locale, or Windows console state.
- Swapping: stop the build, reduce other workloads, and resume with one job.
- Low disk: measure trees, remove old Release/toolchain variants, limit the
  IntelliSense cache, and retain the active Debug tree last.
- Wrong Visual Studio instance: inspect generator, instance, platform, and
  toolset in `CMakeCache.txt`, then select a distinct local user preset and
  build directory instead of rewriting the cache.

### 31. Documentation impact

- Decision: `UpdateRequired`.
- Canonical technical source: `CMakeLists.txt`, `source/CMakeLists.txt`, and the
  CMake target and dependency contracts defined there for the Level 2
  repository.
- Documents: this development guide and the independent, copyable calculator
  example under `docs/examples/tvision-calculator/`.
- Owner: repository maintainer.
- Audience and reader path: a developer starts with purpose and prerequisites,
  pins the commit, selects CLion, CMake command line, VS Code Light, or Visual
  Studio Community on Windows, and then performs native macOS, Windows, and
  Linux verification.
- Language strategy: German primary, equivalent English section in the same
  file.
- Platform evidence: the documented FetchContent integration and calculator
  were configured, built, tested, and launched in an interactive terminal with
  AppleClang on macOS. A permanent matrix job additionally builds the
  calculator and tests its engine on macOS, Linux, and Windows. Two explicit
  Windows jobs prove complete calculator builds with Visual Studio 2022/v143
  and Visual Studio 2026/v145.
- Repository-specific distribution model: source dependency through
  `FetchContent`; no separate runtime, installation, or Home sync copy.
- Navigation impact: direct guide under `docs/`, with its path provided in the
  handoff; the existing English upstream README remains unchanged.
- Re-evaluation trigger: changes to the `tvision` CMake target, FetchContent or
  preset compatibility, supported platforms, CLion CMake/toolchain interfaces,
  Microsoft's C/C++ and CMake Tools extensions for VS Code, or Visual Studio,
  MSVC, and CMake generator contracts.
- Evidence: successful local FetchContent configure, build, CTest, and launch
  on macOS, the three-OS calculator matrix job, the explicit VS 2022 and VS
  2026 generator jobs, and comparison with the local CMake target,
  installation, and export rules and the linked official CMake, JetBrains,
  Microsoft, and VS Code references.
