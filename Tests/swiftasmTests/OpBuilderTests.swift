import XCTest

@testable import swiftasm

final class OpBuilderTests: XCTestCase {
    func testAppendPrologue() throws {
        let sut = OpBuilder()
        try sut.appendPrologue()

        XCTAssertEqual(
            sut.build(),
            [0xfd, 0x7b, 0xbf, 0xa9,
             0xfd, 0x03, 0x00, 0x91]
        )
    }

    func testAppendEpilogue() throws {
        let sut = OpBuilder()
        try sut.appendEpilogue()

        XCTAssertEqual(
            sut.build(),
            [0xfd, 0x7b, 0xc1, 0xa8]
        )
    }

    func testAppendDebugPrintAligned4() throws {
        let sut = OpBuilder()
        sut.appendDebugPrintAligned4("Hello World")

        XCTAssertEqual(
            sut.build(), 
            [
                0xe0, 0x0f, 0x1e, 0xf8, //; str x0, [sp, #-32]!
                0xe1, 0x83, 0x00, 0xf8, //; str x1, [sp, #8]
                0xe2, 0x03, 0x01, 0xf8, //; str x2, [sp, #16]
                0xf0, 0x83, 0x01, 0xf8, //; str x16, [sp, #24]
                0x20, 0x00, 0x80, 0xd2, //; movz x0, #1
                0x21, 0x01, 0x00, 0x10, //; adr x1, #36
                0x62, 0x01, 0x80, 0xd2, //; movz x2, #11
                0x90, 0x00, 0x80, 0xd2, //; movz x16, #4
                0x01, 0x10, 0x00, 0xd4, //; svc 0x0080
                0xf0, 0x0f, 0x40, 0xf9, //; ldr x16, [sp, #24]
                0xe2, 0x0b, 0x40, 0xf9, //; ldr x2, [sp, #16]
                0xe1, 0x07, 0x40, 0xf9, //; ldr x1, [sp, #8]
                0xe0, 0x07, 0x42, 0xf8, //; ldr x0, [sp], #32
                0x04, 0x00, 0x00, 0x14, //; b #16
                0x48, 0x65, 0x6c, 0x6c, //; Hell
                0x6f, 0x20, 0x57, 0x6f, //; o.Wo
                0x72, 0x6c, 0x64      , //; rld
                0x00                  , //; .zero
            ])
    }
}
