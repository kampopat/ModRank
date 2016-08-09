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

////////////////////////////////////////////////////////////////////////////////
protocol MatchmakerProtocol {
    
//    var roundSignal: Signal<RoundProtocol, NSError> { get }
//    var roundObserver: Observer<RoundProtocol, NSError>  { get }
    
    func roundProducer() -> SignalProducer<RoundProtocol, NSError>
    
}

////////////////////////////////////////////////////////////////////////////////
protocol FirebaseMatchMakerProtocol: MatchmakerProtocol {
    var fireRef: FIRDatabaseReference { get }
}


////////////////////////////////////////////////////////////////////////////////
protocol FirebasePairMatchMakerProtocol: MatchmakerProtocol {
    var modulesRef: FIRDatabaseReference { get }
    var firstRef: FIRDatabaseReference? { get set }
    var secondRef: FIRDatabaseReference? { get set }
    
}

////////////////////////////////////////////////////////////////////////////////
struct FirebasePairMatchMaker: FirebasePairMatchMakerProtocol {
    var modulesRef: FIRDatabaseReference
    var firstRef: FIRDatabaseReference? = .None
    var secondRef: FIRDatabaseReference? = .None
    
    var (roundSignal, roundObserver) = Signal<RoundProtocol, NSError>.pipe()
    
    init(modulesRef: FIRDatabaseReference) {
        self.modulesRef = modulesRef
        
        self.modulesRef.observeEventType(.Value,
            withBlock: { snapshot in
                guard let value = snapshot.value as? FirebaseValue else {
                    fatalError("Error getting value from snapshot")
                }
                
                let values = value.map({ module in
                    return module.1 as! [String: AnyObject]
                })
                
                let modules: [ModuleProtocol] = values.map({ moduleDict in
                    return Module(dict: moduleDict)
                })
                
                
                
        })
    }
    
    func roundProducer() -> SignalProducer<RoundProtocol, NSError> {
        fatalError()
    }
}






////////////////////////////////////////////////////////////////////////////////
struct FirebaseMatchMaker: FirebaseMatchMakerProtocol {
    
    var fireRef: FIRDatabaseReference
    
//    var roundSignal: Signal<RoundProtocol, NSError>
//    var roundObserver: Observer<RoundProtocol, NSError>
    
    ////////////////////////////////////////////////////////////////////////////////
    func roundProducer() -> SignalProducer<RoundProtocol, NSError> {
        return firebaseModulesProducer()
            .flatMap(.Latest, transform: self.modulesFromFirebaseProducer)
            .flatMap(.Latest, transform: self.modulesForNextRound)
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
                print("Firebase sent: \(value)")
                observer.sendNext(value)
                observer.sendCompleted()
            })
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func modulesFromFirebaseProducer(value: FirebaseValue) -> SignalProducer<[ModuleProtocol], NSError> {
        
        return SignalProducer { observer, _ in
            let values = value.map({ module in
                return module.1 as! [String: AnyObject]
            })
            
            let modules: [ModuleProtocol] = values.map({ moduleDict in
                return Module(dict: moduleDict)
            })
            
            observer.sendNext(modules)
            observer.sendCompleted()
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////
    private func modulesForNextRound(modules: [ModuleProtocol]) -> SignalProducer<ModulePair, NSError> {
        
        return SignalProducer { observer, _ in
            
            var mods = modules
            
            if mods.count > 1 {
                
                let firstIndex = Int(arc4random_uniform(UInt32(mods.count)))
                let first = mods.removeAtIndex(firstIndex)
                
                let secondIndex = Int(arc4random_uniform(UInt32(mods.count)))
                let second = mods.removeAtIndex(secondIndex)
                let pair = ModulePair(first, second)
                observer.sendNext(pair)
                observer.sendCompleted()
            }
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func nextRound(modules: ModulePair) -> SignalProducer<RoundProtocol, NSError> {
        return SignalProducer { observer, _ in
            
            let elo = EloRating()
            let round = Round(firstModule: modules.0, secondModule: modules.1, elo: elo)
            observer.sendNext(round)
            observer.sendCompleted()
        }
    }
}







