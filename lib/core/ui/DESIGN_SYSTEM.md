# Дизайн-система Akimat Project

## 🎨 Новые компоненты для красивого дизайна

### Декоративные элементы

#### EnhancedCard - Улучшенная карточка
```dart
EnhancedCard(
  showPattern: true,  // Показать декоративный паттерн
  showGlow: true,     // Показать эффект свечения
  child: YourContent(),
)
```

#### GradientCard - Карточка с градиентом
```dart
GradientCard(
  gradient: AppColors.primaryGradient,
  child: YourContent(),
)
```

#### ThemedCard - Карточка с тематической иконкой
```dart
ThemedCard(
  title: 'Полигоны',
  decorativeIcon: DecorativeIconType.polygon,
  child: YourContent(),
)
```

#### EnhancedBackground - Фон с декоративными элементами
```dart
EnhancedBackground(
  showDecorativeCircles: true,
  showPattern: true,
  child: YourContent(),
)
```

#### EmptyState - Пустое состояние
```dart
EmptyState(
  title: 'Нет данных',
  subtitle: 'Добавьте первый элемент',
  decorativeIcon: DecorativeIconType.truck,
  action: ElevatedButton(...),
)
```

### Декоративные иконки

- `DecorativeIconType.truck` - Мусоровоз
- `DecorativeIconType.polygon` - Полигон
- `DecorativeIconType.map` - Карта

### Использование в существующих компонентах

Замените обычные карточки на EnhancedCard для более красивого вида:

```dart
// Было:
Container(
  decoration: BoxDecoration(...),
  child: ...
)

// Стало:
EnhancedCard(
  showPattern: true,
  child: ...
)
```

### Примеры интеграции

1. **В списках карточек:**
```dart
ListView.builder(
  itemBuilder: (context, index) => EnhancedCard(
    showPattern: index % 2 == 0,
    child: ListTile(...),
  ),
)
```

2. **В пустых состояниях:**
```dart
if (items.isEmpty)
  EmptyState(
    title: 'Нет полигонов',
    decorativeIcon: DecorativeIconType.polygon,
  )
```

3. **В фонах страниц:**
```dart
EnhancedBackground(
  showDecorativeCircles: true,
  child: YourPageContent(),
)
```

