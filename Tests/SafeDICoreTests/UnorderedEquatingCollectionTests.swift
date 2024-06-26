// Distributed under the MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import XCTest

@testable import SafeDICore

final class UnorderedEquatingCollectionTests: XCTestCase {
    func test_makeIterator_iteratesInOrder() {
        for (index, value) in UnorderedEquatingCollection([1, 2, 3]).enumerated() {
            if index == 0 {
                XCTAssertEqual(value, 1)
            } else if index == 1 {
                XCTAssertEqual(value, 2)
            } else {
                XCTAssertEqual(index, 2)
                XCTAssertEqual(value, 3)
            }
        }
    }

    func test_hashInto_hashesEquivalentCollectionsIdentically() {
        XCTAssertEqual(
            UnorderedEquatingCollection([1, 2, 3]).hashValue,
            UnorderedEquatingCollection([2, 1, 3]).hashValue
        )
    }

    func test_codable_canDecodeFromEncodedValue() throws {
        let originalCollection = UnorderedEquatingCollection([1, 2, 3])
        XCTAssertEqual(
            originalCollection,
            try JSONDecoder().decode(
                UnorderedEquatingCollection.self,
                from: JSONEncoder().encode(originalCollection)
            )
        )
    }
}
