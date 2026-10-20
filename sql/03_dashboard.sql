/*
Proyek     : Analisis Penjualan E-Commerce Olist
File       : query untuk dashboard (satu query = satu visual)
Cakupan    : Januari 2017 - Agustus 2018
Definisi   : pendapatan = SUM(price) dari olist_order_items (tanpa ongkos kirim);
             pesanan 'canceled' dan 'unavailable' dikeluarkan.
Cara pakai : salin satu query ke satu pertanyaan (SQL query) di Metabase.
==============================================================================
*/

-- V1. KARTU RINGKASAN (KPI)
-- Visual : Number / tabel satu baris
SELECT
    ROUND(SUM(oi.price), 2) AS total_pendapatan,
    COUNT(DISTINCT o.order_id) AS jumlah_pesanan,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 1) AS rata_rata_per_pesanan
FROM olist_orders o
JOIN olist_order_items oi ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';

-- V2. TREN PENDAPATAN BULANAN
-- Visual : Line chart (X = bulan, Y = pendapatan)
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS bulan,
    ROUND(SUM(oi.price), 2) AS pendapatan,
    COUNT(DISTINCT o.order_id) AS jumlah_pesanan
FROM olist_orders o
JOIN olist_order_items oi ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY 1
ORDER BY 1;

-- V3. 10 KATEGORI DENGAN PENDAPATAN TERBESAR
-- Visual : Bar chart horizontal (X = pendapatan, Y = kategori)
WITH kategori AS (
    SELECT
        COALESCE(t.product_category_name_english,
                 pr.product_category_name, 'tidak_diketahui') AS kategori,
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
    ROUND(pendapatan, 2) AS pendapatan,
    ROUND(100.0 * pendapatan / SUM(pendapatan) OVER (), 1) AS persen_total
FROM kategori
ORDER BY pendapatan DESC
LIMIT 10;

-- V4. LONJAKAN PESANAN HARIAN, NOVEMBER 2017
-- Visual : Bar chart (X = tanggal, Y = jumlah_pesanan)
SELECT
    order_purchase_timestamp::date AS tanggal,
    COUNT(*) AS jumlah_pesanan
FROM olist_orders
WHERE order_purchase_timestamp >= '2017-11-01'
  AND order_purchase_timestamp <  '2017-12-01'
GROUP BY 1
ORDER BY 1;

-- V5. KATEGORI PENDORONG KENAIKAN OKTOBER KE NOVEMBER 2017
-- Visual : Bar chart horizontal (X = kenaikan, Y = kategori)
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
),
perbandingan AS (
    SELECT
        kategori,
        COALESCE(SUM(pendapatan) FILTER (WHERE bulan = '2017-10-01'), 0) AS okt_2017,
        COALESCE(SUM(pendapatan) FILTER (WHERE bulan = '2017-11-01'), 0) AS nov_2017
    FROM k
    GROUP BY kategori
)
SELECT
    kategori,
    ROUND(nov_2017 - okt_2017, 2) AS kenaikan,
    ROUND(100.0 * (nov_2017 - okt_2017) / SUM(nov_2017 - okt_2017) OVER (), 1) AS persen_dari_kenaikan
FROM perbandingan
ORDER BY nov_2017 - okt_2017 DESC
LIMIT 10;

-- V6. RATA-RATA HARGA PER ITEM, 15 KATEGORI TERATAS
-- Visual : Bar chart horizontal / Row (label = kategori, nilai = rata_rata_harga)
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
),
top15 AS (
    SELECT
        kategori,
        ROUND(pendapatan / item_terjual, 1) AS rata_rata_harga
    FROM kategori
    ORDER BY pendapatan DESC
    LIMIT 15
)
SELECT kategori, rata_rata_harga
FROM top15
ORDER BY rata_rata_harga DESC;