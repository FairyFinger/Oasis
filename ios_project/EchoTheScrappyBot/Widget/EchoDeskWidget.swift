//
//  EchoDeskWidget.swift
//  Echo: The Scrappy-Bot (iOS Native Edition)
//
//  WidgetKit Widget for iOS Home Screen & Lock Screen ("Le Bureau d'Écho").
//  Locked state before Level 17 victory; Companion AI & Circadian Cycle after.
//

import WidgetKit
import SwiftUI

struct EchoWidgetEntry: TimelineEntry {
    let date: Date
    let isUnlocked: Bool
    let batteryLevel: Int
    let captainName: String
    let statusMessage: String
}

struct EchoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> EchoWidgetEntry {
        EchoWidgetEntry(
            date: Date(),
            isUnlocked: true,
            batteryLevel: 85,
            captainName: "Capitaine",
            statusMessage: "Oasis Silicium en veille stable."
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (EchoWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EchoWidgetEntry>) -> Void) {
        let isUnlocked = ScoreManager.shared.isTrueEndingUnlocked()
        let captain = ScoreManager.shared.getCaptainName()
        let battery = Int(UIDevice.current.batteryLevel * 100)

        let hour = Calendar.current.component(.hour, from: Date())
        let status: String
        if !isUnlocked {
            status = "SECTEUR 17 VERROUILLÉ — Libérez Écho du Traqueur !"
        } else if hour >= 23 || hour < 7 {
            status = "Mode Veille Nocturne (Recharge en cours...)"
        } else {
            status = "Oasis Silicium : Systèmes 100% opérationnels !"
        }

        let entry = EchoWidgetEntry(
            date: Date(),
            isUnlocked: isUnlocked,
            batteryLevel: max(10, battery),
            captainName: captain,
            statusMessage: status
        )

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct EchoDeskWidgetView: View {
    var entry: EchoWidgetEntry

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.08, blue: 0.16)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(entry.isUnlocked ? Color.cyan : Color.red)
                        .frame(width: 8, height: 8)
                    Text(entry.isUnlocked ? "ÉCHO : EN LIGNE" : "ÉCHO : VERROUILLÉ")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(entry.isUnlocked ? .cyan : .red)
                    Spacer()
                    Text("⚡ \(entry.batteryLevel)%")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                }

                Spacer()

                if entry.isUnlocked {
                    Text("Bonjour, \(entry.captainName) !")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text(entry.statusMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                } else {
                    Text("SECTEUR 17")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)
                    Text(entry.statusMessage)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(12)
        }
    }
}

public struct EchoDeskWidget: Widget {
    public let kind: String = "EchoDeskWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EchoWidgetProvider()) { entry in
            EchoDeskWidgetView(entry: entry)
        }
        .configurationDisplayName("Le Bureau d'Écho")
        .description("Surveillez l'état de l'Oasis Silicium et gardez le contact avec Écho.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
