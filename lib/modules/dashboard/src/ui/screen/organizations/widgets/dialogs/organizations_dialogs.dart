  import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/widgets/safe_dropdown_button.dart';
import 'package:akimat_project/core/utils/notification_helper.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrganizationsDialogs {
  const OrganizationsDialogs._();

  static Future<void> showOrganizationDialog({
    required BuildContext context,
    required OrganizationsController controller,
    required OrganizationType type,
    required OrganizationsData data,
    String? parentOrganizationId,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final binController = TextEditingController();
    final headController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedParentOrgId = parentOrganizationId;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: Text(
              type == OrganizationType.kguZkh
                  ? 'Добавить КГУ ЖКХ'
                  : type == OrganizationType.too
                      ? 'Добавить ТОО'
                      : 'Добавить подрядчика',
            ),
            content: SizedBox(
              width: min(MediaQuery.sizeOf(context).width * 0.8, 420),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OrganizationsTextField(
                        controller: nameController,
                        label: 'Наименование*',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Введите наименование' : null,
                      ),
                      OrganizationsTextField(
                        controller: binController,
                        label: 'БИН*',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите БИН';
                          }
                          // Валидация формата БИН: должен содержать только цифры и быть длиной 12 символов
                          final binDigits = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (binDigits.length != 12) {
                            return 'БИН должен содержать 12 цифр';
                          }
                          if (data.organizations.any((org) => org.bin == binDigits)) {
                            return 'Организация с таким БИН уже существует';
                          }
                          return null;
                        },
                      ),
                      OrganizationsTextField(
                        controller: phoneController,
                        label: 'Телефон*',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите номер телефона';
                          }
                          // Нормализация номера: удаляем все пробелы, дефисы и скобки
                          final normalized = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                          
                          // Валидация формата казахстанского номера
                          // Форматы: +7XXXXXXXXXX, 8XXXXXXXXXX, 7XXXXXXXXXX (10-11 цифр после кода страны)
                          final phonePattern = RegExp(r'^(\+?7|8)?[0-9]{10}$');
                          if (!phonePattern.hasMatch(normalized)) {
                            return 'Введите корректный номер телефона (формат: +7XXXXXXXXXX или 8XXXXXXXXXX)';
                          }
                          
                          // Нормализуем к формату +7XXXXXXXXXX для проверки дубликатов
                          String normalizedForCheck = normalized;
                          if (normalizedForCheck.startsWith('8')) {
                            normalizedForCheck = '+7${normalizedForCheck.substring(1)}';
                          } else if (normalizedForCheck.startsWith('7')) {
                            normalizedForCheck = '+7${normalizedForCheck.substring(1)}';
                          } else if (!normalizedForCheck.startsWith('+7')) {
                            normalizedForCheck = '+7$normalizedForCheck';
                          }
                          
                          final occupied = data.organizations.any(
                                (org) {
                                  if (org.phone == null) return false;
                                  final orgNormalized = org.phone!.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                                  String orgNormalizedForCheck = orgNormalized;
                                  if (orgNormalizedForCheck.startsWith('8')) {
                                    orgNormalizedForCheck = '+7${orgNormalizedForCheck.substring(1)}';
                                  } else if (orgNormalizedForCheck.startsWith('7')) {
                                    orgNormalizedForCheck = '+7${orgNormalizedForCheck.substring(1)}';
                                  } else if (!orgNormalizedForCheck.startsWith('+7')) {
                                    orgNormalizedForCheck = '+7$orgNormalizedForCheck';
                                  }
                                  return orgNormalizedForCheck == normalizedForCheck;
                                },
                              ) ||
                              data.drivers.any(
                                (driver) {
                                  final driverNormalized = driver.phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                                  String driverNormalizedForCheck = driverNormalized;
                                  if (driverNormalizedForCheck.startsWith('8')) {
                                    driverNormalizedForCheck = '+7${driverNormalizedForCheck.substring(1)}';
                                  } else if (driverNormalizedForCheck.startsWith('7')) {
                                    driverNormalizedForCheck = '+7${driverNormalizedForCheck.substring(1)}';
                                  } else if (!driverNormalizedForCheck.startsWith('+7')) {
                                    driverNormalizedForCheck = '+7$driverNormalizedForCheck';
                                  }
                                  return driverNormalizedForCheck == normalizedForCheck;
                                },
                              );
                          if (occupied) {
                            return 'Номер уже используется';
                          }
                          return null;
                        },
                      ),
                      // Поле "Руководитель" для КГУ ЖКХ после телефона
                      if (type == OrganizationType.kguZkh)
                        OrganizationsTextField(
                          controller: headController,
                          label: 'Руководитель',
                        ),
                      if (type != OrganizationType.kguZkh) ...[
                        OrganizationsTextField(
                          controller: headController,
                          label: 'ФИО руководителя',
                        ),
                        OrganizationsTextField(
                          controller: addressController,
                          label: 'Адрес',
                        ),
                      ],
                      if (type == OrganizationType.contractor)
                        SafeDropdownButtonFormField<String?>(
                          value: selectedParentOrgId,
                          decoration: const InputDecoration(
                            labelText: 'KGU ZKH*',
                            border: OutlineInputBorder(),
                          ),
                          items: data.organizations
                              .where((org) =>
                                  org.type == OrganizationType.kguZkh && org.isActive)
                              .map(
                                (org) => DropdownMenuItem(
                                  value: org.id,
                                  child: Text(org.name),
                                ),
                              )
                              .toList(),
                          onChanged: parentOrganizationId != null
                              ? null
                              : (value) => setModal(() => selectedParentOrgId = value),
                          validator: (value) =>
                              value == null ? 'Выберите родительскую организацию KGU ZKH' : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  // Нормализация БИН: оставляем только цифры
                  final binNormalized = binController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
                  
                  // Нормализация телефона
                  String phoneNormalized = phoneController.text.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
                  if (phoneNormalized.startsWith('8')) {
                    phoneNormalized = '+7${phoneNormalized.substring(1)}';
                  } else if (phoneNormalized.startsWith('7') && !phoneNormalized.startsWith('+7')) {
                    phoneNormalized = '+7${phoneNormalized.substring(1)}';
                  } else if (!phoneNormalized.startsWith('+7')) {
                    phoneNormalized = '+7$phoneNormalized';
                  }
                  
                  // Получаем значения из контроллеров напрямую
                  final headFullNameRaw = headController.text;
                  final headFullNameValue = headFullNameRaw.trim();
                  final addressValue = type == OrganizationType.kguZkh
                      ? null
                      : addressController.text.trim();
                  
                  // Отладочный вывод перед созданием
                  debugPrint('=== DIALOG VALUES ===');
                  debugPrint('headController.text (raw): "$headFullNameRaw" (length: ${headFullNameRaw.length})');
                  debugPrint('headController.text (trimmed): "$headFullNameValue" (length: ${headFullNameValue.length})');
                  debugPrint('headFullNameValue.isEmpty: ${headFullNameValue.isEmpty}');
                  debugPrint('headFullNameValue.isNotEmpty: ${headFullNameValue.isNotEmpty}');
                  
                  // ВАЖНО: Передаем значение из контроллера как строку
                  // Всегда передаем строку (даже если пустая) - API обработает
                  final finalHeadFullName = headFullNameValue;
                  final finalAddress = (addressValue != null && addressValue.isNotEmpty) ? addressValue : null;
                  
                  debugPrint('finalHeadFullName: "$finalHeadFullName" (isNull: ${finalHeadFullName == null}, length: ${finalHeadFullName?.length ?? 0})');
                  debugPrint('finalAddress: "$finalAddress" (isNull: ${finalAddress == null})');
                  
                  final organization = Organization(
                    id: '',
                    type: type,
                    name: nameController.text.trim(),
                    bin: binNormalized,
                    HeadFullName: finalHeadFullName,
                    address: finalAddress,
                    phone: phoneNormalized,
                    parentOrgId: type == OrganizationType.contractor ? selectedParentOrgId : null,
                    isActive: true,
                  );
                  
                  // Отладочный вывод после создания
                  debugPrint('=== ORGANIZATION OBJECT ===');
                  debugPrint('organization.HeadFullName: "${organization.HeadFullName}" (isNull: ${organization.HeadFullName == null}, length: ${organization.HeadFullName?.length ?? 0})');
                  debugPrint('organization.address: "${organization.address}" (isNull: ${organization.address == null})');
                  
                  try {
                    await controller.createOrganization(organization, skipReload: true);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      await context.showSuccessWithReload(
                        'Организация успешно создана',
                        () async {
                          await controller.refresh();
                        },
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      context.showErrorNotificationFromException(e);
                    }
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showDriverDialog({
    required BuildContext context,
    required OrganizationsController controller,
    required OrganizationsData data,
    required String contractorId,
    Driver? driver,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: driver?.fullName ?? '');
    final iinController = TextEditingController(text: driver?.iin ?? '');
    final birthYearController =
        TextEditingController(text: driver?.birthYear?.toString() ?? '');
    final phoneController = TextEditingController(text: driver?.phone ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(driver == null ? 'Добавить водителя' : 'Редактировать водителя'),
          content: SizedBox(
            width: min(MediaQuery.sizeOf(context).width * 0.8, 420),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OrganizationsTextField(
                      controller: nameController,
                      label: 'ФИО*',
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Введите ФИО' : null,
                    ),
                    OrganizationsTextField(
                      controller: iinController,
                      label: 'ИИН*',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите ИИН';
                        }
                        final exists = data.drivers.any(
                          (d) => d.iin == value && d.id != driver?.id,
                        );
                        if (exists) {
                          return 'Водитель с таким ИИН уже существует';
                        }
                        return null;
                      },
                    ),
                    OrganizationsTextField(
                      controller: birthYearController,
                      label: 'Год рождения',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final year = int.tryParse(value);
                        if (year == null || year < 1940 || year > DateTime.now().year) {
                          return 'Некорректный год';
                        }
                        return null;
                      },
                    ),
                    OrganizationsTextField(
                      controller: phoneController,
                      label: 'Телефон*',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите телефон';
                        }
                        final normalized = value.replaceAll(RegExp(r'\\s+'), '');
                        final occupied = data.organizations.any(
                              (org) => org.phone?.replaceAll(RegExp(r'\\s+'), '') == normalized,
                            ) ||
                            data.drivers.any(
                              (d) =>
                                  d.phone.replaceAll(RegExp(r'\\s+'), '') == normalized &&
                                  d.id != driver?.id,
                            );
                        if (occupied) {
                          return 'Телефон уже используется';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final parsedYear = int.tryParse(birthYearController.text.trim());
                final updated = Driver(
                  id: driver?.id ?? '',
                  contractorId: contractorId,
                  fullName: nameController.text.trim(),
                  iin: iinController.text.trim(),
                  birthYear: parsedYear,
                  phone: phoneController.text.trim(),
                  isActive: driver?.isActive ?? true,
                );
                try {
                  if (driver == null) {
                    await controller.createDriver(updated, skipReload: true);
                  } else {
                    await controller.updateDriver(updated, skipReload: true);
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    // Показываем уведомление об успехе
                    context.showSuccessNotification(
                      driver == null 
                          ? 'Водитель успешно создан'
                          : 'Данные водителя успешно обновлены',
                    );
                    // Сразу перезагружаем данные
                    await controller.refresh();
                  }
                } catch (e) {
                  if (context.mounted) {
                    context.showErrorNotificationFromException(e);
                  }
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showVehicleDialog({
    required BuildContext context,
    required OrganizationsController controller,
    required OrganizationsData data,
    required String contractorId,
    Vehicle? vehicle,
  }) async {
    final formKey = GlobalKey<FormState>();
    final plateController = TextEditingController(text: vehicle?.plateNumber ?? '');
    final brandController = TextEditingController(text: vehicle?.brand ?? '');
    final modelController = TextEditingController(text: vehicle?.model ?? '');
    final colorController = TextEditingController(text: vehicle?.color ?? '');
    final volumeController =
        TextEditingController(text: vehicle?.bodyVolumeM3.toString() ?? '');
    int? selectedYear = vehicle?.year ?? DateTime.now().year;
    
    // Для загрузки файла
    PlatformFile? selectedFile;
    Uint8List? selectedFileBytes;
    String? selectedFileName;
    String? photoUrl = vehicle?.photoUrl; // Сохраняем существующий URL
    // Если у транспортного средства нет фото, показываем дефолтную иконку
    bool useDefaultIcon = vehicle?.photoUrl == null || vehicle!.photoUrl!.isEmpty;

    final years = List<int>.generate(
      DateTime.now().year - 1980 + 1,
      (index) => DateTime.now().year - index,
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: Text(vehicle == null ? 'Добавить транспорт' : 'Редактировать транспорт'),
            content: SizedBox(
              width: min(MediaQuery.sizeOf(context).width * 0.85, 460),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OrganizationsTextField(
                        controller: plateController,
                        label: 'Гос. номер*',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите гос. номер';
                          }
                          final exists = data.vehicles.any(
                            (item) => item.plateNumber == value && item.id != vehicle?.id,
                          );
                          if (exists) {
                            return 'Транспорт с таким номером уже существует';
                          }
                          return null;
                        },
                      ),
                      OrganizationsTextField(
                        controller: brandController,
                        label: 'Марка*',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Введите марку' : null,
                      ),
                      OrganizationsTextField(
                        controller: modelController,
                        label: 'Модель*',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Введите модель' : null,
                      ),
                      OrganizationsTextField(
                        controller: colorController,
                        label: 'Цвет*',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Введите цвет' : null,
                      ),
                      DropdownButtonFormField<int>(
                        value: selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Год*',
                          border: OutlineInputBorder(),
                        ),
                        items: years
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setModal(() => selectedYear = value),
                        validator: (value) => value == null ? 'Выберите год' : null,
                      ),
                      OrganizationsTextField(
                        controller: volumeController,
                        label: 'Объём кузова (м³)*',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите объём';
                          }
                          final parsed = double.tryParse(value.replaceAll(',', '.'));
                          if (parsed == null || parsed <= 0) {
                            return 'Некорректное значение';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Фото',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFilePicker(
                        context: context,
                        selectedFile: selectedFile,
                        selectedFileBytes: selectedFileBytes,
                        selectedFileName: selectedFileName,
                        photoUrl: photoUrl,
                        useDefaultIcon: useDefaultIcon,
                        onFileSelected: (file, bytes, fileName) {
                          setModal(() {
                            selectedFile = file;
                            selectedFileBytes = bytes;
                            selectedFileName = fileName;
                            photoUrl = null; // Очищаем URL при выборе нового файла
                            useDefaultIcon = false; // Сбрасываем флаг дефолтной иконки
                          });
                        },
                        onRemoveFile: () {
                          setModal(() {
                            selectedFile = null;
                            selectedFileBytes = null;
                            selectedFileName = null;
                            photoUrl = null; // Убираем фото
                            useDefaultIcon = true; // Устанавливаем флаг для дефолтной иконки
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  String? finalPhotoUrl = photoUrl;
                  
                  // Если выбран новый файл, конвертируем в base64 data URL
                  if (selectedFile != null && selectedFileBytes != null) {
                    try {
                      // Дополнительная валидация перед отправкой
                      const maxSizeBytes = 5 * 1024 * 1024; // 5MB
                      if (selectedFileBytes!.length > maxSizeBytes) {
                        if (context.mounted) {
                          context.showErrorNotification(
                            'Размер файла слишком большой. Максимальный размер: 5MB'
                          );
                        }
                        return;
                      }
                      
                      // Определяем MIME тип по расширению файла
                      String mimeType = 'image/jpeg';
                      final extension = selectedFileName?.split('.').last.toLowerCase() ?? 'jpg';
                      final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
                      
                      if (!allowedExtensions.contains(extension)) {
                        if (context.mounted) {
                          context.showErrorNotification(
                            'Неподдерживаемый формат файла. Используйте: JPG, PNG или GIF'
                          );
                        }
                        return;
                      }
                      
                      Uint8List processedBytes = selectedFileBytes!;
                      String finalExtension = extension;
                      
                      // Проверяем, что это действительно изображение и декодируем
                      ui.Image? decodedImage;
                      try {
                        decodedImage = await decodeImageFromList(selectedFileBytes!);
                      } catch (e) {
                        if (context.mounted) {
                          context.showErrorNotification(
                            'Не удалось прочитать изображение. Файл поврежден или не является изображением.'
                          );
                        }
                        return;
                      }
                      
                      // Если формат webp или gif, конвертируем в JPEG
                      // (бэкенд не поддерживает эти форматы)
                      if (extension == 'webp' || extension == 'gif') {
                        try {
                          // Конвертируем изображение в JPEG используя canvas
                          final byteData = await decodedImage!.toByteData(
                            format: ui.ImageByteFormat.png,
                          );
                          if (byteData != null) {
                            processedBytes = byteData.buffer.asUint8List();
                            finalExtension = 'png';
                            mimeType = 'image/png';
                          }
                        } catch (e) {
                          if (context.mounted) {
                            context.showErrorNotificationFromException(e);
                          }
                          return;
                        }
                      } else {
                        switch (extension) {
                          case 'png':
                            mimeType = 'image/png';
                            break;
                          case 'jpg':
                          case 'jpeg':
                          default:
                            mimeType = 'image/jpeg';
                        }
                      }
                      
                      // Конвертируем в base64 data URL
                      // Убеждаемся, что данные не пустые
                      if (processedBytes.isEmpty) {
                        if (context.mounted) {
                          context.showErrorNotification('Ошибка: файл изображения пуст');
                        }
                        return;
                      }
                      
                      final base64String = base64Encode(processedBytes);
                      
                      // Проверяем, что base64 строка не пустая
                      if (base64String.isEmpty) {
                        if (context.mounted) {
                          context.showErrorNotification('Ошибка: не удалось закодировать изображение');
                        }
                        return;
                      }
                      
                      finalPhotoUrl = 'data:$mimeType;base64,$base64String';
                    } catch (e) {
                      if (context.mounted) {
                        context.showErrorNotificationFromException(e);
                      }
                      return;
                    }
                  }
                  
                  // Если установлен флаг дефолтной иконки, устанавливаем null для photoUrl
                  if (useDefaultIcon) {
                    finalPhotoUrl = null; // null означает использовать дефолтную иконку
                  } else if (vehicle != null && finalPhotoUrl == null && selectedFile == null) {
                    // Если редактирование и фото не изменялось, используем существующее
                    // НО только если это обычный URL, не data URL
                    if (vehicle.photoUrl != null && !vehicle.photoUrl!.startsWith('data:image/')) {
                      finalPhotoUrl = vehicle.photoUrl;
                    }
                    // Если photoUrl начинается с data:, это означает временные данные
                    // которые уже обработаны, не сохраняем их
                  }
                  
                  final parsedVolume = double.parse(volumeController.text.replaceAll(',', '.'));
                  final updated = Vehicle(
                    id: vehicle?.id ?? '',
                    contractorId: contractorId,
                    driverId: vehicle?.driverId,
                    plateNumber: plateController.text.trim(),
                    brand: brandController.text.trim(),
                    model: modelController.text.trim(),
                    color: colorController.text.trim(),
                    year: selectedYear!,
                    bodyVolumeM3: parsedVolume,
                    photoUrl: finalPhotoUrl, // null означает использовать дефолтную иконку
                    isActive: vehicle?.isActive ?? true,
                  );
                  
                  try {
                    if (vehicle == null) {
                      await controller.createVehicle(updated, skipReload: true);
                    } else {
                      await controller.updateVehicle(updated, skipReload: true);
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      // Показываем уведомление об успехе
                      context.showSuccessNotification(
                        vehicle == null 
                            ? 'Транспорт успешно добавлен'
                            : 'Данные транспорта успешно обновлены',
                      );
                      // Сразу перезагружаем данные
                      await controller.refresh();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      context.showErrorNotificationFromException(e);
                    }
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showAssignVehicleDialog({
    required BuildContext context,
    required OrganizationsController controller,
    required OrganizationsData data,
    required Driver driver,
  }) async {
    String? selectedVehicleId = data.vehicles
        .firstWhere(
          (vehicle) => vehicle.driverId == driver.id && vehicle.isActive,
          orElse: () => Vehicle(
            id: '',
            contractorId: '',
            driverId: null,
            plateNumber: '',
            brand: '',
            model: '',
            color: '',
            year: 0,
            bodyVolumeM3: 0,
            isActive: false,
          ),
        )
        .id;

    final availableVehicles = data.vehicles.where((vehicle) {
      final sameContractor = vehicle.contractorId == driver.contractorId;
      final noDriver = vehicle.driverId == null || vehicle.driverId == driver.id;
      return sameContractor && vehicle.isActive && noDriver;
    }).toList();

    if (availableVehicles.isEmpty) {
      context.showWarningNotification('Нет доступного транспорта. Добавьте транспорт подрядчика.');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: Text('Назначить транспорт — ${driver.fullName}'),
            content: DropdownButtonFormField<String>(
              value: selectedVehicleId?.isEmpty ?? true ? null : selectedVehicleId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Транспорт',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Без транспорта')),
                ...availableVehicles.map(
                  (vehicle) => DropdownMenuItem(
                    value: vehicle.id,
                    child: Text('${vehicle.plateNumber} — ${vehicle.brand} ${vehicle.model}'),
                  ),
                ),
              ],
              onChanged: (value) => setModal(() => selectedVehicleId = value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    // Сначала отвязываем старые транспортные средства от водителя
                    for (final vehicle in data.vehicles) {
                      if (vehicle.driverId == driver.id && vehicle.id != selectedVehicleId) {
                        await controller.updateVehicle(
                          vehicle.copyWith(driverId: null),
                          skipReload: true,
                        );
                      }
                    }
                    // Затем назначаем новый транспорт
                    if (selectedVehicleId != null) {
                      final vehicle = data.vehicles.firstWhere((item) => item.id == selectedVehicleId);
                      await controller.updateVehicle(
                        vehicle.copyWith(driverId: driver.id),
                        skipReload: true,
                      );
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      // Показываем уведомление об успехе
                      context.showSuccessNotification('Транспорт успешно назначен');
                      // Сразу перезагружаем данные
                      await controller.refresh();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      context.showErrorNotificationFromException(e);
                    }
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showAssignDriverDialog({
    required BuildContext context,
    required OrganizationsController controller,
    required OrganizationsData data,
    required Vehicle vehicle,
  }) async {
    String? selectedDriverId = vehicle.driverId;
    final availableDrivers = data.drivers.where((driver) {
      if (!driver.isActive) return false;
      if (driver.contractorId != vehicle.contractorId) return false;
      final assignedVehicle = data.vehicles.firstWhere(
        (item) => item.driverId == driver.id,
        orElse: () => Vehicle(
          id: '',
          contractorId: '',
          driverId: null,
          plateNumber: '',
          brand: '',
          model: '',
          color: '',
          year: 0,
          bodyVolumeM3: 0,
          isActive: false,
        ),
      );
      return assignedVehicle.id.isEmpty || assignedVehicle.id == vehicle.id;
    }).toList();

    if (availableDrivers.isEmpty) {
      context.showWarningNotification('Нет доступных водителей. Добавьте или разблокируйте водителя.');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: Text('Назначить водителя — ${vehicle.plateNumber}'),
            content: DropdownButtonFormField<String>(
              value: selectedDriverId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Водитель',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Без водителя')),
                ...availableDrivers.map(
                  (driver) => DropdownMenuItem(
                    value: driver.id,
                    child: Text(driver.fullName),
                  ),
                ),
              ],
              onChanged: (value) => setModal(() => selectedDriverId = value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () async {
                  if (selectedDriverId == vehicle.driverId) {
                    Navigator.of(context).pop();
                    return;
                  }
                  try {
                    await controller.updateVehicle(
                      vehicle.copyWith(driverId: selectedDriverId),
                      skipReload: true,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      // Показываем уведомление об успехе
                      context.showSuccessNotification('Водитель успешно назначен');
                      // Сразу перезагружаем данные
                      await controller.refresh();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      context.showErrorNotificationFromException(e);
                    }
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildFilePicker({
    required BuildContext context,
    PlatformFile? selectedFile,
    Uint8List? selectedFileBytes,
    String? selectedFileName,
    String? photoUrl,
    // String? photoSelect,
    bool useDefaultIcon = false,
    required Function(PlatformFile?, Uint8List?, String?) onFileSelected,
    required VoidCallback onRemoveFile,
  }) {
    // Определяем, нужно ли показывать превью
    final hasImage = selectedFileBytes != null || 
                     (photoUrl != null && photoUrl!.isNotEmpty) ||
                     useDefaultIcon;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Превью изображения или дефолтная иконка
        if (hasImage)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    gradient: useDefaultIcon
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withOpacity(0.1),
                              AppColors.primary.withOpacity(0.05),
                            ],
                          )
                        : null,
                    color: useDefaultIcon ? null : Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: useDefaultIcon
                        ? Center(
                            child: Icon(
                              Icons.local_shipping_rounded,
                              size: 80,
                              color: AppColors.primary.withOpacity(0.7),
                            ),
                          )
                        : selectedFileBytes != null
                            ? Image.memory(
                                selectedFileBytes!,
                                fit: BoxFit.cover,
                              )
                            : photoUrl != null && photoUrl!.isNotEmpty
                                ? _buildImageFromUrl(photoUrl!)
                                : null,
                  ),
                ),
                
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                    onPressed: onRemoveFile,
                  ),
                ),
              ],
            ),
          ),
        // Кнопка выбора файла
        FilledButton.icon(
          onPressed: () async {
            try {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                allowMultiple: false,
                withData: true, // Загружаем файл в память
              );

              if (result != null && result.files.single.bytes != null) {
                final file = result.files.single;
                Uint8List bytes = file.bytes!;
                
                // Валидация размера файла (максимум 5MB)
                const maxSizeBytes = 5 * 1024 * 1024; // 5MB
                if (bytes.length > maxSizeBytes) {
                  if (context.mounted) {
                    context.showErrorNotification('Размер файла слишком большой. Максимальный размер: 5MB');
                  }
                  return;
                }
                
                // Валидация формата файла
                final extension = file.extension?.toLowerCase();
                final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
                if (extension == null || !allowedExtensions.contains(extension)) {
                  if (context.mounted) {
                    context.showErrorNotification('Неподдерживаемый формат файла. Используйте: JPG, PNG, WEBP или GIF');
                  }
                  return;
                }
                
                // Проверяем, что это действительно изображение
                ui.Image? decodedImage;
                try {
                  // Пытаемся декодировать изображение для проверки
                  decodedImage = await decodeImageFromList(bytes);
                } catch (e) {
                  if (context.mounted) {
                    context.showErrorNotification('Не удалось прочитать изображение. Проверьте файл.');
                  }
                  return;
                }
                
                // Если формат webp или gif, конвертируем в PNG для лучшей совместимости
                Uint8List processedBytes = bytes;
                String? convertedFileName = file.name;
                if (extension == 'webp' || extension == 'gif') {
                  try {
                    // Конвертируем изображение в PNG
                    final byteData = await decodedImage!.toByteData(
                      format: ui.ImageByteFormat.png,
                    );
                    if (byteData != null) {
                      processedBytes = byteData.buffer.asUint8List();
                      // Обновляем имя файла с новым расширением
                      final nameWithoutExt = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
                      convertedFileName = '$nameWithoutExt.png';
                    }
                  } catch (e) {
                    // Если конвертация не удалась, показываем предупреждение
                    if (context.mounted) {
                      context.showWarningNotification(
                        'Предупреждение: формат $extension может не поддерживаться сервером. Ошибка конвертации: $e'
                      );
                    }
                    // Продолжаем с оригинальными байтами
                    processedBytes = bytes;
                  }
                }
                
                onFileSelected(file, processedBytes, convertedFileName ?? file.name);
              }
            } catch (e) {
              if (context.mounted) {
                context.showErrorNotificationFromException(e);
              }
            }
          },
          icon: const Icon(Icons.upload_file),
          label: Text(selectedFileBytes != null || (photoUrl != null && photoUrl!.isNotEmpty)
              ? 'Изменить фото'
              : 'Загрузить фото'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        if (selectedFileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Выбранный файл: $selectedFileName',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
          ),
        ),
      ],
    );
  }

  static Widget _buildImageFromUrl(String url) {
    // Проверяем, является ли URL base64 data URL
    if (url.startsWith('data:image/')) {
      try {
        // Извлекаем base64 данные из data URL
        final base64String = url.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, size: 48),
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, size: 48),
          ),
        );
      }
    } else {
      // Обычный URL
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.broken_image, size: 48),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }
  }
}

