import UIKit

/// Renders a plain-text vet summary into a simple, multi-page A4-ish PDF that a
/// user can AirDrop, email, or print for a vet visit. This is a Plus feature and
/// a key reason the subscription is worth paying for.
enum VetSummaryPDF {
    static func makeFile(title: String, body: String) -> URL? {
        let pageWidth: CGFloat = 612   // 8.5"
        let pageHeight: CGFloat = 792  // 11"
        let margin: CGFloat = 48
        let contentWidth = pageWidth - margin * 2
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.label,
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.label,
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TendPets-VetSummary.pdf")

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                var y = margin

                let titleString = NSAttributedString(string: title, attributes: titleAttrs)
                titleString.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 30))
                y += 38

                // Draw the body, paginating line-by-line so long summaries flow
                // onto new pages instead of being clipped.
                let lineHeight: CGFloat = 17
                for rawLine in body.components(separatedBy: "\n") {
                    let line = rawLine.isEmpty ? " " : rawLine
                    let attr = NSAttributedString(string: line, attributes: bodyAttrs)
                    let bounding = attr.boundingRect(
                        with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        context: nil
                    )
                    let needed = max(lineHeight, bounding.height)
                    if y + needed > pageHeight - margin {
                        ctx.beginPage()
                        y = margin
                    }
                    attr.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: needed))
                    y += needed
                }
            }
            return url
        } catch {
            return nil
        }
    }
}
