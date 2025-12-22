import Foundation
import PDFKit
import SwiftUI
import PencilKit

struct PDFKitViewWithOverlay: UIViewRepresentable {
    let document: PDFDocument
    let pdfView = PDFView()
    
    func makeUIView(context: Context) -> PDFView {
        pdfView.displayMode = .singlePageContinuous
        pdfView.usePageViewController(false)
        pdfView.displayDirection = .vertical
        
        pdfView.pageOverlayViewProvider = context.coordinator
        
        pdfView.document = document
        pdfView.autoScales = false
        pdfView.minScaleFactor = 0.7
        pdfView.maxScaleFactor = 4
        
        return pdfView
    }
 
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Optional: update logic if needed
    }
 
    func makeCoordinator() -> PageOverlayProvider {
        return PageOverlayProvider()
    }
}

struct MyCanvas: UIViewRepresentable {
    @State private var canvasView = PKCanvasView()

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .default
        canvasView.tool = PKInkingTool(.pen, color: .red, width: 15)
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) { }
}

class PageOverlayProvider: NSObject, PDFPageOverlayViewProvider {
    private var canvasViews: [PDFPage: PKCanvasView] = [:]
    
    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        var resultView: PKCanvasView? = nil
        
        if let existingCanvas = canvasViews[page] {
            resultView = existingCanvas
        } else {
            
            // Create a new PencilKit canvas
            let canvas = PKCanvasView()
            canvas.backgroundColor = .clear
            canvas.isOpaque = false
            canvas.tool = PKInkingTool(.monoline, color: .blue, width: 1)
            canvas.drawingPolicy = .pencilOnly
            
            
            canvasViews[page] = canvas
            resultView = canvas
        }
        
        // add drawing
        // let page = page as! MyPDFPage
        // if let drawing = page.drawing {
        //    resultView?.drawing = drawing;
        // }
        
        view.isInMarkupMode = true

        return resultView
    }
    
    func pdfView(_ pdfView: PDFView, willDisplayOverlayView overlayView: UIView, for page: PDFPage) {
       
        // let overlayView = overlayView as! PKCanvasView
        // let page = page as! MyPDFPage
        // page.drawing = overlayView.drawing
        pdfView.isInMarkupMode = true
        
        canvasViews.removeValue(forKey: page)
    }
}


class MyPDFPage: PDFPage {
    var drawing: PKDrawing? = nil
}
class MyPDFAnnotation: PDFAnnotation {
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        UIGraphicsPushContext(context)
        context.saveGState()
        
        // let page = self.page as! MyPDFPage
        // if let drawing = page.drawing {
        //    let image = drawing.image(from: drawing.bounds, scale: 1)
        //    image.draw(in: drawing.bounds)
        // }
        
        context.restoreGState()
        UIGraphicsPopContext()
    }
}
