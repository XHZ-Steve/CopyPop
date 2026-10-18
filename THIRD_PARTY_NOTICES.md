# Third-party notices

CopyPop application code: MIT, copyright 2026 XHZ-Steve and contributors. See LICENSE.

Lucide icons: version 0.468.0, ISC, copyright Lucide contributors and portions copyright Cole Bemis (Feather). Only selected SVGs are packaged. Original SVGs and license: https://github.com/lucide-icons/lucide/tree/0.468.0 . Full notice: licenses/Lucide.txt. Icons are unchanged except Qt applies display color at runtime.

Qt 6.11.1: copyright The Qt Company Ltd. and other contributors. This distribution dynamically links Qt modules; it uses the LGPLv3 option for Qt Base, Qt Declarative (including Qt Quick Controls), Qt SVG, Qt Shader Tools, and any deployed Qt Image Formats plugins. Licenses LGPLv3 and GPLv3 plus the Qt GPL exception are included in licenses/. Qt's bundled third-party attribution is included through the deployed module SBOMs and the matching source archives. The QML used here uses no intentionally GPL-only Qt module.

Recipients may replace the Qt DLLs and plugins with ABI-compatible modified builds. CopyPop's MIT source and build scripts permit relinking; no technical measure or EULA forbids reverse engineering to debug modifications of LGPL components. Installation uses ordinary files and does not require signing keys. The application is currently unsigned.

Exact Qt component source archives, build descriptions and third-party licenses are provided in the companion `CopyPop-1.0.0-third-party-sources` folder (also suitable for publishing alongside the binary download). `scripts/fetch-qt-sources.ps1` downloads the official unmodified 6.11.1 component archives and records SHA256 hashes. Preserve and offer this companion download alongside redistributions; a link to this repository by itself is not a substitute for fulfilling the source distribution obligations. Official upstream: https://download.qt.io/official_releases/qt/6.11/6.11.1/submodules/ . Qt build instructions are in the source archives and https://doc.qt.io/qt-6/windows-building.html . If distributing a different Qt version or patched Qt, update and supply its exact corresponding source, including patches and build instructions.

MinGW runtime: GCC 13.1.0 runtime libraries are covered by GPLv3 with the GCC Runtime Library Exception; winpthreads uses its included permissive license. These notices are in licenses/MinGW-GCC and licenses/MinGW-winpthreads. No compiler binaries are bundled with the portable application.

Windows APIs and UI Automation are provided by the operating system. Their headers are used for compilation; Windows components are not redistributed.
