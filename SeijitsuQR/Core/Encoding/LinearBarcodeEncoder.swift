import Foundation

/// Encodes the one-dimensional barcodes CoreImage cannot generate, as a row of modules (true = bar).
/// Quiet zones are not included. Standards: EAN/UPC (GS1 General Specifications §5.2), Code 39 and
/// Code 93 (ANSI/AIM BC1, BC5), ITF-14 (GS1 §5.3, Interleaved 2 of 5).
enum LinearBarcodeEncoder {
    static func modules(for content: String, symbology: CodeSymbology) -> [Bool]? {
        switch symbology {
        case .ean13: ean13(content)
        case .ean8: ean8(content)
        case .upce: upce(content)
        case .code39: code39(content)
        case .code93: code93(content)
        case .itf14: itf14(content)
        case .qr, .code128, .pdf417, .aztec, .dataMatrix: nil
        }
    }

    // MARK: EAN / UPC

    /// Set A ("L") codes for the digits 0–9. Set B ("G") is the reversed complement; set C ("R") the complement.
    private static let setA = ["0001101", "0011001", "0010011", "0111101", "0100011", "0110001", "0101111", "0111011", "0110111", "0001011"]
    private static func setB(_ digit: Int) -> String { String(setC(digit).reversed()) }
    private static func setC(_ digit: Int) -> String { String(setA[digit].map { $0 == "0" ? "1" : "0" }) }
    /// EAN-13: the first digit selects which of the left six digits use set A ("A") or set B ("B").
    private static let ean13Parity = ["AAAAAA", "AABABB", "AABBAB", "AABBBA", "ABAABB", "ABBAAB", "ABBBAA", "ABABAB", "ABABBA", "ABBABA"]

    private static func digits(_ content: String, count: Int) -> [Int]? {
        let values = content.compactMap(\.wholeNumberValue)
        guard values.count == count, content.count == count, content.allSatisfy(\.isASCII) else { return nil }
        return values
    }

    /// GS1 check digit for the digits before it (weights 3 and 1 from the right).
    static func gs1CheckDigit(_ body: [Int]) -> Int {
        let sum = body.reversed().enumerated().reduce(0) { total, item in total + item.element * (item.offset % 2 == 0 ? 3 : 1) }
        return (10 - sum % 10) % 10
    }

    private static func bits(_ pattern: String) -> [Bool] { pattern.map { $0 == "1" } }

    static func ean13(_ content: String) -> [Bool]? {
        guard let d = digits(content, count: 13), gs1CheckDigit(Array(d.prefix(12))) == d[12] else { return nil }
        let parity = Array(ean13Parity[d[0]])
        var pattern = "101"
        for i in 1...6 { pattern += parity[i - 1] == "A" ? setA[d[i]] : setB(d[i]) }
        pattern += "01010"
        for i in 7...12 { pattern += setC(d[i]) }
        return bits(pattern + "101")
    }

    static func ean8(_ content: String) -> [Bool]? {
        guard let d = digits(content, count: 8), gs1CheckDigit(Array(d.prefix(7))) == d[7] else { return nil }
        var pattern = "101"
        for i in 0..<4 { pattern += setA[d[i]] }
        pattern += "01010"
        for i in 4..<8 { pattern += setC(d[i]) }
        return bits(pattern + "101")
    }

    /// UPC-E (number system 0 or 1): eight digits, number system + six data digits + check digit.
    /// The check digit is that of the expanded UPC-A number and selects the parity of the six data digits.
    static func upce(_ content: String) -> [Bool]? {
        guard let d = digits(content, count: 8), d[0] == 0 || d[0] == 1,
              let upcA = expandUPCE(Array(d[0...6])), gs1CheckDigit(upcA) == d[7] else { return nil }
        // Number system 0, by check digit: "E" = even parity (set B), "O" = odd parity (set A). Number system 1 is the inverse.
        let ns0 = ["EEEOOO", "EEOEOO", "EEOOEO", "EEOOOE", "EOEEOO", "EOOEEO", "EOOOEE", "EOEOEO", "EOEOOE", "EOOEOE"]
        let parity = Array(ns0[d[7]])
        var pattern = "101"
        for i in 1...6 {
            let even = (parity[i - 1] == "E") != (d[0] == 1)
            pattern += even ? setB(d[i]) : setA[d[i]]
        }
        return bits(pattern + "010101")
    }

    /// The 11 digits of the UPC-A number (without check digit) that a UPC-E number stands for.
    static func expandUPCE(_ d: [Int]) -> [Int]? {
        guard d.count == 7 else { return nil }
        let ns = d[0], x = Array(d[1...6])
        let body: [Int]
        switch x[5] {
        case 0, 1, 2: body = [x[0], x[1], x[5], 0, 0, 0, 0, x[2], x[3], x[4]]
        case 3: body = [x[0], x[1], x[2], 0, 0, 0, 0, 0, x[3], x[4]]
        case 4: body = [x[0], x[1], x[2], x[3], 0, 0, 0, 0, 0, x[4]]
        default: body = [x[0], x[1], x[2], x[3], x[4], 0, 0, 0, 0, x[5]]
        }
        return [ns] + body
    }

    // MARK: Code 39

    /// Bars and spaces alternate, starting with a bar; "w" is wide (3 modules), "n" narrow (1 module).
    private static let code39Table: [Character: String] = [
        "0": "nnnwwnwnn", "1": "wnnwnnnnw", "2": "nnwwnnnnw", "3": "wnwwnnnnn", "4": "nnnwwnnnw",
        "5": "wnnwwnnnn", "6": "nnwwwnnnn", "7": "nnnwnnwnw", "8": "wnnwnnwnn", "9": "nnwwnnwnn",
        "A": "wnnnnwnnw", "B": "nnwnnwnnw", "C": "wnwnnwnnn", "D": "nnnnwwnnw", "E": "wnnnwwnnn",
        "F": "nnwnwwnnn", "G": "nnnnnwwnw", "H": "wnnnnwwnn", "I": "nnwnnwwnn", "J": "nnnnwwwnn",
        "K": "wnnnnnnww", "L": "nnwnnnnww", "M": "wnwnnnnwn", "N": "nnnnwnnww", "O": "wnnnwnnwn",
        "P": "nnwnwnnwn", "Q": "nnnnnnwww", "R": "wnnnnnwwn", "S": "nnwnnnwwn", "T": "nnnnwnwwn",
        "U": "wwnnnnnnw", "V": "nwwnnnnnw", "W": "wwwnnnnnn", "X": "nwnnwnnnw", "Y": "wwnnwnnnn",
        "Z": "nwwnwnnnn", "-": "nwnnnnwnw", ".": "wwnnnnwnn", " ": "nwwnnnwnn", "$": "nwnwnwnnn",
        "/": "nwnwnnnwn", "+": "nwnnnwnwn", "%": "nnnwnwnwn", "*": "nwnnwnwnn",
    ]

    static func code39(_ content: String) -> [Bool]? {
        guard !content.isEmpty, !content.contains("*"), content.allSatisfy({ code39Table[$0] != nil }) else { return nil }
        var result: [Bool] = []
        for (index, character) in ("*" + content + "*").enumerated() {
            if index > 0 { result.append(false) }  // narrow gap between characters
            for (element, width) in code39Table[character]!.enumerated() {
                result += Array(repeating: element % 2 == 0, count: width == "w" ? 3 : 1)
            }
        }
        return result
    }

    // MARK: Code 93

    private static let code93Characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%")
    /// Nine-module patterns for the values 0–46 (43–46 are the shift characters ($) (%) (/) (+)).
    private static let code93Patterns = [
        "100010100", "101001000", "101000100", "101000010", "100101000", "100100100", "100100010", "101010000", "100010010", "100001010",
        "110101000", "110100100", "110100010", "110010100", "110010010", "110001010", "101101000", "101100100", "101100010", "100110100",
        "100011010", "101011000", "101001100", "101000110", "100101100", "100010110", "110110100", "110110010", "110101100", "110100110",
        "110010110", "110011010", "101101100", "101100110", "100110110", "100111010", "100101110", "111010100", "111010010", "111001010",
        "101101110", "101110110", "110101110", "100100110", "111011010", "111010110", "100110010",
    ]
    private static let code93StartStop = "101011110"

    static func code93(_ content: String) -> [Bool]? {
        guard !content.isEmpty else { return nil }
        var values: [Int] = []
        for character in content {
            guard let value = code93Characters.firstIndex(of: character) else { return nil }
            values.append(value)
        }
        // Two check characters: C (weights 1–20, repeating) then K (weights 1–15, including C).
        func check(_ values: [Int], maxWeight: Int) -> Int {
            values.reversed().enumerated().reduce(0) { sum, item in sum + item.element * (item.offset % maxWeight + 1) } % 47
        }
        values.append(check(values, maxWeight: 20))
        values.append(check(values, maxWeight: 15))
        let pattern = code93StartStop + values.map { code93Patterns[$0] }.joined() + code93StartStop + "1"
        return bits(pattern)
    }

    // MARK: ITF-14 (Interleaved 2 of 5)

    /// Five elements per digit, two of them wide.
    private static let itfPatterns = ["nnwwn", "wnnnw", "nwnnw", "wwnnn", "nnwnw", "wnwnn", "nwwnn", "nnnww", "wnnwn", "nwnwn"]

    static func itf14(_ content: String) -> [Bool]? {
        guard let d = digits(content, count: 14), gs1CheckDigit(Array(d.prefix(13))) == d[13] else { return nil }
        func run(_ isBar: Bool, _ width: Character) -> [Bool] { Array(repeating: isBar, count: width == "w" ? 3 : 1) }
        var result = run(true, "n") + run(false, "n") + run(true, "n") + run(false, "n")  // start
        for pair in stride(from: 0, to: 14, by: 2) {
            let bars = Array(itfPatterns[d[pair]]), spaces = Array(itfPatterns[d[pair + 1]])
            for i in 0..<5 { result += run(true, bars[i]) + run(false, spaces[i]) }
        }
        return result + run(true, "w") + run(false, "n") + run(true, "n")  // stop
    }
}
