# AppPortfolioKit

Небольшой SwiftUI SDK для ненавязчивого кросс‑промо ваших приложений. Он получает названия, иконки и ссылки напрямую из публичного Apple Lookup API и показывает их в адаптивной сетке.

## Подключение

Добавьте репозиторий через **File → Add Package Dependencies** в Xcode и подключите продукт `AppPortfolioKit` к нужному target.

Если пакет пока находится рядом с приложением, выберите **Add Local…** и укажите папку `AppPortfolioKit`.

## Использование

```swift
import AppPortfolioKit
import SwiftUI

struct MoreAppsView: View {
    var body: some View {
        AppPortfolioView(
            appIDs: [123456789, 987654321],
            configuration: AppPortfolioConfiguration(
                title: "Другие наши приложения",
                columns: 3
            )
        )
        .padding()
    }
}
```

### Список приложений без обновления приложения

Разместите JSON-файл в публичном репозитории или на своём сервере:

```json
{
  "appIDs": [6799032467, 6753864943]
}
```

И передайте его URL. При каждом создании экрана SDK запрашивает свежий файл без использования HTTP-кэша. Если сеть или GitHub временно недоступны, используется резервный список:

```swift
AppPortfolioView(
    manifestURL: URL(string: "https://raw.githubusercontent.com/OWNER/REPOSITORY/main/app-portfolio.json")!,
    fallbackAppIDs: [6799032467, 6753864943],
    configuration: AppPortfolioConfiguration(
        allowedDeveloperID: 1780729890
    )
)
```

`allowedDeveloperID` — рекомендуемая защита публичного манифеста. После загрузки SDK сверяет `artistId` каждого приложения с данными Apple и не показывает приложения другого издателя, даже если чужой ID окажется в JSON.

Передавайте числовую часть ссылки App Store: для `https://apps.apple.com/app/id123456789` это `123456789`. По умолчанию SDK не показывает приложение, внутри которого запущен, если его bundle identifier совпадает с данными App Store.

## Поведение

- Нажатие на карточку открывает соответствующую страницу App Store.
- Порядок приложений совпадает с порядком переданных ID.
- Повторяющиеся и некорректные ID отбрасываются.
- Если сеть недоступна, показывается кнопка повторной загрузки.
- SDK не использует аналитику, рекламные идентификаторы и сторонние зависимости.
