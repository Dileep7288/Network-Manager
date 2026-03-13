//
//  Media.swift
//  NetworkManager
//
//  Created by Dileep Kumar on 26/02/26.
//

import Foundation

public struct Media {
    public let key: String
    public let filename: String
    public let data: Data
    public let mimeType: String

    public init(key: String, filename: String, data: Data, mimeType: String) {
        self.key = key
        self.filename = filename
        self.data = data
        self.mimeType = mimeType
    }
}
