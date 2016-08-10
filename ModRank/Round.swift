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



// --------------------
// MARK: Round Protocol
// --------------------
protocol RoundProtocol {
    var firstRef: FIRDatabaseReference { get set }
    var secondRef: FIRDatabaseReference { get set }
    var elo: EloRatingProtocol { get }
    
    func declareModuleWinner(winner: Winner) -> SignalProducer<(), NoError>
}

// --------------------
// MARK: Round
// --------------------
class Round: RoundProtocol {
    var firstRef: FIRDatabaseReference
    var secondRef: FIRDatabaseReference
    var elo: EloRatingProtocol
    
    typealias ReferenceData = [String: AnyObject]
    
    
    
    ////////////////////////////////////////////////////////////////////////////////
    init(firstRef: FIRDatabaseReference, secondRef: FIRDatabaseReference, elo: EloRatingProtocol) {
        
        self.firstRef = firstRef
        self.secondRef = secondRef
        self.elo = elo
        
        self.firstRef.keepSynced(true)
        self.secondRef.keepSynced(true)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func setKFactorBasedOnRounds(reference: FIRDatabaseReference, rounds: Int) {
        if rounds >= 50 {
            reference.child("kFactor").setValue(8)
        } else if rounds >= 20 {
            reference.child("kFactor").setValue(16)
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func dataForFirstReferenceProducer(existing: ReferenceData? = nil) -> SignalProducer<ReferenceData, NSError> {
        return SignalProducer { observer, _ in
            
            var current = (existing != nil) ? existing! : ReferenceData()
            
            self.firstRef.observeEventType(.Value,
                withBlock: { snapshot in
                    
                    guard let value = snapshot.value as? FirebaseValue else {
                        fatalError()
                    }
                    
                    current[kRatingFirstKey] = value["rating"] as? Double
                    current[kRoundsFirstKey] = value["rounds"] as? Int
                    current[kKFactorFirstKey] = value["kFactor"] as? Int
                    observer.sendNext(current)
                    observer.sendCompleted()
            })
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func dataForSecondReferenceProducer(existing: ReferenceData? = nil) -> SignalProducer<ReferenceData, NSError> {
        return SignalProducer { observer, _ in
            
            var current = (existing != nil) ? existing! : ReferenceData()
            
            self.secondRef.observeEventType(.Value,
                withBlock: { snapshot in
                    
                    guard let value = snapshot.value as? FirebaseValue else {
                        fatalError()
                    }
                    
                    current[kRatingSecondKey] = value["rating"] as? Double
                    current[kRoundsSecondKey] = value["rounds"] as? Int
                    current[kKFactorSecondKey] = value["kFactor"] as? Int
                    observer.sendNext(current)
                    observer.sendCompleted()
            })
        }
    }
 
    ////////////////////////////////////////////////////////////////////////////////
    func declareModuleWinner(winner: Winner) -> SignalProducer<(), NoError> {

        return SignalProducer { observer, _ in
    
            let firstClassification = (winner == Winner.First) ? Classification.Winner : Classification.Loser
            let secondClassification = (winner == Winner.Second) ? Classification.Winner : Classification.Loser
            
            self.dataForFirstReferenceProducer(nil)
                .flatMap(.Latest,
                    transform: self.dataForSecondReferenceProducer)
                .startWithNext({ referenceData in
                    
                    let first = referenceData[kRatingFirstKey] as! Double
                    let second = referenceData[kRatingSecondKey] as! Double
                    let roundsFirst = referenceData[kRoundsFirstKey] as! Int
                    let roundsSecond = referenceData[kRoundsSecondKey] as! Int
                    let kFirst = referenceData[kKFactorFirstKey] as! Int
                    let kSecond = referenceData[kKFactorSecondKey] as! Int
                    
                    let expectedFirst = self.elo.expectedWinProbability(forRating: first, againstRating: second)
                    let expectedSecond = self.elo.expectedWinProbability(forRating: second, againstRating: first)
                    
                    self.elo.newRating(forRating: first,
                        withClassification: firstClassification,
                        expected: expectedFirst,
                        kFactor: kFirst)
                        .on(
                            next: { rating in
                                self.firstRef.child("rating").setValue(rating)
                                let newRounds = roundsFirst + 1
                                self.firstRef.child("rounds").setValue(newRounds)
                                self.setKFactorBasedOnRounds(self.firstRef, rounds: newRounds)
                        })
                        .then(self.elo.newRating(forRating: second,
                            withClassification: secondClassification,
                            expected: expectedSecond,
                            kFactor: kSecond))
                        .on(
                            next: { rating in
                                self.secondRef.child("rating").setValue(rating)
                                let newRounds = roundsSecond + 1
                                self.secondRef.child("rounds").setValue(newRounds)
                                self.setKFactorBasedOnRounds(self.secondRef, rounds: newRounds)
                        })
                        .startWithCompleted({ observer.sendCompleted() })
                })
        }
    }
}
