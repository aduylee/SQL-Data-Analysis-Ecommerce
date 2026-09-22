-- ============================================================================
-- DỰ ÁN PHÂN TÍCH DỮ LIỆU THƯƠNG MẠI ĐIỆN TỬ & TỐI ƯU HÓA TRUY VẤN (SQL SERVER)
-- Tác giả: [aduylee]
-- Công cụ: SQL Server Express / SSMS
-- ============================================================================

USE ThuongMaiDienTu;
GO

-- ----------------------------------------------------------------------------
-- PHẦN 1: CHUẨN BỊ VÀ CẬP NHẬT DỮ LIỆU THỰC HÀNH
-- ----------------------------------------------------------------------------

-- Bổ sung đơn hàng để có đủ dữ liệu tính toán Retention & Chuỗi thời gian
INSERT INTO DonHang VALUES 
(109, 1, '2026-03-20', 3100000),
(110, 2, '2026-03-25', 1800000),
(111, 4, '2026-03-28', 2900000);
GO


-- ----------------------------------------------------------------------------
-- PHẦN 2: BÁO CÁO PHÂN TÍCH DOANH THƯ & THƯƠNG HIỆU (BUSINESS ANALYTICS)
-- ----------------------------------------------------------------------------

-- Yêu cầu 1: Báo cáo Doanh thu theo tháng & Tỷ lệ tăng trưởng MoM (Month-over-Month)
WITH DoanhThuThang AS (
    SELECT 
        YEAR(NgayDat) AS Nam,
        MONTH(NgayDat) AS Thang,
        SUM(TongTien) AS DoanhThu
    FROM DonHang
    GROUP BY YEAR(NgayDat), MONTH(NgayDat)
),
SoSanhCungKy AS (
    SELECT 
        Nam,
        Thang,
        DoanhThu,
        LAG(DoanhThu, 1) OVER (ORDER BY Nam, Thang) AS DoanhThuThangTruoc
    FROM DoanhThuThang
)
SELECT 
    Nam,
    Thang,
    DoanhThu,
    ISNULL(DoanhThuThangTruoc, 0) AS DoanhThuThangTruoc,
    CASE 
        WHEN DoanhThuThangTruoc IS NULL THEN N'N/A'
        ELSE CAST(ROUND(((DoanhThu - DoanhThuThangTruoc) * 100.0 / DoanhThuThangTruoc), 2) AS VARCHAR) + '%'
    END AS TyLeTangTruong_MoM
FROM SoSanhCungKy;
GO


-- Yêu cầu 2: Phân hạng khách hàng RFM (Recency - Frequency - Monetary)
WITH RFM_Metrics AS (
    SELECT 
        k.MaKH,
        k.HoTen,
        k.ThanhPho,
        DATEDIFF(DAY, MAX(d.NgayDat), '2026-04-01') AS Recency_SoNgayChuaMua,
        COUNT(d.MaDH) AS Frequency_SoDon,
        ISNULL(SUM(d.TongTien), 0) AS Monetary_TongChiTieu
    FROM KhachHang k
    LEFT JOIN DonHang d ON k.MaKH = d.MaKH
    GROUP BY k.MaKH, k.HoTen, k.ThanhPho
)
SELECT 
    MaKH,
    HoTen,
    ThanhPho,
    Recency_SoNgayChuaMua,
    Frequency_SoDon,
    Monetary_TongChiTieu,
    CASE 
        WHEN Monetary_TongChiTieu >= 5000000 AND Frequency_SoDon >= 2 THEN N'Khách hàng VIP'
        WHEN Monetary_TongChiTieu > 0 AND Recency_SoNgayChuaMua <= 30 THEN N'Khách hàng Active'
        WHEN Monetary_TongChiTieu > 0 AND Recency_SoNgayChuaMua > 30 THEN N'Khách hàng Churn (Nguy cơ rời bỏ)'
        ELSE N'Khách hàng Lead (Chưa mua)'
    END AS NhomKhachHang
FROM RFM_Metrics
ORDER BY Monetary_TongChiTieu DESC;
GO


-- Yêu cầu 3: Báo cáo PIVOT Doanh thu các Tháng theo từng Thành phố
SELECT 
    ThanhPho,
    ISNULL([1], 0) AS DoanhThu_Thang1,
    ISNULL([2], 0) AS DoanhThu_Thang2,
    ISNULL([3], 0) AS DoanhThu_Thang3,
    (ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0)) AS TongDoanhThu
FROM 
(
    SELECT 
        k.ThanhPho,
        MONTH(d.NgayDat) AS Thang,
        d.TongTien
    FROM DonHang d
    JOIN KhachHang k ON d.MaKH = k.MaKH
) AS SourceTable
PIVOT 
(
    SUM(TongTien)
    FOR Thang IN ([1], [2], [3])
) AS PivotTable;
GO


-- ----------------------------------------------------------------------------
-- PHẦN 3: TỐI ƯU HÓA HIỆU NĂNG TRUY VẤN (PERFORMANCE TUNING)
-- ----------------------------------------------------------------------------

-- 1. Xóa Index cũ nếu tồn tại
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DonHang_NgayDat' AND object_id = OBJECT_ID('DonHang'))
    DROP INDEX IX_DonHang_NgayDat ON DonHang;
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_KhachHang_ThanhPho' AND object_id = OBJECT_ID('KhachHang'))
    DROP INDEX IX_KhachHang_ThanhPho ON KhachHang;
GO

-- 2. Khởi tạo Non-Clustered Indexes tối ưu hóa tìm kiếm & lọc dữ liệu
CREATE NONCLUSTERED INDEX IX_DonHang_NgayDat 
ON DonHang(NgayDat) 
INCLUDE (MaKH, TongTien);
GO

CREATE NONCLUSTERED INDEX IX_KhachHang_ThanhPho 
ON KhachHang(ThanhPho) 
INCLUDE (HoTen);
GO

-- 3. Truy vấn kiểm tra Index Seek
SELECT MaKH, HoTen 
FROM KhachHang 
WHERE ThanhPho = N'Hà Nội';
GO