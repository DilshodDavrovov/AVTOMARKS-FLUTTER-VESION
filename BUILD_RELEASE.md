# Инструкция по сборке релизного APK

## Текущий статус

✅ **APK успешно собран!**

Файл находится здесь:
```
build\app\outputs\flutter-apk\app-release.apk
```

⚠️ **Внимание:** Текущий APK подписан debug ключом. Для production использования нужно создать release keystore.

---

## Создание release keystore (для production)

### Вариант 1: Использование готового скрипта

1. Запустите файл:
   ```
   android\create_keystore.bat
   ```

2. Скрипт автоматически найдет Java и создаст keystore файл `android\app\key.jks`

### Вариант 2: Ручное создание через командную строку

1. Убедитесь, что установлена Java JDK (можно скачать с https://adoptium.net/)

2. Откройте командную строку в папке `android\app`

3. Выполните команду:
   ```bash
   keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key -storepass venons2024 -keypass venons2024 -dname "CN=VENONS AVTOMARKS, OU=Development, O=VENONS, L=City, ST=State, C=UZ"
   ```

4. Файл `key.jks` будет создан в папке `android\app`

### Вариант 3: Через Android Studio

1. Откройте проект в Android Studio
2. Build → Generate Signed Bundle / APK
3. Выберите APK
4. Create new keystore
5. Заполните данные и сохраните в `android\app\key.jks`

---

## После создания keystore

После создания `android\app\key.jks` файла, конфигурация уже настроена в `android\key.properties` и `android\app\build.gradle`.

Просто пересоберите APK:

```bash
flutter clean
flutter build apk --release
```

Новый APK будет подписан release ключом и готов для распространения.

---

## Параметры keystore

- **Файл:** `android\app\key.jks`
- **Пароль хранилища:** `venons2024`
- **Пароль ключа:** `venons2024`
- **Алиас:** `key`
- **Срок действия:** 10000 дней (~27 лет)

⚠️ **ВАЖНО:** Сохраните файл `key.jks` и пароли в безопасном месте! Без них вы не сможете обновлять приложение в Google Play.

---

## Быстрая сборка (текущая конфигурация)

Для быстрой сборки с debug signing (для тестирования):

```bash
flutter build apk --release
```

APK будет в: `build\app\outputs\flutter-apk\app-release.apk`

---

## Размер APK

Текущий размер: **99.6 MB**

Для уменьшения размера можно создать split APK по архитектурам:

```bash
flutter build apk --split-per-abi --release
```

Это создаст отдельные APK для каждой архитектуры (arm64-v8a, armeabi-v7a, x86_64).
