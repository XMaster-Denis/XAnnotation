//
//  ExportModalView.swift
//  XAnnotation
//
//  Created by XMaster on 02.11.24.
//

import SwiftUI

struct ExportModalView: View {
    @EnvironmentObject var exportViewModel: ExportViewModel
    
    var body: some View {
        VStack {
            Text("Export proportion settings")
                .font(.title)
                .padding()
            
            HStack {
                Text("Train:")
                    .frame(width: 100)
                ProgressView(value: exportViewModel.trainExportProgress)
                    .padding()
                Text("\(Int(exportViewModel.trainExportProgress*100))% ")
                    .frame(width: 50)
            }
            
            HStack {
                Text("Test:")
                    .frame(width: 100)
                ProgressView(value: exportViewModel.testExportProgress)
                    .padding()
                Text("\(Int(exportViewModel.testExportProgress*100))% ")
                    .frame(width: 50)
            }
            
            HStack {
                Text("Validation:")
                    .frame(width: 100)
                ProgressView(value: exportViewModel.validExportProgress)
                    .padding()
                Text("\(Int(exportViewModel.validExportProgress*100))% ")
                    .frame(width: 50)
            }
            

            
     
                
            Button("Cancel") {
                
                exportViewModel.isExporting = false
            }
            .padding()
                
       
        }
        .padding()
        
        if exportViewModel.isExporting {
            
        }
    }
}

#Preview {
    ExportModalView()
}
