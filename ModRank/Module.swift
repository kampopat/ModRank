//
//  Module.swift
//  ModRank
//
//  Created by Kam Popat on 26/07/2016.
//  Copyright © 2016 Kam Popat. All rights reserved.
//

import Foundation
import UIKit

// --------------------
// MARK: Module Protocol
// --------------------
protocol ModuleProtocol {
    var icon: UIImage? { get set }
    var name: String { get set }
    var rating: Double { get set }
    var rounds: Int { get set }
    var kFactor: Int { get set }
}

// --------------------
// MARK: Module
// --------------------
struct Module: ModuleProtocol {
    var icon: UIImage?
    var name: String
    var rating: Double
    var rounds: Int
    var kFactor: Int
    
    ////////////////////////////////////////////////////////////////////////////////
    init(name: String, rating: Double, rounds: Int, kFactor: Int) {
        self.name = name
        self.rating = rating
        self.rounds = rounds
        self.kFactor = kFactor
    }
}