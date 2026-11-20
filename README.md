# swift-playgrounds-test

Minimalny pakiet Swift do sprawdzenia przepływu Swift Playgrounds + GitHub + Codex.

## Struktura

```text
swift-playgrounds-test/
├── Package.swift
├── PlaygroundApp.swift
└── Sources/
    └── WelcomeKit/
        └── WelcomeView.swift
```

`WelcomeKit` eksportuje publiczny widok `WelcomeView`. `PlaygroundApp.swift` pokazuje minimalną aplikację, która importuje pakiet.

Projekt nie ma zewnętrznych zależności, usług sieciowych, analityki ani telemetrii.

## Dodanie pakietu w Swift Playgrounds na iPadzie

1. Utwórz lub otwórz aplikację w Swift Playgrounds.
2. Otwórz ustawienia aplikacji/projektu i wybierz dodawanie zależności pakietu (zwykle `Add Package Dependency` / `Add Package Collection`, zależnie od wersji Swift Playgrounds).
3. Wklej URL repozytorium GitHub: `https://github.com/KneshD/swift-playgrounds-test`.
4. Wybierz produkt `WelcomeKit` i dodaj go do aplikacji.
5. W kodzie aplikacji dodaj `import WelcomeKit`, a następnie użyj `WelcomeView()` jako widoku w `WindowGroup`.

Swift Playgrounds pobiera pakiet z adresu repozytorium GitHub, jeśli wersja aplikacji obsługuje dodawanie pakietów z GitHub. Nie jest to synchronizacja całego projektu: pliki aplikacji i pakietu pozostają osobnymi elementami.

## Aktualizowanie po zmianach Codexa

Po wypchnięciu zmian do repozytorium:

1. Nadaj zmianie nowy tag wersji, np. `1.0.1`, jeśli zależność jest przypięta do wersji.
2. W Swift Playgrounds otwórz zarządzanie zależnościami i wybierz aktualizację pakietu/zależności.
3. Jeśli projekt używa zakresu wersji, wybierz `Update Package` lub usuń i dodaj zależność ponownie, gdy aktualizacja nie pojawi się automatycznie.

Nie zakładamy automatycznej synchronizacji po każdym pushu. Zmiana na GitHubie nie zmienia lokalnego projektu na iPadzie bez odświeżenia/aktualizacji zależności.

## Prywatne repozytorium

Projekt jest dostępny w prywatnym repozytorium:

`https://github.com/KneshD/swift-playgrounds-test`

Prywatny pakiet może wymagać uwierzytelnienia obsługiwanego przez konkretną wersję Swift Playgrounds, GitHub i konto Apple. Przed przyjęciem prywatnego repozytorium jako docelowego należy wykonać próbę pobrania na iPadzie. Nie zmieniaj repozytorium na publiczne tylko po to, by ominąć problem z uwierzytelnieniem.

## Publikacja na innym GitHubie

Jeśli chcesz utworzyć kopię w innym koncie, użyj:

```sh
git init
git add Package.swift Sources PlaygroundApp.swift README.md
git commit -m "Add Swift Playgrounds integration test"
git branch -M main
git remote add origin https://github.com/<konto>/swift-playgrounds-test.git
git push -u origin main
```

Na GitHubie wybierz widoczność `Private`.

## Weryfikacja

- Manifest zawiera nazwę pakietu, produkt biblioteczny i target `WelcomeKit`.
- `WelcomeView` i jego inicjalizator są publiczne.
- Widok używa wyłącznie SwiftUI i lokalnego stanu `@State`.
- W środowisku roboczym nie ma polecenia `swift`, więc nie wykonano kompilacji SPM.
- Na iPadzie trzeba sprawdzić kompilację, dodanie zależności, działanie przycisku oraz aktualizację po pushu.

Apple przewiduje dodawanie zależności Swift Package w Swift Playgrounds, ale dostępność nazw poleceń i obsługa prywatnych repozytoriów mogą zależeć od wersji aplikacji. Przed wdrożeniem sprawdź aktualny przewodnik Apple „Add a Swift package to your app” dla Swift Playgrounds oraz wersję iPadOS/Swift Playgrounds używaną na urządzeniu.


## Wersja 1.2.0

Pakiet zawiera lokalne nagrywanie i polską transkrypcję przez Apple Speech. Aplikacja wymaga zgody na mikrofon i rozpoznawanie mowy. W Swift Playgrounds zaakceptuj oba komunikaty systemowe przy pierwszym użyciu przycisku „Nagraj po polsku”.

Transkrypcja wymusza tryb lokalny i używa locale `pl-PL`. iPad musi mieć dostępny i pobrany polski model mowy. Dźwięk nie jest zapisywany ani wysyłany do usługi sieciowej. Po zatrzymaniu nagrania wybierz „Wstaw transkrypcję”, a następnie zapisz tekst jako notatkę lub zadanie.
