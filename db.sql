CREATE TABLE IF NOT EXISTS `nextz_trading` (
  `stock` tinytext DEFAULT NULL,
  `owner` text DEFAULT NULL,
  `amount` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;