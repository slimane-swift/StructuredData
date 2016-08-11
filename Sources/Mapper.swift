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

public enum MapperError : Error {
    case cantInitFromRawValue
    case noStrutcuredData(key: String)
    case incompatibleSequence
}

public final class Mapper {
    public init(structuredData: StructuredData) {
        self.structuredData = structuredData
    }
    
    fileprivate let structuredData: StructuredData
}

extension Mapper {
    public func map<T>(from key: String) throws -> T {
        let value: T = try structuredData.get(at: key)
        return value
    }
    
    public func map<T: StructuredDataInitializable>(from key: String) throws -> T {
        if let nested = structuredData[key] {
            return try unwrap(T(structuredData: nested))
        }
        throw MapperError.noStrutcuredData(key: key)
    }
    
    public func map<T: RawRepresentable>(from key: String) throws -> T where T.RawValue: StructuredDataInitializable {
        guard let rawValue = try structuredData[key].flatMap({ try T.RawValue(structuredData: $0) }) else {
            throw MapperError.cantInitFromRawValue
        }
        if let value = T(rawValue: rawValue) {
            return value
        }
        throw MapperError.cantInitFromRawValue
    }
}

extension Mapper {
    public func map<T>(arrayFrom key: String) throws -> [T] {
        return try structuredData.flatMapThrough(key) { try $0.get() as T }
    }
    
    public func map<T>(arrayFrom key: String) throws -> [T] where T: StructuredDataInitializable {
        return try structuredData.flatMapThrough(key) { try? T(structuredData: $0) }
    }
    
    public func map<T: RawRepresentable>(arrayFrom key: String) throws -> [T] where
        T.RawValue: StructuredDataInitializable {
            return try structuredData.flatMapThrough(key) {
                return (try? T.RawValue(structuredData: $0)).flatMap({ T(rawValue: $0) })
            }
    }
}

extension Mapper {
    public func map<T>(optionalFrom key: String) -> T? {
        do {
            return try map(from: key)
        } catch {
            return nil
        }
    }
    
    public func map<T: StructuredDataInitializable>(optionalFrom key: String) -> T? {
        if let nested = structuredData[key] {
            return try? T(structuredData: nested)
        }
        return nil
    }
    
    public func map<T: RawRepresentable>(optionalFrom key: String) -> T? where T.RawValue: StructuredDataInitializable {
        do {
            if let rawValue = try structuredData[key].flatMap({ try T.RawValue(structuredData: $0) }),
                let value = T(rawValue: rawValue) {
                return value
            }
            return nil
        } catch {
            return nil
        }
    }
}

extension Mapper {
    public func map<T>(optionalArrayFrom key: String) -> [T]? {
        return try? structuredData.flatMapThrough(key) { try $0.get() as T }
    }
    
    public func map<T>(optionalArrayFrom key: String) -> [T]? where T: StructuredDataInitializable {
        return try?  structuredData.flatMapThrough(key) { try? T(structuredData: $0) }
    }
    
    public func map<T: RawRepresentable>(optionalArrayFrom key: String) -> [T]? where
        T.RawValue: StructuredDataInitializable {
            return try? structuredData.flatMapThrough(key) {
                return (try? T.RawValue(structuredData: $0)).flatMap({ T(rawValue: $0) })
            }
    }
}

public enum UnwrapError: Error {
    case tryingToUnwrapNil
}

extension Mapper {
    fileprivate func unwrap<T>(_ optional: T?) throws -> T {
        if let nonoptional = optional {
            return nonoptional
        }
        throw UnwrapError.tryingToUnwrapNil
    }
}
