import Foundation
import PaperKit
import Testing
import UIKit
@testable import notesToGo

@MainActor
struct CanvasChangeTests {
    @Test func onlyChangedNativeMarkupReportsAnEdit() throws {
        let parent = UIViewController()
        parent.loadViewIfNeeded()
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 400)
        let pageView = PageView(frame: bounds)
        var changes = 0
        pageView.onContentChanged = { changes += 1 }
        pageView.configure(with: Page(id: UUID(), markup: PaperMarkup(bounds: bounds), background: .plain(.white)), pdfPage: nil, parentViewController: parent)
        defer { pageView.cleanup() }
        let controller = try #require(parent.children.first as? PaperMarkupViewController)
        pageView.paperMarkupViewControllerDidChangeMarkup(controller)
        pageView.paperMarkupViewControllerDidChangeSelection(controller)
        pageView.paperMarkupViewControllerDidBeginDrawing(controller)
        pageView.paperMarkupViewControllerDidChangeContentVisibleFrame(controller)
        #expect(changes == 0)

        var markup = try #require(controller.markup)
        markup.insertNewLine(configuration: .init(type: .rectangle), from: .init(x: 10, y: 10), to: .init(x: 70, y: 70))
        controller.markup = markup
        pageView.paperMarkupViewControllerDidChangeMarkup(controller)
        #expect(changes == 1)
        pageView.paperMarkupViewControllerDidChangeMarkup(controller)
        #expect(changes == 1)

        pageView.transform(2, to: .init(width: 600, height: 800))
        pageView.paperMarkupViewControllerDidChangeMarkup(controller)
        #expect(changes == 1)
        #expect(pageView.currentMarkup()?.bounds.size == CGSize(width: 600, height: 800))
    }
}
