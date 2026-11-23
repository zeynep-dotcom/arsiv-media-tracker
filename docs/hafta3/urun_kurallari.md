# Hafta 3 Ürün Kuralları

**Hazırlayan:** Ahmet · **Durum:** Ekip onayı bekliyor

Metinler `dev/akif` dalındaki `AuthService` ve giriş ekranlarıyla uyumludur. Sayısal
değerler ve fiyatlar öneridir; ekip onayıyla kesinleşir.

## 1. Giriş ve kayıt kuralları

| Konu | Kural |
|---|---|
| Kayıtta zorunlu alanlar | Ad, e-posta, şifre, şifre tekrarı |
| Kullanım koşulları | Onay kutusu işaretlenmeden kayıt yapılamaz |
| Şifre | En az 6 karakter (Firebase alt sınırı) |
| Şifre tekrarı | Şifreyle aynı olmalı |
| E-posta | Baştaki ve sondaki boşluklar temizlenir, biçimi Firebase denetler |
| E-posta doğrulaması | Hafta 3'te zorunlu değil; doğrulanmamış kullanıcı da giriş yapabilir |
| Yeni kullanıcı | `users/{uid}` belgesi `plan: "free"` ile oluşur |
| Oturum | Çıkış yapılana kadar açık kalır |

## 2. Hata mesajları

| Firebase kodu | Kullanıcıya gösterilen metin |
|---|---|
| `invalid-credential`, `wrong-password` | E-posta veya şifre hatalı. |
| `user-not-found` | Bu e-postayla kayıtlı bir hesap bulunamadı. |
| `email-already-in-use` | Bu e-postayla zaten bir hesap var. |
| `weak-password` | Şifre en az 6 karakter olmalı. |
| `invalid-email` | Geçerli bir e-posta adresi gir. |
| `missing-email` | E-posta adresi boş olamaz. |
| `missing-password` | Şifre boş olamaz. |
| `user-disabled` | Bu hesap devre dışı bırakılmış. |
| `too-many-requests` | Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene. |
| `network-request-failed` | İnternet bağlantısı yok. |
| `permission-denied` | Hesap bilgileri kaydedilemedi. |
| Diğer | Bir hata oluştu. Lütfen tekrar dene. |

Firebase'in e-posta koruması açıksa kayıtlı olmayan adres için `user-not-found` dönmeyebilir;
bu durumda girişte `invalid-credential` mesajı görünür.

## 3. Premium ve ödeme kuralları

| Özellik | Ücretsiz | Premium |
|---|---|---|
| Kütüphanedeki içerik | En fazla 50 | Sınırsız |
| Film, kitap, oyun keşfi ve arama | Var | Var |
| Favori, puan ve durum takibi | Var | Var |
| Temel sayılar (film, kitap, oyun adedi) | Var | Var |
| Aylık grafik ve favori türler | Yok | Var |
| Reklam | Reklam eklenirse gösterilir | Reklamsız |

| Plan | Önerilen fiyat | Not |
|---|---|---|
| Aylık | 49,90 TL | Her ay yenilenir |
| Yıllık | 399,90 TL | Aylık plana göre yaklaşık %33 avantajlı |

### Hafta 3 sınırları

- Ödeme sahtedir (mock): 2 saniye bekleme sonrası başarı ekranı gösterilir, para çekilmez.
- Kart alanı bulunmaz; kart bilgisi uygulamada ve Firestore'da saklanmaz.
- `plan` alanı `"free"` kalır. `firestore.rules` uygulamanın `premium` yazmasına izin vermez;
  bu geçişi gerçek ödeme doğrulandıktan sonra sunucu yapacak.
- Mock Premium gerçek yetki açmadığı için 50 içerik ve grafik sınırları Hafta 3'te uygulanmaz.
- Gerçek ödeme yolu Hafta 4 açılış toplantısında seçilir.
