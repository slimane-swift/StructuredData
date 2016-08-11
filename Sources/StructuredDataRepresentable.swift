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

extension StructuredDataFallibleRepresentable {
    public func asStructuredData() throws -> StructuredData {
        let props = try properties(self)
        var dictionary = [String: StructuredData](minimumCapacity: props.count)
        for property in props {
            guard let representable = property.value as? StructuredDataFallibleRepresentable else {
                throw StructuredDataError.notStructuredDataRepresentable(type(of: property.value))
            }
            dictionary[property.key] = try representable.asStructuredData()
        }
        return .dictionary(dictionary)
    }
}

extension StructuredData : StructuredDataRepresentable {
    public var structuredData: StructuredData {
        return self
    }
}

extension Bool : StructuredDataRepresentable {
    public var structuredData: StructuredData {
        return .bool(self)
    }
}

extension Double : StructuredDataRepresentable {
    public var structuredData: StructuredData {
        return .double(self)
    }
}

extension Int : StructuredDataRepresentable {
    public var structuredData: StructuredData {
        return .int(self)
    }
}

extension String : StructuredDataRepresentable {
    public var structuredData: StructuredData {
        return .string(self)
    }
}

extension Data : StructuredDataRepresentable {
    public var structuredData: StructuredData {
        return .data(self)
    }
}

extension Optional where Wrapped : StructuredDataRepresentable {
    public var structuredData: StructuredData {
        switch self {
        case .some(let wrapped): return wrapped.structuredData
        case .none: return .null
        }
    }
}

extension Array where Element : StructuredDataRepresentable {
    public var structuredDataArray: [StructuredData] {
        return self.map({$0.structuredData})
    }
    
    public var structuredData: StructuredData {
        return .array(structuredDataArray)
    }
}

public protocol StructuredDataDictionaryKeyRepresentable {
    var structuredDataDictionaryKey: String { get }
}

extension String : StructuredDataDictionaryKeyRepresentable {
    public var structuredDataDictionaryKey: String {
        return self
    }
}

extension Dictionary where Key : StructuredDataDictionaryKeyRepresentable, Value : StructuredDataRepresentable {
    public var structuredDataDictionary: [String: StructuredData] {
        var dictionary: [String: StructuredData] = [:]
        
        for (key, value) in self.map({($0.0.structuredDataDictionaryKey, $0.1.structuredData)}) {
            dictionary[key] = value
        }
        
        return dictionary
    }
    
    public var structuredData: StructuredData {
        return .dictionary(structuredDataDictionary)
    }
}

// MARK: StructuredDataFallibleRepresentable

extension Optional : StructuredDataFallibleRepresentable {
    public func asStructuredData() throws -> StructuredData {
        guard Wrapped.self is StructuredDataFallibleRepresentable.Type else {
            throw StructuredDataError.notStructuredDataRepresentable(Wrapped.self)
        }
        if case .some(let wrapped as StructuredDataFallibleRepresentable) = self {
            return try wrapped.asStructuredData()
        }
        return .null
    }
}

extension Array : StructuredDataFallibleRepresentable {
    public func asStructuredData() throws -> StructuredData {
        guard Element.self is StructuredDataFallibleRepresentable.Type else {
            throw StructuredDataError.notStructuredDataRepresentable(Element.self)
        }
        var array: [StructuredData] = []
        array.reserveCapacity(count)
        for element in self {
            let element = element as! StructuredDataFallibleRepresentable
            array.append(try element.asStructuredData())
        }
        return .array(array)
    }
}

extension Dictionary : StructuredDataFallibleRepresentable {
    public func asStructuredData() throws -> StructuredData {
        guard Key.self is StructuredDataDictionaryKeyRepresentable.Type else {
            throw StructuredDataError.notStructuredDataDictionaryKeyRepresentable(Value.self)
        }
        guard Value.self is StructuredDataFallibleRepresentable.Type else {
            throw StructuredDataError.notStructuredDataRepresentable(Value.self)
        }
        var dictionary = [String: StructuredData](minimumCapacity: count)
        for (key, value) in self {
            let value = value as! StructuredDataFallibleRepresentable
            let key = key as! StructuredDataDictionaryKeyRepresentable
            dictionary[key.structuredDataDictionaryKey] = try value.asStructuredData()
        }
        return .dictionary(dictionary)
    }
}
