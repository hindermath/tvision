# GitHub Copilot Agent Instructions — tvision

Diese Agentenfläche ergänzt [die allgemeinen Copilot-Anweisungen](../copilot-instructions.md).
Sie hält die projektspezifischen Fakten für agentische Aufgaben kurz und
textorientiert fest.

*This agent surface supplements [the general Copilot instructions](../copilot-instructions.md).
It keeps the project-specific facts for agentic work concise and text-oriented.*

- Primärsprache ist C++14 mit CMake. Der Build mit Tests verwendet
  `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DTV_BUILD_TESTS=ON` und
  `cmake --build build`.
- Die Nicht-MSL-Ausnahme beruht auf der notwendigen Borland-/Turbo-Vision-
  Quell- und ABI-Kompatibilität über Unix-, Windows- und DOS-Ziele hinweg.
- Eingaben, Puffergrenzen, Zeigerlebenszeiten und Terminal-I/O benötigen bei
  Änderungen eine explizite Secure-Coding-Prüfung.
- Bestehende englische Upstream-Dokumentation bleibt erhalten. Neue lokale
  Governance-Inhalte stehen Deutsch zuerst und Englisch danach.
- Die konservative und vorläufige Thorsten-Solo-Referenz beträgt jeweils
  `80` Zeilen/Arbeitstag; ein eigener C++-Speedup braucht eine begründete
  Neufestlegung.

*The primary language is C++14 with CMake. The non-MSL exception preserves
Borland/Turbo Vision source and ABI compatibility across Unix, Windows, and
DOS targets. Changes require explicit secure-coding review of input, buffer
bounds, pointer lifetimes, and terminal I/O. Existing English upstream
documentation is preserved; new local governance content is German-first and
English-second. Both conservative and provisional Thorsten-solo references
remain `80` lines per workday until a justified C++ baseline is adopted.*
