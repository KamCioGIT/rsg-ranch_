-- ============================================================================
-- RSG-RANCH SQL SCHEMA (Optimized for 100+ Concurrent Players)
-- ============================================================================
-- Run this SQL to create/update the ranch database tables.
-- IMPORTANT: If updating existing tables, see migration section at bottom.
-- ============================================================================

-- Ranch Funds Table
CREATE TABLE IF NOT EXISTS `rsg_ranch_funds` (
  `ranchid` varchar(50) NOT NULL,
  `funds` double DEFAULT 0,
  PRIMARY KEY (`ranchid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Ranch Employees Table
CREATE TABLE IF NOT EXISTS `rsg_ranch_employees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ranchid` varchar(50) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `fullname` varchar(100) DEFAULT NULL,
  `grade` tinyint(3) unsigned DEFAULT 0,
  `hired_date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_unique_employee` (`ranchid`, `citizenid`),
  KEY `idx_citizenid` (`citizenid`),
  KEY `idx_ranchid` (`ranchid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Ranch Animals Table (Main table - most frequently accessed)
CREATE TABLE IF NOT EXISTS `rsg_ranch_animals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ranchid` varchar(50) NOT NULL,
  `animalid` bigint(20) NOT NULL,
  `model` varchar(50) NOT NULL,
  `name` varchar(50) DEFAULT NULL,
  
  -- Location
  `pos_x` float NOT NULL DEFAULT 0,
  `pos_y` float NOT NULL DEFAULT 0,
  `pos_z` float NOT NULL DEFAULT 0,
  `pos_w` float NOT NULL DEFAULT 0,
  
  -- Stats (optimized data types for memory efficiency)
  `age` smallint(5) unsigned DEFAULT 0,
  `born` int(10) unsigned NOT NULL DEFAULT 0,
  `health` tinyint(3) unsigned DEFAULT 100,
  `hunger` tinyint(3) unsigned DEFAULT 100,
  `thirst` tinyint(3) unsigned DEFAULT 100,
  
  -- Production & Growth
  `scale` decimal(6,5) DEFAULT 0.50000,
  `last_production` int(10) unsigned DEFAULT 0,
  `product_ready` tinyint(1) DEFAULT 0,
  
  -- Breeding
  `pregnant` tinyint(1) DEFAULT 0,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_unique_animalid` (`animalid`),
  KEY `idx_ranchid` (`ranchid`),
  KEY `idx_product_ready` (`product_ready`),
  KEY `idx_ranch_animals` (`ranchid`, `animalid`),
  KEY `idx_bulk_update` (`animalid`, `hunger`, `scale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Ranch Objects Table (Crafting Tables, etc.)
CREATE TABLE IF NOT EXISTS `rsg_ranch_objects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ranchid` varchar(50) NOT NULL,
  `model` varchar(50) NOT NULL,
  `coords` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_unique_ranch_object` (`ranchid`),
  KEY `idx_ranchid` (`ranchid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- INDEXES FOR HIGH-CONCURRENCY QUERIES
-- ============================================================================
-- These indexes optimize the most common queries:
-- 1. Counting animals per ranch (SELECT COUNT WHERE ranchid)
-- 2. Bulk updates by animalid list (UPDATE WHERE animalid IN (?))
-- 3. Fetching animals by ranch (SELECT WHERE ranchid)
-- ============================================================================

-- ============================================================================
-- MIGRATION SCRIPTS (Run if updating existing database)
-- ============================================================================

-- Add 'pregnant' column if missing
-- ALTER TABLE `rsg_ranch_animals` ADD COLUMN IF NOT EXISTS `pregnant` tinyint(1) DEFAULT 0;

-- Change animalid from varchar to bigint for better performance
-- ALTER TABLE `rsg_ranch_animals` MODIFY COLUMN `animalid` bigint(20) NOT NULL;

-- Add composite index for bulk operations
-- ALTER TABLE `rsg_ranch_animals` ADD INDEX IF NOT EXISTS `idx_bulk_update` (`animalid`, `hunger`, `scale`);

-- Reset animals to baby size (run once if needed)
-- UPDATE rsg_ranch_animals SET scale = 0.50, age = 0;

-- ============================================================================
-- PERFORMANCE NOTES FOR 100+ PLAYERS
-- ============================================================================
-- 
-- Expected Data Volume:
-- - 100 players × 20 animals max = 2,000 animals max
-- - 100 players × 1 employee each = ~100-500 employees
-- - 9 ranches × 1 object each = ~9 objects
-- - 9 ranches × 1 fund record = 9 fund records
--
-- Query Frequency (per minute):
-- - Growth tick: 2 bulk UPDATEs on rsg_ranch_animals
-- - Animal counts: ~10-20 SELECT COUNT queries
-- - Animal fetches: ~10-20 SELECT queries
--
-- The indexes above ensure:
-- - Counting animals: Uses idx_ranchid (fast)
-- - Bulk updates: Uses idx_unique_animalid (fast)
-- - Ranch lookups: Uses idx_ranch_animals (fast)
-- ============================================================================
