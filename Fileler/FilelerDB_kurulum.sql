/* =====================================================================
   FilelerDB - Kurulum Scripti
   Halı saha rezervasyon sitesi

   Nasıl çalıştırılır:
   1) SSMS'de localhost\SQLEXPRESS'e bağlan
   2) File > Open > File ile bu dosyayı aç
   3) Execute (F5)

   Güvenli: Tekrar çalıştırılabilir. Var olan veritabanını, tabloları
   veya veriyi SİLMEZ. Olmayanı oluşturur, örnek veriyi sadece tablolar
   boşsa ekler.
   ===================================================================== */

-- 1) Veritabanı ---------------------------------------------------------
IF DB_ID(N'FilelerDB') IS NULL
    CREATE DATABASE FilelerDB;
GO

USE FilelerDB;
GO

-- 2) Tablolar (bağımlılık sırasına göre) --------------------------------
IF OBJECT_ID(N'dbo.Facilities', N'U') IS NULL
CREATE TABLE dbo.Facilities (
    Id      INT IDENTITY(1,1) PRIMARY KEY,
    Name    NVARCHAR(100) NOT NULL,
    City    NVARCHAR(50)  NOT NULL,
    Address NVARCHAR(250) NULL
);
GO

IF OBJECT_ID(N'dbo.Fields', N'U') IS NULL
CREATE TABLE dbo.Fields (
    Id         INT IDENTITY(1,1) PRIMARY KEY,
    FacilityId INT NOT NULL
        FOREIGN KEY REFERENCES dbo.Facilities(Id),
    Name       NVARCHAR(50) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
CREATE TABLE dbo.Users (
    Id           INT IDENTITY(1,1) PRIMARY KEY,
    FullName     NVARCHAR(100) NOT NULL,
    Email        NVARCHAR(150) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,   -- Şifre düz metin SAKLANMAZ, hash'lenmiş gelir
    Phone        NVARCHAR(20)  NULL,
    CreatedAt    DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID(N'dbo.TimeSlots', N'U') IS NULL
CREATE TABLE dbo.TimeSlots (
    Id        INT IDENTITY(1,1) PRIMARY KEY,
    FieldId   INT NOT NULL
        FOREIGN KEY REFERENCES dbo.Fields(Id),
    StartTime TIME NOT NULL,
    EndTime   TIME NOT NULL,
    Price     DECIMAL(10,2) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.Reservations', N'U') IS NULL
CREATE TABLE dbo.Reservations (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    UserId          INT NOT NULL
        FOREIGN KEY REFERENCES dbo.Users(Id),
    TimeSlotId      INT NOT NULL
        FOREIGN KEY REFERENCES dbo.TimeSlots(Id),
    ReservationDate DATE NOT NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    -- Aynı saat dilimi aynı tarihte iki kez alınamaz (çifte rezervasyon koruması).
    -- İhlalde SQL Server 2627 hatası döner; uygulama bu hatayı yakalamalı.
    CONSTRAINT UQ_Reservation_Slot_Date UNIQUE (TimeSlotId, ReservationDate)
);
GO

-- 3) İndeksler (Foreign Key sütunları için) ------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = N'IX_Fields_FacilityId' AND object_id = OBJECT_ID(N'dbo.Fields'))
    CREATE INDEX IX_Fields_FacilityId ON dbo.Fields(FacilityId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = N'IX_TimeSlots_FieldId' AND object_id = OBJECT_ID(N'dbo.TimeSlots'))
    CREATE INDEX IX_TimeSlots_FieldId ON dbo.TimeSlots(FieldId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = N'IX_Reservations_UserId' AND object_id = OBJECT_ID(N'dbo.Reservations'))
    CREATE INDEX IX_Reservations_UserId ON dbo.Reservations(UserId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = N'IX_Facilities_City' AND object_id = OBJECT_ID(N'dbo.Facilities'))
    CREATE INDEX IX_Facilities_City ON dbo.Facilities(City);
GO

-- 4) Örnek veri (Seed Data) - sadece Facilities boşsa eklenir -------------
-- Bağlantılar Id ile değil isim/e-posta ile kurulur, bu yüzden IDENTITY
-- sayacı kaç olursa olsun çalışır.
-- Özet: 5 tesis, 10 saha, 30 saat dilimi, 10 kullanıcı, 12 rezervasyon.
IF NOT EXISTS (SELECT 1 FROM dbo.Facilities)
BEGIN
    -- Tesisler
    INSERT INTO dbo.Facilities (Name, City, Address) VALUES
    (N'Yıldız Halı Saha',      N'İzmir',    N'Bornova, Örnek Mah. 123 Sok.'),
    (N'Arena Spor Tesisleri',  N'İzmir',    N'Karşıyaka, Test Cad. No:45'),
    (N'Gol Park Halı Saha',    N'İzmir',    N'Buca, Deneme Mah. 7. Sok. No:12'),
    (N'Şampiyon Halı Saha',    N'Ankara',   N'Çankaya, Örnek Cad. No:88'),
    (N'Kale Spor Kompleksi',   N'İstanbul', N'Kadıköy, Test Sok. No:21');

    -- Sahalar (her tesiste 2 saha)
    INSERT INTO dbo.Fields (FacilityId, Name)
    SELECT f.Id, v.FieldName
    FROM (VALUES
        (N'Yıldız Halı Saha',     N'Saha 1'),
        (N'Yıldız Halı Saha',     N'Saha 2'),
        (N'Arena Spor Tesisleri', N'Ana Saha'),
        (N'Arena Spor Tesisleri', N'Saha B'),
        (N'Gol Park Halı Saha',   N'Saha 1'),
        (N'Gol Park Halı Saha',   N'Saha 2'),
        (N'Şampiyon Halı Saha',   N'Saha 1'),
        (N'Şampiyon Halı Saha',   N'Saha 2'),
        (N'Kale Spor Kompleksi',  N'Saha A'),
        (N'Kale Spor Kompleksi',  N'Saha B')
    ) v(FacilityName, FieldName)
    JOIN dbo.Facilities f ON f.Name = v.FacilityName;

    -- Saat dilimleri: her sahaya 18-19, 19-20, 20-21 (saha başına sabit fiyat)
    INSERT INTO dbo.TimeSlots (FieldId, StartTime, EndTime, Price)
    SELECT fl.Id, t.StartTime, t.EndTime, p.Price
    FROM (VALUES
        (N'Yıldız Halı Saha',     N'Saha 1',   800),
        (N'Yıldız Halı Saha',     N'Saha 2',   850),
        (N'Arena Spor Tesisleri', N'Ana Saha', 1000),
        (N'Arena Spor Tesisleri', N'Saha B',   900),
        (N'Gol Park Halı Saha',   N'Saha 1',   700),
        (N'Gol Park Halı Saha',   N'Saha 2',   700),
        (N'Şampiyon Halı Saha',   N'Saha 1',   900),
        (N'Şampiyon Halı Saha',   N'Saha 2',   900),
        (N'Kale Spor Kompleksi',  N'Saha A',   1100),
        (N'Kale Spor Kompleksi',  N'Saha B',   1000)
    ) p(FacilityName, FieldName, Price)
    JOIN dbo.Facilities f ON f.Name = p.FacilityName
    JOIN dbo.Fields fl    ON fl.FacilityId = f.Id AND fl.Name = p.FieldName
    CROSS JOIN (VALUES
        ('18:00', '19:00'),
        ('19:00', '20:00'),
        ('20:00', '21:00')
    ) t(StartTime, EndTime);

    -- Kullanıcılar (PasswordHash sahte, gerçek hash'i MVC tarafı üretecek)
    INSERT INTO dbo.Users (FullName, Email, PasswordHash, Phone) VALUES
    (N'Ali Yılmaz',    'ali.yilmaz@mail.com',    'HASH_ORNEK_01', '05550000001'),
    (N'Ayşe Kaya',     'ayse.kaya@mail.com',     'HASH_ORNEK_02', '05550000002'),
    (N'Mehmet Demir',  'mehmet.demir@mail.com',  'HASH_ORNEK_03', '05550000003'),
    (N'Fatma Çelik',   'fatma.celik@mail.com',   'HASH_ORNEK_04', '05550000004'),
    (N'Emre Şahin',    'emre.sahin@mail.com',    'HASH_ORNEK_05', '05550000005'),
    (N'Zeynep Aydın',  'zeynep.aydin@mail.com',  'HASH_ORNEK_06', '05550000006'),
    (N'Burak Öztürk',  'burak.ozturk@mail.com',  'HASH_ORNEK_07', '05550000007'),
    (N'Elif Arslan',   'elif.arslan@mail.com',   'HASH_ORNEK_08', '05550000008'),
    (N'Can Doğan',     'can.dogan@mail.com',     'HASH_ORNEK_09', '05550000009'),
    (N'Selin Kurt',    'selin.kurt@mail.com',    'HASH_ORNEK_10', '05550000010');

    -- Rezervasyonlar (aynı saat dilimi + aynı tarih ikinci kez eklenmemeli)
    INSERT INTO dbo.Reservations (UserId, TimeSlotId, ReservationDate)
    SELECT u.Id, ts.Id, CAST(r.ResDate AS DATE)
    FROM (VALUES
        ('ali.yilmaz@mail.com',   N'Yıldız Halı Saha',     N'Saha 1',   '18:00', '2026-10-20'),
        ('ayse.kaya@mail.com',    N'Yıldız Halı Saha',     N'Saha 1',   '19:00', '2026-10-20'),
        ('mehmet.demir@mail.com', N'Yıldız Halı Saha',     N'Saha 2',   '20:00', '2026-10-20'),
        ('fatma.celik@mail.com',  N'Arena Spor Tesisleri', N'Ana Saha', '19:00', '2026-10-21'),
        ('emre.sahin@mail.com',   N'Arena Spor Tesisleri', N'Ana Saha', '20:00', '2026-10-21'),
        ('zeynep.aydin@mail.com', N'Arena Spor Tesisleri', N'Saha B',   '18:00', '2026-10-21'),
        ('burak.ozturk@mail.com', N'Gol Park Halı Saha',   N'Saha 1',   '19:00', '2026-10-22'),
        ('elif.arslan@mail.com',  N'Gol Park Halı Saha',   N'Saha 2',   '20:00', '2026-10-22'),
        ('can.dogan@mail.com',    N'Şampiyon Halı Saha',   N'Saha 1',   '18:00', '2026-10-22'),
        ('selin.kurt@mail.com',   N'Şampiyon Halı Saha',   N'Saha 2',   '19:00', '2026-10-23'),
        ('ali.yilmaz@mail.com',   N'Kale Spor Kompleksi',  N'Saha A',   '20:00', '2026-10-23'),
        ('ayse.kaya@mail.com',    N'Kale Spor Kompleksi',  N'Saha B',   '19:00', '2026-10-23')
    ) r(Email, FacilityName, FieldName, StartTime, ResDate)
    JOIN dbo.Users u      ON u.Email = r.Email
    JOIN dbo.Facilities f ON f.Name  = r.FacilityName
    JOIN dbo.Fields fl    ON fl.FacilityId = f.Id AND fl.Name = r.FieldName
    JOIN dbo.TimeSlots ts ON ts.FieldId = fl.Id AND ts.StartTime = CAST(r.StartTime AS TIME);
END
GO

-- 5) Kontrol --------------------------------------------------------------
SELECT f.Name AS Tesis, fl.Name AS Saha, ts.StartTime, ts.EndTime,
       u.FullName, r.ReservationDate
FROM dbo.Reservations r
JOIN dbo.Users u       ON u.Id  = r.UserId
JOIN dbo.TimeSlots ts  ON ts.Id = r.TimeSlotId
JOIN dbo.Fields fl     ON fl.Id = ts.FieldId
JOIN dbo.Facilities f  ON f.Id  = fl.FacilityId;
GO
