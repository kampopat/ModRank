//
//  EloRating.swift
//  ModRank
//
//  Created by Kam Popat on 25/07/2016.
//  Copyright © 2016 Kam Popat. All rights reserved.
//

import Foundation
import ReactiveCocoa
import enum Result.NoError

// --------------------
// MARK: Rounding
// --------------------
extension Double {
    /// Rounds the double to decimal places value
    func roundToPlaces(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(self * divisor) / divisor
    }
}

// --------------------
// MARK: Classification
// --------------------
enum Classification {
    case Winner, Loser
}

// --------------------
// MARK: Elo Rating Protocol
// --------------------
protocol EloRatingProtocol {
    
    func expectedWinProbability(forModule fModule: ModuleProtocol, againstModule aModule: ModuleProtocol)
        -> Double
    
    func expectedWinProbabilityProducer(forModule fModule: ModuleProtocol, againstModule aModule: ModuleProtocol)
        -> SignalProducer<Double, NoError>
    
    func newRating(forModule module: ModuleProtocol,
                   withClassification classification: Classification, expected: Double)
        -> SignalProducer<Double, NoError>
}

// --------------------
// MARK: EloRating
// --------------------
struct EloRating: EloRatingProtocol {
    
    func expectedWinProbability(forModule fModule: ModuleProtocol, againstModule aModule: ModuleProtocol) -> Double {
        return 1 / (1 +  pow(10.0, ((aModule.rating-fModule.rating)/400.0)))
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    func expectedWinProbabilityProducer(forModule fModule: ModuleProtocol, againstModule aModule: ModuleProtocol) -> SignalProducer<Double, NoError> {
        return SignalProducer { observer, _ in
            
            let probability = 1 / (1 +  pow(10.0, ((aModule.rating-fModule.rating)/400.0)))
            observer.sendNext(probability)
            observer.sendCompleted()
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    func newRating(forModule module: ModuleProtocol, withClassification classification: Classification, expected: Double)
        -> SignalProducer<Double, NoError> {
            
            switch classification {
            case .Winner:
                return winnerNewRating(module, expected: expected)
            case .Loser:
                return loserNewRating(module, expected: expected)
            }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func loserNewRating(module: ModuleProtocol, expected: Double)
        -> SignalProducer<Double, NoError> {
            return SignalProducer { observer, _ in
                let rating = module.rating + ( Double(module.kFactor) * (0-expected))
                observer.sendNext(rating.roundToPlaces(3))
                observer.sendCompleted()
            }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func winnerNewRating(module: ModuleProtocol, expected: Double)
        -> SignalProducer<Double, NoError> {
            return SignalProducer { observer, _ in
                let rating = module.rating + ( Double(module.kFactor) * (1-expected))
                observer.sendNext(rating.roundToPlaces(3))
                observer.sendCompleted()
            }
    }
}











