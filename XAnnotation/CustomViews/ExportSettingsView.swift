import SwiftUI

struct ExportSettingsView: View {
    @ObservedObject var settings: Settings = Settings.shared
    
    var body: some View {
        VStack {
            Text("Export Image Settings")
                .font(.title)
                .padding()
            
            HStack {
                Text("Train:")
                    .frame(width: 100)
                Slider(value: $settings.exportProportions.trainPercentage, in: 0...100, step: 5, onEditingChanged: { editing in
                    if !editing  {
                        adjustNextValue(for: .train)
                    }
                })
                .padding()
                Text("\(Int(settings.exportProportions.trainPercentage))% ")
                    .frame(width: 50)
            }
            
            HStack {
                Text("Test:")
                    .frame(width: 100)
                Slider(value: $settings.exportProportions.testPercentage, in: 0...100, step: 5, onEditingChanged: { editing in
                    if !editing {
                        adjustNextValue(for: .test)
                    }
                })
                .padding()
                Text("\(Int(settings.exportProportions.testPercentage))% ")
                    .frame(width: 50)
            }
            
            HStack {
                Text("Validation:")
                    .frame(width: 100)
                Slider(value: $settings.exportProportions.validPercentage, in: 0...100, step: 5, onEditingChanged: { editing in
                    if !editing  {
                        adjustNextValue(for: .valid)
                    }
                })
                .padding()
                Text("\(Int(settings.exportProportions.validPercentage))% ")
                    .frame(width: 50)
            }
            
            Text("Total: \(Int(settings.exportProportions.trainPercentage + settings.exportProportions.testPercentage + settings.exportProportions.validPercentage))%")
                .foregroundColor((settings.exportProportions.trainPercentage + settings.exportProportions.testPercentage + settings.exportProportions.validPercentage) == 100 ? .green : .red)
                .padding()
            
            HStack{
                
            Button("Cancel") {
                settings.showExportSettingsView = false
            }
            .padding()
                
            Button("Save") {
                settings.saveProportions()
                settings.showExportSettingsView = false
            }
            .padding()
            }
        }
        .padding()
    }
    
    enum PercentageType {
        case train, test, valid
    }
    
    private func adjustNextValue(for adjustedType: PercentageType) {
        // Round the adjusted percentage to the nearest multiple of 5
        var adjustedPercentage = round(percentage(for: adjustedType) / 5) * 5
        setPercentage(for: adjustedType, value: adjustedPercentage)
        
        // Calculate the difference needed to bring the total to 100%
        let total = settings.exportProportions.trainPercentage + settings.exportProportions.testPercentage + settings.exportProportions.validPercentage
        var difference = 100 - total

        // Define the order of adjustment based on the adjusted slider
        let adjustmentOrder: [PercentageType]
        switch adjustedType {
        case .train:
            adjustmentOrder = [.test, .valid]
        case .test:
            adjustmentOrder = [.valid, .train]
        case .valid:
            adjustmentOrder = [.train, .test]
        }
        
        // Adjust other sliders in order
        for type in adjustmentOrder {
            if difference == 0 { break }
            var percentageValue = percentage(for: type)
            let maxAdjustment = min(max(difference, -percentageValue), 100 - percentageValue)
            let adjustment = (maxAdjustment / 5).rounded() * 5
            percentageValue += adjustment
            percentageValue = min(max(percentageValue, 0), 100)
            setPercentage(for: type, value: percentageValue)
            difference -= adjustment
        }
        
        // If there's still a difference, adjust the adjusted slider
        if difference != 0 {
            adjustedPercentage = percentage(for: adjustedType)
            let maxAdjustment = min(max(difference, -adjustedPercentage), 100 - adjustedPercentage)
            let adjustment = (maxAdjustment / 5).rounded() * 5
            adjustedPercentage += adjustment
            adjustedPercentage = min(max(adjustedPercentage, 0), 100)
            setPercentage(for: adjustedType, value: adjustedPercentage)
        }
    }
        
    // Helper functions
    private func percentage(for type: PercentageType) -> Double {
        switch type {
        case .train:
            return settings.exportProportions.trainPercentage
        case .test:
            return settings.exportProportions.testPercentage
        case .valid:
            return settings.exportProportions.validPercentage
        }
    }

    private func setPercentage(for type: PercentageType, value: Double) {
        let roundedValue = (value / 5).rounded() * 5
        switch type {
        case .train:
            settings.exportProportions.trainPercentage = roundedValue
        case .test:
            settings.exportProportions.testPercentage = roundedValue
        case .valid:
            settings.exportProportions.validPercentage = roundedValue
        }
    }
    
    
}

struct ExportSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ExportSettingsView()
    }
}
