# Analisis Penjualan E-Commerce Olist dengan PostgreSQL
Proyek ini merupakan proyek analitik end-to-end berbasis dataset e-commerce Olist Brasil. Proyek ini meliputi perancangan database PostgreSQL yang terstruktur dan terversi, otomasi proses ingestion dari sembilan file CSV, serta analisis mendalam menggunakan SQL untuk mengidentifikasi wawasan bisnis strategis seperti tren pendapatan bulanan dan kategori produk dengan kontribusi penjualan tertinggi.

**Teknologi:** PostgreSQL · SQL (CTE, window function) · Python · SQLAlchemy · Alembic · pgAdmin · Metabase

---

## Daftar Isi
1. [Ringkasan](#ringkasan)
2. [Pertanyaan Bisnis](#pertanyaan-bisnis)
3. [Temuan Utama](#temuan-utama)
4. [Dashboard](#dashboard)
5. [Dataset](#dataset)
6. [Struktur Database](#struktur-database)
7. [Metodologi dan Keputusan Analisis](#metodologi-dan-keputusan-analisis)
8. [Keterbatasan Data](#keterbatasan-data)
9. [Struktur Proyek](#struktur-proyek)
10. [Cara Menjalankan](#cara-menjalankan)
11. [Pengembangan Lanjutan](#pengembangan-lanjutan)
12. [Tentang Pembuat](#tentang-pembuat)

---

## Ringkasan
Pengolahan data mentah menggunakan format CSV secara berulang memiliki keterbatasan dari segi efisiensi dan konsistensi. Proyek ini memindahkan seluruh dataset ke database relasional PostgreSQL melalui pipeline terstruktur yang dapat dijalankan ulang (reproducible) dari awal kapan saja.

- Skema database terversi: menggunakan Alembic sehingga setiap perubahan struktur tercatat sebagai migration.

- Pemuatan data otomatis: menggunakan skrip Python (`load_olist.py`): CSV dimuat ke tabel staging, dikonversi tipenya, lalu dimasukkan ke tabel final. Skrip aman dijalankan berulang dan memvalidasi jumlah baris di setiap tabel.

- Analisis SQL: query didokumentasikan di folder `sql/` yang mencakup pertanyaan bisnis, definisi metrik, dan cakupan data di setiap file.

- Dashboard: dashboard Metabase yang terhubung langsung ke database (lihat bagian [Dashboard](#dashboard)).

## Pertanyaan Bisnis
> **Bagaimana tren pendapatan bulanan, dan kategori produk apa yang menyumbang paling besar?**
Untuk menjawab pertanyaan utama tersebut, analisis dibagi ke dalam dua fokus berikut:
1. Bagaimana arah pendapatan dari bulan ke bulan, kapan puncaknya, dan apakah pertumbuhannya berasal dari volume pesanan atau nilai per pesanan?
2. Kategori produk apa yang menyumbang pendapatan terbesar, dan seberapa terkonsentrasi pendapatannya?

## Temuan Utama
Cakupan analisis: 
**Januari 2017 sampai Agustus 2018** (20 bulan dengan data lengkap, mencakup 99,67% dari total pendapatan). Pendapatan dalam mata uang real Brasil (BRL) dihitung dari harga produk tanpa ongkos kirim. Alasan pembatasan periode dijelaskan di bagian [Keterbatasan Data](#keterbatasan-data).

### 1. Pertumbuhan didorong oleh volume pesanan, bukan harga

| Periode | Pendapatan | Jumlah pesanan |
|---|---|---|
| Jan sampai Agu 2017 | 3.080.851 | 22.562 |
| Jan sampai Agu 2018 | 7.341.037 | 53.530 |
| **Perubahan** | **+138,3%** | **+137,3%** |

Pendapatan dan jumlah pesanan tumbuh hampir sama besar, sementara rata-rata nilai per pesanan relatif stabil di kisaran 125 sampai 153 sepanjang 20 bulan. Artinya pertumbuhan berasal dari lebih banyaknya transaksi, bukan dari naiknya nilai belanja per transaksi.

### 2. Terdapat Dinamika Pendapatan: tumbuh pesat di 2017, lalu mendatar di 2018

- Pada tahun 2017 pendapatan naik dari 120.098 (Januari) menjadi 1.003.862 (November), sekitar 8,4 kali lipat.
- Pada puncak November 2017, 1.003.862 dari 7.421 pesanan, naik 52,1% dari Oktober, lalu turun 26,1% di Desember. Lonjakan ini bertepatan dengan **Black Friday (24 November 2017)**: pada hari itu tercatat 1.176 pesanan, sekitar 2,4 kali lipat hari tertinggi berikutnya (499 pesanan pada 25 November). Karena puncak ini didorong oleh satu peristiwa, November 2017 tidak mencerminkan tren dasar. Pendapatan Desember (742.184) dan Januari 2018 (945.456) tetap berada di atas level Oktober 2017 (660.180), sehingga level penjualan tidak kembali ke posisi sebelum puncak.
- Pada tahun 2018, pendapatan bulanan bergerak di kisaran 838 ribu sampai 994 ribu dan tidak pernah melampaui puncak November 2017.
- Periode setelah Mei 2018, jumlah pesanan turun dari 6.833 (Mei) menjadi 6.145 (Juni) dan bertahan di kisaran 6.100 sampai 6.400. Rata-rata nilai per pesanan relatif stabil, sehingga penurunan pendapatan lebih mungkin berasal dari berkurangnya jumlah transaksi.
- Terdapatpat pola dibulan Juni, pendapatan turun di Juni 2017 (-14,6%) dan Juni 2018 (-13,1%). Dengan hanya dua tahun data, ini belum cukup untuk disebut pola musiman.

<details>
<summary>Lihat tabel pendapatan per bulan (Jan 2017 sampai Agu 2018)</summary>

| Bulan | Jumlah pesanan | Pendapatan | Rata-rata per pesanan | Pertumbuhan (%) |
|---|---:|---:|---:|---:|
| 2017-01 | 787 | 120.098,27 | 152,6 | |
| 2017-02 | 1.718 | 244.959,35 | 142,6 | 104,0 |
| 2017-03 | 2.617 | 368.341,32 | 140,7 | 50,4 |
| 2017-04 | 2.377 | 353.842,98 | 148,9 | -3,9 |
| 2017-05 | 3.640 | 503.159,19 | 138,2 | 42,2 |
| 2017-06 | 3.205 | 429.916,61 | 134,1 | -14,6 |
| 2017-07 | 3.946 | 492.287,30 | 124,8 | 14,5 |
| 2017-08 | 4.272 | 568.245,79 | 133,0 | 15,4 |
| 2017-09 | 4.227 | 621.415,91 | 147,0 | 9,4 |
| 2017-10 | 4.547 | 660.179,62 | 145,2 | 6,2 |
| 2017-11 | 7.421 | 1.003.862,14 | 135,3 | 52,1 |
| 2017-12 | 5.618 | 742.183,79 | 132,1 | -26,1 |
| 2018-01 | 7.187 | 945.456,29 | 131,6 | 27,4 |
| 2018-02 | 6.624 | 837.895,43 | 126,5 | -11,4 |
| 2018-03 | 7.168 | 981.051,06 | 136,9 | 17,1 |
| 2018-04 | 6.919 | 993.592,98 | 143,6 | 1,3 |
| 2018-05 | 6.833 | 992.871,75 | 145,3 | -0,1 |
| 2018-06 | 6.145 | 863.265,53 | 140,5 | -13,1 |
| 2018-07 | 6.233 | 878.044,27 | 140,9 | 1,7 |
| 2018-08 | 6.421 | 848.860,10 | 132,2 | -3,3 |

</details>

#### Kategori pendorong lonjakan November 2017
Pendapatan naik 343.683 dari Oktober ke November 2017 (+52,1%). Kenaikan ini tersebar di banyak kategori sekaligus: sepuluh kategori teratas menyumbang 78,6% dari kenaikan, sedangkan kategori terbesar ('bed_bath_table') hanya menyumbang 12,5%.

| Kategori | Okt 2017 | Nov 2017 | Kenaikan | Kontribusi ke kenaikan | Perubahan |
|---|---:|---:|---:|---:|---:|
| bed_bath_table | 46.198,00 | 89.172,65 | 42.974,65 | 12,5% | +93,0% |
| health_beauty | 41.905,82 | 78.976,65 | 37.070,83 | 10,8% | +88,5% |
| furniture_decor | 30.189,64 | 63.011,03 | 32.821,39 | 9,5% | +108,7% |
| watches_gifts | 65.060,53 | 96.575,58 | 31.515,05 | 9,2% | +48,4% |
| toys | 34.252,21 | 64.210,99 | 29.958,78 | 8,7% | +87,5% |
| computers_accessories | 42.684,29 | 71.356,01 | 28.671,72 | 8,3% | +67,2% |
| garden_tools | 25.978,74 | 45.473,18 | 19.494,44 | 5,7% | +75,0% |
| housewares | 15.996,63 | 34.486,22 | 18.489,59 | 5,4% | +115,6% |
| perfumery | 16.894,72 | 31.831,81 | 14.937,09 | 4,3% | +88,4% |
| sports_leisure | 49.611,45 | 63.730,92 | 14.119,47 | 4,1% | +28,5% |

- Kategori perlengkapan rumah (housewares, furniture_decor, bed_bath_table) (naik paling tajam, sekitar dua kali lipat (+93% sampai +116%).
- Kolom "toys" hanya peringkat 11 dalam pendapatan keseluruhan, tetapi peringkat 5 dalam kontribusi kenaikan, sehingga tampak lebih sensitif terhadap momen belanja akhir tahun.
- Kolom watches_gifts dan sports_leisure naik di bawah rata-rata keseluruhan (+52,1%); keduanya sudah memiliki basis Oktober yang relatif tinggi.
- Kenaikan serentak di banyak kategori sejalan dengan lonjakan pesanan pada 24 November 2017 (Black Friday), yaitu 1.176 pesanan dalam satu hari. Ini menunjukkan faktor yang berlaku untuk seluruh toko, bukan tren satu kategori. Data tidak memuat detail promosi, sehingga rinciannya (diskon, kategori yang dipromosikan) tidak bisa dipastikan.

### 3. Pendapatan tersebar di banyak kategori, tidak didominasi satu kategori

| Peringkat | Kategori | Item terjual | Pendapatan | Kontribusi | Kumulatif | Rata-rata harga per item |
|---:|---|---:|---:|---:|---:|---:|
| 1 | health_beauty | 9.585 | 1.251.146 | 9,3% | 9,3% | 130,5 |
| 2 | watches_gifts | 5.965 | 1.194.825 | 8,9% | 18,2% | 200,3 |
| 3 | bed_bath_table | 11.089 | 1.035.485 | 7,7% | 25,9% | 93,4 |
| 4 | sports_leisure | 8.573 | 977.729 | 7,3% | 33,2% | 114,0 |
| 5 | computers_accessories | 7.760 | 902.923 | 6,7% | 39,9% | 116,4 |
| 6 | furniture_decor | 8.229 | 721.584 | 5,4% | 45,2% | 87,7 |
| 7 | housewares | 6.903 | 625.539 | 4,7% | 49,9% | 90,6 |
| 8 | cool_stuff | 3.772 | 619.724 | 4,6% | 54,5% | 164,3 |
| 9 | auto | 4.195 | 585.177 | 4,4% | 58,8% | 139,5 |
| 10 | garden_tools | 4.323 | 479.650 | 3,6% | 62,4% | 111,0 |

- **Kategori terbesar hanya menyumbang 9,3%,** terdapat lima kategori teratas menyumbang 39,9%, sepuluh teratas 62,4%, dan tujuh kategori teratas hampir tepat separuh (49,9%). Prinsip 80/20 tidak terlalu kuat di sini: dibutuhkan 15 kategori untuk mencapai 76,3%.
- **Peringkat volume dan peringkat pendapatan berbeda.** "bed_bath_table" paling banyak terjual (11.089 item) tetapi hanya peringkat 3 dalam pendapatan, sedangkan "watches_gifts" peringkat 2 dalam pendapatan dengan hanya 5.965 item karena harga rata-ratanya sekitar dua kali lipat (200,3 berbanding 93,4).
- Kategori berharga tinggi dengan volume kecil, seperti "cool_stuff" (164,3) dan "office_furniture" (161,7), efisien dari sisi pendapatan per item. Sebaliknya "telephony" (71,3) volumenya cukup besar tetapi kontribusinya hanya 2,4%.

**Catatan:** penyebab di balik pola-pola di atas (misalnya faktor promosi atau musiman) adalah dugaan. Data hanya menunjukkan apa yang terjadi bukan mengapa, sehingga diperlukan data tambahan atau analisis lanjutan untuk memastikannya.

## Dashboard

Dashboard dibuat dengan Metabase yang terhubung langsung ke database PostgreSQL. Isinya tiga kartu ringkasan, tren pendapatan bulanan, lonjakan pesanan harian pada Black Friday 2017, kenaikan pendapatan per kategori, serta kategori teratas dan rata-rata harga per item. Query untuk setiap visual ada di `sql/03_dashboard.sql`.

<img src="dashboard/dashboard.png" alt="Dashboard penjualan Olist" width="900">

## Dataset

Sumber: *Brazilian E-Commerce Public Dataset by Olist* (Kaggle), berisi data pesanan e-commerce di Brasil dari September 2016 sampai Oktober 2018. Lisensi dan ketentuan penggunaan dataset mengikuti halaman dataset di Kaggle; periksa ketentuan tersebut sebelum memakainya di luar keperluan belajar atau portofolio.

| Tabel di database | File CSV | Isi |
|---|---|---|
| `olist_customers` | olist_customers_dataset.csv | Data pelanggan dan lokasi |
| `olist_orders` | olist_orders_dataset.csv | Pesanan, status, dan tanggal |
| `olist_order_items` | olist_order_items_dataset.csv | Item per pesanan, harga, ongkos kirim |
| `olist_order_payments` | olist_order_payments_dataset.csv | Pembayaran per pesanan |
| `olist_order_reviews` | olist_order_reviews_dataset.csv | Ulasan dan skor pelanggan |
| `olist_products` | olist_products_dataset.csv | Data produk dan kategori |
| `olist_sellers` | olist_sellers_dataset.csv | Data penjual |
| `olist_geolocation` | olist_geolocation_dataset.csv | Koordinat berdasarkan kode pos |
| `product_category_name_translation` | product_category_name_translation.csv | Terjemahan nama kategori ke bahasa Inggris |

Total **99.441 pesanan** dari 4 September 2016 sampai 17 Oktober 2018. File CSV tidak disertakan di repository ini (lihat `.gitignore`); unduh dari Kaggle dan letakkan di folder `data/`.

## Struktur Database

Relasi antar tabel (garis lurus adalah foreign key; garis putus-putus adalah hubungan logis yang sengaja tidak dibuat sebagai foreign key):

```mermaid
erDiagram
  olist_customers ||--o{ olist_orders : places
  olist_orders ||--o{ olist_order_items : contains
  olist_orders ||--o{ olist_order_payments : "paid by"
  olist_orders ||--o{ olist_order_reviews : "reviewed in"
  olist_products ||--o{ olist_order_items : "sold in"
  olist_sellers ||--o{ olist_order_items : sells
  olist_products }o..o| product_category_name_translation : "category name"
  olist_customers }o..o{ olist_geolocation : "zip prefix"
  olist_sellers }o..o{ olist_geolocation : "zip prefix"
  olist_customers {
    char customer_id PK
    char customer_unique_id
    char customer_zip_code_prefix
    char customer_state
  }
  olist_orders {
    char order_id PK
    char customer_id FK
    varchar order_status
    timestamp order_purchase_timestamp
  }
  olist_order_items {
    char order_id PK
    int order_item_id PK
    char product_id FK
    char seller_id FK
    numeric price
  }
  olist_order_payments {
    char order_id PK
    int payment_sequential PK
    varchar payment_type
    numeric payment_value
  }
  olist_order_reviews {
    int id PK
    char review_id
    char order_id FK
    int review_score
  }
  olist_products {
    char product_id PK
    varchar product_category_name
    int product_weight_g
  }
  olist_sellers {
    char seller_id PK
    char seller_zip_code_prefix
    char seller_state
  }
  product_category_name_translation {
    varchar product_category_name PK
    varchar product_category_name_english
  }
  olist_geolocation {
    bigint id PK
    char geolocation_zip_code_prefix
    float geolocation_lat
    float geolocation_lng
  }
```

Keputusan desain yang perlu diketahui:

- Table olist_order_reviews dan olist_geolocation memakai id sendiri sebagai primary key, karena kolom review_id tidak unik di data asli dan satu kode pos punya banyak baris koordinat.
- Tidak ada foreign key ke tabel olist_geolocation dan ke tabel terjemahan kategori, karena kode pos tidak unik di geolocation dan sebagian kategori produk tidak punya terjemahan. Tabel-tabel ini dihubungkan lewat JOIN biasa (LEFT JOIN untuk terjemahan).
- Kolom product_name_lenght dan product_description_lenght di CSV asli (typo dari sumber data) diperbaiki menjadi product_name_length dan product_description_length di database.
- Kode pos disimpan sebagai CHAR(5) agar angka nol di depan (misalnya 01037) tidak hilang.

## Metodologi dan Keputusan Analisis

- **Definisi pendapatan:** SUM(price) dari olist_order_items, yaitu nilai penjualan produk tanpa ongkos kirim.
- **Pesanan yang dikeluarkan:** status CANCELED dan UNAVAIABLE, karena tidak menghasilkan pendapatan.
- **Tidak menggabungkan tabel order_items dengan order_payments dalam satu query.** Satu pesanan bisa memiliki beberapa baris pembayaran, sehingga kolom "price" akan terhitung berkali-kali dan pendapatan menjadi membengkak.
- **Pertumbuhan bulanan** dihitung dengan window function LAG(). Filter periode ditaruh di SELECT akhir (bukan di dalam CTE) supaya bulan pertama tidak dibandingkan dengan bulan di luar cakupan.
- **Nama kategori** diterjemahkan lewat LEFT JOIN ke tabel terjemahan. Produk tanpa kategori atau tanpa terjemahan tetap dihitung dengan label "tidak_diketahui" atau nama aslinya.
- **Identifikasi pelanggan:** kolom customer_id dibuat baru untuk setiap pesanan. Untuk mengenali pelanggan yang sama, menngunakan kolom customer_unique_id.

## Keterbatasan Data

- **Data awal sangat sedikit.** September sampai Desember 2016 hanya berisi 2, 290, dan 1 pesanan, dan November 2016 tidak memiliki data sama sekali. Bulan-bulan ini dikeluarkan dari analisis tren.
- **Data akhir tidak lengkap.** Pada september 2018 berisi 15 pesanan canceled dan 1 shipped lalu, Oktober 2018 hanya 4 pesanan canceled. Bulan-bulan ini dikeluarkan karena tidak mewakili aktivitas penuh.
- **Pertumbuhan persentase di awal periode tidak bermakna** (misalnya lonjakan ribuan persen di Januari 2017 jika dibandingkan dengan Desember 2016), karena basisnya sangat kecil. Karena itu pertumbuhan bulanan dihitung mulai Februari 2017.
- **Hanya dua tahun data** (dan baru 20 bulan penuh), sehingga pola musiman belum bisa disimpulkan.
- **Pendapatan tidak mencakup ongkos kirim**, dan "item terjual" menghitung item, bukan pesanan.
- **Analisis bersifat deskriptif.** Data memuat kapan perubahan terjadi, tetapi tidak memuat penyebabnya. Lonjakan November 2017 bertepatan dengan Black Friday, namun detail promosi dan faktor lain tidak tersedia, dan data tidak mencakup Black Friday 2018 sebagai pembanding.

## Struktur Proyek

```
olist-sales-analysis/
├── README.md                                       (dokumentasi proyek)
├── requirements.txt                                (daftar library Python yang dibutuhkan)
├── .gitignore                                      (file dan folder yang tidak diunggah ke Git)
├── alembic.ini                                     (konfigurasi Alembic)
├── load_olist.py                                   (memuat 9 file CSV ke PostgreSQL dan memvalidasi jumlah baris)
├── migrations/                                     (riwayat perubahan skema database)
│   ├── env.py                                      (pengaturan koneksi Alembic ke database)
│   └── versions/
│       ├── 0001_create_olist_sellers.py            (tabel penjual)
│       ├── 0002_add_state_index.py                 (index kolom state pada tabel penjual)
│       ├── 0003_create_sellers_per_state_view.py   (view jumlah penjual per state)
│       └── 0004_create_remaining_olist_tables.py   (tabel lainnya: pelanggan, produk, pesanan, dan seterusnya)
├── sql/
│   ├── 01_data_quality.sql                         (pengecekan kualitas data)
│   ├── 02_sales.sql                                (tren pendapatan bulanan dan analisis kategori)
│   └── 03_dashboard.sql                            (query untuk setiap visual di dashboard)
├── docs/
│   └── erd.png                                     (diagram relasi tabel)
├── dashboard/
│   └── dashboard.png                               (screenshot dashboard Metabase)
└── data/                                           (file CSV dari Kaggle, tidak di-commit)
```

## Cara Menjalankan
### Prasyarat
- Python 3.10 atau lebih baru
- PostgreSQL (dengan pgAdmin atau psql)
- Dataset Olist dari Kaggle

### Langkah (Windows PowerShell)
**1. Unduh proyek dan siapkan environment Python**
```powershell
git clone https://github.com/srhtbgg13/olist-sales-analysis.git
cd olist-sales-analysis
python -m venv venv
venv\Scripts\Activate.ps1
pip install -r requirements.txt
```
Jika muncul error *execution policy* saat mengaktifkan venv, jalankan sekali:
`Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

**2. Buat database kosong bernama `olist`**

Lewat pgAdmin (klik kanan *Databases* → *Create* → *Database*) atau lewat SQL:
```sql
CREATE DATABASE olist;
```

**3. Letakkan file CSV di folder `data/`** (sembilan file dari Kaggle).

**4. Atur koneksi database**

Alamat koneksi dibaca dari environment variable `DATABASE_URL` sehingga password tidak tersimpan di dalam kode. Fungsi `EscapeDataString` menangani password yang mengandung karakter khusus seperti `@` atau `#`.

```powershell
$pw = [uri]::EscapeDataString('PASSWORD_ANDA')
$env:DATABASE_URL = "postgresql+psycopg2://postgres:${pw}@localhost:5432/olist"
```

Di macOS atau Linux:
```bash
export DATABASE_URL="postgresql+psycopg2://postgres:PASSWORD@localhost:5432/olist"
```
Variabel ini hanya berlaku di jendela terminal yang sama, jadi ulangi langkah ini setiap membuka terminal baru.

**5. Buat struktur tabel**

```powershell
alembic upgrade head
```
Hasil yang diharapkan: empat baris `Running upgrade ...` (0001 sampai 0004).

**6. Muat data**

```powershell
python load_olist.py
```
Skrip menampilkan jumlah baris CSV dan jumlah baris di tabel untuk setiap file, lalu menyatakan semua tabel cocok. Pemuatan tabel `olist_geolocation` (sekitar 1 juta baris) bisa memakan waktu beberapa menit. Skrip aman dijalankan ulang tanpa menggandakan data.

**7. Jalankan analisis**

Buka file di folder `sql/` lewat pgAdmin Query Tool (blok satu query, lalu tekan F5), atau dari terminal:

```powershell
psql -U postgres -d olist -f sql/02_sales.sql
```

Perintah `psql` hanya bisa dipakai jika folder `bin` PostgreSQL sudah ada di PATH. Jika belum, gunakan pgAdmin.

**8. (Opsional) Buat dashboard di Metabase**

Jalankan Metabase dari folder terpisah di luar proyek ini (`java -jar metabase.jar`), buka `http://localhost:3000`, lalu tambahkan database PostgreSQL `olist` lewat Admin → Databases. Setiap visual dibuat dari satu query di `sql/03_dashboard.sql` (New → SQL query, pilih database `olist`, lalu simpan ke dashboard).

## Pengembangan Lanjutan

Pertanyaan bisnis lain yang bisa dijawab dengan database yang sama:
- **Pengiriman:** berapa persen pesanan terlambat, dan apakah keterlambatan menurunkan skor review?
- **Seller:** apakah penjualan terkonsentrasi pada segelintir seller atau state tertentu?
- **Pelanggan:** berapa persen pelanggan yang membeli lebih dari sekali (berdasarkan `customer_unique_id`)?

## Tentang Pembuat
Dibuat oleh **Sarah** sebagai proyek portofolio di bidang data analytics.
- GitHub: [github.com/srhtbgg13](https://github.com/srhtbgg13)
- Email: [sarahtbg@gmail.com](mailto:sarahtbg@gmail.com)

## Kredit
Dataset: *Brazilian E-Commerce Public Dataset by Olist*, tersedia di Kaggle.
