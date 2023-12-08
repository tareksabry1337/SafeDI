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

import Collections

/// A model of the scoped dependencies required for an `@Instantiable` in the reachable dependency tree.
final class Scope {

    // MARK: Initialization

    init(instantiable: Instantiable) {
        self.instantiable = instantiable
    }

    // MARK: Internal

    let instantiable: Instantiable

    /// The properties that this scope is responsible for instantiating.
    var propertiesToInstantiate = [PropertyToInstantiate]()

    struct PropertyToInstantiate {
        let property: Property
        let instantiable: Instantiable
        let scope: Scope
        let type: Property.PropertyType
    }

    var properties: [Property] {
        instantiable
            .dependencies
            .map(\.property)
    }

    var inheritedProperties: [Property] {
        instantiable
            .dependencies
            .filter {
                switch $0.source {
                case .forwarded,
                        .instantiated,
                        .lazyInstantiated:
                    return false
                case .inherited:
                    return true
                }
            }
            .map(\.property)
    }

    func createCombinedScope(
        for property: Property? = nil,
        instantiableStack: OrderedSet<Instantiable> = [],
        propertyStack: OrderedSet<Property> = []
    ) throws -> CombinedScope {
        var childPropertyToInstantiableConstant = [Property: Instantiable]()
        var childPropertyToCombinedScopeMap = [Property: CombinedScope]()

        func findCombinedScopeInformation(
            on scope: Scope,
            instantiableStack: OrderedSet<Instantiable>,
            propertyStack: OrderedSet<Property>
        ) throws {
            if let cycleIndex = instantiableStack.firstIndex(of: scope.instantiable) {
                throw ScopeError.dependencyCycleDetected([scope.instantiable] + instantiableStack.elements[0...cycleIndex])
            } else {
                var instantiableStack = instantiableStack
                instantiableStack.insert(scope.instantiable, at: 0)
                var propertyStack = propertyStack
                if let property {
                    propertyStack.insert(property, at: 0)
                }
                for propertyToInstantiate in scope.propertiesToInstantiate {
                    switch propertyToInstantiate.type {
                    case .constant:
                        childPropertyToInstantiableConstant[propertyToInstantiate.property] = propertyToInstantiate.instantiable
                        try findCombinedScopeInformation(
                            on: propertyToInstantiate.scope,
                            instantiableStack: instantiableStack,
                            propertyStack: propertyStack)
                    case .lazy,
                            .instantiator,
                            .forwardingInstantiator:
                        let childCombinedScope = try propertyToInstantiate
                            .scope
                            .createCombinedScope(
                                for: propertyToInstantiate.property,
                                instantiableStack: instantiableStack,
                                propertyStack: propertyStack
                            )
                        childPropertyToCombinedScopeMap[propertyToInstantiate.property] = childCombinedScope
                    }
                }
            }
        }

        try findCombinedScopeInformation(
            on: self,
            instantiableStack: instantiableStack,
            propertyStack: propertyStack
        )

        let combinedScope = CombinedScope(
            instantiable: instantiable,
            childPropertyToInstantiableConstant: childPropertyToInstantiableConstant,
            childPropertyToCombinedScopeMap: childPropertyToCombinedScopeMap,
            inheritedProperties: Set(
                instantiableStack
                    .flatMap(\.dependencies)
                    .filter {
                        ($0.source == .instantiated || $0.source == .forwarded)
                        && !propertyStack.contains($0.property)
                        && $0.property != property
                    }
                    .map(\.property)
            )
        )
        Task {
            // Kick off code generation.
            try await combinedScope.generateCode()
        }
        return combinedScope
    }

    // MARK: ScopeError

    private enum ScopeError: Error, CustomStringConvertible {

        case dependencyCycleDetected([Instantiable])

        var description: String {
            switch self {
            case let .dependencyCycleDetected(instantiables):
                """
                Dependency cycle detected!
                \(instantiables
                    .map(\.concreteInstantiableType.asSource)
                    .joined(separator: " -> "))
                """
            }
        }
    }
}
