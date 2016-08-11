// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
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

extension StructuredDataInitializable {
    public init(structuredData: StructuredData) throws {
        guard case .dictionary(let dictionary) = structuredData else {
            throw StructuredDataError.cannotInitialize(type: Self.self, from: try type(of: structuredData.get()))
        }
        self = try construct { property in
            guard let initializable = property.type as? StructuredDataInitializable.Type else {
                throw StructuredDataError.notStructuredDataInitializable(property.type)
            }
            switch dictionary[property.key] ?? .null {
            case .null:
                guard let expressibleByNilLiteral = property.type as? ExpressibleByNilLiteral.Type else {
                    throw ReflectionError.requiredValueMissing(key: property.key)
                }
                return expressibleByNilLiteral.init(nilLiteral: ())
            case let x:
                return try initializable.init(structuredData: x)
            }
        }
    }
}

extension StructuredData : StructuredDataInitializable {
    public init(structuredData: StructuredData) throws {
        self = structuredData
    }
}

extension Bool : StructuredDataInitializable {
    public init(structuredData: StructuredData) throws {
        guard case .bool(let bool) = structuredData else {
            throw StructuredDataError.cannotInitialize(type: Bool.self, from: try type(of: structuredData.get()))
        }
        self = bool
    }
}

extension Double : StructuredDataInitializable {
    public init(structuredData: StructuredData) throws {
        guard case .double(let double) = structuredData else {
            throw StructuredDataError.cannotInitialize(type: Double.self, from: try type(of: structuredData.get()))
        }
        self = double
    }
}

extension Int : StructuredDataInitializable {
    public init(structuredData: StructuredData) throws {
        guard case .int(let int) = structuredData else {
            throw StructuredDataError.cannotInitialize(type: Int.self, from: try type(of: structuredData.get()))
        }
        self = int
    }
}

extension String : StructuredDataInitializable {
    public init(structuredData: StructuredData) throws {
        guard case .string(let string) = structuredData else {
            throw StructuredDataError.cannotInitialize(type: String.self, from: try type(of: structuredData.get()))
        }
        self = string
    }
}

extension Data : StructuredDataInitializable {
    public init(structuredData: StructuredData) throws {
        guard case .data(let data) = structuredData else {
            throw StructuredDataError.cannotInitialize(type: Data.self, from: try type(of: structuredData.get()))
        }
        self = data
    }
}

extension Optional : StructuredDataInitializable {
    public init(structuredData: StructuredData) throws {
        guard let initializable = Wrapped.self as? StructuredDataInitializable.Type else {
            throw StructuredDataError.notStructuredDataInitializable(Wrapped.self)
        }
        if case .null = structuredData {
            self = .none
        } else {
            self = try initializable.init(structuredData: structuredData) as? Wrapped
        }
    }
}

extension Array : StructuredDataInitializable {
    public init(structuredData: StructuredData) throws {
        guard case .array(let array) = structuredData else {
            throw StructuredDataError.cannotInitialize(type: Array.self, from: try type(of: structuredData.get()))
        }
        guard let initializable = Element.self as? StructuredDataInitializable.Type else {
            throw StructuredDataError.notStructuredDataInitializable(Element.self)
        }
        var this = Array()
        this.reserveCapacity(array.count)
        for element in array {
            if let value = try initializable.init(structuredData: element) as? Element {
                this.append(value)
            }
        }
        self = this
    }
}

public protocol StructuredDataDictionaryKeyInitializable {
    init(structuredDataDictionaryKey: String)
}

extension String : StructuredDataDictionaryKeyInitializable {
    public init(structuredDataDictionaryKey: String) {
        self = structuredDataDictionaryKey
    }
}

extension Dictionary : StructuredDataInitializable {
    public init(structuredData: StructuredData) throws {
        guard case .dictionary(let dictionary) = structuredData else {
            throw StructuredDataError.cannotInitialize(type: Dictionary.self, from: try type(of: structuredData.get()))
        }
        guard let keyInitializable = Key.self as? StructuredDataDictionaryKeyInitializable.Type else {
            throw StructuredDataError.notStructuredDataDictionaryKeyInitializable(type(of: self))
        }
        guard let valueInitializable = Value.self as? StructuredDataInitializable.Type else {
            throw StructuredDataError.notStructuredDataInitializable(Element.self)
        }
        var this = Dictionary(minimumCapacity: dictionary.count)
        for (key, value) in dictionary {
            if let key = keyInitializable.init(structuredDataDictionaryKey: key) as? Key {
                this[key] = try valueInitializable.init(structuredData: value) as? Value
            }
        }
        self = this
    }
}
