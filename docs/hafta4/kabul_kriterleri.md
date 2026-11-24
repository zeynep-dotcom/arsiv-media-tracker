# Hafta 4 Kabul Kriterleri

**Hazırlayan:** Ahmet · **Hafta lideri:** Akif

Bir özelliğin "bitti" sayılması için kendi bölümündeki maddelerin hepsi geçmelidir.
Maddeler güncel `main` üzerinde, gerçek Firebase projesiyle ve `--dart-define-from-file=env.json`
ile denenir. Kanıt (ekran görüntüsü veya kısa video) PR açıklamasına eklenir.

## 1. Koleksiyonlar (Akif, Emir)

- [ ] KOL-1: Kütüphanem › Koleksiyonlar sekmesinde "Yeni koleksiyon" ile koleksiyon oluşturulur; kartta ad, içerik sayısı ve ilk 4 afiş görünür.
- [ ] KOL-2: Koleksiyon adı 1-40 karakter olmalı; boş ya da 40 karakterden uzun ad kaydedilmez ve kullanıcıya nedeni gösterilir.
- [ ] KOL-3: Hiç koleksiyon yokken boş durum metni ve "Yeni koleksiyon" butonu görünür.
- [ ] KOL-4: Detay › "Koleksiyona ekle" paneli açılır; içerik bir ya da birkaç koleksiyona işaretlenerek eklenir.
- [ ] KOL-5: Kütüphanede olmayan içerik koleksiyona eklenince kütüphaneye "İzlenecek" durumuyla da eklenir.
- [ ] KOL-6: Koleksiyon ekranında içerik kaydırılarak koleksiyondan çıkarılır; içerik kütüphanede kalır.
- [ ] KOL-7: Koleksiyon yeniden adlandırılır; yeni ad kartta ve ekran başlığında görünür.
- [ ] KOL-8: Koleksiyon silinmeden önce onay sorulur; silinen koleksiyonun içerikleri kütüphanede kalır.
- [ ] KOL-9: Kütüphaneden silinen içerik bütün koleksiyonlardan da çıkar.
- [ ] KOL-10: Uygulama kapatılıp açılınca koleksiyonlar ve içerikleri yerinde durur.
- [ ] KOL-11: Başka hesapla girildiğinde önceki kullanıcının koleksiyonları görünmez.
- [ ] KOL-12: Bir koleksiyona en fazla 200 içerik eklenebilir; sınır aşılınca uygulama çökmez, "Kaydedilemedi. Tekrar dene." görünür.

## 2. Kütüphanem (Ece, Akif)

- [ ] KÜT-1: Uzunluğu bilinen içerikte ilerleme birimle görünür: kitapta "140 / 350 sayfa", oyunda saat, filmde dakika.
- [ ] KÜT-2: İlerleme sayısı elle girilebilir; uzunluktan büyük ya da negatif değer kabul edilmez.
- [ ] KÜT-3: Uzunluk bilinmiyorsa ilerleme % olarak görünür; hiçbir yerde "0 / 0" yazmaz.
- [ ] KÜT-4: Kütüphanem satırında da Detay'daki birimin aynısı görünür.
- [ ] KÜT-5: Satır sola kaydırılınca içerik silinir ve "Geri al" çıkar.
- [ ] KÜT-6: "Geri al"a basılınca içerik durumu, puanı, favorisi ve ilerlemesiyle geri gelir.
- [ ] KÜT-7: Satıra uzun basınca durum menüsü açılır; seçilen durum hemen uygulanır.
- [ ] KÜT-8: Sekme adları içeriği doğru anlatır (film, kitap ve oyun ayrımı karışmaz).
- [ ] KÜT-9: Firestore bir kaydı reddederse hangi ekranda olunursa olunsun "Kaydedilemedi. Tekrar dene." görünür.

## 3. Film detayı (Ali Kağan)

- [ ] FİL-1: Film detayında süre ("148 dk"), türler ve Türkçe özet görünür.
- [ ] FİL-2: Popüler filmler satırı sona kaydırılınca sonraki sayfa yüklenir.
- [ ] FİL-3: "Türkiye'de nerede izlenir" bölümünde TR platformları logolarıyla ve JustWatch kaynak notuyla görünür.
- [ ] FİL-4: Türkiye'de platform yoksa bölüm hiç görünmez (boş başlık kalmaz).
- [ ] FİL-5: "Fragmanı izle" fragmanı YouTube'da açar; fragman yoksa buton görünmez.

## 4. Barkodla kitap (Abdulkadir)

- [ ] KİT-1: Ara ekranındaki barkod ikonu kamerayı açar.
- [ ] KİT-2: Kamera izni reddedilirse ne yapılması gerektiğini anlatan açık bir mesaj görünür, uygulama çökmez.
- [ ] KİT-3: Kitabın arkasındaki ISBN barkodu okutulunca bulunan kitabın Detay ekranı açılır.
- [ ] KİT-4: Bulunamayan barkodda "Bu barkodla kitap bulunamadı" görünür.
- [ ] KİT-5: Bulunan kitap Detay'dan tek dokunuşla kütüphaneye eklenir.
- [ ] KİT-6: Deneme gerçek bir Android telefonda yapılır (emülatörde kamera yok).

## 5. Oyun vitrini (Enes)

- [ ] OYN-1: Oyun detayında ekran görüntüleri yatay galeride görünür; dokununca tam ekran açılır.
- [ ] OYN-2: Platformlar çip olarak görünür (PC, PlayStation, Switch...).
- [ ] OYN-3: "Aynı seriden" satırı seriye ait oyunları gösterir; seri yoksa satır görünmez.
- [ ] OYN-4: Galeri yoksa ya da istek başarısız olursa boş alan kalmaz, uygulama çökmez.

## 6. Tür tercihi ve öneri motoru (Ahmet)

- [ ] ÖNR-1: Kayıt tamamlanınca "Hangi türleri seversin?" ekranı açılır; girişte (kayıt değilse) açılmaz.
- [ ] ÖNR-2: GenreMap'teki 9 tür seçilebilir çip olarak görünür.
- [ ] ÖNR-3: 3 türden az seçiliyken "Devam" kapalıdır; seçim sayısı ekranda yazar.
- [ ] ÖNR-4: "Devam" seçimleri `users/{uid}` belgesindeki `favoriteGenres` alanına yazar; `plan` ve `name` alanları değişmez.
- [ ] ÖNR-5: "Atla" seçim yapmadan Keşfet'e geçer; `favoriteGenres` yazılmaz.
- [ ] ÖNR-6: Kayıt başarısız olursa ekranda "Kaydedilemedi. Tekrar dene." görünür, kullanıcı ekranda kalır.
- [ ] ÖNR-7: Kütüphanesi boş yeni kullanıcıda "Bu haftanın önerisi" seçtiği türlerden biridir.
- [ ] ÖNR-8: Kütüphanede olan içerik "Bu haftanın önerisi" olarak gösterilmez.
- [ ] ÖNR-9: Öneri puanı %70 tür uyumu ve %30 API puanından oluşur (`test/recommendation_test.dart`).
- [ ] ÖNR-10: Öneri hafta içinde aynı kalır; API'lerden biri hata verse de kart boş kalmaz.

## 7. Premium akışı (Emir)

- [ ] ÖDE-1: Hesabım › "Premium'a geç" mock ödeme ekranını açar.
- [ ] ÖDE-2: Aylık ve yıllık plan seçilebilir; sahte ödeme butonu başarı ekranını gösterir.
- [ ] ÖDE-3: Gerçek para çekilmez, kart alanı yoktur, kart bilgisi saklanmaz.
- [ ] ÖDE-4: Firestore'daki `plan` alanı `"free"` kalır.

## 8. Kalite kontrolü (Zeynep)

- [ ] CI-1: Her PR'da GitHub Actions `flutter analyze` ve `flutter test` çalıştırır.
- [ ] CI-2: Analiz uyarısı ya da kırmızı test varsa PR birleştirilemez.
- [ ] CI-3: CI testleri API anahtarı ve internet istemez.
- [ ] CI-4: `test/collection_store_test.dart` koleksiyon oluşturma, ekleme, çıkarma ve silmeyi test eder.
- [ ] CI-5: UML class diyagramında UserCollection ve CollectionStore bulunur.
- [ ] CI-6: Depoda API anahtarı ya da parola yoktur.

## Açık kararlar

| Konu | Öneri | Karar veren |
|---|---|---|
| Ücretsiz planda koleksiyon sayısı | 5 (Akif'in önerisi); Premium'da sınırsız | Ekip |
| Tür tercihini sonradan değiştirme | Hafta 5'te Hesabım'a "Türlerimi düzenle" eklenmesi | Ekip |
