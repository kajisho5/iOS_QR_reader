import CoreTransferable
import UniformTypeIdentifiers

/// What the paste button hands over (docs/DESIGN_1.2.md §2, M): an image to read codes from, or text to show as it is.
/// The clipboard is read only through PasteButton, i.e. only when the user taps it, so iOS shows no paste prompt.
struct PastedContent: Transferable, Sendable {
    enum Value: Sendable {
        case image(Data)
        case text(String)
    }

    let value: Value

    static var transferRepresentation: some TransferRepresentation {
        // An image first: a copied screenshot or photo often carries a text representation as well.
        DataRepresentation(importedContentType: .image) { data in PastedContent(value: .image(data)) }
        ProxyRepresentation(importing: { (text: String) in PastedContent(value: .text(text)) })
    }
}
