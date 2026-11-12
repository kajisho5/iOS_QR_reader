import SwiftUI
import UIKit

/// The share extension (docs/DESIGN_1.1.md §5, E): reads the codes in a shared image on device and shows what
/// they contain. It cannot open the browser or the app (iOS allows that only from widgets and iMessage apps),
/// so it offers Copy, and queues the code for the app's history.
final class ShareViewController: UIViewController {
    private var model: ShareModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        let model = ShareModel { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
        self.model = model
        let host = UIHostingController(rootView: ShareView(model: model))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)

        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
            .filter { $0.hasItemConformingToTypeIdentifier("public.image") }
        guard let provider = providers.first else {
            model.state = .noCode
            return
        }
        provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
            Task { @MainActor in await model.read(data) }
        }
    }
}
