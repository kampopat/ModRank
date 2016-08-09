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
import Firebase
import FirebaseDatabase

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
    
    private var _ref: FIRDatabaseReference
    
    init(firstModule: ModuleProtocol, secondModule: ModuleProtocol, elo: EloRatingProtocol) {
        
        self.firstModule = firstModule
        self.secondModule = secondModule
        self.elo = elo
        
        self._ref = FIRDatabase.database().reference()
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
                        
                        self._ref
                            .child("modules")
                            .child(self.firstModule.name.lowercaseString)
                            .child("rating").setValue(rating, withCompletionBlock: { _ in
                                print("Should have completed writing first module")
                            })
                    
                })
                .then(self.elo.newRating(forModule: self.secondModule,
                    withClassification: .Loser,
                    expected: expectedSecond))
                .on(
                    next: { rating in
                        self.secondModule.rating = rating
                        self.secondModule.rounds += 1
                        
                    
                        
                        self._ref
                            .child("modules")
                            .child(self.secondModule.name.lowercaseString)
                            .child("rating").setValue(rating, withCompletionBlock: { _ in
                                print("Should have completed writing second module")
                            })
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
                        
                        self._ref
                            .child("modules")
                            .child(self.secondModule.name.lowercaseString)
                            .child("rating").setValue(rating, withCompletionBlock: { _ in
                                print("Should have completed writing second module")
                            })
                })
                .then(self.elo.newRating(forModule: self.firstModule,
                    withClassification: .Loser,
                    expected: expectedFirst))
                .on(
                    next: { rating in
                        self.firstModule.rating = rating
                        self.firstModule.rounds += 1
                        
                        
                        
                        self._ref
                            .child("modules")
                            .child(self.firstModule.name.lowercaseString)
                            .child("rating").setValue(rating, withCompletionBlock: { _ in
                                print("Should have completed writing first module")
                            })
                })
                .startWithCompleted({
                    observer.sendCompleted()
                })
        }
    }
    
    
}
