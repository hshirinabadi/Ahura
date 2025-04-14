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
            // Show error
            return
        }
        
        verifyButton.isEnabled = false
        
        AuthService.shared.verifyCode(code, for: phoneNumber) { [weak self] result in
            DispatchQueue.main.async {
                self?.verifyButton.isEnabled = true
                
                switch result {
                case .success:
                    // Navigate to main app
                    print("Successfully verified!")
                case .failure(let error):
                    // Show error alert
                    print(error.message)
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
                    // Show success message
                    print("Code resent!")
                case .failure(let error):
                    // Show error alert
                    print(error.message)
                }
            }
        }
    }
} 