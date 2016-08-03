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

protocol MatchmakerProtocol {
    func roundProducer() -> SignalProducer<RoundProtocol, NSError>
}

protocol FirebaseMatchMakerProtocol: MatchmakerProtocol {
    var fireRef: FIRDatabaseReference { get }
}


struct FirebaseMatchMaker: FirebaseMatchMakerProtocol {
    
    var fireRef: FIRDatabaseReference
    
    
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
            
            self.fireRef.observeSingleEventOfType(.Value,
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





let facebookTest = Module(name: "Facebook", rating: 1400, rounds: 0, kFactor: 32)
let twitterTest = Module(name: "Twitter", rating: 1400, rounds: 0, kFactor: 32)
let calTest = Module(name: "Calendar", rating: 1400, rounds: 0, kFactor: 32)
let emailTest = Module(name: "Email", rating: 1400, rounds: 0, kFactor: 32)

let testModules = [facebookTest, twitterTest, calTest, emailTest]

struct MatchmakerTest: MatchmakerProtocol {
    
    func roundProducer() -> SignalProducer<RoundProtocol, NSError> {
        return self.modulesForNextRound()
            .flatMap(FlattenStrategy.Latest, transform: self.nextRound)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    func modulesForNextRound() -> SignalProducer<ModulePair, NSError> {
        return SignalProducer { observer, _ in
            
            var roundModules = testModules
            
            if roundModules.count > 1 {
                
                let firstIndex = Int(arc4random_uniform(UInt32(roundModules.count)))
                let first = roundModules.removeAtIndex(firstIndex)
                
                let secondIndex = Int(arc4random_uniform(UInt32(roundModules.count)))
                let second = roundModules.removeAtIndex(secondIndex)
                let pair = ModulePair(first, second)
                observer.sendNext(pair)
                observer.sendCompleted()
            }
            
            //TODO: Handle Error cases
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    func nextRound(modules: ModulePair) -> SignalProducer<RoundProtocol, NSError> {
        return SignalProducer { observer, _ in
            
            let elo = EloRating()
            let round = Round(firstModule: modules.0, secondModule: modules.1, elo: elo)
            observer.sendNext(round)
            observer.sendCompleted()
        }
    }
}


