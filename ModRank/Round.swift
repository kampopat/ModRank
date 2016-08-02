//
//  Round.swift
//  ModRank
//
//  Created by Kam Popat on 26/07/2016.
//  Copyright © 2016 Kam Popat. All rights reserved.
//

import Foundation
import ReactiveCocoa
import enum Result.NoError

// --------------------
// MARK: Protocol
// --------------------
protocol RoundProtocol {
    var firstModule: ModuleProtocol { get set }
    var secondModule: ModuleProtocol { get set }
    var elo: EloRatingProtocol { get }
    
    func declareFirstModuleWinner() -> SignalProducer<(), NoError>
    func declareSecondModuleWinner() -> SignalProducer<(), NoError>
    
}

class Round: RoundProtocol {
    
    var firstModule: ModuleProtocol
    var secondModule: ModuleProtocol
    var elo: EloRatingProtocol
    
    init(firstModule: ModuleProtocol, secondModule: ModuleProtocol, elo: EloRatingProtocol) {
        self.firstModule = firstModule
        self.secondModule = secondModule
        self.elo = elo
    }
    
    func declareFirstModuleWinner() -> SignalProducer<(), NoError> {
        return SignalProducer { observer, _ in
            
            let expectedFirst = self.elo.expectedWinProbability(forModule: self.firstModule, againstModule: self.secondModule)
            let expectedSecond = self.elo.expectedWinProbability(forModule: self.secondModule, againstModule: self.firstModule)
            
            self.elo.newRating(forModule: self.firstModule,
                withClassification: .Winner,
                expected: expectedFirst)
                .on(
                    next: { rating in
                        self.firstModule.rating = rating
                        self.firstModule.rounds += 1
                })
                .then(self.elo.newRating(forModule: self.secondModule,
                    withClassification: .Loser,
                    expected: expectedSecond))
                .on(
                    next: { rating in
                        self.secondModule.rating = rating
                        self.secondModule.rounds += 1
                })
                .startWithCompleted({
                    observer.sendCompleted()
                })
        }
    }
    
    func declareSecondModuleWinner() -> SignalProducer<(), NoError> {
        return SignalProducer { observer, _ in
            
            let expectedFirst = self.elo.expectedWinProbability(forModule: self.firstModule, againstModule: self.secondModule)
            let expectedSecond = self.elo.expectedWinProbability(forModule: self.secondModule, againstModule: self.firstModule)
            
            self.elo.newRating(forModule: self.secondModule,
                withClassification: .Winner,
                expected: expectedSecond)
                .on(
                    next: { rating in
                        self.secondModule.rating = rating
                        self.secondModule.rounds += 1
                })
                .then(self.elo.newRating(forModule: self.firstModule,
                    withClassification: .Loser,
                    expected: expectedFirst))
                .on(
                    next: { rating in
                        self.firstModule.rating = rating
                        self.firstModule.rounds += 1
                })
                .startWithCompleted({
                    observer.sendCompleted()
                })
        }
    }
    
    
}
