import UIKit

class ReservationCell: UITableViewCell {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let venueNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let partySizeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(venueNameLabel)
        containerView.addSubview(dateTimeLabel)
        containerView.addSubview(partySizeLabel)
        containerView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            venueNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            venueNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            venueNameLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            
            dateTimeLabel.topAnchor.constraint(equalTo: venueNameLabel.bottomAnchor, constant: 8),
            dateTimeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            dateTimeLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            
            partySizeLabel.topAnchor.constraint(equalTo: dateTimeLabel.bottomAnchor, constant: 8),
            partySizeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            partySizeLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            partySizeLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -16),
            
            statusLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            statusLabel.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    // MARK: - Configuration
    func configure(with reservation: Reservation) {
        venueNameLabel.text = reservation.venueName
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        if let date = dateFormatter.date(from: reservation.date),
           let time = timeFormatter.date(from: reservation.time) {
            dateFormatter.dateStyle = .medium
            timeFormatter.timeStyle = .short
            
            let formattedDate = dateFormatter.string(from: date)
            let formattedTime = timeFormatter.string(from: time)
            
            dateTimeLabel.text = "\(formattedDate) at \(formattedTime)"
        } else {
            dateTimeLabel.text = "\(reservation.date) at \(reservation.time)"
        }
        
        partySizeLabel.text = "Party of \(reservation.partySize)"
        
        // Configure status label
        statusLabel.text = reservation.status.rawValue.capitalized
        
        switch reservation.status {
        case .confirmed:
            statusLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            statusLabel.textColor = .systemGreen
        case .pending:
            statusLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
            statusLabel.textColor = .systemOrange
        case .cancelled:
            statusLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
            statusLabel.textColor = .systemRed
        case .completed:
            statusLabel.backgroundColor = UIColor.systemGray.withAlphaComponent(0.2)
            statusLabel.textColor = .systemGray
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        venueNameLabel.text = nil
        dateTimeLabel.text = nil
        partySizeLabel.text = nil
        statusLabel.text = nil
    }
} 