import SwiftUI

struct ResizableHandle: View {
    enum HandlePosition {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    let position: HandlePosition
    let handleSize: CGFloat = 12
    let currentRect: CGRect
    let imageOrigin: CGPoint

    var onDrag: (CGPoint) -> Void
    
    @EnvironmentObject var annotationsData: AnnotationViewModel

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: handleSize, height: handleSize)
            .overlay(
                Circle()
                    .stroke(Color.black, lineWidth: 2)
            )
            .position(handlePosition())
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { value in
                        let newPosition = CGPoint(
                            x: value.location.x - imageOrigin.x,
                            y: value.location.y - imageOrigin.y
                        )
                        onDrag(newPosition)
                    }
                    .onEnded{ value in
                        annotationsData.saveAnnotationsToFile()
                    }
            )
    }

    private func handlePosition() -> CGPoint {
        switch position {
        case .topLeft:
            return CGPoint(x: currentRect.minX, y: currentRect.minY)
        case .topRight:
            return CGPoint(x: currentRect.maxX, y: currentRect.minY)
        case .bottomLeft:
            return CGPoint(x: currentRect.minX, y: currentRect.maxY)
        case .bottomRight:
            return CGPoint(x: currentRect.maxX, y: currentRect.maxY)
        }
    }
}

//struct ResizableHandle_Previews: PreviewProvider {
//    static var previews: some View {
//        ResizableHandle(
//            position: .topLeft,
//            currentRect: CGRect(x: 50, y: 50, width: 100, height: 100),
//            imageOrigin: CGPoint(x: 0, y: 0),
//            saveAnnotations: {},
//            onDrag: { _ in }
//        )
//    }
//}
