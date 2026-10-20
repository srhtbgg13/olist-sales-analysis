/*
Proyek     : Analisis Penjualan E-Commerce Olist                             
Pertanyaan : Bagaimana tren pendapatan bulanan, dan kategori apa yang        
             menyumbang pendapatan paling besar?

Definisi   : pendapatan = SUM(price) dari olist_order_items
             (harga produk, tanpa ongkos kirim)
Filter     : pesanan berstatus 'canceled' dan 'unavailable' dikeluarkan
Cakupan    : Januari 2017 - Agustus 2018. Bulan di luar rentang ini datanya
             sangat sedikit atau tidak lengkap (lihat bagian 1).

Cara pakai : jalankan satu query per kali. Di pgAdmin, blok satu query lalu
             tekan F5 (kalau tidak diblok, hanya hasil query terakhir yang
             tampil).
*/


-- 1. EKSPLORASI DATA
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
Pertanyaan : Bagaimana sebaran status pesanan?
Tabel      : olist_orders
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
Catatan    : hampir semua pesanan di bulan-bulan ini dibatalkan, sehingga
             bulan tersebut dikeluarkan dari analisis tren.
*/
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS bulan,
    order_status,
    COUNT(*) AS jumlah
FROM olist_orders
WHERE order_purchase_timestamp >= '2018-09-01'
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- 2. TREN PENDAPATAN BULANAN
/*
Pertanyaan : Bagaimana tren pendapatan bulanan?
Tabel      : olist_orders, olist_order_items
Catatan    : filter periode ditaruh di SELECT akhir (bukan di dalam CTE)
             supaya LAG() untuk bulan pertama kosong, bukan dibandingkan
             dengan bulan di luar cakupan.
*/
WITH bulanan AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS bulan,
        COUNT(DISTINCT o.order_id) AS jumlah_pesanan,
        SUM(oi.price) AS pendapatan
    FROM olist_orders o
    JOIN olist_order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1
)
SELECT
    bulan,
    jumlah_pesanan,
    ROUND(pendapatan, 2) AS pendapatan,
    ROUND(pendapatan / jumlah_pesanan, 1) AS rata_rata_per_pesanan,
    ROUND(100.0 * (pendapatan - LAG(pendapatan) OVER (ORDER BY bulan))
          / NULLIF(LAG(pendapatan) OVER (ORDER BY bulan), 0), 1) AS pertumbuhan_persen
FROM bulanan
WHERE bulan BETWEEN '2017-01-01' AND '2018-08-01'
ORDER BY bulan;


-- 3. KATEGORI PENYUMBANG PENDAPATAN TERBESAR
/*
Pertanyaan : Kategori produk apa yang menyumbang pendapatan terbesar?
Tabel      : olist_order_items, olist_orders, olist_products,
             product_category_name_translation
Catatan    : LEFT JOIN ke tabel terjemahan karena tidak semua kategori punya
             terjemahan. Produk tanpa kategori diberi label 'tidak_diketahui'.
*/
WITH kategori AS (
    SELECT
        COALESCE(t.product_category_name_english,
                 pr.product_category_name, 'tidak_diketahui') AS kategori,
        COUNT(*) AS item_terjual,
        SUM(oi.price) AS pendapatan
    FROM olist_order_items oi
    JOIN olist_orders o    ON o.order_id = oi.order_id
    JOIN olist_products pr ON pr.product_id = oi.product_id
    LEFT JOIN product_category_name_translation t
           ON t.product_category_name = pr.product_category_name
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY 1
)
SELECT
    kategori,
    item_terjual,
    ROUND(pendapatan, 2) AS pendapatan,
    ROUND(pendapatan / item_terjual, 1) AS rata_rata_harga,
    ROUND(100.0 * pendapatan / SUM(pendapatan) OVER (), 1) AS persen_total,
    ROUND(100.0 * SUM(pendapatan) OVER (ORDER BY pendapatan DESC)
          / SUM(pendapatan) OVER (), 1) AS persen_kumulatif
FROM kategori
ORDER BY pendapatan DESC
LIMIT 15;

-- 4. ANALISIS LANJUTAN: LONJAKAN NOVEMBER 2017
/*
Pertanyaan : Pada hari apa pesanan November 2017 paling banyak?
Tabel      : olist_orders
Catatan    : untuk memeriksa dugaan efek Black Friday (24 November 2017).
*/
SELECT
    order_purchase_timestamp::date AS tanggal,
    COUNT(*) AS jumlah_pesanan
FROM olist_orders
WHERE order_purchase_timestamp >= '2017-11-01'
  AND order_purchase_timestamp <  '2017-12-01'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;


/*
Pertanyaan : Kategori apa yang paling mendorong kenaikan dari Oktober ke
             November 2017?
Tabel      : olist_order_items, olist_orders, olist_products,
             product_category_name_translation
*/
WITH k AS (
    SELECT
        COALESCE(t.product_category_name_english,
                 pr.product_category_name, 'tidak_diketahui') AS kategori,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS bulan,
        SUM(oi.price) AS pendapatan
    FROM olist_order_items oi
    JOIN olist_orders o    ON o.order_id = oi.order_id
    JOIN olist_products pr ON pr.product_id = oi.product_id
    LEFT JOIN product_category_name_translation t
           ON t.product_category_name = pr.product_category_name
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
      AND o.order_purchase_timestamp >= '2017-10-01'
      AND o.order_purchase_timestamp <  '2017-12-01'
    GROUP BY 1, 2
)
SELECT
    kategori,
    ROUND(SUM(pendapatan) FILTER (WHERE bulan = '2017-10-01'), 2) AS okt_2017,
    ROUND(SUM(pendapatan) FILTER (WHERE bulan = '2017-11-01'), 2) AS nov_2017,
    ROUND(COALESCE(SUM(pendapatan) FILTER (WHERE bulan = '2017-11-01'), 0)
        - COALESCE(SUM(pendapatan) FILTER (WHERE bulan = '2017-10-01'), 0), 2) AS selisih
FROM k
GROUP BY kategori
ORDER BY selisih DESC
LIMIT 10;