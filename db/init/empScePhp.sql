-- MySQL dump 10.13  Distrib 8.0.42, for Linux (x86_64)
--
-- Host: localhost    Database: empScePhp
-- ------------------------------------------------------
-- Server version	8.0.42

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `empScePhp`
--

/*!40000 DROP DATABASE IF EXISTS `empScePhp`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `empScePhp` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `empScePhp`;

--
-- Table structure for table `employe`
--

DROP TABLE IF EXISTS `employe`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employe` (
  `matricule` char(4) NOT NULL,
  `nom` varchar(25) NOT NULL,
  `prenom` varchar(20) NOT NULL,
  `cadre` char(1) NOT NULL,
  `service` char(3) NOT NULL,
  PRIMARY KEY (`matricule`),
  KEY `service` (`service`),
  CONSTRAINT `employe_ibfk_1` FOREIGN KEY (`service`) REFERENCES `service` (`code`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `employe`
--

LOCK TABLES `employe` WRITE;
/*!40000 ALTER TABLE `employe` DISABLE KEYS */;
INSERT INTO `employe` VALUES ('0824','FLEURY','Josette','N','FIN'),('1047','CARRE','Patricia','N','HRH'),('1120','TEIXEIRA','Marcel','N','DEV'),('1277','LAMBERT','Gabrielle','N','DSI'),('1760','MALLET','Isaac','N','DSI'),('2129','CORDIER','Étienne','N','COM'),('2190','THIERRY','Joseph','N','DSI'),('2480','MICHAUD','Christine','O','MKT'),('3134','GONCALVES','Thibaut','O','MKT'),('3163','MAURICE','Margot','O','DSI'),('3780','BARBE','Léon','O','MKT'),('4058','ROSSI','Margaud','O','DEV'),('5381','MAILLET','Jeannine','O','MKT'),('5776','MATHIEU','Jean','O','DSI'),('5805','DOS SANTOS','Olivie','N','DEV'),('6255','VALLET','Victor','N','DEV'),('6314','VAILLANT','Alix','N','HRH'),('6412','PICARD','Marianne','N','COM'),('6510','PELTIER','Margaux','N','MKT'),('6572','BIGOT','Océane','N','FIN'),('6576','ROCHER','Virginie','O','MKT'),('6820','JEAN','Jérôme','N','DEV'),('7373','PERRET','Alexandrie','O','HRH'),('7994','PASCAL','Dominique','N','MKT'),('8146','JOUBERT','Thierry','N','FIN'),('8334','LEDOUX','Jacques','N','COM'),('8388','LAUNAY','Gabrielle','N','HRH'),('9608','PRUVOST','Emmanuelle','N','HRH'),('9879','MARION','Martine','O','HRH'),('9893','GROS','Léon','N','MKT');
/*!40000 ALTER TABLE `employe` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service`
--

DROP TABLE IF EXISTS `service`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `service` (
  `code` char(3) NOT NULL,
  `designation` varchar(30) NOT NULL,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service`
--

LOCK TABLES `service` WRITE;
/*!40000 ALTER TABLE `service` DISABLE KEYS */;
INSERT INTO `service` VALUES ('COM','Communication'),('DEV','Développement'),('DSI','Informatique'),('FIN','Finance'),('HRH','Ressources humaines'),('MKT','Marketing');
/*!40000 ALTER TABLE `service` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'empScePhp'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-05-20 19:58:50
