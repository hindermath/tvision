# Gesamtprojekt-Nachweis für C++17 in Issue #226

## Zusammenfassung

- Auf Commit `2e6edf724e77d70d31da0d5a69bf6229730c6827` sämtliche CMake-Ziele temporär mit strengem C++17 bauen.
- Alle Tests und dokumentierten Demos prüfen.
- Anschließend einen englischen Nachweis-Kommentar in [Issue #226](https://github.com/magiblot/tvision/issues/226) veröffentlichen.
- Keine Quelldateien, Commits oder Einstellungen von [PR #227](https://github.com/magiblot/tvision/pull/227) verändern.

## Durchführung

1. Einen frischen temporären Build konfigurieren:

   ```sh
   cmake -S <source> -B <temp-build> \
     -DCMAKE_BUILD_TYPE=Release \
     -DTV_BUILD_TESTS=ON \
     -DCMAKE_CXX_STANDARD=17 \
     -DCMAKE_CXX_STANDARD_REQUIRED=ON \
     -DCMAKE_CXX_EXTENSIONS=OFF \
     -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
   cmake --build <temp-build> --parallel
   ```

2. In `compile_commands.json` prüfen, dass alle 222 Übersetzungseinheiten `-std=c++17` verwenden:

   - Bibliothek: 207
   - Beispiele und Werkzeuge: 12
   - Tests: 3

3. Die Testsuite ausführen und `39/39` bestandene Tests aus 12 Suites nachweisen.
4. Die sechs dokumentierten Demos einzeln in einem echten Terminal starten:

   - `hello`
   - `tvdemo`
   - `tvedit`
   - `tvdir`
   - `mmenu`
   - `palette`

5. Bei jeder Demo sichtbare Ausgabe abwarten und sie anschließend mit Alt-X regulär beenden. Erwarteter Exitcode: `0`.
6. Den unveränderten Commit und einen sauberen Git-Status bestätigen.
7. Einen freundlichen englischen Kommentar in Issue #226 schreiben. Darin dokumentieren:

   - macOS `26.6.1`, `arm64`
   - Apple Clang `21.0.0`
   - CMake `4.4.2`
   - GoogleTest `1.17.0`
   - geprüften Commit und CMake-Optionen
   - erfolgreichen Gesamtbuild
   - `222/222` Compile-Kommandos mit strengem C++17
   - `39/39` bestandene Tests
   - sechs erfolgreich gestartete und sauber beendete Demos
   - Verweise auf PR #227 und den vorhandenen CI-Lauf
   - Hinweis, dass dies die Machbarkeit auf einer macOS-CMake-Toolchain belegt, aber noch keine plattformübergreifende Freigabe für C++17 darstellt

## Abnahmekriterien

- Konfiguration und Gesamtbuild enden mit Exitcode `0`.
- Kein CMake-Ziel fällt auf C++14 oder GNU-Erweiterungen zurück.
- Alle 39 Tests bestehen.
- Alle sechs Demos zeichnen ihre Oberfläche und enden regulär mit Exitcode `0`.
- Das Git-Arbeitsverzeichnis bleibt abgesehen von dieser Plandatei unverändert.
- Bei einer Abweichung wird kein GitHub-Kommentar veröffentlicht; stattdessen wird der Fehler lokal berichtet.

## Annahmen

- „Gesamtes Projekt“ umfasst alle CMake-Ziele: Bibliothek, Beispiele, Anwendungen, Werkzeuge und Tests.
- Der historische Borland-/DOS-Build gehört nicht zum C++17-Nachweis.
- Es erfolgt keine dauerhafte C++17-Umstellung und keine Änderung öffentlicher APIs.
- Dokumentationsauswirkung der späteren Nachweisführung: `NoUpdateRequired`.
