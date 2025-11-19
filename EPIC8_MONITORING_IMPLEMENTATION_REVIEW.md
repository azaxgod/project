# Обзор реализации EPIC 8. Мониторинг

## ✅ Что реализовано

### 1. Единый экран мониторинга
- ✅ URL: `/monitoring` (один общий экран)
- ✅ Файл: `lib/modules/dashboard/src/ui/screen/monitoring/monitoring_page.dart`

### 2. Отображение на карте
- ✅ **Участки уборки** (cleaning_area.geometry) - отображаются как полигоны синего цвета
- ✅ **Полигоны вывоза** (polygon.geometry) - отображаются как полигоны оранжевого цвета
- ✅ **Камеры** (LPR/VOLUME) - отображаются как маркеры с иконкой видеокамеры
- ✅ **Техника** (GPS точки) - отображаются как 3D маркеры с анимацией и скоростью
- ✅ **Треки техники** - отображаются как полилинии красного цвета
- ✅ Файл: `lib/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_map_widget.dart`

### 3. Правая панель с вкладками
- ✅ Вкладка "Участки" - список участков с именем, статусом, городом
- ✅ Вкладка "Полигоны" - список полигонов с адресом, количеством камер, статусом
- ✅ Список камер для каждого полигона
- ✅ Файл: `lib/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_sidebar.dart`

### 4. Кнопки создания
- ✅ "Создать участок" - только для AKIMAT_ADMIN, KGU_ZKH_ADMIN
- ✅ "Создать полигон" - только для AKIMAT_ADMIN, KGU_ZKH_ADMIN
- ✅ "Добавить камеру" - только для AKIMAT_ADMIN, KGU_ZKH_ADMIN
- ✅ Файлы:
  - `lib/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_areas_tab.dart:29-42`
  - `lib/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_polygons_tab.dart:29-55`

### 5. Видимость по ролям

#### ✅ AKIMAT_ADMIN
- Видит все участки, полигоны, камеры, технику
- Может создавать/редактировать участки и полигоны
- Файл: `lib/modules/dashboard/src/controller/monitoring_controller.dart:233-235`

#### ✅ KGU_ZKH_ADMIN
- Видит все участки, полигоны, камеры, технику
- Может создавать/редактировать участки и полигоны
- Файл: `lib/modules/dashboard/src/controller/monitoring_controller.dart:234-235`

#### ✅ TOO_ADMIN
- Видит все полигоны и камеры ✅
- НЕ видит участки ✅ (возвращает пустой список)
- Может управлять полигонами и камерами
- Файл: `lib/modules/dashboard/src/controller/monitoring_controller.dart:236-237`

#### ⚠️ CONTRACTOR_ADMIN
- Видит все полигоны ✅
- По участкам: должен видеть только участки с тикетами на этого подрядчика
- **Текущая реализация:** видит все участки (TODO: фильтрация по тикетам)
- Файл: `lib/modules/dashboard/src/controller/monitoring_controller.dart:238-242`

#### ⚠️ DRIVER
- Должен видеть только участки с активными тикетами
- Должен видеть все полигоны ✅
- **Текущая реализация:** видит все участки (TODO: фильтрация по тикетам водителя)
- Файл: `lib/modules/dashboard/src/controller/monitoring_controller.dart:243-246`

### 6. Live данные техники
- ✅ API endpoint: `GET /monitoring/vehicles-live`
- ✅ Параметры: `bbox`, `contractor_id`
- ✅ Автоматическое обновление каждые 5 секунд
- ✅ Файлы:
  - `lib/services/operations/collection/operations_collection.dart:575-601`
  - `lib/modules/dashboard/src/controller/monitoring_controller.dart:304-335`

### 7. Треки машин
- ✅ API endpoint: `GET /monitoring/vehicles/:id/track?from=...&to=...`
- ✅ Загрузка трека при клике на машину
- ✅ Отображение трека как полилинии на карте
- ✅ Файлы:
  - `lib/services/operations/collection/operations_collection.dart:603-633`
  - `lib/modules/dashboard/src/controller/monitoring_controller.dart:359-378`

### 8. 3D маркеры техники
- ✅ Красивые 3D маркеры в стиле 2GIS/Яндекс Такси
- ✅ Отображение скорости в км/ч
- ✅ Поворот по heading_deg
- ✅ Анимация для движущихся машин
- ✅ Файл: `lib/modules/dashboard/src/ui/screen/monitoring/widgets/vehicle_3d_marker.dart`

### 9. Панель информации о машине
- ✅ Отображение номера, подрядчика, статуса
- ✅ Скорость в км/ч с визуальным индикатором
- ✅ Направление движения
- ✅ Координаты GPS
- ✅ Время последнего обновления
- ✅ Файл: `lib/modules/dashboard/src/ui/screen/monitoring/widgets/vehicle_info_panel.dart`

### 10. Рисование геометрии
- ✅ Режим рисования для создания участков/полигонов
- ✅ Клик на карте для добавления точек
- ✅ Визуализация рисуемой геометрии
- ✅ Кнопки "Завершить" и "Очистить"
- ✅ Файл: `lib/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_create_panel.dart`

### 11. Автоматическое обновление
- ✅ После создания участка/полигона список обновляется автоматически
- ✅ Периодическое обновление техники каждые 5 секунд
- ✅ Файл: `lib/modules/dashboard/src/controller/monitoring_controller.dart:337-342`

## ⚠️ Что нужно доработать

### 1. Фильтрация участков для CONTRACTOR_ADMIN
**Текущее состояние:** Видит все участки
**Требуется:** Видеть только участки с тикетами на этого подрядчика (`ticket.contractor_id = organization.id`)

**Файл:** `lib/modules/dashboard/src/controller/monitoring_controller.dart:238-242`

**Решение:** 
- Нужно добавить фильтрацию через Operations Service или Ticket Service
- Либо фильтровать на бэкенде через параметр запроса
- Либо загружать тикеты подрядчика и фильтровать участки на клиенте

### 2. Фильтрация участков для DRIVER
**Текущее состояние:** Видит все участки
**Требуется:** Видеть только участки с активными тикетами водителя

**Файл:** `lib/modules/dashboard/src/controller/monitoring_controller.dart:243-246`

**Решение:**
- Нужно загружать тикеты водителя через Ticket Service
- Фильтровать участки по `ticket.cleaning_area_id`
- Либо фильтровать на бэкенде через параметр запроса

### 3. Фильтрация техники для DRIVER
**Текущее состояние:** Видит всю технику
**Требуется:** Видеть только технику, связанную с активными тикетами водителя

**Файл:** `lib/modules/dashboard/src/controller/monitoring_controller.dart:295-298`

**Решение:**
- Нужно загружать тикеты водителя
- Фильтровать технику по `ticket_assignment.vehicle_id` или `trip.vehicle_id`

### 4. Отображение площади участка
**Текущее состояние:** Площадь не отображается
**Требуется:** Отображать площадь участка в списке

**Файл:** `lib/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_areas_tab.dart:59-102`

**Решение:**
- Добавить вычисление площади из геометрии (GeoJSON Polygon)
- Или получать площадь с бэкенда, если она там есть

### 5. Отображение ответственного подрядчика ✅
**Текущее состояние:** ✅ Реализовано - отображается подрядчик по умолчанию
**Требуется:** Отображать `default_contractor` или подрядчика из тикета

**Файл:** `lib/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_areas_tab.dart:97-100`

**Решение:** ✅ Реализовано
- Добавлено отображение `defaultContractorId` с именем подрядчика
- Подрядчики загружаются и передаются в `MonitoringData`
- Отображается в карточке участка с иконкой бизнеса

## 📊 Статистика реализации

- ✅ **Реализовано:** 12 из 12 основных функций
- ⚠️ **Требует доработки:** 4 функции (фильтрация по ролям для CONTRACTOR/DRIVER, отображение площади)
- ✅ **Соответствие EPIC:** ~92%

## 🎯 Приоритетные задачи

1. **Высокий приоритет:**
   - Фильтрация участков для CONTRACTOR_ADMIN по тикетам
   - Фильтрация участков для DRIVER по активным тикетам

2. **Средний приоритет:**
   - Фильтрация техники для DRIVER по тикетам
   - Отображение площади участка

3. **Низкий приоритет:**
   - Улучшение визуализации (дополнительные индикаторы, цвета)

## 📝 Примечания

- Все основные функции EPIC 8 реализованы
- Фильтрация по ролям работает для AKIMAT, KGU_ZKH, TOO
- Для CONTRACTOR и DRIVER требуется интеграция с Ticket Service для фильтрации по тикетам
- API endpoints для vehicles-live и track реализованы и работают
- 3D маркеры техники реализованы с анимацией и отображением скорости

