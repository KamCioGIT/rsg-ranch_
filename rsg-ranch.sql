CREATE TABLE IF NOT EXISTS `rsg_ranch_funds` (
  `ranchid` varchar(50) NOT NULL,
  `funds` double DEFAULT 0,
  PRIMARY KEY (`ranchid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `rsg_ranch_employees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ranchid` varchar(50) DEFAULT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  `fullname` varchar(100) DEFAULT NULL,
  `grade` int(11) DEFAULT 0,
  `hired_date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `ranchid` (`ranchid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `rsg_ranch_animals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ranchid` varchar(50) DEFAULT NULL,
  `animalid` varchar(50) DEFAULT NULL,
  `model` varchar(50) NOT NULL,
  `name` varchar(50) DEFAULT NULL,
  
  -- Location
  `pos_x` float NOT NULL DEFAULT 0,
  `pos_y` float NOT NULL DEFAULT 0,
  `pos_z` float NOT NULL DEFAULT 0,
  `pos_w` float NOT NULL DEFAULT 0,
  
  -- Stats
  `age` smallint(5) unsigned DEFAULT 0,
  `born` int(10) unsigned NOT NULL DEFAULT 0,
  `health` tinyint(3) unsigned DEFAULT 100,
  `hunger` tinyint(3) unsigned DEFAULT 100,
  `thirst` tinyint(3) unsigned DEFAULT 100,
  
  -- Production & Growth
  `scale` decimal(4,2) DEFAULT 0.50,
  `last_production` int(10) unsigned DEFAULT 0,
  `product_ready` tinyint(1) DEFAULT 0,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_animalid` (`animalid`),
  KEY `idx_ranchid` (`ranchid`),
  KEY `idx_product` (`product_ready`),
  KEY `idx_ranch_product` (`ranchid`, `product_ready`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `rsg_ranch_objects` (
  `ranchid` varchar(50) NOT NULL,
  `model` varchar(50) NOT NULL,
  `coords` longtext DEFAULT NULL,
  PRIMARY KEY (`ranchid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
