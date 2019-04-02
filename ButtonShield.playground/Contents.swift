
import UIKit
import PlaygroundSupport

fileprivate extension CGFloat {
  static var outerCircleRatio: CGFloat = 0.8
  static var innerCircleRatio: CGFloat = 0.55
  static var inProgressRatio: CGFloat = 0.58
}

fileprivate extension Double {
  static var animationDuration: Double = 0.5
  static var inProgressPeriod: Double = 2.0
}


class ButtonView: UIView {
    enum State {
        case off
        case inProgress
        case on
    }
    
    public var state: State = .off {
        didSet {
            switch state {
            case .inProgress:
                showInProgress(true)
            case .on:
                showInProgress(false)
                animateTo(.on)
            case .off:
                showInProgress(false)
                animateTo(.off)
            }
        }
    }
    
    private let buttonLayer = CALayer()
    private lazy var innerCircle: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = Utils.pathForCircleInRect(rect: buttonLayer.bounds, scaled: CGFloat.innerCircleRatio)
        layer.fillColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        layer.strokeColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        layer.lineWidth = 3
        
        layer.shadowRadius = 15
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 15, height: 0)
        layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        return layer
    }()
  
    private lazy var outerCircle: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = Utils.pathForCircleInRect(rect: buttonLayer.bounds, scaled: CGFloat.outerCircleRatio)
        layer.fillColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        layer.opacity = 0.4
        return layer
    }()
    
    private lazy var badgeLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)].map { $0.cgColor }
        layer.frame = self.layer.bounds
        layer.mask = createBadgeMaskLayer()
        return layer
    }()
    
    private lazy var inProgressLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1), UIColor(white: 1, alpha: 0)].map { $0.cgColor }
        layer.frame = CGRect(centre: buttonLayer.bounds.centre, size: buttonLayer.bounds.size.rescale(CGFloat.inProgressRatio))
        layer.locations = [0 , 0.7].map { NSNumber(floatLiteral: $0) }
        
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(ovalIn: layer.bounds).cgPath
        layer.mask = mask
        
        layer.isHidden = true
        
        return layer
    }()
    
    private lazy var greenBackground: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = Utils.pathForCircleInRect(rect: buttonLayer.frame, scaled: CGFloat.innerCircleRatio)
        layer.fillColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        layer.mask = createBadgeMaskLayer()
        return layer
    }()
    
    private func createBadgeMaskLayer() -> CAShapeLayer {
        let mask = CAShapeLayer()
        mask.path = UIBezierPath.badgePath.cgPath
        let scale = self.layer.bounds.width / UIBezierPath.badgePath.bounds.width
        mask.transform = CATransform3DMakeScale(scale, scale, 1)
        return mask
    }
    
  override init(frame: CGRect) {
    super.init(frame: frame)
    configureLayers()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureLayers()
  }
  
  private func configureLayers() {
    backgroundColor = #colorLiteral(red: 0.9600390625, green: 0.9600390625, blue: 0.9600390625, alpha: 1)
    buttonLayer.frame = bounds.largestContainedSquare.offsetBy(dx: 0, dy: -20)
//    buttonLayer.addSublayer(badgeLayer)
    buttonLayer.addSublayer(outerCircle)
    buttonLayer.addSublayer(inProgressLayer)
    buttonLayer.addSublayer(innerCircle)
    
    layer.addSublayer(badgeLayer)
    layer.addSublayer(greenBackground)
    layer.addSublayer(buttonLayer)
  }
    private func showInProgress(_ show: Bool = true) {
        if show {
            inProgressLayer.isHidden = false
            let animation = CABasicAnimation(keyPath: "transform.rotation.z")
            animation.fromValue = 0
            animation.toValue = 2 * Double.pi
            animation.duration = Double.inProgressPeriod
            animation.repeatCount = .greatestFiniteMagnitude
            inProgressLayer.add(animation, forKey: "inProgressAnimation")
        } else {
            inProgressLayer.isHidden = true
            inProgressLayer.removeAnimation(forKey: "inProgressAnimation")
        }
    }
    
    private func animateTo(_ state: State) {
        let animationKey: String
        let path: CGPath
        
        switch state {
        case .on:
            path = Utils.pathForCircleThatContains(rect: bounds)
            animationKey = "onAnimation"
            break
        case .off:
            path = Utils.pathForCircleInRect(rect: buttonLayer.frame, scaled: CGFloat.innerCircleRatio)
            animationKey = "offAnimation"
            break
        default:
            animationKey = ""
            path = UIBezierPath().cgPath
        }
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = greenBackground.path
        animation.toValue = path
        animation.duration = Double.animationDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        greenBackground.add(animation, forKey: animationKey)
        greenBackground.path = path
    }
}



let aspectRatio = UIBezierPath.badgePath.bounds.width / UIBezierPath.badgePath.bounds.height
let button = ButtonView(frame: CGRect(x: 0, y: 0, width: 300, height: 300 / aspectRatio))

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = button

let connection = PseudoConnection(connectionTime: 5) { (state) in
    switch state {
    case .disconnected:
        print("Disconnected")
        button.state = .off
    case .connecting:
        print("Connecting")
        button.state = .inProgress
    case .connected:
        print("Connected")
        button.state = .on
    }
}

let gesture = UITapGestureRecognizer(target: connection, action: #selector(PseudoConnection.toggle))
button.addGestureRecognizer(gesture)
