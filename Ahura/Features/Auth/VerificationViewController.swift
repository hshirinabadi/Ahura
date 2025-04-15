import UIKit

class VerificationViewController: UIViewController {
    private let phoneNumber: String
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter verification code"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .appSecondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let codeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter 4-digit code"
        textField.keyboardType = .numberPad
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        return textField
    }()
    
    private let verifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Verify", for: .normal)
        button.backgroundColor = .appPrimary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    
    private let resendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Resend Code", for: .normal)
        return button
    }()
    
    init(phoneNumber: String) {
        self.phoneNumber = phoneNumber
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        updateSubtitle()
    }
    
    private func setupUI() {
        view.backgroundColor = .appBackground
        
        view.addSubview(stackView)
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(codeTextField)
        stackView.addArrangedSubview(verifyButton)
        stackView.addArrangedSubview(resendButton)
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            verifyButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        verifyButton.addTarget(self, action: #selector(verifyButtonTapped), for: .touchUpInside)
        resendButton.addTarget(self, action: #selector(resendButtonTapped), for: .touchUpInside)
    }
    
    private func updateSubtitle() {
        subtitleLabel.text = "We've sent a verification code to \(phoneNumber)"
    }
    
    @objc private func verifyButtonTapped() {
        guard let code = codeTextField.text, !code.isEmpty else {
            showError("Please enter the verification code")
            return
        }
        
        verifyButton.isEnabled = false
        showLoading(true)
        
        AuthService.shared.verifyCode(code, for: phoneNumber) { [weak self] result in
            DispatchQueue.main.async {
                self?.verifyButton.isEnabled = true
                self?.showLoading(false)
                
                switch result {
                case .success:
                    // Get the SceneDelegate to switch to main interface
                    if let sceneDelegate = UIApplication.shared.connectedScenes
                        .first?.delegate as? SceneDelegate {
                        sceneDelegate.showMainInterface()
                    }
                case .failure(let error):
                    self?.showError(error.message)
                }
            }
        }
    }
    
    @objc private func resendButtonTapped() {
        resendButton.isEnabled = false
        
        AuthService.shared.sendVerificationCode(to: phoneNumber) { [weak self] result in
            DispatchQueue.main.async {
                self?.resendButton.isEnabled = true
                
                switch result {
                case .success:
                    self?.showSuccess("Code resent successfully")
                case .failure(let error):
                    self?.showError(error.message)
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccess(_ message: String) {
        let alert = UIAlertController(
            title: "Success",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showLoading(_ show: Bool) {
        if show {
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.startAnimating()
            verifyButton.setTitle("", for: .normal)
            verifyButton.addSubview(activityIndicator)
            activityIndicator.center = CGPoint(x: verifyButton.bounds.width/2, y: verifyButton.bounds.height/2)
        } else {
            verifyButton.subviews.forEach { $0.removeFromSuperview() }
            verifyButton.setTitle("Verify", for: .normal)
        }
    }
} 