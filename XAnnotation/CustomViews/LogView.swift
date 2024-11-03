//
//  LogView.swift
//  XAnnotation
//
//  Created by XMaster on 02.11.24.
//


import SwiftUI

struct LogView: View {
    @ObservedObject var logModel: LogViewModel = .shared
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(Array(logModel.logs.enumerated()), id: \.offset) { index, log in
                        Text(log)
                            .id(index) // Задаем идентификатор для каждой строки
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(2)
            }
            .onChange(of: logModel.logs.count) {
                // Прокрутка к последней строке при добавлении нового лога
                if let lastIndex = logModel.logs.indices.last {
                    proxy.scrollTo(lastIndex, anchor: .bottom)
                }
            }
        }
        .frame(height: 150) // Ограничиваем высоту для 5 строк
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(0)
    }

}
