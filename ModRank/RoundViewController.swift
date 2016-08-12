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
import Chameleon
import FirebaseDatabase


enum Winner {
    case First, Second
}

public class RoundViewController: UIViewController {
    
    typealias ButtonSignal = Signal<Winner, NoError>
    
    private var fireRef: FIRDatabaseReference!
    private var _currentRound: RoundProtocol!
    
    //UI Components
    private var _mainLabel: UILabel = UILabel()
    private var _nameLabel: UILabel = UILabel()
    private var _firstModuleButton: UIButton = UIButton()
    private var _secondModuleButton: UIButton = UIButton()
    private var _firstTitle: UILabel = UILabel()
    private var _secondTitle: UILabel = UILabel()
    
    
    //Signals
    private var _roundProducer: SignalProducer<RoundProtocol, NSError>
    private var (_firstButtonSignal, _firstButtonObserver) = ButtonSignal.pipe()
    private var (_secondButtonSignal, _secondButtonObserver) = ButtonSignal.pipe()
    private var (_winnerSignal, _winnerObserver) = Signal<ButtonSignal, NoError>.pipe()
    
    
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
    
    ////////////////////////////////////////////////////////////////////////////////
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clearColor()
      
        self._roundProducer.startWithResult { (result) in
            
            switch result {
            case let .Success(round):
                self._currentRound = round
                self.setUpViewWithRound()
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
                self._currentRound.declareModuleWinner(winner).start()
        }
        
        _winnerObserver.sendNext(_firstButtonSignal)
        _winnerObserver.sendNext(_secondButtonSignal)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func setUpViewWithRound() {
        
        self.setUpMainLabel()
        self.setUpNameLabel()
        self.setUpButtons()
        self.setUpModuleTitles()
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func setUpMainLabel() {
        self._mainLabel.text = kMainLabelText
        self._mainLabel.font = UIFont.systemFontOfSize(24, weight: UIFontWeightLight)
        self._mainLabel.textColor = UIColor.whiteColor()
        self._mainLabel.sizeToFit()
        
        let viewCenter = self.view.center
        let center = CGPoint(x: viewCenter.x, y: 75.0)
        self._mainLabel.center = center
        
        self.view.addSubview(self._mainLabel)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func setUpNameLabel() {
        self._nameLabel.text = String(format: kNameLabelText, "Kam")
        self._nameLabel.font = UIFont.systemFontOfSize(24, weight: UIFontWeightLight)
        self._nameLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.55)
        self._nameLabel.sizeToFit()
        
        let viewCenter = self.view.center
        let center = CGPoint(x: viewCenter.x, y: 105.0)
        self._nameLabel.center = center
        
        self.view.addSubview(self._nameLabel)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func setUpButtons() {
        
        let viewCenter = self.view.center
        let kButtonSize = 65.0
        let kButtonGap = 40.0
        let xDelta = CGFloat((kButtonGap + kButtonSize)/2.0)
        
        let buttonSize = CGSize(width: kButtonSize, height: kButtonSize)
        let radius = CGFloat(kButtonSize / 2.0)
        let buttonBorder = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        
        
        let firstCenter = CGPoint(x: viewCenter.x - xDelta, y: viewCenter.y)
        let secondCenter = CGPoint(x: viewCenter.x + xDelta, y: viewCenter.y)
        
        self._firstModuleButton.backgroundColor = UIColor.randomFlatColor()
        self._secondModuleButton.backgroundColor = UIColor.randomFlatColor()
        
        self._firstModuleButton.frame.size = buttonSize
        self._firstModuleButton.center = firstCenter
        self._secondModuleButton.frame.size = buttonSize
        self._secondModuleButton.center = secondCenter
        
        self._firstModuleButton.layer.cornerRadius =  radius
        self._firstModuleButton.clipsToBounds = true
        self._secondModuleButton.layer.cornerRadius = radius
        self._secondModuleButton.clipsToBounds = true
        
        self._firstModuleButton.layer.borderWidth = 5.0
        self._secondModuleButton.layer.borderWidth = 5.0
        self._firstModuleButton.layer.borderColor = buttonBorder.CGColor
        self._secondModuleButton.layer.borderColor = buttonBorder.CGColor
        
        self.view.addSubview(_firstModuleButton)
        self.view.addSubview(_secondModuleButton)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func setUpModuleTitles() {
        self._currentRound.firstRef.observeSingleEventOfType(
            .Value,
            withBlock: { snapshot in
                if let val = snapshot.value as? [String: AnyObject] {
                    let name: String = val["name"] as! String
                    
                    self.setUpLabel(self._firstTitle, forButton: self._firstModuleButton, text: name)
                }
        })
        
        self._currentRound.secondRef.observeSingleEventOfType(
            .Value,
            withBlock: { snapshot in
                if let val = snapshot.value as? [String: AnyObject] {
                    let name: String = val["name"] as! String
                    
                    self.setUpLabel(self._secondTitle, forButton: self._secondModuleButton, text: name)
                }
        })
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    private func setUpLabel(label: UILabel, forButton button: UIButton, text: String) {
        label.text = text
        
        label.font = UIFont.systemFontOfSize(15, weight: UIFontWeightRegular)
        label.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        label.sizeToFit()
        
        let buttonCenter = button.center
        let center = CGPoint(x: buttonCenter.x, y: buttonCenter.y + 55.0)
        label.center = center

        self.view.addSubview(label)
    }
    
}






