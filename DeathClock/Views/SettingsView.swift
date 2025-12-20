import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top spacer to ensure content doesn't touch top edge
            Color.clear.frame(height: 0)
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button(action: {
                    MenuBarController.shared.closePopover()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
                
            GroupBox("Personal Information") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Date of Birth:")
                            .frame(width: 100, alignment: .leading)
                        DatePicker("", selection: $viewModel.dateOfBirth, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    
                    HStack {
                        Text("Sex:")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $viewModel.selectedSex) {
                            ForEach(UserProfile.Sex.allCases, id: \.self) { sex in
                                Text(sex.rawValue).tag(sex)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    HStack {
                        Text("Country:")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $viewModel.selectedCountry) {
                            ForEach(viewModel.countries, id: \.self) { country in
                                Text(country).tag(country)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        Text("Region:")
                            .frame(width: 100, alignment: .leading)
                        TextField("Optional", text: $viewModel.region)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
                
            GroupBox("Display Options") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Format:")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $viewModel.displayFormat) {
                            ForEach(AppSettings.DisplayFormat.allCases, id: \.self) { format in
                                Text(viewModel.formatPreview(for: format)).tag(format)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack {
                        Text("Mode:")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $viewModel.mementoMode) {
                            ForEach(AppSettings.MementoMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            GroupBox("General") {
                HStack {
                    Text("Start at Login:")
                        .frame(width: 100, alignment: .leading)
                    Toggle("", isOn: $viewModel.startAtLogin)
                        .onChange(of: viewModel.startAtLogin) { viewModel.debouncedSave() }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            HStack {
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(minWidth: 350, idealWidth: 400, maxWidth: 450)
        .onChange(of: viewModel.dateOfBirth) { 
            viewModel.updatePreview()
            viewModel.debouncedSave() 
        }
        .onChange(of: viewModel.selectedSex) { 
            viewModel.updatePreview()
            viewModel.debouncedSave() 
        }
        .onChange(of: viewModel.selectedCountry) { 
            viewModel.updatePreview()
            viewModel.debouncedSave() 
        }
        .onChange(of: viewModel.region) { viewModel.debouncedSave() }
        .onChange(of: viewModel.displayFormat) { viewModel.debouncedSave() }
        .onChange(of: viewModel.mementoMode) { viewModel.debouncedSave() }
    }
}

