import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramBaseController
import AccountContext

private struct DogGramNFTUsername: Codable {
    var name: String
    var price: String
    var currency: String
}

private struct DogGramDemoAsset: Codable {
    var name: String
    var quantity: String
    var currency: String
    var displayedValue: String
}

private struct DogGramVisualSettings: Codable {
    var premiumDemo = false
    var checkDemo = false
    var verification = "Выключена"
    var level = "Обычный"
    var displayNumber = "+888"
    var stars = "33408112"
    var gram = "381.82"
    var avatarData: Data?
    var usernames: [DogGramNFTUsername] = []
    var gifts: [String] = []
    var demoAssets: [DogGramDemoAsset] = []
    var demoOperations: [String] = []
    var profileColor = "Синий"
    var profileBackground = "Не задан"
    var profileTheme = "Тёмная"
    var workingHours = "Не заданы"
    var address = "Не задан"

    static let legacyKey = "DogGram.VisualSettings.v1"

    static func load(accountId: Int64) -> DogGramVisualSettings {
        let accountKey = "\(legacyKey).\(accountId)"
        if let data = UserDefaults.standard.data(forKey: accountKey),
           let value = try? JSONDecoder().decode(DogGramVisualSettings.self, from: data) {
            return value
        }

        if let data = UserDefaults.standard.data(forKey: legacyKey),
           let value = try? JSONDecoder().decode(DogGramVisualSettings.self, from: data) {
            value.save(accountId: accountId)
            UserDefaults.standard.removeObject(forKey: legacyKey)
            return value
        }

        return DogGramVisualSettings()
    }

    func save(accountId: Int64) {
        guard let data = try? JSONEncoder().encode(self) else {
            return
        }
        UserDefaults.standard.set(data, forKey: "\(Self.legacyKey).\(accountId)")
        NotificationCenter.default.post(name: Notification.Name("DogGramVisualSettingsDidChange"), object: nil)
    }
}

private final class DogGramControlView: UIView {
    var onAction: ((String) -> Void)?
    var onInputRequested: ((String, String, @escaping (String) -> Void) -> Void)?
    var onDualInputRequested: ((String, (String, String), (String, String), @escaping (String, String) -> Void) -> Void)?
    var onOptionsRequested: ((String, [(title: String, destructive: Bool)], @escaping (String) -> Void) -> Void)?
    var onNotice: ((String) -> Void)?
    var onImageRequested: (() -> Void)?
    var onConfirmationRequested: ((String, String, @escaping (Bool) -> Void) -> Void)?
    var onPageChanged: ((String) -> Void)?
    private let accountId: Int64
    private var settings: DogGramVisualSettings
    private var page = "control"
    private let stack = UIStackView()
    private let scrollView = UIScrollView()

    var pageTitle: String {
        switch self.page {
        case "profile": return "Профиль"
        case "balances": return "Балансы"
        case "operations": return "Операции · Demo"
        case "gifts": return "Подарки"
        case "nft": return "NFT-юзернеймы"
        case "style": return "Оформление"
        default: return "DuckGram"
        }
    }

    init(accountId: Int64) {
        self.accountId = accountId
        self.settings = DogGramVisualSettings.load(accountId: accountId)
        super.init(frame: .zero)
        self.backgroundColor = .systemGroupedBackground
        self.scrollView.alwaysBounceVertical = true
        self.addSubview(self.scrollView)
        self.stack.axis = .vertical
        self.stack.spacing = 12
        self.scrollView.addSubview(self.stack)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.stack.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 12),
            self.stack.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor, constant: -12),
            self.stack.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 12),
            self.stack.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor, constant: -28),
            self.stack.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor, constant: -24)
        ])
        self.render()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func perform(_ action: String) {
        switch action {
        case "profile", "profilePicker": self.page = "profile"
        case "balances": self.page = "balances"
        case "gifts": self.page = "gifts"
        case "nft": self.page = "nft"
        case "style": self.page = "style"
        case "operations": self.page = "operations"
        case "back": self.page = "control"
        case "premium": self.settings.premiumDemo.toggle()
        case "check": self.settings.checkDemo.toggle()
        case "avatar": self.onImageRequested?()
        case "access":
            self.onNotice?("Доступ к DuckGram уже открыт на этом устройстве. Повторная проверка не требуется.")
        case "verification":
            self.onOptionsRequested?("Верификация", [("Major", false), ("Hold", false), ("Выключить", true)]) { [weak self] value in
                guard let self else { return }
                self.settings.verification = value == "Выключить" ? "Выключена" : value
                self.saveSettings()
                self.render()
            }
        case "level": self.settings.level = self.settings.level == "Обычный" ? "Пользовательский · Demo" : "Обычный"
        case "number":
            self.onInputRequested?("Номер профиля · Demo", self.settings.displayNumber) { [weak self] value in
                self?.settings.displayNumber = value
                self?.saveSettings()
                self?.render()
            }
        case "stars":
            self.onInputRequested?("Демо-баланс звёзд", self.settings.stars) { [weak self] value in
                self?.settings.stars = value
                self?.saveSettings()
                self?.render()
            }
        case "gram":
            self.onInputRequested?("Демо-баланс GRAM", self.settings.gram) { [weak self] value in
                self?.settings.gram = value
                self?.saveSettings()
                self?.render()
            }
        case "addStarsOperation":
            self.onInputRequested?("Изменить демо-баланс Stars (+/-)", "+1") { [weak self] value in
                guard let self, let amount = Int64(value), amount != 0 else {
                    self?.onNotice?("Введите целое число, например +10 или -3.")
                    return
                }
                let balance = Int64(self.settings.stars) ?? 0
                let (updatedBalance, overflow) = balance.addingReportingOverflow(amount)
                guard !overflow, updatedBalance >= 0 else {
                    self.onNotice?("Демо-баланс Stars не может быть отрицательным или превышать лимит.")
                    return
                }
                self.settings.stars = String(updatedBalance)
                self.settings.demoOperations.append("Stars · \(amount > 0 ? "+" : "")\(amount)")
                self.saveSettings()
                self.render()
            }
        case "addGramOperation":
            self.onInputRequested?("Изменить демо-баланс GRAM (+/-)", "+1") { [weak self] value in
                let normalizedValue = value.replacingOccurrences(of: ",", with: ".")
                guard let self, let amount = Decimal(string: normalizedValue), amount != 0 else {
                    self?.onNotice?("Введите число, например +1.5 или -0.25.")
                    return
                }
                let currentBalance = Decimal(string: self.settings.gram.replacingOccurrences(of: ",", with: ".")) ?? 0
                let updatedBalance = currentBalance + amount
                guard updatedBalance >= 0 else {
                    self.onNotice?("Демо-баланс GRAM не может быть отрицательным.")
                    return
                }
                self.settings.gram = NSDecimalNumber(decimal: updatedBalance).stringValue
                let amountString = NSDecimalNumber(decimal: amount).stringValue
                self.settings.demoOperations.append("GRAM · \(amount > 0 ? "+" : "")\(amountString)")
                self.saveSettings()
                self.render()
            }
        case "gramCard": self.onNotice?("Демо-карточка GRAM. Средства не списываются, карта не выпускается.")
        case "addUsername":
            self.onDualInputRequested?("NFT-юзернейм", ("Имя", "duck"), ("Цена TON", "25")) { [weak self] name, price in
                guard let self else {
                    return
                }
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else {
                    return
                }
                self.settings.usernames.append(DogGramNFTUsername(name: trimmedName, price: price, currency: "TON"))
                self.saveSettings()
                self.render()
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "d MMM yyyy"
                let dateString = formatter.string(from: Date())
                self.onNotice?("Юзернейм @\(trimmedName) закреплён на Fragment \(dateString) за \(price) TON · Demo. Локальная витрина, реальная покупка не выполняется.")
            }
        case "workingHours":
            self.onInputRequested?("Часы работы · Demo", self.settings.workingHours) { [weak self] value in
                self?.settings.workingHours = value
                self?.saveSettings()
                self?.render()
            }
        case "address":
            self.onInputRequested?("Адрес профиля · Demo", self.settings.address) { [weak self] value in
                self?.settings.address = value
                self?.saveSettings()
                self?.render()
            }
        case "color":
            self.settings.profileColor = self.settings.profileColor == "Синий" ? "Фиолетовый" : "Синий"
        case "background":
            self.onInputRequested?("Фоновое изображение · Demo", self.settings.profileBackground) { [weak self] value in
                self?.settings.profileBackground = value
                self?.saveSettings()
                self?.render()
            }
        case "theme":
            self.settings.profileTheme = self.settings.profileTheme == "Тёмная" ? "Светлая" : "Тёмная"
        case "addAsset":
            self.onInputRequested?("Название демо-актива", "My asset") { [weak self] name in
                guard let self, !name.isEmpty else {
                    return
                }
                self.onInputRequested?("Количество", "1") { [weak self] quantity in
                    guard let self else {
                        return
                    }
                    self.onInputRequested?("Валюта", "DOG") { [weak self] currency in
                        guard let self else {
                            return
                        }
                        self.onInputRequested?("Отображаемая стоимость · Demo", "0") { [weak self] displayedValue in
                            guard let self else {
                                return
                            }
                            self.settings.demoAssets.append(DogGramDemoAsset(name: name, quantity: quantity, currency: currency, displayedValue: displayedValue))
                            self.saveSettings()
                            self.render()
                        }
                    }
                }
            }
        case "addGift":
            self.onInputRequested?("Получатель подарка", "@username") { [weak self] recipient in
                guard let self, !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                self.onInputRequested?("Подпись", "") { [weak self] caption in
                    guard let self else { return }
                    self.onConfirmationRequested?("Отправить подарок", "Записать подарок локально? Реальная отправка не выполняется.") { [weak self] confirmed in
                        guard let self, confirmed else { return }
                        self.settings.gifts.append("Подарок · \(recipient)" + (caption.isEmpty ? "" : " · \(caption)"))
                        self.saveSettings()
                        self.render()
                    }
                }
            }
        case "addNFTGift":
            self.onInputRequested?("Ссылка на NFT · Demo", "https://") { [weak self] link in
                self?.onConfirmationRequested?("Предпросмотр NFT · Demo", "\(link)\n\nДобавить только в локальную коллекцию Dog Gram?") { [weak self] confirmed in
                    guard let self, confirmed else {
                        return
                    }
                    self.settings.gifts.append("NFT · \(link)")
                    self.saveSettings()
                    self.render()
                }
            }
        case "sendGift": self.onNotice?("Демонстрационный сценарий. Ничего не отправлено и не куплено.")
        case "reset": self.settings = DogGramVisualSettings()
        default: break
        }
        self.saveSettings()
        self.render()
    }

    private func render() {
        self.onPageChanged?(self.pageTitle)
        self.stack.arrangedSubviews.forEach { view in
            self.stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        switch self.page {
        case "profile":
            self.section([("Выбор профиля", "Мой профиль", "back"), ("Назад", "", "back")])
            self.section([("Telegram Premium", "", "premium"), ("Галочка Telegram", "", "check"), ("Верификация", self.settings.verification, "verification")])
            self.section([("Добавить NFT-юзернейм", "", "nft"), ("Номер профиля", self.settings.displayNumber, "number"), ("Уровень", self.settings.level, "level"), ("Юзернеймы", "\(self.settings.usernames.count)", "nft")])
            self.section([("Цвета и фон профиля", "", "style"), ("Часы работы", self.settings.workingHours, "workingHours"), ("Адрес", self.settings.address, "address")])
        case "balances":
            self.section([("Выбор профиля", "Мой профиль", "back"), ("Назад", "", "back")])
            self.section([("Баланс звёзд", self.settings.stars, "stars"), ("Добавить операцию", "", "addStarsOperation"), ("Мои операции звёзд", "", "operations")])
            self.section([("Баланс GRAM", self.settings.gram, "gram"), ("Добавить операцию", "", "addGramOperation"), ("Оформить карточку GRAM", "", "gramCard"), ("Мои операции GRAM", "", "operations")])
            self.section(self.settings.demoAssets.map { ($0.name, "\($0.quantity) · \($0.displayedValue) \($0.currency)", "balances") } + [("Добавить демо-актив", "", "addAsset")])
        case "operations":
            self.section([("Назад", "", "back")])
            self.section(self.settings.demoOperations.map { ($0, "Demo", "operations") })
        case "gifts":
            self.section([("Выбор профиля", "Мой профиль", "profilePicker"), ("Назад", "", "back")])
            self.section([("Отправить NFT", "", "addNFTGift"), ("Отправить обычный подарок", "", "addGift")])
            self.section(self.settings.gifts.map { ($0, "Demo", "sendGift") })
        case "nft":
            self.section([("Назад", "", "back"), ("Добавить юзернейм", "", "addUsername")])
            self.section(self.settings.usernames.map { ($0.name, "\($0.price) \($0.currency) · NFT", "nft") })
            if !self.settings.usernames.isEmpty {
                let explanation = UILabel()
                explanation.text = "Коллекционные имена Telegram приобретаются и управляются через Fragment. Здесь показана только локальная визуальная карточка DogGram."
                explanation.textColor = UIColor(white: 0.68, alpha: 1.0)
                explanation.numberOfLines = 0
                explanation.font = .systemFont(ofSize: 13)
                self.stack.addArrangedSubview(explanation)
            }
        case "style":
            self.section([("Назад", "", "back"), ("Цвет профиля", self.settings.profileColor, "color"), ("Фоновое изображение", self.settings.profileBackground, "background"), ("Цветовая тема", self.settings.profileTheme, "theme"), ("Часы работы", self.settings.workingHours, "workingHours"), ("Адрес", self.settings.address, "address")])
            self.addAppearancePreview()
        default:
            self.section([("Доступ", "Проверить ›", "access"), ("Выбор профиля", "Мой профиль ›", "profilePicker")])
            self.section([("Профиль", "", "profile"), ("Подарки", "", "gifts"), ("Балансы", "", "balances")])
            self.section([("Очистить всё оформление", "", "reset")], destructive: true)
        }
    }

    private func saveSettings() {
        self.settings.save(accountId: self.accountId)
    }

    private func section(_ rows: [(String, String, String)], destructive: Bool = false) {
        let card = UIStackView()
        card.axis = .vertical
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 10
        card.clipsToBounds = true
        for (index, row) in rows.enumerated() {
            let rowView = UIView()
            let title = UILabel()
            title.text = row.0
            title.textColor = destructive ? .systemRed : .label
            title.font = .systemFont(ofSize: 17, weight: .regular)
            title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let value = UILabel()
            value.text = row.1
            value.textColor = .secondaryLabel
            value.font = .systemFont(ofSize: 15)
            value.textAlignment = .right
            let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
            arrow.tintColor = .tertiaryLabel
            arrow.contentMode = .scaleAspectFit
            let toggle = UISwitch()
            toggle.isUserInteractionEnabled = false
            if row.2 == "premium" || row.2 == "check" {
                toggle.isHidden = false
                toggle.isOn = row.2 == "premium" ? self.settings.premiumDemo : self.settings.checkDemo
                arrow.isHidden = true
                value.isHidden = true
            } else {
                toggle.isHidden = true
            }
            let button = UIButton(type: .system)
            button.accessibilityIdentifier = row.2
            button.addTarget(self, action: #selector(self.selectedRow(_:)), for: .touchUpInside)
            let childViews: [UIView] = [title, value, arrow, toggle, button]
            for child in childViews {
                child.translatesAutoresizingMaskIntoConstraints = false
                rowView.addSubview(child)
            }
            NSLayoutConstraint.activate([
                rowView.heightAnchor.constraint(equalToConstant: 58),
                title.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 16),
                title.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                title.trailingAnchor.constraint(lessThanOrEqualTo: value.leadingAnchor, constant: -8),
                title.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -8),
                value.leadingAnchor.constraint(greaterThanOrEqualTo: title.trailingAnchor, constant: 8),
                value.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                arrow.leadingAnchor.constraint(equalTo: value.trailingAnchor, constant: 8),
                arrow.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -14),
                arrow.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                arrow.widthAnchor.constraint(equalToConstant: 8),
                arrow.heightAnchor.constraint(equalToConstant: 14),
                toggle.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -14),
                toggle.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                button.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
                button.topAnchor.constraint(equalTo: rowView.topAnchor),
                button.bottomAnchor.constraint(equalTo: rowView.bottomAnchor)
            ])
            card.addArrangedSubview(rowView)
            if index < rows.count - 1 {
                let divider = UIView()
                divider.backgroundColor = .separator
                divider.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
                card.addArrangedSubview(divider)
            }
        }
        self.stack.addArrangedSubview(card)
    }

    private func addAvatarPreview() {
        let container = UIView()
        let image = self.settings.avatarData.flatMap { UIImage(data: $0) }
        let imageView = UIImageView(image: image)
        imageView.backgroundColor = UIColor(white: 0.18, alpha: 1.0)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 32
        let label = UILabel()
        label.text = "Локальный аватар · Dog Gram Visual"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        for view in [imageView, label] {
            view.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(view)
        }
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 72),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 64),
            imageView.heightAnchor.constraint(equalToConstant: 64),
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 14),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        self.stack.addArrangedSubview(container)
    }

    private func addAppearancePreview() {
        let preview = UIView()
        let baseColor = self.settings.profileColor == "Фиолетовый" ? UIColor(red: 0.28, green: 0.20, blue: 0.42, alpha: 1.0) : UIColor(red: 0.12, green: 0.31, blue: 0.48, alpha: 1.0)
        preview.backgroundColor = self.settings.profileTheme == "Светлая" ? baseColor.withAlphaComponent(0.72) : baseColor
        preview.layer.cornerRadius = 14
        let label = UILabel()
        label.text = "Мой профиль\n\(self.settings.profileBackground)\nDog Gram Visual · DEMO"
        label.textColor = self.settings.profileTheme == "Светлая" ? UIColor(white: 0.98, alpha: 1.0) : .white
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        preview.addSubview(label)
        NSLayoutConstraint.activate([
            preview.heightAnchor.constraint(equalToConstant: 112),
            label.leadingAnchor.constraint(equalTo: preview.leadingAnchor, constant: 18),
            label.trailingAnchor.constraint(equalTo: preview.trailingAnchor, constant: -18),
            label.centerYAnchor.constraint(equalTo: preview.centerYAnchor)
        ])
        self.stack.addArrangedSubview(preview)
    }

    func setAvatar(_ data: Data) {
        self.settings.avatarData = data
        self.saveSettings()
        self.render()
    }

    @objc private func selectedRow(_ sender: UIButton) {
        if let action = sender.accessibilityIdentifier {
            self.onAction?(action)
        }
    }
}

public final class DogGramControlController: TelegramBaseController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var panelView: DogGramControlView?

    private let accountId: Int64

    public init(context: AccountContext) {
        self.accountId = context.account.peerId.toInt64()
        super.init(context: context, navigationBarPresentationData: nil)
        self.title = "DuckGram"
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadDisplayNode() {
        let panel = DogGramControlView(accountId: self.accountId)
        panel.onAction = { [weak panel] action in
            panel?.perform(action)
        }
        panel.onPageChanged = { [weak self] title in
            self?.title = title
        }
        panel.onInputRequested = { [weak self] title, value, completed in
            guard let self else {
                return
            }
            let alert = UIAlertController(title: title, message: "Изменение локального оформления", preferredStyle: .alert)
            alert.addTextField { field in
                field.text = value
            }
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { _ in
                completed(alert.textFields?.first?.text ?? value)
            })
            self.present(alert, animated: true)
        }
        panel.onDualInputRequested = { [weak self] title, first, second, completed in
            guard let self else {
                return
            }
            let alert = UIAlertController(title: title, message: "Изменение локального оформления", preferredStyle: .alert)
            alert.addTextField { field in
                field.placeholder = first.0
                field.text = first.1
            }
            alert.addTextField { field in
                field.placeholder = second.0
                field.text = second.1
            }
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { _ in
                let firstValue = alert.textFields?.first?.text ?? first.1
                let secondValue = alert.textFields?.last?.text ?? second.1
                completed(firstValue, secondValue)
            })
            self.present(alert, animated: true)
        }
        panel.onOptionsRequested = { [weak self] title, options, completed in
            guard let self else {
                return
            }
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
            for option in options {
                alert.addAction(UIAlertAction(title: option.title, style: option.destructive ? .destructive : .default) { _ in
                    completed(option.title)
                })
            }
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            if let popover = alert.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            self.present(alert, animated: true)
        }
        panel.onNotice = { [weak self] message in
            let alert = UIAlertController(title: "Dog Gram Visual · Demo", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
        panel.onImageRequested = { [weak self] in
            guard let self, UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
                return
            }
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true)
        }
        panel.onConfirmationRequested = { [weak self] title, message, completed in
            guard let self else {
                return
            }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { _ in
                completed(false)
            })
            alert.addAction(UIAlertAction(title: "Добавить локально", style: .default) { _ in
                completed(true)
            })
            self.present(alert, animated: true)
        }
        self.panelView = panel
        self.title = panel.pageTitle
        self.displayNode = ASDisplayNode(viewBlock: { panel })
        self.displayNodeDidLoad()
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            let canvas = CGSize(width: 512, height: 512)
            let scale = max(canvas.width / image.size.width, canvas.height / image.size.height)
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(x: (canvas.width - size.width) / 2.0, y: (canvas.height - size.height) / 2.0)
            let renderer = UIGraphicsImageRenderer(size: canvas)
            let thumbnail = renderer.image { _ in
                image.draw(in: CGRect(origin: origin, size: size))
            }
            if let data = thumbnail.jpegData(compressionQuality: 0.72) {
                self.panelView?.setAvatar(data)
            }
        }
        self.dismiss(animated: true)
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }
}
