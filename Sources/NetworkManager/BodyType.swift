//
//  BodyType.swift
//  NetworkManager
//
//  Created by Dileep Kumar on 26/02/26.
//

public enum BodyType {
    case json
    case formURLEncoded
    case multipart(boundary: String?, media: [Media]?)
}
