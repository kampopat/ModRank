//
//  Matchmaker.swift
//  ModRank
//
//  Created by Kam Popat on 22/07/2016.
//  Copyright © 2016 Kam Popat. All rights reserved.
//

import Foundation
import ReactiveCocoa
import enum Result.NoError
import FirebaseDatabase

typealias ModulePair = (ModuleProtocol, ModuleProtocol)
typealias FirebaseValue = [String: AnyObject]
typealias FirebasePair = (FIRDatabaseReference, FIRDatabaseReference)

// --------------------
// MARK: Matchmaker protocol
// --------------------
////////////////////////////////////////////////////////////////////////////////
protocol MatchmakerProtocol {
    
    func roundProducer() -> SignalProducer<RoundProtocol, NSError>
}

// --------------------
// MARK: Firebase matchmaker protocol
// --------------------
////////////////////////////////////////////////////////////////////////////////
protocol FirebaseMatchMakerProtocol: MatchmakerProtocol {
    var fireRef: FIRDatabaseReference { get }
}

// --------------------
// MARK: Firebase matchmaker 
// --------------------
////////////////////////////////////////////////////////////////////////////////
struct FirebaseMatchMaker: FirebaseMatchMakerProtocol {
    
    var fireRef: FIRDatabaseReference
    
    ////////////////////////////////////////////////////////////////////////////////
    func roundProducer() -> SignalProducer<RoundProtocol, NSError> {
        return firebaseModulesProducer()
            .flatMap(.Latest, transform: self.firebaseReferencesProducer)
            .flatMap(.Latest, transform: self.referencesForNextRound)
            .flatMap(.Latest, transform: self.nextRound)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func firebaseModulesProducer() -> SignalProducer<FirebaseValue, NSError> {
        
        return SignalProducer { observer, _ in
            
            self.fireRef.observeEventType(.Value,
                withBlock: { snapshot in
                    guard let value = snapshot.value as? FirebaseValue else {
                        fatalError()
                }
                observer.sendNext(value)
                observer.sendCompleted()
            })
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func firebaseReferencesProducer(value: FirebaseValue) -> SignalProducer<[FIRDatabaseReference], NSError> {
        return SignalProducer { observer, _ in
        
            let keys = value.map({ module in
                return module.0
            })
            
            let references = keys.map({ key in
                return self.fireRef.child(key)
            })
            
            observer.sendNext(references)
            observer.sendCompleted()
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func referencesForNextRound(references: [FIRDatabaseReference]) -> SignalProducer<FirebasePair, NSError> {
        
        return SignalProducer { observer, _ in
            
            var refs = references
            
            if refs.count > 1 {
                let firstIndex = Int(arc4random_uniform(UInt32(refs.count)))
                let first = refs.removeAtIndex(firstIndex)
                
                let secondIndex = Int(arc4random_uniform(UInt32(refs.count)))
                let second = refs.removeAtIndex(secondIndex)
                
                let pair = FirebasePair(first, second)
                observer.sendNext(pair)
                observer.sendCompleted()
            }
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func nextRound(references: FirebasePair) -> SignalProducer<RoundProtocol, NSError> {
        return SignalProducer { observer, _ in
            
            let elo = EloRating()
            let round = Round(firstRef: references.0, secondRef: references.1, elo: elo)
            observer.sendNext(round)
            observer.sendCompleted()
        }
    }
}







