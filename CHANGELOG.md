# Changelog

## [0.5.0](https://github.com/vergissberlin/ambientnav/compare/ambientnav-v0.4.0...ambientnav-v0.5.0) (2026-06-20)


### Features

* add cross-platform Flutter app for navigation and controller management ([5b399d6](https://github.com/vergissberlin/ambientnav/commit/5b399d6a3b045bb206831e093155af433d0f7bef))
* **app,design-system:** iOS background navigation, route progress tracker & design system ([b4e2b27](https://github.com/vergissberlin/ambientnav/commit/b4e2b27380e6ebd08598b418009035f7949818d9))
* **app:** add CarPlay/Android Auto bridge and native template references ([d05ddda](https://github.com/vergissberlin/ambientnav/commit/d05dddaa9e64c94ee12a2bdcc7ec7f17e391d06c))
* **app:** add dev route simulation mode ([331e8a5](https://github.com/vergissberlin/ambientnav/commit/331e8a50e749de619a3f6da3536d880ff7e603f5))
* **app:** add real flutter_blue_plus BLE controller repository ([27d59f0](https://github.com/vergissberlin/ambientnav/commit/27d59f075d6be18bf2e92c8be5b9b694cb15f280))
* **app:** heading-up follow camera + route overview toggle ([d8e53bb](https://github.com/vergissberlin/ambientnav/commit/d8e53bb3d4ed63fb8e4f8888c74b2d331d064309))
* **app:** iOS background navigation, route progress tracker & design system ([1f71d65](https://github.com/vergissberlin/ambientnav/commit/1f71d6561fb8a6cc3fa74b0908832692ba954da0))
* **app:** wire up navigation — street map, search, routing, voice ([c6f2d07](https://github.com/vergissberlin/ambientnav/commit/c6f2d079542b8b1a8203ae1d419f220b2a9dd00f))
* **design-system:** add animated LogoMark with turn-signal dot animation ([f5f6467](https://github.com/vergissberlin/ambientnav/commit/f5f64676351d81cde70949ae8bb7e7abe580fe91))
* **docs:** add AmbientNav Starlight theme from design system ([5964f20](https://github.com/vergissberlin/ambientnav/commit/5964f20cd77a68829a4ea7746986712e3979fbe8))
* **docs:** add animated LED hero visual and system diagram to homepage ([f015b93](https://github.com/vergissberlin/ambientnav/commit/f015b93424d2e74cca743ddca7f3f630f9283e38))
* **docs:** add v0.2.0 and v0.3.0 to version selector ([5a07585](https://github.com/vergissberlin/ambientnav/commit/5a07585d0b31ce18e7d61c50fc736c0ea2db1fbd))
* **docs:** dynamically populate version selector from git tags ([ef73223](https://github.com/vergissberlin/ambientnav/commit/ef73223ed60c6df6e4b0c6e8389947ee711d0dfc))
* **docs:** link release notes for each selected version in sidebar ([d2f18dd](https://github.com/vergissberlin/ambientnav/commit/d2f18dd1d689b143eeee8d4050eaaf9815fe7a6d))
* **docs:** replace favicon and add brand logo mark to Starlight ([a3fc4bd](https://github.com/vergissberlin/ambientnav/commit/a3fc4bd52d8fd5ef74801b1761deb5f9c7c06449))
* **ios:** add Local.xcconfig.example for setting up Apple Developer Team ID ([f8e233d](https://github.com/vergissberlin/ambientnav/commit/f8e233de28b6c66bfde3d41af31fa8d84cccc2d5))
* **Justfile:** add Justfile for development shortcuts ([a57347d](https://github.com/vergissberlin/ambientnav/commit/a57347d6816884ed6802f1fab475da1088b1b5f1))
* **localization:** add AppLocalizations for multilingual support ([7e41a79](https://github.com/vergissberlin/ambientnav/commit/7e41a79a2703184e4fbdd1a18db0bd2651a22f37))
* **localization:** add German and English translations ([7e41a79](https://github.com/vergissberlin/ambientnav/commit/7e41a79a2703184e4fbdd1a18db0bd2651a22f37))
* **localization:** add localization delegate for German and English ([7e41a79](https://github.com/vergissberlin/ambientnav/commit/7e41a79a2703184e4fbdd1a18db0bd2651a22f37))
* **map:** add dark mode support for map tiles ([fc7d49f](https://github.com/vergissberlin/ambientnav/commit/fc7d49fb023cba2ff480fbd4cdcf0535230aa1d6))


### Bug Fixes

* **android:** bump Kotlin Gradle plugin to 2.2.20 for flutter_tts ([06db1f4](https://github.com/vergissberlin/ambientnav/commit/06db1f436ac302a0d186986fa01fe6fb8ee509cf))
* **app:** apply dart format to fix CI formatting check ([166f64c](https://github.com/vergissberlin/ambientnav/commit/166f64c4196fb3c805e00d3e3a0ee9e73e61aaff))
* **build-app.yml:** ensure sdkmanager accepts licenses by piping 'yes' to command ([c9690cd](https://github.com/vergissberlin/ambientnav/commit/c9690cdb6652d62eb99866f627eab048d69745eb))
* **ci:** revert l10n synthetic-package:false to keep gen-l10n + format check green ([f8e6c52](https://github.com/vergissberlin/ambientnav/commit/f8e6c52a101e8a878fb9b0f3fb13a01afeaba624))
* **ci:** trigger firmware build and asset upload on release-please releases ([2d61b40](https://github.com/vergissberlin/ambientnav/commit/2d61b40fd23096e6d731bb8c360d4dc572f5ab84))
* **docs:** skip starlight-versions plugin when no previous versions exist ([ebb3962](https://github.com/vergissberlin/ambientnav/commit/ebb396259f98e8f82708211d8b78d171ae8182f7))
* **firmware:** add mergebin post-build script for merged flash images ([9328c38](https://github.com/vergissberlin/ambientnav/commit/9328c38b1fd62a8ecf0f0217191bc7cfbe628b28))
* **map:** replace setStyleString with ValueKey for dark mode switching ([3f7a377](https://github.com/vergissberlin/ambientnav/commit/3f7a377d9bb035bb86cd9399a6abbcfcb0736171))


### Documentation

* add new logo image to documentation ([76e4b62](https://github.com/vergissberlin/ambientnav/commit/76e4b622e232b195c2100eb9706466f5900ea1d9))
* add user-facing module documentation pages ([fb34577](https://github.com/vergissberlin/ambientnav/commit/fb34577a6fb3d5e80a9b14cf4946e143a0bded12))
* **AGENTS.md:** add UI Component Architecture section detailing Atomic Design principles for Flutter app development ([b5a8a78](https://github.com/vergissberlin/ambientnav/commit/b5a8a781433dc6c4149c73d6229d3082845bd990))
* **README.md:** add instructions for iOS device setup and wireless debugging ([f8e233d](https://github.com/vergissberlin/ambientnav/commit/f8e233de28b6c66bfde3d41af31fa8d84cccc2d5))
* **README.md:** specify plaintext for code block to improve readability ([7e41a79](https://github.com/vergissberlin/ambientnav/commit/7e41a79a2703184e4fbdd1a18db0bd2651a22f37))
* **README.md:** update development section with Justfile commands ([a57347d](https://github.com/vergissberlin/ambientnav/commit/a57347d6816884ed6802f1fab475da1088b1b5f1))


### Firmware

* implement extended GATT protocol with passkey bonding and OTA ([1e291df](https://github.com/vergissberlin/ambientnav/commit/1e291df8345def288a82044a3d5029b79b82d97b))

## [0.4.0](https://github.com/vergissberlin/ambientnav/compare/ambientnav-v0.3.0...ambientnav-v0.4.0) (2026-06-17)


### Features

* add merged firmware binaries to release assets and flash-firmware docs ([741a14f](https://github.com/vergissberlin/ambientnav/commit/741a14fb62eb69637e4aa57154cc2702738250d4))
* **docs:** add ESP Web Tools in-browser firmware flasher ([e6b0c71](https://github.com/vergissberlin/ambientnav/commit/e6b0c715bf750facc10177972425d09b6e99778a))


### Bug Fixes

* resolve merge conflicts with main ([243e525](https://github.com/vergissberlin/ambientnav/commit/243e525c2aa2d3e2f3b435703055e6a0fc861a1d))


### Documentation

* add compatible microcontrollers section with Amazon affiliate links ([0b393ea](https://github.com/vergissberlin/ambientnav/commit/0b393eafab1984e9e422bd164fff71523d7a5c5a))

## [0.3.0](https://github.com/vergissberlin/ambientnav/compare/ambientnav-v0.2.0...ambientnav-v0.3.0) (2026-06-17)


### Features

* **docs:** upgrade Starlight 0.40 + Astro 6, add version selector and Hardware/Wiring section ([0236cb9](https://github.com/vergissberlin/ambientnav/commit/0236cb912525c3270931bf47558aba308ad13e1a))
* **docs:** upgrade Starlight 0.40 + Astro 6, version selector, Hardware/Wiring section ([d1bdfaa](https://github.com/vergissberlin/ambientnav/commit/d1bdfaad3606bd176badf36a1e539c8459c64f69))


### Bug Fixes

* **ci:** sanitize changed file paths in translate script ([f17a397](https://github.com/vergissberlin/ambientnav/commit/f17a397d1c79875ce7600e5470fa4a171bf604fc))

## [0.2.0](https://github.com/vergissberlin/ambientnav/compare/ambientnav-v0.1.0...ambientnav-v0.2.0) (2026-06-17)


### Features

* **docs:** add custom favicon for Starlight docs site ([17ef3ca](https://github.com/vergissberlin/ambientnav/commit/17ef3ca1850030829559d05b2d5a14a6ba929e83))
* **docs:** add favicon.svg to enhance branding and visual identity ([997b45a](https://github.com/vergissberlin/ambientnav/commit/997b45a292c251d3c6336d43a71871b5496b62fb))
* **firmware:** ESP32 firmware, user docs & CI/CD release pipeline ([cb50e11](https://github.com/vergissberlin/ambientnav/commit/cb50e111413f72cc38674f01f5342829321ecf46))
* **firmware:** implement ESP32 front/rear firmware, user docs, and CI/CD release pipeline ([7220ce3](https://github.com/vergissberlin/ambientnav/commit/7220ce3a8f4e230f5dbe679539a8190c76d570af))
* initial project setup ([d406774](https://github.com/vergissberlin/ambientnav/commit/d406774828eccf4de1ca98a256a93bacf1708662))


### Bug Fixes

* **ci:** repair release-please PR creation ([15b300b](https://github.com/vergissberlin/ambientnav/commit/15b300bedb8554c60a0ba31fe94f3bacc32a1917))
* **ci:** repair release-please PR creation ([1253b52](https://github.com/vergissberlin/ambientnav/commit/1253b5295b6825ad94b38a4412083e39af59ef17))


### Documentation

* **AGENTS.md:** add repository workflow guidelines for trunk-based development ([3b4c883](https://github.com/vergissberlin/ambientnav/commit/3b4c883f350f771667ab322747fd3845b2c8a479))
