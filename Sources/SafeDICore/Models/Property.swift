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

import SwiftSyntax

/// A representation of a property.
/// e.g. `let myProperty: MyProperty`
public struct Property: Codable, Hashable, Comparable {

    // MARK: Initialization

    init(
        label: String,
        typeDescription: TypeDescription)
    {
        self.label = label
        self.typeDescription = typeDescription
    }

    // MARK: Public

    /// The label by which the property is referenced.
    public let label: String
    /// The type to which the property conforms.
    public var typeDescription: TypeDescription

    // MARK: Hashable

    public static func < (lhs: Property, rhs: Property) -> Bool {
        lhs.label < rhs.label
    }

    // MARK: Internal

    var asSource: String {
        "\(label): \(typeDescription.asSource)"
    }

    var asFunctionParamter: FunctionParameterSyntax {
        FunctionParameterSyntax(
            firstName: .identifier(label),
            colon: .colonToken(trailingTrivia: .space),
            type: IdentifierTypeSyntax(name: .identifier(typeDescription.asSource))
        )
    }

    var nonLazyPropertyType: PropertyType {
        switch typeDescription {
        case let .simple(name, _):
            if name == Dependency.instantiatorType {
                return .instantiator
            } else if name == Dependency.forwardingInstantiatorType {
                return .forwardingInstantiator
            } else {
                return .constant
            }
        case .any,
                .array,
                .attributed,
                .closure,
                .composition,
                .dictionary,
                .implicitlyUnwrappedOptional,
                .metatype,
                .nested,
                .optional,
                .some,
                .tuple,
                .unknown:
            return .constant
        }
    }

    // MARK: PropertyType

    enum PropertyType {
        /// A `let` property.
        case constant
        // TODO: Enable lazy instantiated properties to forward themselves down their own scope.
        //       We can enable this without an unexpected retain problem because lazy instantiated
        //       properties are already retained.
        /// A  lazily instantiated property. Backed by an `Instantiator`.
        /// The instantiated product is not forwarded down the dependency tree.
        case lazy
        /// An `Instantiator` property.
        /// The instantiated product is not forwarded down the dependency tree. This is done intentionally to avoid unexpected retains.
        case instantiator
        /// A `ForwardingInstantiator` property.
        /// The instantiated product is not forwarded down the dependency tree. This is done intentionally to avoid unexpected retains.
        case forwardingInstantiator
    }
}
