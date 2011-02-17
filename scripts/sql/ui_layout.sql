-- MySQL dump 10.13  Distrib 5.1.41, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: syslog
-- ------------------------------------------------------
-- Server version	5.1.41-3ubuntu12.8

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `ui_layout`
--

DROP TABLE IF EXISTS `ui_layout`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ui_layout` (
  `id` int(9) NOT NULL AUTO_INCREMENT,
  `userid` smallint(5) unsigned NOT NULL DEFAULT '1',
  `pagename` enum('Main','Charts','About','Admin','Bugs','Top_Messages','Graph','User','Portlet_Admin','Results','Email_Alerts','Error') NOT NULL DEFAULT 'Main',
  `col` smallint(5) unsigned NOT NULL DEFAULT '1',
  `rowindex` int(9) NOT NULL,
  `header` varchar(40) NOT NULL,
  `group_access` varchar(255) NOT NULL DEFAULT 'users',
  `content` varchar(120) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uid_header` (`userid`,`header`)
) ENGINE=MyISAM AUTO_INCREMENT=1801 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ui_layout`
--

LOCK TABLES `ui_layout` WRITE;
/*!40000 ALTER TABLE `ui_layout` DISABLE KEYS */;
INSERT INTO `ui_layout` VALUES (219,0,'Admin',1,1,'Server Settings','admins','includes/portlets/portlet-sadmin.php'),(218,0,'Charts',2,4,'Messages Per Month','users','includes/portlets/portlet-chart_mpmo.php'),(217,0,'Results',1,12,'Search Results','users','includes/portlets/portlet-table.php'),(216,0,'Main',1,1,'Severities','users','includes/portlets/portlet-severities.php'),(215,0,'Main',2,4,'Search Options','users','includes/portlets/portlet-search_options.php'),(214,0,'Charts',1,1,'Messages Per Second','users','includes/portlets/portlet-chart_mps.php'),(213,0,'Main',1,2,'Facilities','users','includes/portlets/portlet-facilities.php'),(212,0,'Charts',2,6,'Messages Per Day','users','includes/portlets/portlet-chart_mpd.php'),(211,0,'Main',1,3,'Programs','users','includes/portlets/portlet-programs.php'),(210,0,'Charts',1,2,'Messages Per Minute','users','includes/portlets/portlet-chart_mpm.php'),(209,0,'Main',3,8,'Messages','users','includes/portlets/portlet-sphinxquery.php'),(208,0,'Main',2,5,'Date and Time','users','includes/portlets/portlet-datepicker.php'),(207,0,'Main',3,7,'Hosts','users','includes/portlets/portlet-hosts.php'),(220,0,'Top_Messages',1,11,'Top Messages','users','includes/portlets/portlet-chart_topmsgs.php'),(221,0,'About',1,13,'About','users','includes/portlets/portlet-about.php'),(222,0,'Bugs',1,1,'Bugs','users','includes/portlets/portlet-known_bugs.php'),(223,0,'Charts',1,3,'Messages Per Hour','users','includes/portlets/portlet-chart_mph.php'),(224,0,'Charts',2,5,'Messages Per Week','users','includes/portlets/portlet-chart_mpw.php'),(279,0,'Graph',1,0,'Graph Results','users','includes/portlets/portlet-chart_adhoc.php'),(567,0,'User',2,0,'Change Password','users','includes/portlets/portlet-uadmin_chpw.php'),(611,0,'User',1,0,'Delete User','admins','includes/portlets/portlet-uadmin_deluser.php'),(809,0,'User',3,0,'Groups','admins','includes/portlets/portlet-groupadmin.php'),(546,0,'User',1,0,'Add User','admins','includes/portlets/portlet-uadmin_adduser.php'),(1109,0,'Portlet_Admin',2,0,'Portlet Group Permissions','admins','includes/portlets/portlet-portlet_permissions_group.php'),(1182,0,'Portlet_Admin',1,0,'Portlet User Permissions','admins','includes/portlets/portlet-portlet_permissions_user.php'),(1758,1,'Main',1,1,'Severities','admins','includes/portlets/portlet-severities.php'),(1757,1,'Portlet_Admin',1,0,'Portlet User Permissions','admins','includes/portlets/portlet-portlet_permissions_user.php'),(1756,1,'Portlet_Admin',2,0,'Portlet Group Permissions','admins','includes/portlets/portlet-portlet_permissions_group.php'),(1755,1,'Charts',2,5,'Messages Per Week','admins','includes/portlets/portlet-chart_mpw.php'),(1754,1,'Charts',1,1,'Messages Per Second','admins','includes/portlets/portlet-chart_mps.php'),(1753,1,'Charts',2,4,'Messages Per Month','admins','includes/portlets/portlet-chart_mpmo.php'),(1752,1,'Charts',1,2,'Messages Per Minute','admins','includes/portlets/portlet-chart_mpm.php'),(1751,1,'Charts',1,3,'Messages Per Hour','admins','includes/portlets/portlet-chart_mph.php'),(1750,1,'Charts',2,6,'Messages Per Day','admins','includes/portlets/portlet-chart_mpd.php'),(1749,1,'Main',3,8,'Messages','admins','includes/portlets/portlet-sphinxquery.php'),(1359,0,'User',3,5,'Group Assignments','admins','includes/portlets/portlet-uadmin_group_assign.php'),(1748,1,'Main',3,7,'Hosts','admins','includes/portlets/portlet-hosts.php'),(1747,1,'User',3,0,'Groups','admins','includes/portlets/portlet-groupadmin.php'),(1746,1,'User',3,5,'Group Assignments','admins','includes/portlets/portlet-uadmin_group_assign.php'),(1745,1,'Graph',1,0,'Graph Results','admins','includes/portlets/portlet-chart_adhoc.php'),(1744,1,'Main',1,2,'Facilities','admins','includes/portlets/portlet-facilities.php'),(1743,1,'User',1,0,'Delete User','admins','includes/portlets/portlet-uadmin_deluser.php'),(1742,1,'Main',2,5,'Date and Time','admins','includes/portlets/portlet-datepicker.php'),(1741,1,'User',2,0,'Change Password','admins','includes/portlets/portlet-uadmin_chpw.php'),(1740,1,'Bugs',1,1,'Bugs','admins','includes/portlets/portlet-known_bugs.php'),(1739,1,'User',1,0,'Add User','admins','includes/portlets/portlet-uadmin_adduser.php'),(1738,1,'About',1,13,'About','admins','includes/portlets/portlet-about.php'),(1759,1,'Main',1,3,'Programs','admins','includes/portlets/portlet-programs.php'),(1760,1,'Main',2,4,'Search Options','admins','includes/portlets/portlet-search_options.php'),(1761,1,'Results',1,12,'Search Results','admins','includes/portlets/portlet-table.php'),(1762,1,'Admin',1,1,'Server Settings','admins','includes/portlets/portlet-sadmin.php'),(1763,1,'Top_Messages',1,11,'Top Messages','admins','includes/portlets/portlet-chart_topmsgs.php'),(1790,1,'Main',2,4,'Mnemonics','admins','includes/portlets/portlet-mnemonics.php'),(1791,0,'Main',2,4,'Mnemonics','users','includes/portlets/portlet-mnemonics.php'),(1793,0,'Email_Alerts',1,0,'Email Alerts','admins','includes/portlets/portlet-email_alerts.php'),(1794,1,'Email_Alerts',1,0,'Email Alerts','admins','includes/portlets/portlet-email_alerts.php'),(1797,0,'Error',1,0,'Error','users','includes/portlets/errors.php'),(1798,1,'Error',1,0,'Error','users','includes/portlets/portlet-error.php');
/*!40000 ALTER TABLE `ui_layout` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-02-16 22:30:21
