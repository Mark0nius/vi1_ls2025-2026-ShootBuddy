//
//  Injected.swift
//  ShootBuddy
//
//  Created by Gabriela Staňková on 13.06.2026.
//
@propertyWrapper
struct Injected<T> {
    let wrappedValue: T

    init() {
        wrappedValue = DIContainer.shared.resolve()
    }
}
