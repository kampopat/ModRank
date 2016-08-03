//
//  RoundViewController.swift
//  ModRank
//
//  Created by Kam Popat on 26/07/2016.
//  Copyright © 2016 Kam Popat. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa
import enum Result.NoError

import FirebaseDatabase


public class RoundViewController: UIViewController {
    
    enum Winner {
        case First, Second
    }
    
    typealias ButtonSignal = Signal<Winner, NoError>
    
    
    private var _roundProducer: SignalProducer<RoundProtocol, NSError>
    private var _firstModuleButton: UIButton = UIButton()
    private var _secondModuleButton: UIButton = UIButton()
    
    private var (_firstButtonSignal, _firstButtonObserver) = ButtonSignal.pipe()
    private var (_secondButtonSignal, _secondButtonObserver) = ButtonSignal.pipe()
    private var (_winnerSignal, _winnerObserver) = Signal<ButtonSignal, NoError>.pipe()
    
    private var _currentRound: RoundProtocol!
    
    
    ////////////////////////////////////////////////////////////////////////////////
    init(roundProducer: SignalProducer<RoundProtocol, NSError>) {
        self._roundProducer = roundProducer
        
        _firstButtonSignal = _firstModuleButton
            .signalForControlEvents(.TouchUpInside).map({
                return Winner.First
            })
        
        _secondButtonSignal = _secondModuleButton
            .signalForControlEvents(.TouchUpInside).map({
                return Winner.Second
            })

        
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.redColor()
        
        self._roundProducer.startWithResult { (result) in
            
            switch result {
            case let .Success(round):
                self._currentRound = round
                self.setUpViewWithRound(self._currentRound)
                self.observeWinnerSignal()
            case let .Failure(error):
                print("Error: \(error)")
            }
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func observeWinnerSignal() {
        
        _winnerSignal.flatten(.Merge).take(1)
            .observeNext { winner in
                
                switch winner {
                case .First:
                    self._currentRound.declareFirstModuleWinner()
                        .startWithCompleted({
                            self.roundPrint()
                        })
                case .Second:
                    self._currentRound.declareSecondModuleWinner()
                        .startWithCompleted({
                            self.roundPrint()
                        })
                }
        }
        
        _winnerObserver.sendNext(_firstButtonSignal)
        _winnerObserver.sendNext(_secondButtonSignal)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func roundPrint() {
        print("Ratings after round:")
        print("\(self._currentRound.firstModule.name): \(self._currentRound.firstModule.rating)")
        print("\(self._currentRound.secondModule.name): \(self._currentRound.secondModule.rating)")
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func setUpViewWithRound(round: RoundProtocol) {
        var first = round.firstModule
        var second = round.secondModule
        
        self._firstModuleButton.setTitle(first.name, forState: .Normal)
        self._secondModuleButton.setTitle(second.name, forState: .Normal)
        
        
        self._firstModuleButton.backgroundColor = UIColor.blackColor()
        self._secondModuleButton.backgroundColor = UIColor.blackColor()
        
        
        let minVal = min(self.view.frame.height, self.view.frame.width) - 100.0
        let buttonSize = CGSize(width: minVal, height: minVal)
        
        let firstFrame = CGRect(origin: CGPointZero, size: buttonSize)
        
        let secondOrigin = CGPoint(x: 0.0, y: self.view.frame.height/2)
        let secondFrame = CGRect(origin: secondOrigin, size: buttonSize)
        
        self._firstModuleButton.frame = firstFrame
        self._secondModuleButton.frame = secondFrame
        
        let radius = minVal / 2.0
        
        self._firstModuleButton.layer.cornerRadius =  radius
        self._firstModuleButton.clipsToBounds = true
        self._secondModuleButton.layer.cornerRadius = radius
        
        self.view.addSubview(_firstModuleButton)
        self.view.addSubview(_secondModuleButton)
    }
    
}








