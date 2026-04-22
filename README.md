# Klinik Randevu ve Muayene Kayıt Sistemi

Bu proje, Mobil Programlama dersi final projesi kapsamında geliştirilmiştir.  
Uygulama Flutter ile geliştirilmiş, veri tabanı ve kimlik doğrulama işlemleri için Supabase kullanılmıştır.

## Öğrenci Bilgileri
Selçuk Üniversitesi Teknoloji Fakültesi Bilgisayar Mühendisliği
Okul No         : 233301108
Ad Soyad        : Umutcan Batakbaşı
Sınıfı          : Normal Öğretim - 4. Sınıf
Telefon         : (+90) 537 688 2588


## Proje Özeti

Uygulama iki farklı kullanıcı rolüne sahiptir:

- Hasta
- Doktor

Sistemde kullanıcılar kayıt olabilir, giriş yapabilir, çıkış yapabilir ve oturum bilgileri uygulama kapatılıp açıldığında korunur.

## Kullanılan Teknolojiler

- Flutter
- Dart
- Supabase Auth
- Supabase Database

## Uygulama Özellikleri

### Ortak Özellikler
- Kayıt olma
- Giriş yapma
- Çıkış yapma
- Oturumun korunması
- Log kaydı tutma

### Hasta Özellikleri
- Randevu oluşturma
- Randevularını görüntüleme
- Doktor tarafından güncellenen randevu durumlarını görme
- Bildirimleri görüntüleme
- Muayene geçmişini görüntüleme

### Doktor Özellikleri
- Kendisine gelen randevuları görüntüleme
- Randevu detayını görüntüleme
- Randevuyu onaylama / reddetme / iptal etme
- Doktor notu ekleme
- Muayene notu oluşturma ve güncelleme

## Veritabanı Tabloları

Projede aşağıdaki tablolar kullanılmaktadır:

- profiles
- appointments
- notifications
- examinations
- logs

## Test Hesapları

### Doktor Hesabı
- E-posta: doktor_test@mail.com
- Şifre: doktor123456

### Hasta Hesabı
- E-posta: hasta_test@mail.com
- Şifre: hasta123456

## Kurulum ve Çalıştırma

1. Proje klasörünü açın.
2. Terminalde aşağıdaki komutu çalıştırın:

```bash
flutter pub get