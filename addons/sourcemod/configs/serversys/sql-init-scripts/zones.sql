SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

CREATE TABLE IF NOT EXISTS `zones` (
  `id` int(11) NOT NULL,
  `map` int(11) NOT NULL,
  `type` varchar(64) NOT NULL,
  `value` int(11) NOT NULL DEFAULT '0',
  `name` varchar(128) DEFAULT NULL,
  `target` varchar(128) DEFAULT NULL,
  `visible` tinyint(1) NOT NULL DEFAULT '0',
  `width` float NOT NULL DEFAULT '2',
  `posx1` double DEFAULT NULL,
  `posy1` double DEFAULT NULL,
  `posz1` double DEFAULT NULL,
  `posx2` double DEFAULT NULL,
  `posy2` double DEFAULT NULL,
  `posz2` double DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

ALTER TABLE `zones`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id` (`id`),
  ADD KEY `map` (`map`),
  ADD KEY `type` (`type`),
  ADD KEY `value` (`value`),
  ADD KEY `name` (`name`),
  ADD KEY `target` (`target`),
  ADD KEY `visible` (`visible`),
  ADD KEY `width` (`width`),
  ADD KEY `posx1` (`posx1`),
  ADD KEY `posy1` (`posy1`),
  ADD KEY `posz1` (`posz1`),
  ADD KEY `posx2` (`posx2`),
  ADD KEY `posz2` (`posz2`),
  ADD KEY `posy2` (`posy2`);

--
ALTER TABLE `zones`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
