-- MySQL dump 10.13  Distrib 5.1.31, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: syslog
-- ------------------------------------------------------
-- Server version	5.1.31-1ubuntu2-log

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
-- Table structure for table `settings`
--

DROP TABLE IF EXISTS `settings`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `settings` (
  `id` int(3) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `value` varchar(255) NOT NULL,
  `type` enum('enum','int','varchar') NOT NULL DEFAULT 'varchar',
  `options` varchar(50) NOT NULL,
  `default` varchar(25) NOT NULL,
  `description` text NOT NULL,
  `hide` enum('yes','no') NOT NULL DEFAULT 'no',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `settings`
--

LOCK TABLES `settings` WRITE;
/*!40000 ALTER TABLE `settings` DISABLE KEYS */;
INSERT INTO `settings` VALUES (1,'ADMIN_EMAIL','cdukes@cdukes.com','varchar','','None','This variable sets the email address for the site Administrator','no'),(2,'ADMIN_NAME','admin','varchar','','admin','This variable sets the user name for the site Administrator, some features of the site, such as the server configuration, will be locked out if this variable does not match the logged in user.','no'),(3,'TBL_AUTH','users','varchar','','users','This variable sets the auth table name for local user information.','no'),(4,'AUTHTYPE','local','enum','local,ldap,msad,webbasic,none','local','This variable is used to set the authentication method to one of the following:<br><ul><li>Local Authentication</li><li>LDAP Authentication</li><li>Microsoft AD Domain Authentication</li><li>WEB Basic (Apache .htaccess) Authentication</li><li>None (No Authentication)</li></ul><b><br>NOTE: ONLY LOCAL AND NONE ARE SUPPORTED AT THIS TIME</b>','no'),(5,'DEBUG','0','enum','0,1','0','This variable enables and disables site-wide debugging','no'),(6,'DEDUP','1','enum','0,1','1','This variable is used to Enable or Disable Message Deduplication in the db_insert.pl script','no'),(7,'DEDUP_DIST','5','int','','5','This variable is used to set distance for message deduplication.<br>The higher the number, the more likely compared messages will match.','no'),(8,'DEDUP_WINDOW','300','int','','300','If Message deduplication is enabled, this setting is used to indicate the amount of time (in seconds) to compare messages from the same host.<br>When an event arrives, messages from the same host within this time frame are compared.','no'),(9,'DEMO','0','enum','0,1','0','This variable is used to place the server into Demo mode. This setting is only used by me on my demo website and should not normally need to be changed.','yes'),(10,'EMDB','1','enum','0,1','1','This variable is used to enable or disable the Error Message Database.','no'),(11,'EMDB_TBL_CISCO','cemdb','varchar','','cemdb','If the EMDB is enabled, this table is used to retrieve Cisco Error message information.','no'),(12,'EXCEL_DRK','C0C0C0','varchar','','C0C0C0','This variable sets the dark row color for Excel exports.','no'),(13,'EXCEL_HDR','96AED2','varchar','','96AED2','This variable sets the header row color for Excel exports.','no'),(14,'EXCEL_LT','E0E0E0','varchar','','E0E0E0','This variable sets the light row color for Excel exports.','no'),(15,'GRAPHS','1','enum','0,1','1','This variable is used to indicate whether or not the main page graphs should be shown.','no'),(16,'LDAP_BASE_DN','ou=active:ou=employees:ou=people:o=company.com','varchar','','ou=active:ou=employees:ou','This variable sets the LDAP Base DN if LDAP is enabled.','yes'),(17,'LDAP_CN','uid','varchar','','uid','This variable is used to set the LDAP CN.','yes'),(18,'LDAP_DOMAIN','gdd.net','varchar','','gdd.net',' LDAP Domain name','yes'),(19,'LDAP_MS','0','enum','0,1','0','This variable is used to enable MS-type LDAP autentication when LDAP is enabled.','yes'),(20,'LDAP_PRIV','0','enum','0,1','0','This settings is used to enable LDAP Authentication.','yes'),(21,'LDAP_RO_FILTERS','','varchar','','None','This variable can be used to specify which hosts will be shown (or NOT shown) to the ldap_ro users. <br>Hosts should be separated by a colon (:) and may include ! (for NOT) and * for a wildcard match<br>Example:<br>192.168.*.*:!192.168.1.*<br>Would allow all hosts in the 192.168.*.* network to be viewed by the ldap_ro group, EXCLUDING the 192.168.1.* subnet.','yes'),(22,'LDAP_RO_GRP','users','varchar','','users','This variable is used to set the LDAP read-only group name, users in this group will have limited access to the site.','yes'),(23,'LDAP_RW_GRP','admins','varchar','','admins','This variable is used to set the LDAP read-write group name, users in this group will have full access to the site.','yes'),(24,'LDAP_SRV','ldap.gdd.net','varchar','','None','This variable sets the LDAP server name to use if LDAP is enabled.','yes'),(25,'MSG_EXPLODE','1','enum','0,1','1','This variable is used to enable or disable message filtering by words when they are displayed.','no'),(26,'PATH_BASE','/var/www/logzilla.beta16','varchar','','/var/www/logzilla/html','This variable is used to set the base path of your LogZilla installation html directory, <b><u>DO NOT</u></b> include a trailing slash<br>Example: /var/www/logzilla/html','no'),(27,'PATH_LOGS','/var/log/logzilla','varchar','','/var/log/logzilla','This variable is used to indicate which directory to store logs in.<br>Note: Be sure the directory exists!','no'),(29,'PROGNAME','LogZilla','varchar','','LogZilla','This variable sets the internal program name and should not be changed.','yes'),(30,'RETENTION','30','int','','30','This variable is used to determine the number of days to keep old data in the database. <br>All data older than this setting will be DROPPED.','yes'),(31,'SEQ_DISP','0','enum','0,1','0','This setting is used to enable or disable displaying of Sequence columns in search results.<br>The Sequence field is not very accurate as many systems do not use them. I will probably be getting rid of it completely in a future release.','yes'),(32,'SESS_EXP','3600','varchar','','3600','This variable sets the default session expiration time in seconds.','no'),(33,'SITE_NAME','The home of LogZilla','varchar','','LogZilla','This variable sets the Website Name.','no'),(34,'SITE_URL','/','varchar','','/','This variable is used to set the website url, including trailing slash <br>Example: /logs/','no'),(35,'SPX_PORT','3312','varchar','','3312','This variable sets the Sphinx Server port.','yes'),(36,'SPX_SRV','localhost','varchar','','localhost','This variable sets the Sphinx Server address.','yes'),(38,'TBL_CACHE','search_cache','varchar','','search_cache','This variable is used to set the name of the cache table.','yes'),(39,'TBL_MAIN','logs','varchar','','logs','This variable sets the name of the main table used to store log data.','no'),(40,'VERSION','3.0','varchar','','2.10.0','This variable sets the LogZilla version number.','yes'),(41,'TBL_ACTIONS','actions','varchar','','actions','This variable sets the name of the actions table used to store default authentication actions for local users.','no'),(42,'TBL_USER_ACCESS','user_access','varchar','','user_access','This variable sets the name of the user_access table used to store default access for local users.','no'),(55,'OPTION_HGRID_SEARCH','LIKE','enum','LIKE, RLIKE','LIKE','This variable is used to set the type of search to perform when filtering the Hosts grid.<br>Using LIKE will speed up searches on large systems<br>Using RLIKE will allow for regular expression searches.','no'),(44,'CISCO_MNE_PARSE','1','enum','0,1','1','This variable is used to Enable or Disable extraction of messages for Cisco-based events.<br>If enabled, all incoming messages will be reformatted to strip out the syslog mnemonic between the \'%\' and \':\' delimiters.','no'),(45,'SPX_MEM_LIMIT','256','int','','256','Set the Sphinx Memory limit your liking: The default is 32M, but I have 26G available<br>\r\nso I set it to 1024M (max recommended in the docs)<br>\r\nA more sane setting would be 256M which will process about 600k rows at a time<br>\r\nSee http://sphinxsearch.com/docs/current.html#conf-mem-limit for more information.','yes'),(46,'SPX_MAX_MATCHES','1000','int','','1000','Sets the maximum results to return on a search<br>\r\nThere\'s not much of a good reason to return more than 1000 results since you should find what you\'re looking for in the first 100 or so results.<br>\r\nFeel free to play with this number, just be aware that the higher you set it, the more memory it will take.','yes'),(47,'CACHE_CHART_TOPHOSTS','30','int','','30','Sets the cache timeout (in minutes) for the Top Hosts chart.','no'),(48,'CACHE_CHART_TOPMSGS','60','int','','60','Sets the cache timeout (in minutes) for the Top Messages chart.','no'),(49,'CHART_MPD_DAYS','30','int','','30','Sets the number of days back to display on the Messages Per Day chart.','no'),(50,'CACHE_CHART_MPH','24','int','','24','Sets the number of hours back to display on the Messages Per Hour chart.','no'),(51,'CHART_SOW','Sun','enum','Sun,Mon','Sun','This variable is used to format the chart data on the Messages Per Week chart and is used to indicate the first day of the week for your region. <br>The options are:<ul><li>Sun</li><li>Mon</li></ul><br>','no'),(52,'VERSION_SUB','Beta 16','varchar','','None','Sets the sub-version number.','yes'),(53,'CACHE_CHART_MPW','4','int','','4','Sets the number of weeks back to display on the Messages Per Week chart.','no'),(54,'SHOWCOUNTS','1','enum','0,1','1','This variable enables the portal counts on the main page.<br>\r\nIf you have a large system (> 20m events), you may want to disable this to increase the page load times.','no'),(57,'PAGINATE','10','int','','10','This option sets the number of items to display on a single Search Results page.','no'),(58,'TOOLTIP_REPEAT','60','int','','60','This variable sets the time (in minutes) before the same tip will be repeated (tips are show during the main page load).','no'),(59,'TOOLTIP_GLOBAL','1','enum','0,1','1','This setting will enable or disable the Main page Tips on a global level (all users).<br>To disable Tips for an individual user, please edit the \"totd\" value for that user in the \"users\" table.','no');
/*!40000 ALTER TABLE `settings` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-03-22 18:01:17
