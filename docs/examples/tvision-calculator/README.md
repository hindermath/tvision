# Eigenstaendiger tvision-Calculator / Stand-alone tvision Calculator

## Deutsch

### Zweck

Dieses Verzeichnis ist ein vollstaendiges, eigenstaendiges CMake-Projekt. Es
zeigt, wie ein neues Programm ausserhalb des tvision-Quellbaums aufgebaut wird
und den persoenlichen Fork als fest versionierte Abhaengigkeit einbindet. Das
Programm ist vom historischen Calculator in `TVDemo` inspiriert, verwendet
aber eine neu geschriebene, kleine Rechen-Engine und kopiert keinen historischen
Borland-Quellcode.

Der Calculator unterstuetzt:

- die Ziffern `0` bis `9` und einen Dezimalpunkt;
- Addition, Subtraktion, Multiplikation und Division;
- `=` oder Enter zum Berechnen;
- `C` zum vollstaendigen Zuruecksetzen;
- `Error` bei einer Division durch null;
- Tastatur- und Mausbedienung sowie Escape zum Schliessen.

Wie bei einem einfachen Taschenrechner werden Operationen sofort von links
nach rechts ausgewertet. `2 + 3 * 4 =` ergibt deshalb `20`, nicht `14`.

### Projektstruktur

```text
tvision-calculator/
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

`calculator_engine` enthaelt nur die Rechenregeln und kann ohne Terminal oder
tvision getestet werden. `tvision_calculator` stellt diese Engine als
Terminalanwendung dar. Die Trennung haelt die interaktive Oberflaeche klein
und macht die fachlichen Regeln deterministisch pruefbar.

### Voraussetzungen

Auf allen Systemen werden Git, CMake, ein C++17-Compiler und ein natives
Buildwerkzeug benoetigt. Die mitgelieferten Presets verwenden den
Standardgenerator des jeweiligen Systems, sodass Ninja optional bleibt.

- macOS: Xcode Command Line Tools mit AppleClang.
- Linux: GCC oder Clang sowie die ncursesw-Entwicklungsdateien.
- Windows: Visual Studio Community beziehungsweise Build Tools 2022 oder 2026
  mit der Workload `Desktop development with C++`; alternativ kann eine
  bewusst konfigurierte MinGW-Toolchain verwendet werden. Der explizite
  VS-2026-Generator benoetigt CMake 4.2 oder neuer.

Debian und Ubuntu stellen die Linux-Abhaengigkeiten beispielsweise so bereit:

```bash
sudo apt update
sudo apt install build-essential cmake git libncurses-dev
```

### In ein neues Verzeichnis kopieren

Vom Wurzelverzeichnis des geklonten tvision-Forks aus:

```bash
cp -R docs/examples/tvision-calculator ../mein-tvision-calculator
cd ../mein-tvision-calculator
git init
```

In PowerShell:

```powershell
Copy-Item -Recurse docs/examples/tvision-calculator ../mein-tvision-calculator
Set-Location ../mein-tvision-calculator
git init
```

Das neue Verzeichnis ist ein eigenes Projekt. Sein Build ruft den in
`CMakeLists.txt` festgelegten tvision-Commit ab; es benoetigt den urspruenglichen
tvision-Klon nach dem Kopieren nicht mehr.

### Bauen und testen mit Presets

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

Ein Windows-Generator mit nur einer Konfiguration, beispielsweise Ninja, legt
die EXE gegebenenfalls direkt unter `build/windows-debug/` ab. Der konkrete
Pfad steht nach dem Linkschritt in der CMake-Ausgabe.

Die Presets begrenzen Builds auf zwei parallele Jobs. Bei starkem Speicherdruck
kann stattdessen direkt mit `cmake --build <buildverzeichnis> --parallel 1`
gebaut werden.

### Bauen ohne Presets

macOS oder Linux:

```bash
cmake -S . -B build/local-debug \
  -DCMAKE_BUILD_TYPE=Debug \
  -DBUILD_TESTING=ON
cmake --build build/local-debug --parallel 2
ctest --test-dir build/local-debug --output-on-failure
./build/local-debug/tvision_calculator
```

Windows mit dem Visual-Studio-Standardgenerator:

```powershell
cmake -S . -B build/local-debug -DBUILD_TESTING=ON
cmake --build build/local-debug --config Debug --parallel 2
ctest --test-dir build/local-debug -C Debug --output-on-failure
./build/local-debug/Debug/tvision_calculator.exe
```

### Visual Studio Community 2022 und 2026

Das Verzeichnis ist direkt als CMake-Projekt verwendbar. In Community 2022
oder 2026 wird `File | Open | Folder` gewaehlt und genau dieses
Calculator-Verzeichnis geoeffnet. Danach das Windows-Debug-Preset,
`tvision_calculator` als Ziel und ein echtes Terminal fuer den TUI-Start
waehlen. `.sln`- und `.vcxproj`-Dateien werden nicht im Quellbaum gepflegt.

Fuer einen eindeutigen VS-2022-Nachweis in Developer PowerShell:

```powershell
cmake -S . -B build/windows-vs2022 `
  -G "Visual Studio 17 2022" -A x64 -T v143 `
  -DBUILD_TESTING=ON
cmake --build build/windows-vs2022 --config Release --parallel 2
ctest --test-dir build/windows-vs2022 -C Release --output-on-failure
& .\build\windows-vs2022\Release\tvision_calculator.exe
```

Fuer Community 2026 muss das aufgerufene CMake mindestens Version 4.2 haben:

```powershell
cmake -S . -B build/windows-vs2026 `
  -G "Visual Studio 18 2026" -A x64 -T v145 `
  -DBUILD_TESTING=ON
cmake --build build/windows-vs2026 --config Release --parallel 2
ctest --test-dir build/windows-vs2026 -C Release --output-on-failure
& .\build\windows-vs2026\Release\tvision_calculator.exe
```

Bei paralleler Installation erhalten beide Versionen getrennte Buildbaeume.
Eine lokale `CMakeUserPresets.json` kann Generator, Architektur und Toolset
festlegen; sie ist bereits ignoriert und wird nicht eingecheckt. Die
ausfuehrliche Side-by-Side-Konfiguration, IDE-Bedienung und Fehlerdiagnose steht
in der uebergeordneten plattformuebergreifenden Entwickleranleitung.

### Verwendung eines lokalen tvision-Checkouts

Die normale Anwendung verwendet bewusst den unveraenderlichen Remote-Commit.
Maintainer koennen fuer einen Test gegen einen lokalen Checkout die von CMake
bereitgestellte FetchContent-Uebersteuerung verwenden:

```bash
cmake -S . -B build/local-source \
  -DCMAKE_BUILD_TYPE=Debug \
  -DFETCHCONTENT_SOURCE_DIR_TVISION=/vollstaendiger/pfad/zu/tvision
cmake --build build/local-source --parallel 2
ctest --test-dir build/local-source --output-on-failure
```

PowerShell verwendet denselben CMake-Parameter mit einem Windows-Pfad. Absolute
lokale Pfade gehoeren nicht in `CMakeLists.txt` oder `CMakePresets.json` und
werden nicht eingecheckt.

### CLion, VS Code und Visual Studio

In CLion wird dieses Verzeichnis, nicht der uebergeordnete tvision-Fork, als
Projekt geoeffnet. CLion erkennt die `CMakeLists.txt` und die fuer das aktuelle
Betriebssystem gueltigen Presets. Als Run-Konfiguration wird das Ziel
`tvision_calculator` ausgewaehlt. Das Programm muss in einem interaktiven
Terminal laufen.

In VS Code genuegen fuer den leichten Arbeitsweg die Erweiterungen C/C++ und
CMake Tools. Nach `CMake: Select Configure Preset` wird das passende
Debug-Preset ausgewaehlt, danach `CMake: Build`. Gestartet wird die erzeugte
Datei im integrierten Terminal, nicht in einem reinen Ausgabefenster.

In Visual Studio Community wird der Ordner als CMake-Projekt geoeffnet. Die IDE
verwendet dieselben Presets, zeigt die CMake Targets an und kann den Calculator
mit MSVC bauen und debuggen. Die abschliessende interaktive TUI-Pruefung erfolgt
auch hier in Windows Terminal, Developer PowerShell oder einem vollwertigen
integrierten Terminal.

### Aktualisieren des Fork-Commits

Die Zeile `GIT_TAG` in `CMakeLists.txt` ist die Versionsgrenze. Ein neuer Stand
wird zuerst auf macOS, danach unter Linux und Windows konfiguriert, gebaut,
getestet und interaktiv gestartet. Erst danach wird der neue vollstaendige
Commit-Hash eingecheckt. Ein Branchname wie `master` bleibt als `GIT_TAG`
ungeeignet, weil er keinen reproduzierbaren Build garantiert.

## English

### Purpose

This directory is a complete stand-alone CMake project. It demonstrates how a
new application outside the tvision source tree consumes the personal fork as
an immutable dependency. The program is inspired by the historical calculator
in `TVDemo`, but its compact calculation engine is newly written and does not
copy historical Borland source code.

The calculator supports digits, one decimal point, the four basic arithmetic
operations, equals or Enter, clearing with `C`, a division-by-zero error, mouse
and keyboard input, and Escape to close the dialog. Operations are evaluated
immediately from left to right, so `2 + 3 * 4 =` produces `20`.

### Project layout and responsibilities

The file layout shown in the German section is the complete project. The
`calculator_engine` target contains terminal-independent arithmetic rules and
the `tvision_calculator` target presents that engine as a TUI. This separation
keeps the interaction layer small and makes the behavior deterministic to
test.

### Prerequisites

All platforms require Git, CMake, a C++17 compiler, and a native build tool.
The presets use each platform's default generator, so Ninja remains optional.
macOS uses AppleClang from the Xcode Command Line Tools. Linux additionally
needs ncurses development headers. Windows uses Visual Studio Community or
Build Tools 2022/2026 with the `Desktop development with C++` workload, unless
a deliberate MinGW toolchain is configured. Selecting the VS 2026 generator
explicitly requires CMake 4.2 or newer.

### Copying into a new directory

Run the Bash or PowerShell copy commands from the German section at the root of
the tvision fork. The copied directory becomes an independent project. Its
`CMakeLists.txt` retrieves the pinned tvision commit, so the original local
tvision clone is no longer required after copying.

### Configure, build, test, and run

Use the matching `macos-debug`, `linux-debug`, or `windows-debug` configure,
build, and test preset exactly as shown above. The presets use at most two
parallel jobs. Reduce a direct build to `--parallel 1` on a memory-constrained
machine.

Without presets, use separate source and build directories, set
`CMAKE_BUILD_TYPE=Debug` on single-configuration generators, and pass
`--config Debug` plus `ctest -C Debug` to a Visual Studio multi-configuration
build. Never reuse one build tree with another compiler or generator.

### Visual Studio Community 2022 and 2026

Open this calculator directory with `File | Open | Folder`, select the Windows
Debug preset and `tvision_calculator` target, then run the TUI in a real
terminal. Do not maintain `.sln` or `.vcxproj` files in the source tree.

Use distinct build trees when proving each toolchain explicitly:

```powershell
cmake -S . -B build/windows-vs2022 `
  -G "Visual Studio 17 2022" -A x64 -T v143 `
  -DBUILD_TESTING=ON
cmake --build build/windows-vs2022 --config Release --parallel 2
ctest --test-dir build/windows-vs2022 -C Release --output-on-failure

cmake -S . -B build/windows-vs2026 `
  -G "Visual Studio 18 2026" -A x64 -T v145 `
  -DBUILD_TESTING=ON
cmake --build build/windows-vs2026 --config Release --parallel 2
ctest --test-dir build/windows-vs2026 -C Release --output-on-failure
```

Keep version-specific generator, architecture, toolset, instance, and absolute
paths in the ignored local `CMakeUserPresets.json`. See the parent cross-
platform guide for the complete side-by-side preset, IDE, runtime, and
troubleshooting workflow.

### Local source override

Normal consumers deliberately use the immutable remote commit. Maintainers can
set `FETCHCONTENT_SOURCE_DIR_TVISION` to an absolute local checkout for a
focused integration test. Local absolute paths must not be committed to the
shared CMake files.

### CLion, VS Code, and Visual Studio

Open this calculator directory itself as the project. CLion discovers the
CMake project and applicable presets; select `tvision_calculator` as the run
target. For a lighter VS Code workflow, install only C/C++ and CMake Tools,
select the host preset, build, and launch the binary in the integrated terminal
rather than a non-interactive output panel.

Visual Studio Community opens the same directory as a CMake project and uses
the same presets and targets with MSVC. Debug in the IDE after first verifying
the TUI in Windows Terminal, Developer PowerShell, or a full integrated
terminal.

### Updating tvision

`GIT_TAG` is the dependency version boundary. Validate a new full commit hash
on macOS, Linux, and Windows before committing it. Do not replace the immutable
hash with a moving branch such as `master`.
