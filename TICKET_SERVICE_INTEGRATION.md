# Интеграция с Snowops Ticket Service

## Проблема

При создании тикета возникала ошибка 404, так как запросы отправлялись в Operations Service (`https://snowops-operations-service.onrender.com/tickets`), но тикеты должны обрабатываться через отдельный **Ticket Service**.

## Решение

Создан отдельный модуль Ticket Service с правильными endpoints согласно документации:

### Структура

```
lib/services/tickets/
├── module.dart              # Провайдеры Dio и сервисов
├── services.dart            # Обертка для сервисов
└── collection/
    └── tickets_collection.dart  # API методы для работы с тикетами
```

### Endpoints по ролям

#### KGU ZKH Admin
- **POST** `/kgu/tickets` - Создать тикет
- **GET** `/kgu/tickets` - Получить тикеты KGU
- **GET** `/kgu/tickets/:id` - Получить тикет
- **PUT** `/kgu/tickets/:id/cancel` - Отменить тикет
- **PUT** `/kgu/tickets/:id/close` - Закрыть тикет

#### Contractor Admin
- **GET** `/contractor/tickets` - Получить тикеты подрядчика
- **GET** `/contractor/tickets/:id` - Получить тикет
- **PUT** `/contractor/tickets/:id/complete` - Завершить тикет
- **POST** `/contractor/tickets/:id/assignments` - Создать назначение
- **GET** `/contractor/tickets/:id/assignments` - Получить назначения
- **DELETE** `/contractor/assignments/:id` - Удалить назначение

#### Akimat Admin
- **GET** `/akimat/tickets` - Получить все тикеты (read-only)
- **GET** `/akimat/tickets/:id` - Получить тикет (read-only)

### Изменения в коде

1. **OperationsRepositoryImpl** теперь использует Ticket Service для операций с тикетами:
   - `loadTickets()` - использует правильный endpoint в зависимости от роли
   - `createTicket()` - использует `/kgu/tickets` для KGU ZKH Admin

2. **TicketsController** передает TicketsServices и UserRole в OperationsRepositoryImpl

3. **Fallback механизм**: Если Ticket Service недоступен, используется Operations Service (для обратной совместимости)

### Базовый URL

**ВАЖНО:** Нужно обновить базовый URL в `lib/services/tickets/module.dart`:

```dart
baseUrl: 'https://snowops-ticket-service.onrender.com', // TODO: заменить на реальный URL
```

### Тестирование

После обновления URL:
1. KGU ZKH Admin должен создавать тикеты через `/kgu/tickets`
2. Contractor Admin должен видеть только свои тикеты через `/contractor/tickets`
3. Akimat Admin должен видеть все тикеты через `/akimat/tickets`

### Примечания

- Все endpoints требуют JWT авторизации
- Ответы оборачиваются в `{"data": ...}`
- Ошибки возвращаются в формате `{"error": "..."}`


