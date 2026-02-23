# Руководство по современному стилю UI

## Обзор
Этот проект использует современную систему дизайна с премиум типографикой, гармоничной цветовой палитрой и элегантными визуальными эффектами.

## Типографика

### Основные стили текста

```dart
// Для заголовков
AppTextStyles.hero      // 64px, для hero-секций
AppTextStyles.display   // 52px, для больших заголовков
AppTextStyles.largeTitle // 40px, для главных заголовков
AppTextStyles.title1    // 32px, для секций
AppTextStyles.title2     // 26px, для подзаголовков
AppTextStyles.title3     // 22px, для карточек

// Для основного контента
AppTextStyles.bodyLarge  // 18px, важный текст
AppTextStyles.body       // 16px, основной текст
AppTextStyles.callout    // 17px, выделенный текст
AppTextStyles.subheadline // 15px, вторичный текст

// Для метаданных
AppTextStyles.footnote   // 13px, вспомогательный текст
AppTextStyles.caption    // 12px, подписи
AppTextStyles.overline   // 11px, очень маленькие метки
```

### Современные текстовые виджеты

```dart
// Градиентный текст
ModernGradientText(
  text: 'Заголовок',
  gradient: AppColors.primaryGradient,
  style: AppTextStyles.title2,
)

// Текст с тенью
TextWithShadow(
  text: 'Текст',
  style: AppTextStyles.title2,
)

// Заголовок с подчеркиванием
ElegantHeading(
  text: 'Заголовок',
  underlineColor: AppColors.primary,
)

// Текст с иконкой
TextWithIcon(
  text: 'Текст',
  icon: Icons.star,
)
```

## Цветовая палитра

### Основные цвета

```dart
// Primary (синий)
AppColors.primary          // #1E40AF
AppColors.primaryLight     // #3B82F6
AppColors.primaryLighter   // #60A5FA

// Secondary (фиолетовый)
AppColors.secondary        // #6D28D9
AppColors.secondaryLight   // #8B5CF6

// Accent (голубой)
AppColors.accent           // #06B6D4
```

### Градиенты

```dart
AppColors.primaryGradient      // Трехцветный градиент primary
AppColors.secondaryGradient    // Трехцветный градиент secondary
AppColors.premiumGradient      // Премиум градиент
AppColors.backgroundGradient   // Фоновый градиент
```

## Компоненты UI

### Карточки

```dart
// Базовая карточка
EnhancedCard(
  child: YourContent(),
  showGlow: true,
  showPattern: true,
)

// Градиентная карточка
GradientCard(
  child: YourContent(),
  gradient: AppColors.primaryGradient,
)

// Тематическая карточка
ThemedCard(
  title: 'Заголовок',
  icon: Icons.star,
  child: YourContent(),
)
```

### Кнопки

```dart
// Современная кнопка
ModernButton(
  text: 'Нажмите',
  onPressed: () {},
  gradient: AppColors.primaryGradient,
  icon: Icons.add,
)
```

### Поля ввода

```dart
ModernInputField(
  label: 'Название',
  hint: 'Введите текст',
  prefixIcon: Icons.search,
  controller: textController,
)
```

### Статистика

```dart
// Статистический блок
StatBlock(
  value: '1,234',
  label: 'Всего',
  icon: Icons.trending_up,
)

// Статистическая карточка
StatCard(
  title: 'Заголовок',
  value: '1,234',
  subtitle: 'Подзаголовок',
  icon: Icons.star,
)
```

### Списки

```dart
// Современный элемент списка
ModernListItem(
  leading: Icon(Icons.star),
  title: Text('Заголовок'),
  subtitle: Text('Подзаголовок'),
  trailing: Icon(Icons.arrow_forward),
)
```

### Чипы/Теги

```dart
ModernChip(
  label: 'Тег',
  icon: Icons.label,
  selected: true,
)
```

## Визуальные эффекты

### Тени

```dart
// Мягкое свечение
PremiumEffects.softGlowShadow(
  color: AppColors.primary,
  blur: AppSize.shadowBlurMedium,
)

// Многослойная тень
PremiumEffects.layeredShadow(
  elevation: 2,
)
```

### Премиум контейнер

```dart
PremiumContainer(
  child: YourContent(),
  showGlow: true,
  gradient: AppColors.primaryGradient,
  elevation: 2,
)
```

## Размеры и отступы

### Радиусы скругления

```dart
AppSize.cardRadius      // 20px - для карточек
AppSize.buttonRadius    // 14px - для кнопок
AppSize.smallRadius     // 10px - для маленьких элементов
AppSize.mediumRadius    // 16px - для средних элементов
AppSize.largeRadius     // 24px - для больших элементов
AppSize.pillRadius      // 9999 - для pill-форм
```

### Отступы

```dart
AppPadding.xs      // 4px
AppPadding.small   // 10px
AppPadding.normal   // 18px
AppPadding.medium   // 24px
AppPadding.large    // 32px
AppPadding.xl       // 40px
AppPadding.xxl      // 48px
AppPadding.xxxl     // 64px
```

## Лучшие практики

1. **Используйте градиенты умеренно** - только для важных элементов
2. **Применяйте тени с умом** - для создания глубины, не перегружайте
3. **Соблюдайте иерархию** - используйте правильные размеры шрифтов
4. **Гармония цветов** - придерживайтесь цветовой палитры
5. **Просторная компоновка** - используйте достаточные отступы
6. **Консистентность** - используйте компоненты из системы дизайна

## Примеры использования

### Hero-секция

```dart
Container(
  padding: EdgeInsets.all(AppPadding.xxxl),
  decoration: BoxDecoration(
    gradient: AppColors.backgroundGradient,
  ),
  child: Column(
    children: [
      ModernGradientText(
        text: 'Добро пожаловать',
        gradient: AppColors.primaryGradient,
        style: AppTextStyles.hero,
      ),
      SizedBox(height: AppPadding.large),
      Text(
        'Описание',
        style: AppTextStyles.bodyLarge,
      ),
    ],
  ),
)
```

### Карточка с данными

```dart
EnhancedCard(
  showGlow: true,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Заголовок', style: AppTextStyles.title2),
      SizedBox(height: AppPadding.normal),
      Text('Контент', style: AppTextStyles.body),
    ],
  ),
)
```

### Статистическая панель

```dart
Row(
  children: [
    Expanded(
      child: StatCard(
        title: 'Всего',
        value: '1,234',
        icon: Icons.trending_up,
      ),
    ),
    SizedBox(width: AppPadding.normal),
    Expanded(
      child: StatCard(
        title: 'Активных',
        value: '567',
        icon: Icons.check_circle,
        gradient: AppColors.successGradient,
      ),
    ),
  ],
)
```


