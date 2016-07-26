//
//  Round.swift
//  ModRank
//
//  Created by Kam Popat on 26/07/2016.
//  Copyright © 2016 Kam Popat. All rights reserved.
//

import Foundation
import ReactiveCocoa

// --------------------
// MARK: Protocol
// --------------------
protocol RoundProtocol {
    var firstModule: ModuleProtocol { get }
    var secondModule: ModuleProtocol { get }
    var firstExpected: Double { get set }
    var secondExpected: Double { get set }
    var elo: EloRatingProtocol { get }
}

struct Round: RoundProtocol {
    
    var firstModule: ModuleProtocol
    var secondModule: ModuleProtocol
    var firstExpected: Double
    var secondExpected: Double
    var elo: EloRatingProtocol
    
    ////////////////////////////////////////////////////////////////////////////////
    init(first: ModuleProtocol, second: ModuleProtocol, elo: EloRatingProtocol) {
        self.firstModule = first
        self.secondModule = second
        self.elo = elo
        
        self.firstExpected = elo.expectedWinProbability(forModule: firstModule, againstModule: secondModule)
        self.secondExpected = elo.expectedWinProbability(forModule: secondModule, againstModule: firstModule)
        
    }
    
}
