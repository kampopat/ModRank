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


typealias UpdateValues = [String: AnyObject]
let kRatingFirstKey = "ratingFirst"
let kRatingSecondKey = "ratingSecond"
let kKFactorFirstKey = "kFactorFirst"
let kKFactorSecondKey = "kFactorySecond"


// --------------------
// MARK: Protocol
// --------------------
protocol RoundProtocol {
    var firstRef: FIRDatabaseReference { get set }
    var secondRef: FIRDatabaseReference { get set }
    var elo: EloRatingProtocol { get }
    
    func declareFirstModuleWinner() -> SignalProducer<(), NoError>
    func declareSecondModuleWinner() -> SignalProducer<(), NoError>
    
}

class Round: RoundProtocol {
    var firstRef: FIRDatabaseReference
    var secondRef: FIRDatabaseReference
    var elo: EloRatingProtocol
    
    ////////////////////////////////////////////////////////////////////////////////
    init(firstRef: FIRDatabaseReference, secondRef: FIRDatabaseReference, elo: EloRatingProtocol) {
        
        self.firstRef = firstRef
        self.secondRef = secondRef
        self.elo = elo
        
        self.firstRef.keepSynced(true)
        self.secondRef.keepSynced(true)
        
    }
    
    
    //TODO: Split this into two so that we can send completed for each reference
    private func updateValuesProducer() -> SignalProducer<UpdateValues, NSError> {
        return SignalProducer { observer, _ in
        
            var vals = UpdateValues()
            
            self.firstRef.observeEventType(.Value,
                withBlock: { snapshot in
                    
                    guard let value = snapshot.value as? FirebaseValue else {
                        fatalError()
                    }
                    
                    vals[kRatingFirstKey] = value["rating"] as? Double
                    vals[kKFactorFirstKey] = value["kFactor"] as? Int
                    
            })
            
            self.secondRef.observeEventType(.Value,
                withBlock: { snapshot in
                    
                    guard let value = snapshot.value as? FirebaseValue else {
                        fatalError()
                    }
                    
                    vals[kRatingSecondKey] = value["rating"] as? Double
                    vals[kKFactorSecondKey] = value["kFactor"] as? Int
                    
                    observer.sendNext(vals)
                    observer.sendCompleted()
            })
        
        }
        
        
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    func declareFirstModuleWinner() -> SignalProducer<(), NoError> {
        return SignalProducer { observer, _ in
            
            self.updateValuesProducer().startWithNext({ vals in
                
                let first = vals[kRatingFirstKey] as! Double
                let second = vals[kRatingSecondKey] as! Double
                let kFirst = vals[kKFactorFirstKey] as! Int
                let kSecond = vals[kKFactorSecondKey] as! Int
                
                let expectedFirst = self.elo.expectedWinProbability(forModule: first, againstModule: second)
                let expectedSecond = self.elo.expectedWinProbability(forModule: second, againstModule: first)
                
                self.elo.newRating(forRating: first,
                    withClassification: .Winner,
                    expected: expectedFirst,
                    kFactor: kFirst)
                    .on(
                        next: { rating in
                            
                            self.firstRef
                                .child("rating").setValue(rating, withCompletionBlock: { _ in
                                    print("Should have completed writing first module")
                                })
                            
                    })
                    .then(self.elo.newRating(forRating: second,
                        withClassification: .Loser,
                        expected: expectedSecond,
                        kFactor: kSecond))
                    .on(
                        next: { rating in
                            
                            self.secondRef
                                .child("rating").setValue(rating, withCompletionBlock: { _ in
                                    print("Should have completed writing second module")
                                })
                    })
                    .startWithCompleted({
                        observer.sendCompleted()
                    })
            })
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    func declareSecondModuleWinner() -> SignalProducer<(), NoError> {
        return SignalProducer { observer, _ in
            
            self.updateValuesProducer().startWithNext({ vals in
                
                let first = vals[kRatingFirstKey] as! Double
                let second = vals[kRatingSecondKey] as! Double
                let kFirst = vals[kKFactorFirstKey] as! Int
                let kSecond = vals[kKFactorSecondKey] as! Int
                
                let expectedFirst = self.elo.expectedWinProbability(forModule: first, againstModule: second)
                let expectedSecond = self.elo.expectedWinProbability(forModule: second, againstModule: first)
                
                self.elo.newRating(forRating: first,
                    withClassification: .Loser,
                    expected: expectedFirst,
                    kFactor: kFirst)
                    .on(
                        next: { rating in
                            
                            self.firstRef
                                .child("rating").setValue(rating, withCompletionBlock: { _ in
                                    print("Should have completed writing first module")
                                })
                            
                    })
                    .then(self.elo.newRating(forRating: second,
                        withClassification: .Winner,
                        expected: expectedSecond,
                        kFactor: kSecond))
                    .on(
                        next: { rating in
                            
                            self.secondRef
                                .child("rating").setValue(rating, withCompletionBlock: { _ in
                                    print("Should have completed writing second module")
                                })
                    })
                    .startWithCompleted({
                        observer.sendCompleted()
                    })
            })
        }
    }
}
