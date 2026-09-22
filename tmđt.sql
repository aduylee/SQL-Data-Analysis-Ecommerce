-- 1. Tạo cơ sở dữ liệu mới có tên ThuongMaiDienTu
CREATE DATABASE ThuongMaiDienTu;
GO

-- 2. Chuyển sang sử dụng cơ sở dữ liệu vừa tạo
USE ThuongMaiDienTu;
GO

-- 3. Tạo bảng KhachHang (Customers)
CREATE TABLE KhachHang (
    MaKH INT PRIMARY KEY,
    HoTen NVARCHAR(100),
    ThanhPho NVARCHAR(50),
    NgayDangKy DATE
);

-- 4. Tạo bảng DonHang (Orders)
CREATE TABLE DonHang (
    MaDH INT PRIMARY KEY,
    MaKH INT,
    NgayDat DATE,
    TongTien DECIMAL(18, 2),
    FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH)
);

-- 5. Chèn dữ liệu mẫu vào bảng KhachHang
INSERT INTO KhachHang VALUES 
(1, N'Nguyễn Văn An', N'Hà Nội', '2025-01-15'),
(2, N'Trần Thị Bích', N'TP. Hồ Chí Minh', '2025-02-20'),
(3, N'Lê Hoàng Nam', N'Đà Nẵng', '2025-03-10'),
(4, N'Phạm Minh Anh', N'Hà Nội', '2025-04-05');

-- 6. Chèn dữ liệu mẫu vào bảng DonHang
INSERT INTO DonHang VALUES 
(101, 1, '2026-01-10', 1500000),
(102, 1, '2026-02-15', 2300000),
(103, 2, '2026-02-18', 5000000),
(104, 3, '2026-03-01', 800000);
GO