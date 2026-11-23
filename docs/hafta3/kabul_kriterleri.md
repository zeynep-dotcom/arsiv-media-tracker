# Hafta 3 Kabul Kriterleri

**Hazırlayan:** Ahmet · **Hedef demo:** 4 Kasım 2026

Bir özelliğin "çalışıyor" sayılması için kendi bölümündeki maddelerin hepsi geçmelidir.
Maddeler gerçek uygulamada, gerçek Firebase projesiyle denenir. Kanıt (ekran görüntüsü veya
kısa video) PR'a eklenir.

## 1. Giriş

- [ ] GİR-1: Oturum yoksa uygulama Giriş ekranıyla açılır.
- [ ] GİR-2: Doğru e-posta ve şifreyle giriş yapılınca Keşfet ekranı açılır.
- [ ] GİR-3: E-posta veya şifre boşsa istek gönderilmez, "E-posta ve şifreni gir." görünür.
- [ ] GİR-4: Yanlış şifrede "E-posta veya şifre hatalı." görünür, kullanıcı Giriş ekranında kalır.
- [ ] GİR-5: Oturum açıkken uygulama kapatılıp açılınca yeniden giriş istenmez.
- [ ] GİR-6: İnternet yokken "İnternet bağlantısı yok." görünür, uygulama çökmez.
- [ ] GİR-7: İşlem sürerken buton yükleniyor durumundadır, ikinci kez basılamaz.

## 2. Kayıt

- [ ] KAY-1: Ad, e-posta, şifre ve şifre tekrarı dolu, kullanım koşulları işaretliyse kayıt tamamlanır ve Keşfet ekranı açılır.
- [ ] KAY-2: Kayıttan sonra Firestore'da `users/{uid}` belgesi `name`, `email`, `createdAt` ve `plan: "free"` alanlarıyla oluşur.
- [ ] KAY-3: Ad, e-posta veya şifre boşsa "Ad, e-posta ve şifre alanlarını doldur." görünür.
- [ ] KAY-4: Şifreler farklıysa "Şifreler aynı değil." görünür.
- [ ] KAY-5: Kullanım koşulları işaretli değilse "Devam etmek için kullanım koşullarını kabul et." görünür.
- [ ] KAY-6: 6 karakterden kısa şifrede "Şifre en az 6 karakter olmalı." görünür.
- [ ] KAY-7: Kayıtlı e-postayla tekrar kayıt olunursa "Bu e-postayla zaten bir hesap var." görünür.
- [ ] KAY-8: Geçersiz e-postada "Geçerli bir e-posta adresi gir." görünür.

## 3. Şifremi unuttum

- [ ] ŞİF-1: Boş e-postada "E-posta adresini gir." görünür.
- [ ] ŞİF-2: Kayıtlı e-postayla gönderim sonrası "E-postanı kontrol et" ekranı görünür.
- [ ] ŞİF-3: Sıfırlama e-postası gelir (spam klasörü de kontrol edilir).
- [ ] ŞİF-4: Bağlantıyla belirlenen yeni şifreyle giriş yapılır, eski şifreyle yapılamaz.
- [ ] ŞİF-5: "Girişe dön" butonu Giriş ekranına götürür.

## 4. Çıkış

- [ ] ÇIK-1: Hesabım ekranındaki "Çıkış yap" butonu Giriş ekranına götürür.
- [ ] ÇIK-2: Çıkıştan sonra geri tuşuyla ana ekrana dönülemez.
- [ ] ÇIK-3: Başka hesapla girildiğinde önceki kullanıcının kütüphanesi görünmez.
- [ ] ÇIK-4: Aynı hesapla tekrar girildiğinde kullanıcının kütüphanesi geri gelir.

## 5. Detay ekranında dinamik yükleme

- [ ] DET-1: Ekran açılır açılmaz karttaki mevcut bilgiler görünür, boş ekran beklenmez.
- [ ] DET-2: Film detayında süre, türler ve açıklama servisten gelip ekranda güncellenir.
- [ ] DET-3: Kitap detayında tam açıklama, sayfa sayısı ve yazar bilgisi görünür.
- [ ] DET-4: Oyun detayında gerçek oyun açıklaması, oynama süresi ve geliştirici bilgisi görünür.
- [ ] DET-5: İstek başarısız olursa uygulama çökmez, karttaki bilgiler ekranda kalır.
- [ ] DET-6: Eksik alan varsa "null" gibi teknik bir ifade görünmez.
- [ ] DET-7: Kütüphanedeki içeriğin durumu "Devam ediyor" ise ilerleme kaydırıcısı (%0-%100) görünür; değer uygulama yeniden açılınca korunur.

## 6. Ödeme (mock)

- [ ] ÖDE-1: Hesabım ekranındaki "Premium'a geç" butonu Ödeme ekranını açar.
- [ ] ÖDE-2: Aylık ve yıllık plan kartları, fiyatları ve Premium özellik listesi görünür.
- [ ] ÖDE-3: "Satın al" butonuna basınca yaklaşık 2 saniye yükleniyor durumu, ardından başarı ekranı görünür.
- [ ] ÖDE-4: Gerçek para çekilmez; ekranda kart numarası veya başka bir kart alanı yoktur.
- [ ] ÖDE-5: Kart bilgisi uygulamada ve Firestore'da saklanmaz.
- [ ] ÖDE-6: Firestore'daki `plan` alanı `"free"` kalır. Mock akış kullanıcıyı gerçekten Premium yapmaz.

## Açık kararlar

| Konu | Öneri | Karar veren |
|---|---|---|
| E-posta doğrulaması | Hafta 3'te zorunlu olmasın; kodda şu an doğrulama yok | Ekip |
| Ödeme başarısız sonuç ekranı | Plan hem başarılı/başarısız sonuç hem "her zaman başarı" diyor. Tasarım hazırlansın, mock akışı başarıyla bitsin | Emir, Ahmet |
| Ödeme fiyatları | [Ürün kuralları](urun_kurallari.md) dokümanındaki önerilen fiyatlar ekip onayıyla kesinleşir | Ekip |
