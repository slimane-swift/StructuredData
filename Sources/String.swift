//
//  String.swift
//  StructuredData
//
//  Created by Yuki Takei on 8/12/16.
//
//

extension String {
    func split(separator: Character, maxSplits: Int = .max, omittingEmptySubsequences: Bool = true) -> [String] {
        return characters.split(separator: separator, maxSplits: maxSplits, omittingEmptySubsequences: omittingEmptySubsequences).map(String.init)
    }
}
