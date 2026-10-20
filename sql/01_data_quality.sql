/*
Proyek     : Analisis Penjualan E-Commerce Olist
Tujuan     : memastikan data termuat lengkap dan mengetahui keterbatasannya
             sebelum dipakai untuk analisis di 02_sales.sql.
*/

-- 1. KELENGKAPAN DATA
/*
Pertanyaan : Berapa jumlah baris di setiap tabel?
Catatan    : bandingkan dengan jumlah baris di output load_olist.py.
             olist_orders (99.441 baris dan olist_sellers 3.095)
*/
SELECT 'olist_customers' AS tabel, COUNT(*) AS jumlah_baris FROM olist_customers
UNION ALL SELECT 'olist_geolocation', COUNT(*) FROM olist_geolocation
UNION ALL SELECT 'olist_orders', COUNT(*) FROM olist_orders
UNION ALL SELECT 'olist_order_items', COUNT(*) FROM olist_order_items
UNION ALL SELECT 'olist_order_payments', COUNT(*) FROM olist_order_payments
UNION ALL SELECT 'olist_order_reviews', COUNT(*) FROM olist_order_reviews
UNION ALL SELECT 'olist_products', COUNT(*) FROM olist_products
UNION ALL SELECT 'olist_sellers', COUNT(*) FROM olist_sellers
UNION ALL SELECT 'product_category_name_translation', COUNT(*) FROM product_category_name_translation;

/*
Pertanyaan : Berapa rentang waktu data pesanan?
Tabel      : olist_orders
*/
SELECT
    MIN(order_purchase_timestamp)::date AS pertama,
    MAX(order_purchase_timestamp)::date AS terakhir,
    COUNT(*) AS total_pesanan
FROM olist_orders;

/*
Pertanyaan : Apakah ada bulan yang tidak memiliki data pesanan?
Tabel      : olist_orders
Catatan    : November 2016 tidak memiliki pesanan sama sekali, dan bulan-bulan
             di awal serta akhir data sangat sedikit. Ini dasar pembatasan
             analisis ke Januari 2017 - Agustus 2018.
*/
WITH rentang AS (
    SELECT GENERATE_SERIES(
               DATE_TRUNC('month', MIN(order_purchase_timestamp)),
               DATE_TRUNC('month', MAX(order_purchase_timestamp)),
               INTERVAL '1 month')::date AS bulan
    FROM olist_orders
),
ada AS (
    SELECT DATE_TRUNC('month', order_purchase_timestamp)::date AS bulan,
           COUNT(*) AS jumlah_pesanan
    FROM olist_orders
    GROUP BY 1
)
SELECT r.bulan, COALESCE(a.jumlah_pesanan, 0) AS jumlah_pesanan
FROM rentang r
LEFT JOIN ada a ON a.bulan = r.bulan
ORDER BY r.bulan;

-- 2. STATUS PESANAN
/*
Pertanyaan : Bagaimana sebaran status pesanan?
Tabel      : olist_orders
Catatan    : 'canceled' dan 'unavailable' tidak termasuk dalam hitungan
              pendapatan
*/
SELECT
    order_status,
    COUNT(*) AS jumlah
FROM olist_orders
GROUP BY order_status
ORDER BY jumlah DESC;

/*
Pertanyaan : Mengapa September dan Oktober 2018 hampir tanpa pendapatan?
Tabel      : olist_orders
Catatan    : hampir semua pesanan di bulan-bulan ini dibatalkan.
*/
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS bulan,
    order_status,
    COUNT(*) AS jumlah
FROM olist_orders
WHERE order_purchase_timestamp >= '2018-09-01'
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

/*
Pertanyaan : Apakah ada pesanan yang tidak memiliki item?
Tabel      : olist_orders, olist_order_items
Catatan    : pesanan tanpa item tidak menghasilkan pendapatan, sehingga tidak
             muncul di analisis yang memakai JOIN ke olist_order_items.
*/
SELECT
    o.order_status,
    COUNT(*) AS jumlah
FROM olist_orders o
LEFT JOIN olist_order_items oi ON oi.order_id = o.order_id
WHERE oi.order_id IS NULL
GROUP BY o.order_status
ORDER BY jumlah DESC;



-- 3. NILAI KOSONG
/*
Pertanyaan : Berapa banyak nilai kosong di kolom tanggal pesanan?
Tabel      : olist_orders
Catatan    : tanggal persetujuan, pengiriman, dan penerimaan wajar kosong untuk
             pesanan yang dibatalkan atau belum sampai.
*/
SELECT
    COUNT(*) AS total_pesanan,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS approved_kosong,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS dikirim_kosong,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS diterima_kosong
FROM olist_orders;

/*
Pertanyaan : Berapa banyak produk tanpa kategori?
Tabel      : olist_products
Catatan    : produk tanpa kategori dilabeli 'tidak_diketahui' di analisis.
*/
SELECT
    COUNT(*) AS total_produk,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS tanpa_kategori
FROM olist_products;

/*
Pertanyaan : Kategori produk apa yang tidak memiliki terjemahan?
Tabel      : olist_products, product_category_name_translation
Catatan    : inilah alasan tabel terjemahan dihubungkan dengan LEFT JOIN dan
             bukan foreign key.
*/
SELECT
    pr.product_category_name,
    COUNT(*) AS jumlah_produk
FROM olist_products pr
LEFT JOIN product_category_name_translation t
       ON t.product_category_name = pr.product_category_name
WHERE pr.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY pr.product_category_name
ORDER BY jumlah_produk DESC;
 
-- 4. DUPLIKAT DAN IDENTITAS
/*
Pertanyaan : Apakah review_id unik?
Tabel      : olist_order_reviews
Catatan    : review_id tidak unik di data asli (selisih lebih dari nol), karena
             itu tabel memakai kolom id sendiri sebagai primary key.
*/
SELECT
    COUNT(*) AS total_baris,
    COUNT(DISTINCT review_id) AS review_id_unik,
    COUNT(*) - COUNT(DISTINCT review_id) AS selisih
FROM olist_order_reviews;

/*
Pertanyaan : Berapa pelanggan unik dibandingkan jumlah customer_id?
Tabel      : olist_customers
Catatan    : customer_id dibuat baru untuk setiap pesanan, jadi untuk
             mengenali pelanggan yang sama gunakan customer_unique_id.
*/
SELECT
    COUNT(*) AS total_customer_id,
    COUNT(DISTINCT customer_unique_id) AS pelanggan_unik
FROM olist_customers;

-- 5. NILAI YANG TIDAK MASUK AKAL
/*
Pertanyaan : Apakah ada harga atau ongkos kirim yang tidak wajar?
Tabel      : olist_order_items
*/
SELECT
    COUNT(*) FILTER (WHERE price <= 0) AS harga_nol_atau_negatif,
    COUNT(*) FILTER (WHERE freight_value < 0) AS ongkir_negatif,
    MIN(price) AS harga_terendah,
    MAX(price) AS harga_tertinggi
FROM olist_order_items;

/*
Pertanyaan : Apakah ada urutan tanggal yang tidak logis?
Tabel      : olist_orders
Catatan    : barang tidak mungkin diterima sebelum pesanan dibuat.
*/
SELECT
    COUNT(*) FILTER (WHERE order_delivered_customer_date < order_purchase_timestamp) AS diterima_sebelum_dipesan,
    COUNT(*) FILTER (WHERE order_approved_at < order_purchase_timestamp) AS disetujui_sebelum_dipesan
FROM olist_orders;

/*
Pertanyaan : Apakah skor review berada di rentang 1 sampai 5?
Tabel      : olist_order_reviews
*/
SELECT
    review_score,
    COUNT(*) AS jumlah
FROM olist_order_reviews
GROUP BY review_score
ORDER BY review_score;

-- 6. HUBUNGAN YANG TIDAK DIJAGA FOREIGN KEY
/*
Pertanyaan : Berapa pelanggan dan penjual yang kode posnya tidak ada di
             tabel geolokasi?
Tabel      : olist_customers, olist_sellers, olist_geolocation
Catatan    : inilah alasan geolokasi dihubungkan lewat JOIN biasa bukan
             foreign key.
*/
SELECT
    (SELECT COUNT(*) FROM olist_customers c
     WHERE NOT EXISTS (SELECT 1 FROM olist_geolocation g
                       WHERE g.geolocation_zip_code_prefix = c.customer_zip_code_prefix)) AS pelanggan_tanpa_geolokasi,
    (SELECT COUNT(*) FROM olist_sellers s
     WHERE NOT EXISTS (SELECT 1 FROM olist_geolocation g
                       WHERE g.geolocation_zip_code_prefix = s.seller_zip_code_prefix)) AS penjual_tanpa_geolokasi;

/*
Pertanyaan : Apakah kode pos tetap memiliki nol di depan?
Tabel      : olist_customers
Catatan    : seluruh kode pos harus 5 karakter (contoh 01037, bukan 1037).
*/
SELECT
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE LENGTH(customer_zip_code_prefix) = 5) AS lima_karakter
FROM olist_customers;

-- 7. CAKUPAN ANALISIS
/*
Pertanyaan : Berapa persen pendapatan yang tercakup periode analisis
             (Januari 2017 - Agustus 2018)?
Tabel      : olist_orders, olist_order_items
Catatan    : dasar klaim "99,67% dari total pendapatan" di README.
*/
SELECT
    ROUND(SUM(oi.price) FILTER (
        WHERE o.order_purchase_timestamp >= '2017-01-01'
          AND o.order_purchase_timestamp <  '2018-09-01'), 2) AS pendapatan_dalam_cakupan,
    ROUND(SUM(oi.price), 2) AS pendapatan_total,
    ROUND(100.0 * SUM(oi.price) FILTER (
        WHERE o.order_purchase_timestamp >= '2017-01-01'
          AND o.order_purchase_timestamp <  '2018-09-01') / SUM(oi.price), 2) AS persen_cakupan
FROM olist_orders o
JOIN olist_order_items oi ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable');