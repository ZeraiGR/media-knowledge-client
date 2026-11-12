import AppKit

let size = NSSize(width: 720, height: 480)
let image = NSImage(size: size)
image.lockFocus()
NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()

func text(_ value: String, y: CGFloat, size: CGFloat, bold: Bool = false, color: NSColor = .darkGray) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size),
        .foregroundColor: color,
        .paragraphStyle: paragraph,
    ]
    (value as NSString).draw(in: NSRect(x: 24, y: y, width: 672, height: 60), withAttributes: attributes)
}

text("Установка Media Knowledge", y: 390, size: 27, bold: true)
text("Перетащите приложение в папку «Программы»", y: 345, size: 18)
let arrow = NSBezierPath()
arrow.lineWidth = 5
arrow.lineCapStyle = .round
arrow.move(to: NSPoint(x: 302, y: 260))
arrow.line(to: NSPoint(x: 418, y: 260))
arrow.move(to: NSPoint(x: 398, y: 280))
arrow.line(to: NSPoint(x: 418, y: 260))
arrow.line(to: NSPoint(x: 398, y: 240))
NSColor.systemBlue.setStroke()
arrow.stroke()
text("Перед обновлением закройте приложение (⌘Q).\nПодтвердите замену предыдущей версии.", y: 95, size: 16)
text("Уже установлено в ~/Applications?\nОткройте эту папку в Finder (⌘⇧G) и замените приложение там.", y: 20, size: 13)
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
