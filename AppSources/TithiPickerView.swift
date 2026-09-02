import SwiftUI
import PanchangAlarmCore

struct TithiPickerView: View {
    @Binding var selected: Set<Int>

    var body: some View {
        List {
            Section("Common observances") {
                ForEach(TithiPreset.common) { preset in
                    Button {
                        toggle(preset)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.title).foregroundStyle(.primary)
                                Text(preset.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isPresetFullySelected(preset) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                                    .accessibilityIdentifier("preset_\(preset.title)_checked")
                            }
                        }
                    }
                    .accessibilityIdentifier("preset_\(preset.title)")
                }
            }

            Section("All 30 tithis") {
                ForEach(TithiOption.all) { option in
                    Button {
                        toggleSingle(option.number)
                    } label: {
                        HStack {
                            Text(option.displayName).foregroundStyle(.primary)
                            Spacer()
                            if selected.contains(option.number) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Choose Tithis")
    }

    private func isPresetFullySelected(_ preset: TithiPreset) -> Bool {
        Set(preset.tithiNumbers).isSubset(of: selected)
    }

    private func toggle(_ preset: TithiPreset) {
        if isPresetFullySelected(preset) {
            selected.subtract(preset.tithiNumbers)
        } else {
            selected.formUnion(preset.tithiNumbers)
        }
    }

    private func toggleSingle(_ number: Int) {
        if selected.contains(number) {
            selected.remove(number)
        } else {
            selected.insert(number)
        }
    }
}

#Preview {
    NavigationStack {
        TithiPickerView(selected: .constant([11, 15, 19]))
    }
}
