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

    static let key = "DogGram.VisualSettings.v1"

    static func load() -> DogGramVisualSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let value = try? JSONDecoder().decode(DogGramVisualSettings.self, from: data) else {
            return DogGramVisualSettings()
        }
        return value
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else {
            return
        }
        UserDefaults.standard.set(data, forKey: Self.key)
        NotificationCenter.default.post(name: Notification.Name("DogGramVisualSettingsDidChange"), object: nil)
    }
}

private final class DogGramControlView: UIView {
    var onAction: ((String) -> Void)?
    var onInputRequested: ((String, String, @escaping (String) -> Void) -> Void)?
    var onNotice: ((String) -> Void)?
    var onImageRequested: (() -> Void)?
    var onConfirmationRequested: ((String, String, @escaping (Bool) -> Void) -> Void)?
    var onPageChanged: ((String) -> Void)?
    private var settings = DogGramVisualSettings.load()
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
        default: return "DogGram"
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(red: 0.09, green: 0.13, blue: 0.17, alpha: 1.0)
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
        case "profile": self.page = "profile"
        case "balances": self.page = "balances"
        case "gifts": self.page = "gifts"
        case "nft": self.page = "nft"
        case "style": self.page = "style"
        case "operations": self.page = "operations"
        case "back": self.page = "control"
        case "premium": self.settings.premiumDemo.toggle()
        case "check": self.settings.checkDemo.toggle()
        case "avatar": self.onImageRequested?()
        case "verification":
            self.settings.verification = self.settings.verification == "Major · Demo" ? "Hold · Demo" : (self.settings.verification == "Hold · Demo" ? "Выключена" : "Major · Demo")
        case "level": self.settings.level = self.settings.level == "Обычный" ? "Пользовательский · Demo" : "Обычный"
        case "number":
            self.onInputRequested?("Номер профиля · Demo", self.settings.displayNumber) { [weak self] value in
                self?.settings.displayNumber = value
                self?.settings.save()
                self?.render()
            }
        case "stars":
            self.onInputRequested?("Демо-баланс звёзд", self.settings.stars) { [weak self] value in
                self?.settings.stars = value
                self?.settings.save()
                self?.render()
            }
        case "gram":
            self.onInputRequested?("Демо-баланс GRAM", self.settings.gram) { [weak self] value in
                self?.settings.gram = value
                self?.settings.save()
                self?.render()
            }
        case "addStarsOperation":
            self.onInputRequested?("Описание операции · Demo", "+1 звезда") { [weak self] value in
                self?.settings.demoOperations.append("Звёзды · \(value)")
                self?.settings.save()
                self?.render()
            }
        case "addGramOperation":
            self.onInputRequested?("Описание операции · Demo", "+1 GRAM") { [weak self] value in
                self?.settings.demoOperations.append("GRAM · \(value)")
                self?.settings.save()
                self?.render()
            }
        case "gramCard": self.onNotice?("Демо-карточка GRAM. Средства не списываются, карта не выпускается.")
        case "addUsername":
            self.onInputRequested?("Название NFT-юзернейма", "@doggram") { [weak self] name in
                guard let self, !name.isEmpty else {
                    return
                }
                self.onInputRequested?("Демо-цена", "25") { [weak self] price in
                    guard let self else {
                        return
                    }
                    self.onInputRequested?("Валюта", "TON") { [weak self] currency in
                        guard let self else {
                            return
                        }
                        self.settings.usernames.append(DogGramNFTUsername(name: name, price: price, currency: currency))
                        self.settings.save()
                        self.render()
                    }
                }
            }
        case "workingHours":
            self.onInputRequested?("Часы работы · Demo", self.settings.workingHours) { [weak self] value in
                self?.settings.workingHours = value
                self?.settings.save()
                self?.render()
            }
        case "address":
            self.onInputRequested?("Адрес профиля · Demo", self.settings.address) { [weak self] value in
                self?.settings.address = value
                self?.settings.save()
                self?.render()
            }
        case "color":
            self.settings.profileColor = self.settings.profileColor == "Синий" ? "Фиолетовый" : "Синий"
        case "background":
            self.onInputRequested?("Фоновое изображение · Demo", self.settings.profileBackground) { [weak self] value in
                self?.settings.profileBackground = value
                self?.settings.save()
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
                            self.settings.save()
                            self.render()
                        }
                    }
                }
            }
        case "addGift":
            self.onConfirmationRequested?("Подарок · Demo", "Демонстрационный элемент. Покупка не совершается.") { [weak self] confirmed in
                guard let self, confirmed else {
                    return
                }
                self.settings.gifts.append("Обычный подарок · Demo")
                self.settings.save()
                self.render()
            }
        case "addNFTGift":
            self.onInputRequested?("Ссылка на NFT · Demo", "https://") { [weak self] link in
                self?.onConfirmationRequested?("Предпросмотр NFT · Demo", "\(link)\n\nДобавить только в локальную коллекцию Dog Gram?") { [weak self] confirmed in
                    guard let self, confirmed else {
                        return
                    }
                    self.settings.gifts.append("NFT · \(link)")
                    self.settings.save()
                    self.render()
                }
            }
        case "sendGift": self.onNotice?("Демонстрационный сценарий. Ничего не отправлено и не куплено.")
        case "reset": self.settings = DogGramVisualSettings()
        default: break
        }
        self.settings.save()
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
            self.addAvatarPreview()
            self.section([("Выбор профиля", "Мой профиль", "back"), ("Назад", "", "back")])
            self.section([("Локальный аватар", self.settings.avatarData == nil ? "Выбрать" : "Установлен · Demo", "avatar")])
            self.section([("Premium в DogGram · Demo", "", "premium"), ("Значок в DogGram · Demo", "", "check"), ("Верификация · Demo", self.settings.verification, "verification")])
            self.section([("Добавить NFT-юзернейм", "", "nft"), ("Номер профиля · Demo", self.settings.displayNumber, "number"), ("Уровень · Demo", self.settings.level, "level"), ("Юзернеймы", "\(self.settings.usernames.count)", "nft")])
            self.section([("Подарки DogGram · Demo", "\(self.settings.gifts.count)", "gifts"), ("Балансы DogGram · Demo", "Звёзды · GRAM", "balances")])
            self.section([("Цвета и фон профиля", "", "style"), ("Часы работы", self.settings.workingHours, "workingHours"), ("Адрес", self.settings.address, "address")])
        case "balances":
            self.section([("Выбор профиля", "Мой профиль", "back"), ("Назад", "", "back")])
            self.section([("Баланс звёзд · Demo", self.settings.stars, "stars"), ("Добавить операцию · Demo", "", "addStarsOperation"), ("Мои операции звёзд · Demo", "", "operations")])
            self.section([("Баланс GRAM · Demo", self.settings.gram, "gram"), ("Оформить карточку GRAM · Demo", "", "gramCard"), ("Мои операции GRAM · Demo", "", "operations")])
            self.section(self.settings.demoAssets.map { ($0.name, "\($0.quantity) · \($0.displayedValue) \($0.currency)", "balances") } + [("Добавить демо-актив", "", "addAsset")])
        case "operations":
            self.section([("Назад", "", "back")])
            self.section(self.settings.demoOperations.map { ($0, "Demo", "operations") })
        case "gifts":
            self.section([("Назад", "", "back"), ("Добавить NFT в профиль", "Demo", "addNFTGift"), ("Добавить подарок", "Demo", "addGift"), ("Демо-сценарий отправки", "Demo", "sendGift")])
            self.section(self.settings.gifts.map { ($0, "Demo", "sendGift") })
        case "nft":
            self.section([("Назад", "", "back"), ("Добавить юзернейм", "Demo", "addUsername")])
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
            self.section([("Выбор профиля", "Мой профиль", "profile")])
            self.section([("Профиль", "", "profile"), ("Подарки", "", "gifts"), ("Балансы", "", "balances")])
            self.section([("NFT-юзернеймы", "", "nft"), ("Оформление профиля", "", "style")])
            self.section([("Очистить всё оформление", "", "reset")], destructive: true)
        }
        let note = UILabel()
        note.text = "Dog Gram Visual · DEMO\nИзменения сохраняются только на этом устройстве."
        note.textColor = UIColor(white: 0.58, alpha: 1.0)
        note.numberOfLines = 0
        note.font = .systemFont(ofSize: 12)
        note.textAlignment = .center
        self.stack.addArrangedSubview(note)
    }

    private func section(_ rows: [(String, String, String)], destructive: Bool = false) {
        let card = UIStackView()
        card.axis = .vertical
        card.backgroundColor = UIColor(red: 0.13, green: 0.19, blue: 0.24, alpha: 1.0)
        card.layer.cornerRadius = 10
        card.clipsToBounds = true
        for (index, row) in rows.enumerated() {
            let rowView = UIView()
            let title = UILabel()
            title.text = row.0
            title.textColor = destructive ? .systemRed : .white
            title.font = .systemFont(ofSize: 17, weight: .regular)
            title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let value = UILabel()
            value.text = row.1
            value.textColor = UIColor(red: 0.55, green: 0.72, blue: 0.82, alpha: 1.0)
            value.font = .systemFont(ofSize: 15)
            value.textAlignment = .right
            let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
            arrow.tintColor = UIColor(red: 0.43, green: 0.55, blue: 0.62, alpha: 1.0)
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
                divider.backgroundColor = UIColor(red: 0.18, green: 0.25, blue: 0.30, alpha: 1.0)
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
        preview.backgroundColor = self.settings.profileColor == "Фиолетовый" ? UIColor(red: 0.28, green: 0.20, blue: 0.42, alpha: 1.0) : UIColor(red: 0.12, green: 0.31, blue: 0.48, alpha: 1.0)
        preview.layer.cornerRadius = 14
        let label = UILabel()
        label.text = "Мой профиль\nDog Gram Visual · DEMO"
        label.textColor = .white
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
        self.settings.save()
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

    public init(context: AccountContext) {
        super.init(context: context, navigationBarPresentationData: nil)
        self.title = "DogGram"
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadDisplayNode() {
        let panel = DogGramControlView()
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
            let alert = UIAlertController(title: title, message: "Локальные данные Dog Gram Visual", preferredStyle: .alert)
            alert.addTextField { field in
                field.text = value
            }
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { _ in
                completed(alert.textFields?.first?.text ?? value)
            })
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
