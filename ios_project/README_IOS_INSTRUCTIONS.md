# 🍏 ECHO: THE SCRAPPY-BOT — PROJET NATIVE IOS (IPHONE & IPAD)

> **Projet :** Adaptation Officielle iOS d'*Echo: The Scrappy-Bot*  
> **Technologies :** Swift 5.9+ / Swift 6, SwiftUI, C++20 Natif (`ScavengerEngine`), Objective-C++ Bridge, Metal Shaders, `AVAudioEngine` DSP 24 kHz, CoreHaptics, WidgetKit.  
> **Compatibilité :** iOS 16.0+, iOS 17.0+, iOS 18.0+ (iPhone & iPad).

---

## 1. STRUCTURE DU PROJET IOS

```
ios/
├── EchoTheScrappyBot/
│   ├── App/
│   │   ├── EchoTheScrappyBotApp.swift   # Point d'entrée de l'application iOS (@main)
│   │   ├── ContentView.swift            # Menus, coordination, overlays et boucles
│   │   └── Info.plist                   # Déclarations permissions zéro-trust (Caméra, Motion)
│   ├── Engine/                          # CŒUR DU JEU C++20 (100% IDENTIQUE À ANDROID)
│   │   ├── ScavengerDebris.h            # Définition 16-octets SIMD des reliques & bombes
│   │   ├── ScavengerEngine.h            # Moteur physique, Parry, 17 Niveaux, Boss 840 PV
│   │   ├── ScavengerEngine.cpp          # Algorithmes de jeu C++20 standards
│   │   ├── ScavengerBridge.h            # Interface Objective-C++ pour Swift
│   │   ├── ScavengerBridge.mm           # Implémentation du pont C++ <-> Swift
│   │   └── EchoTheScrappyBot-Bridging-Header.h
│   ├── Views/
│   │   ├── RetroGameView.swift          # Rendu Canvas 60/120 FPS vectoriel & Touch
│   │   ├── CRTShaders.metal             # Shaders Metal (Trinitron CRT, scanlines, glitches)
│   │   └── TerminalView.swift           # Écran système Level 17 (ECHO.EXE & 6 Épreuves)
│   ├── Audio/
│   │   └── RetroSoundManager.swift      # Synthétiseur logiciel DSP 5 couches (AVAudioEngine 24kHz)
│   ├── Hardware/
│   │   └── HardwareTrialsManager.swift  # Gestionnaire des 6 capteurs physiques sur iPhone
│   ├── Localization/
│   │   └── EchoLocalization.swift       # 12 Langues officielles intégrées
│   ├── Persistence/
│   │   └── ScoreManager.swift           # Sauvegarde persistante UserDefaults & Auto-Save
│   └── Widget/
│       └── EchoDeskWidget.swift         # Widget iOS WidgetKit ("Le Bureau d'Écho")
├── .github/workflows/
│   └── ios_build.yml                    # Compilation automatique dans le cloud sans Mac !
├── Package.swift                        # Manifeste Swift Package Manager moderne
└── README_IOS_INSTRUCTIONS.md           # Ce guide
```

---

## 2. LES 6 ÉPREUVES DU NIVEAU 17 ADAPTÉES SUR IPHONE

| Épreuve | Capteur iPhone sollicité | Adaptation Technique iOS |
| :---: | :--- | :--- |
| **1/6 : Voile d'Ombre** | Obscurité ambiante / Occlusion | Détection de chute de luminosité d'écran (`UIScreen.brightness`) et capteur de proximité frontal quand le téléphone est couvert. |
| **2/6 : Fanal Stellaire** | Lampe Torche dans les 45s | Pilotage matériel via `AVCaptureDevice.torchMode = .on` / `.off`. |
| **3/6 : Bouclier Thermique** | Proximité frontale (< 5 cm) | `UIDevice.current.isProximityMonitoringEnabled = true` (bloque le scan orbital quand la main est posée sur l'écouteur). |
| **4/6 : Résonance 432 Hz** | Boutons physiques de Volume | Observation directe du bus audio `AVAudioSession.sharedInstance().observe(\.outputVolume)` (3 pressions = 144 ➔ 288 ➔ 432 Hz). |
| **5/6 : Défragmentation** | Secousses physiques réelles | `CMMotionManager` avec détection de G-Force > 1.35G (> 13 m/s²) pour 3 secousses consécutives. |
| **6/6 : Bouclier Optique** | Prise de photo réelle | `AVCapturePhotoOutput` / `UIImagePickerController` : convertit la photo en RAM en texture CRT 8-bit sans écriture disque. |

---

## 3. COMMENT OUVRIR ET COMPILER LE PROJET

### Option A : Sur un Mac (avec Xcode)
1. Copiez le dossier `ios/` sur un Mac.
2. Ouvrez **Xcode** et sélectionnez `File > Open`, puis choisissez le dossier `ios/` (ou le fichier `Package.swift`).
3. Xcode détecte automatiquement le pont Objective-C++ et le code C++20.
4. Sélectionnez votre iPhone (ou le simulateur iPhone 15/16) et appuyez sur **Cmd + R** (Run) pour jouer !

### Option B : Sans aucun Mac (Via GitHub Actions dans le Cloud)
1. Poussez le projet sur un dépôt GitHub (privé ou public).
2. GitHub détecte automatiquement le fichier `.github/workflows/ios_build.yml`.
3. Un serveur Mac virtuel (`macos-14`) démarre gratuitement, compile le code Swift et le moteur C++20, et vous génère l'archive prête à l'emploi dans l'onglet **Actions** !
