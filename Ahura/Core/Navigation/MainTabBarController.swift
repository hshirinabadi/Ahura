import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }
    
    private func setupTabs() {
        let requestsVC = UINavigationController(rootViewController: RequestsViewController())
        requestsVC.tabBarItem = UITabBarItem(title: "Requests", image: UIImage(systemName: "doc.text"), tag: 0)
        
        let instantBookVC = UINavigationController(rootViewController: InstantBookViewController())
        instantBookVC.tabBarItem = UITabBarItem(title: "Instant Book", image: UIImage(systemName: "bolt"), tag: 1)
        
        let reservationsVC = UINavigationController(rootViewController: ReservationsViewController())
        reservationsVC.tabBarItem = UITabBarItem(title: "Reservations", image: UIImage(systemName: "fork.knife"), tag: 2)
        
        let alertsVC = UINavigationController(rootViewController: AlertsViewController())
        alertsVC.tabBarItem = UITabBarItem(title: "Alerts", image: UIImage(systemName: "bell"), tag: 3)
        
        let settingsVC = UINavigationController(rootViewController: SettingsViewController())
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 4)
        
        viewControllers = [requestsVC, instantBookVC, reservationsVC, alertsVC, settingsVC]
        
        // Set the initial tab
        selectedIndex = 2 // Reservations tab
    }
    
    private func setupAppearance() {
        tabBar.tintColor = .appPrimary
        tabBar.backgroundColor = .appBackground
    }
}

// Placeholder View Controllers
class RequestsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Requests"
        view.backgroundColor = .appBackground
    }
}

class InstantBookViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Instant Book"
        view.backgroundColor = .appBackground
    }
}

class ReservationsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Reservations"
        view.backgroundColor = .appBackground
    }
}

class AlertsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Alerts"
        view.backgroundColor = .appBackground
    }
}

class SettingsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .appBackground
    }
} 