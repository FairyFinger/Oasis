//
//  EchoLocalization.swift
//  Echo: The Scrappy-Bot (iOS Native Edition)
//
//  Complete 12-Language Localization Engine for Story, Dialogues,
//  AVSpeechSynthesizer Voice, and Level 17 Hardware Trials.
//

import Foundation

public enum EchoLanguage: String, CaseIterable, Identifiable {
    case fr = "fr"
    case en = "en"
    case de = "de"
    case es = "es"
    case it = "it"
    case pt = "pt"
    case ja = "ja"
    case zh = "zh"
    case ko = "ko"
    case id = "id"
    case th = "th"
    case ar = "ar"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .fr: return "Français"
        case .en: return "English"
        case .de: return "Deutsch"
        case .es: return "Español"
        case .it: return "Italiano"
        case .pt: return "Português (Brasil)"
        case .ja: return "日本語"
        case .zh: return "中文 (简体)"
        case .ko: return "한국어"
        case .id: return "Bahasa Indonesia"
        case .th: return "ภาษาไทย"
        case .ar: return "العربية"
        }
    }
}

public struct EchoLocalization {
    public static var currentLanguage: EchoLanguage {
        let code = Locale.current.language.languageCode?.identifier ?? "fr"
        return EchoLanguage(rawValue: code) ?? .fr
    }

    public static func getUserTag(_ lang: EchoLanguage = currentLanguage) -> String {
        switch lang {
        case .en: return "[YOU]"
        case .de: return "[DU]"
        case .es: return "[TÚ]"
        case .it: return "[TU]"
        case .pt: return "[VOCÊ]"
        case .ja: return "[YOU]"
        case .zh: return "[你]"
        case .ko: return "[당신]"
        case .id: return "[ANDA]"
        case .th: return "[คุณ]"
        case .ar: return "[أنت]"
        case .fr: return "[VOUS]"
        }
    }

    public static func getCaptainTitle(_ lang: EchoLanguage = currentLanguage, customName: String = "") -> String {
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed.lowercased() != "capitaine" && trimmed.lowercased() != "captain" {
            return trimmed
        }
        switch lang {
        case .en: return "Captain"
        case .de: return "Kapitän"
        case .es: return "Capitán"
        case .it: return "Capitano"
        case .pt: return "Capitão"
        case .ja: return "艦長"
        case .zh: return "舰长"
        case .ko: return "선장님"
        case .id: return "Kapten"
        case .th: return "กัปตัน"
        case .ar: return "أيها القبطان"
        case .fr: return "Capitaine"
        }
    }

    // Hardware Trial instructions
    public static func getTrial1Prompt(_ lang: EchoLanguage = currentLanguage) -> String {
        switch lang {
        case .en: return "TRIAL 1/6: Voile d'Ombre\nCover the screen or darken your room (< 25 lux) to activate Echo's optical camouflage!"
        case .de: return "PRÜFUNG 1/6: Schatten-Schleier\nBedecke den Bildschirm (< 25 Lux), um Echos optische Tarnung zu aktivieren!"
        case .es: return "PRUEBA 1/6: Velo de Sombra\n¡Cubre la pantalla (< 25 lux) para activar el camuflaje óptico de Echo!"
        case .it: return "PROVA 1/6: Velo d'Ombra\nCopri lo schermo (< 25 lux) per attivare il camuffamento ottico di Echo!"
        case .pt: return "PROVA 1/6: Véu de Sombra\nCubra a tela (< 25 lux) para ativar a camuflagem óptica de Echo!"
        case .ja: return "試練 1/6: 影のベール\n画面を手で覆うか部屋を暗くして（25ルクス未満）、エコーの光学迷彩を起動せよ！"
        case .zh: return "考验 1/6：暗影面纱\n遮住屏幕或调暗房间光线（低于25勒克斯），启动Echo的光学伪装！"
        case .ko: return "시련 1/6: 그림자의 장막\n화면을 가리거나 어둡게 하여(25럭스 미만) 에코의 광학 위장을 활성화하세요!"
        case .id: return "UJIAN 1/6: Selubung Bayangan\nTutup layar ponsel (< 25 lux) untuk mengaktifkan kamuflase optik Echo!"
        case .th: return "บททดสอบ 1/6: ม่านเงา\nปิดหน้าจอหรือทำให้ห้องมืดลง (< 25 lux) เพื่อเปิดใช้งานการพรางตัวของ Echo!"
        case .ar: return "الاختبار 1/6: حجاب الظل\nغطِّ الشاشة أو أطفئ الضوء (< 25 لوكس) لتفعيل تمويه إيكو البصري!"
        case .fr: return "ÉPREUVE 1/6 : Voile d'Ombre\nCouvrez l'écran ou plongez dans le noir (< 25 lux) pour activer le camouflage optique d'Écho !"
        }
    }

    public static func getTrial2Prompt(_ lang: EchoLanguage = currentLanguage) -> String {
        switch lang {
        case .en: return "TRIAL 2/6: Fanal Stellaire\nTurn ON your phone flashlight within 45s to blind the Tracker's optical matrix!"
        case .de: return "PRÜFUNG 2/6: Sternenfeuer\nSchalte deine Taschenlampe ein, um die optischen Sensoren des Jägers zu blenden!"
        case .es: return "PRUEBA 2/6: Faro Estelar\n¡Enciende la linterna de tu teléfono para cegar los sensores ópticos del Cazador!"
        case .it: return "PROVA 2/6: Fanale Stellare\nAccendi la torcia del telefono per accecare i sensori del Cacciatore!"
        case .pt: return "PROVA 2/6: Farol Estelar\nLigue a lanterna do celular para cegar os sensores ópticos do Rastreador!"
        case .ja: return "試練 2/6: 星の灯火\nスマホの懐中電灯（フラッシュライト）を点灯させてトラッカーの光学センサーを盲目にせよ！"
        case .zh: return "考验 2/6：星辰信标\n打开手机手电筒，致盲追踪者的光学探测矩阵！"
        case .ko: return "시련 2/6: 별빛 봉화\n스마트폰의 손전등(플래시)을 켜서 추적자의 광학 센서를 무력화하세요!"
        case .id: return "UJIAN 2/6: Lentera Bintang\nNyalakan senter ponsel untuk membutakan sensor optik sang Pelacak!"
        case .th: return "บททดสอบ 2/6: ประภาคารดวงดาว\nเปิดไฟฉายโทรศัพท์ของคุณเพื่อทำให้เซ็นเซอร์ออปติคอลของนักล่าตาบอด!"
        case .ar: return "الاختبار 2/6: المنارة النجمية\nشغّل فلاش الهاتف لإعماء مصفوفة المتتبع البصرية!"
        case .fr: return "ÉPREUVE 2/6 : Fanal Stellaire\nAllumez la lampe torche de votre iPhone pour aveugler la matrice optique du Traqueur !"
        }
    }

    public static func getTrial3Prompt(_ lang: EchoLanguage = currentLanguage) -> String {
        switch lang {
        case .en: return "TRIAL 3/6: Thermal Shield\nHold your hand over the top speaker (< 5 cm) to deflect the orbital thermal scan!"
        case .de: return "PRÜFUNG 3/6: Hitzeschild\nHalte deine Hand über die Hörmuschel (< 5 cm), um den Scan abzuwehren!"
        case .es: return "PRUEBA 3/6: Escudo Térmico\n¡Coloca la mano sobre la parte superior (< 5 cm) para bloquear el escaneo térmico!"
        case .it: return "PROVA 3/6: Scudo Termico\nPosiziona la mano vicino alla parte superiore (< 5 cm) per bloccare la scansione!"
        case .pt: return "PROVA 3/6: Escudo Térmico\nColoque a mão sobre o topo do celular (< 5 cm) para repelir o escaneamento orbital!"
        case .ja: return "試練 3/6: 熱シールド\n画面上部に手をかざして（5cm以内）、軌道熱スキャンを遮断せよ！"
        case .zh: return "考验 3/6：热能护盾\n将手置于手机顶部听筒上方（5厘米内），阻挡轨道热能扫描！"
        case .ko: return "시련 3/6: 열 보호막\n화면 상단부(5cm 이내)에 손을 올려 궤도 열 스캔을 차단하세요!"
        case .id: return "UJIAN 3/6: Perisai Termal\nDekatkan tangan Anda ke bagian atas layar (< 5 cm) untuk memblokir pemindaian!"
        case .th: return "บททดสอบ 3/6: โล่ความร้อน\nวางมือของคุณไว้เหนือหน้าจอ (< 5 ซม.) เพื่อป้องกันการสแกนความร้อน!"
        case .ar: return "الاختبار 3/6: الدرع الحراري\nضع يدك فوق أعلى الشاشة (< 5 سم) لصد المسح الحراري المداري!"
        case .fr: return "ÉPREUVE 3/6 : Bouclier Thermique\nApprochez votre main du haut de l'écran (< 5 cm) pour dévier le scan thermique orbital !"
        }
    }

    public static func getTrial4Prompt(_ lang: EchoLanguage = currentLanguage) -> String {
        switch lang {
        case .en: return "TRIAL 4/6: Resonance 432 Hz\nPress the hardware Volume buttons 3 times (144 Hz -> 288 Hz -> 432 Hz) to balance the acoustic core!"
        case .de: return "PRÜFUNG 4/6: Resonanz 432 Hz\nDrücke die physischen Lautstärketasten 3 Mal, um die Frequenzen abzustimmen!"
        case .es: return "PRUEBA 4/6: Resonancia 432 Hz\n¡Presiona los botones físicos de volumen 3 veces para estabilizar el núcleo!"
        case .it: return "PROVA 4/6: Risonanza 432 Hz\nPremi i tasti fisici del volume 3 volte per sincronizzare la risonanza armonica!"
        case .pt: return "PROVA 4/6: Ressonância 432 Hz\nPressione os botões de volume físico 3 vezes para calibrar o núcleo sônico!"
        case .ja: return "試練 4/6: 432Hz共鳴\n音量ボタンを3回押して（144Hz ➔ 288Hz ➔ 432Hz）、音響コアを調律せよ！"
        case .zh: return "考验 4/6：432赫兹共振\n按压实体音量键3次（144Hz ➔ 288Hz ➔ 432Hz），调谐声学核心！"
        case .ko: return "시련 4/6: 432Hz 공명\n음량 조절 물리 버튼을 3회 눌러(144Hz ➔ 288Hz ➔ 432Hz) 음향 코어를 조율하세요!"
        case .id: return "UJIAN 4/6: Resonansi 432 Hz\nTekan tombol volume fisik 3 kali untuk menyelaraskan inti akustik!"
        case .th: return "บททดสอบ 4/6: เสียงสะท้อน 432 Hz\nกดปุ่มปรับระดับเสียง 3 ครั้ง เพื่อปรับแต่งคลื่นความถี่ของแกนอะคูสติก!"
        case .ar: return "الاختبار 4/6: الرنين 432 هرتز\nاضغط على أزرار الصوت 3 مرات لموازنة النواة الصوتية!"
        case .fr: return "ÉPREUVE 4/6 : Résonance 432 Hz\nAppuyez 3 fois sur les boutons physiques de Volume (144 Hz ➔ 288 Hz ➔ 432 Hz) pour stabiliser le noyau !"
        }
    }

    public static func getTrial5Prompt(_ lang: EchoLanguage = currentLanguage) -> String {
        switch lang {
        case .en: return "TRIAL 5/6: Kinetic Defragmentation\nPhysically shake your iPhone 3 times (> 13 m/s²) to purge corrupted RAM locks!"
        case .de: return "PRÜFUNG 5/6: Kinetische Defragmentierung\nSchüttle dein iPhone 3 Mal kräftig, um beschädigte RAM-Sperren zu lösen!"
        case .es: return "PRUEBA 5/6: Desfragmentación Cinética\n¡Sacude físicamente tu iPhone 3 veces para romper los bloqueos de RAM corruptos!"
        case .it: return "PROVA 5/6: Deframmentazione Cinetica\nScuoti fisicamente l'iPhone 3 volte per spezzare i blocchi di memoria RAM!"
        case .pt: return "PROVA 5/6: Desfragmentação Cinética\nSacuda fisicamente seu iPhone 3 vezes para quebrar as travas corrompidas de RAM!"
        case .ja: return "試練 5/6: 運動デフラグ\niPhoneを3回力強く振って、破損したRAMロックを粉砕せよ！"
        case .zh: return "考验 5/6：动能碎片整理\n用力晃动iPhone 3次，粉碎崩溃的内存死锁！"
        case .ko: return "시련 5/6: 운동 디프래그\niPhone을 힘차게 3번 흔들어 손상된 RAM 잠금을 해제하세요!"
        case .id: return "UJIAN 5/6: Defragmentasi Kinetik\nGoyangkan iPhone Anda 3 kali untuk menghancurkan kunci RAM yang rusak!"
        case .th: return "บททดสอบ 5/6: การจัดเรียงข้อมูลจลน์\nเขย่า iPhone ของคุณ 3 ครั้ง เพื่อปลดล็อกหน่วยความจำ RAM ที่เสียหาย!"
        case .ar: return "الاختبار 5/6: إلغاء التجزئة الحركية\nهزّ جهاز الآيفون 3 مرات بقوة لكسر أقفال الذاكرة التالفة!"
        case .fr: return "ÉPREUVE 5/6 : Défragmentation Cinétique\nSecouez physiquement votre iPhone 3 fois (> 13 m/s²) pour briser les verrous RAM corrompus !"
        }
    }

    public static func getTrial6Prompt(_ lang: EchoLanguage = currentLanguage) -> String {
        switch lang {
        case .en: return "TRIAL 6/6: Optical Real Shield\nTake a real photo of your surroundings: Echo will convert it into an 8-bit CRT energy shield!"
        case .de: return "PRÜFUNG 6/6: Reales Optisches Schild\nMach ein echtes Foto deiner Umgebung: Echo verwandelt es in ein 8-Bit-CRT-Schild!"
        case .es: return "PRUEBA 6/6: Escudo Óptico Real\n¡Toma una foto real de tu entorno: Echo la convertirá en un escudo de energía CRT de 8 bits!"
        case .it: return "PROVA 6/6: Scudo Ottico Reale\nScatta una foto reale dell'ambiente circostante: Echo la trasformerà in uno scudo CRT a 8 bit!"
        case .pt: return "PROVA 6/6: Escudo Óptico Real\nTire uma foto real ao seu redor: Echo vai convertê-la em um escudo CRT de 8 bits!"
        case .ja: return "試練 6/6: 実世界光学シールド\n周囲の写真を1枚撮影せよ：エコーが8ビットCRTエナジーシールドに変換する！"
        case .zh: return "考验 6/6：真实光学护盾\n拍一张你周围环境的照片：Echo会将其合成为8位CRT能量护盾！"
        case .ko: return "시련 6/6: 실제 광학 방패\n주변 풍경을 사진으로 촬영하세요: 에코가 8비트 CRT 에너지 방패로 변환합니다!"
        case .id: return "UJIAN 6/6: Perisai Optik Nyata\nAmbil foto lingkungan Anda: Echo akan mengubahnya menjadi perisai energi CRT 8-bit!"
        case .th: return "บททดสอบ 6/6: โล่ออปติคอลของจริง\nถ่ายภาพสภาพแวดล้อมของคุณ: Echo จะแปลงมันเป็นโล่พลังงาน CRT 8 บิต!"
        case .ar: return "الاختبار 6/6: الدرع البصري الحقيقي\nالتقط صورة حقيقية لمحيطك: سيحولها إيكو إلى درع طاقة بنمط 8-بت!"
        case .fr: return "ÉPREUVE 6/6 : Bouclier Optique Réel\nPrenez une photo en temps réel de votre environnement : Écho l'injectera dans son bouclier CRT 8-bit !"
        }
    }
}
