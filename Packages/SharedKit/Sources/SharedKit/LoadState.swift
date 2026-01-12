//
//  LoadState.swift
//  SharedKit
//
//  Created by Ashish Shaik on 1/12/26.
//

public enum LoadState<Value>: Equatable where Value: Equatable {
    case idle
    case loading
    case success(Value)
    case failure(String)
}
