import SwiftUI
import PanchangAlarmCore

struct ContentView: View {
    @AppStorage("panchang.config.data") private var configData: Data = try! JSONEncoder().encode(AppAlarmConfig.empty)
    @StateObject private var scheduler = AlarmScheduler()
    @State private var showingTithiPicker = false
    @State private var showingLocationPicker = false
    @State private var isScheduling = false
    @State private var lastScheduledSummary: String?

    private var config: AppAlarmConfig {
        get { (try? JSONDecoder().decode(AppAlarmConfig.self, from: configData)) ?? .empty }
    }

    private func updateConfig(_ transform: (inout AppAlarmConfig) -> Void) {
        var current = config
        transform(&current)
        configData = (try? JSONEncoder().encode(current)) ?? configData
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.orange)
                            .frame(width: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Panchang Alarm")
                                .font(.headline)
                            Text("Wake up on the days that matter")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)

                Section("Location") {
                    Button {
                        showingLocationPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Location")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(config.locationName.isEmpty ? "Not set" : config.locationName)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("locationSummaryText")
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("locationRow")
                }

                Section("Tithis to track") {
                    Button {
                        showingTithiPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "moon.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Selected tithis")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(config.trackedTithiNumbers.isEmpty ? "None" : "\(config.trackedTithiNumbers.count) selected")
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("tithiSummaryText")
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("tithiRow")
                }

                Section("Alarm time") {
                    HStack(spacing: 12) {
                        Image(systemName: "alarm.fill")
                            .foregroundStyle(.orange)
                        DatePicker(
                            "Ring at",
                            selection: Binding(
                                get: {
                                    var comps = DateComponents()
                                    comps.hour = config.alarmHour
                                    comps.minute = config.alarmMinute
                                    return Calendar.current.date(from: comps) ?? Date()
                                },
                                set: { newValue in
                                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                    updateConfig {
                                        $0.alarmHour = comps.hour ?? 6
                                        $0.alarmMinute = comps.minute ?? 0
                                    }
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                Section {
                    Button {
                        Task { await scheduleAlarms() }
                    } label: {
                        HStack {
                            Spacer()
                            if isScheduling {
                                ProgressView()
                            } else {
                                Text("Enable My Tithi Alarms")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .accessibilityIdentifier("enableAlarmsButton")
                    .disabled(config.locationName.isEmpty || config.trackedTithiNumbers.isEmpty || isScheduling)
                }
                .listRowBackground(
                    (config.locationName.isEmpty || config.trackedTithiNumbers.isEmpty || isScheduling)
                    ? Color(.systemGray5)
                    : Color.orange
                )
                .foregroundStyle(
                    (config.locationName.isEmpty || config.trackedTithiNumbers.isEmpty || isScheduling)
                    ? Color.primary
                    : Color.white
                )

                if let summary = lastScheduledSummary {
                    Section("Status") {
                        Label(summary, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(scheduler.usingRealAlarms
                             ? "Using real system alarms (rings through silent mode)."
                             : "Using time-sensitive notifications (fallback - real alarms not yet available on this device/account).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = scheduler.lastError {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Panchang Alarm")
            .tint(.orange)
            .sheet(isPresented: $showingTithiPicker) {
                NavigationStack {
                    TithiPickerView(selected: Binding(
                        get: { config.trackedTithiNumbers },
                        set: { newValue in updateConfig { $0.trackedTithiNumbers = newValue } }
                    ))
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingTithiPicker = false }
                        }
                    }
                }
                .tint(.orange)
            }
            .sheet(isPresented: $showingLocationPicker) {
                NavigationStack {
                    LocationPickerView { name, lat, lon in
                        updateConfig {
                            $0.locationName = name
                            $0.latitude = lat
                            $0.longitude = lon
                        }
                        showingLocationPicker = false
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingLocationPicker = false }
                        }
                    }
                }
                .tint(.orange)
            }
        }
    }

    private func scheduleAlarms() async {
        isScheduling = true
        defer { isScheduling = false }
        await scheduler.rescheduleAll(config: config)
        let matches = TithiCalculator.upcomingMatches(
            trackedTithis: config.trackedTithiNumbers,
            startDate: Date(),
            maxDays: 180,
            latitude: config.latitude,
            longitude: config.longitude
        )
        lastScheduledSummary = "\(matches.count) alarms scheduled over the next 180 days."
    }
}

#Preview {
    ContentView()
}
