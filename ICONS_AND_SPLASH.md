# Инструкция по замене иконок и заставок

## Android

### Иконки приложения
Замените файлы в следующих папках на ваши иконки с названием `ic_launcher.png`:

- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48 px)
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72 px)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96 px)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144 px)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192 px)

### Заставка (Splash Screen)
Настройки заставки находятся в:
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/drawable-v21/launch_background.xml`

## iOS

### Иконки приложения
Замените файлы в `ios/Runner/Assets.xcassets/AppIcon.appiconset/`:

- `icon-40.png` (40x40 px)
- `icon-76.png` (76x76 px)
- `icon-80.png` (80x80 px)
- `icon-81.png` (81x81 px)
- `icon-120.png` (120x120 px)
- `icon-121.png` (121x121 px)
- `icon-152.png` (152x152 px)
- `icon-167.png` (167x167 px)
- `icon-180.png` (180x180 px)
- `icon-1024.png` (1024x1024 px)

### Заставка (Launch Screen)
Замените файлы в `ios/Runner/Assets.xcassets/LaunchImage.imageset/`:

- `LaunchImage.png` (320x480 px для iPhone 3GS)
- `LaunchImage@2x.png` (640x960 px для iPhone 4/4S)
- `LaunchImage@3x.png` (1242x2208 px для iPhone 6 Plus)

Или настройте `ios/Runner/Base.lproj/LaunchScreen.storyboard` для кастомной заставки.

## Автоматическая генерация иконок (рекомендуется)

Для автоматической генерации всех размеров иконок из одного исходного файла можно использовать пакет `flutter_launcher_icons`:

1. Добавьте в `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"  # Путь к вашей исходной иконке (1024x1024 px)
```

2. Создайте папку `assets/icon/` и поместите туда вашу иконку `icon.png` (1024x1024 px)

3. Запустите:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```
