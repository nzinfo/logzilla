-- MySQL dump 10.13  Distrib 5.5.29, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: syslog
-- ------------------------------------------------------
-- Server version	5.5.29-0ubuntu0.12.04.1

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
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `settings` (
  `id` int(3) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `value` varchar(2047) DEFAULT NULL,
  `type` enum('enum','int','varchar') NOT NULL DEFAULT 'varchar',
  `options` varchar(125) NOT NULL,
  `default` varchar(125) NOT NULL,
  `description` text NOT NULL,
  `hide` enum('yes','no') NOT NULL DEFAULT 'no',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=113 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `settings`
--

LOCK TABLES `settings` WRITE;
/*!40000 ALTER TABLE `settings` DISABLE KEYS */;
INSERT INTO `settings` VALUES (1,'ADMIN_EMAIL','root@localhost','varchar','','None','This\n    variable sets the email address for the site\n    Administrator','no'),(2,'ADMIN_NAME','admin','varchar','','admin','This variable sets the user\n    name for the site Administrator, some features of the site, such as the server configuration,\n    will be locked out if this variable does not match the logged in\n    user.','no'),(3,'TBL_AUTH','users','varchar','','users','This variable sets the auth table name\n    for local user information.','yes'),(4,'AUTHTYPE','local','enum','local,ldap,none','local','This\n    variable is used to set the authentication method to one of the following:<br><ul><li>Local\n    Authentication</li><li>LDAP Authentication</li><li>None (No\n        Authentication)</li></ul>','no'),(5,'DEBUG','0','enum','0,1,2,3,4,5','0','This variable\n    enables and disables site-wide debugging','no'),(6,'DEDUP','0','enum','0,1','1','This variable\n    is used to Enable or Disable Message Deduplication in the log_processor\n    script','no'),(7,'DEDUP_DIST','5','int','','5','This variable is used to set distance for\n    message deduplication.<br>The higher the number, the more likely compared messages will\n    match.','no'),(8,'DEDUP_WINDOW','300','int','','300','If Message deduplication is enabled, this\n    setting is used to indicate the amount of time (in seconds) to compare messages from the same\n    host.<br>When an event arrives, messages from the same host within this time frame are\n    compared.','no'),(9,'DEMO','0','enum','0,1','0','This variable is used to place the server into\n    Demo mode. This setting is only used by us on the demo website and should not normally need to\n    be changed.','yes'),(10,'EMDB','1','enum','0,1','1','This variable is used to enable or disable\n    the Error Message Database.','yes'),(11,'EMDB_TBL_CISCO','cemdb','varchar','','cemdb','If the\n    EMDB is enabled, this table is used to retrieve Cisco Error message\n    information.','yes'),(12,'EXCEL_DRK','E2E4FF','varchar','','C0C0C0','This variable sets the dark\n    row color for Excel exports.','yes'),(13,'EXCEL_HDR','FB9E01','varchar','','96AED2','This\n    variable sets the header row color for Excel\n    exports.','yes'),(14,'EXCEL_LT','FFFFFF','varchar','','E0E0E0','This variable sets the light row\n    color for Excel exports.','yes'),(15,'GRAPHS','1','enum','0,1','1','This variable is used to\n    indicate whether or not the main page graphs should be\n    shown.','yes'),(16,'LDAP_BASE_DN','ou=active, ou=employees, ou=people,\n    o=somewhere.com','varchar','','ou=active:ou=employees:ou','This variable sets the LDAP Base DN\n    if LDAP is enabled.','no'),(17,'LDAP_CN','uid','varchar','','uid','This variable is used to set\n        the LDAP CN.','no'),(18,'LDAP_DOMAIN','somewhere.com','varchar','','gdd.net',' LDAP Domain\n        name','no'),(19,'LDAP_MS','0','enum','0,1','0','This variable is used to enable MS-type LDAP\n        authentication when LDAP is enabled.','no'),(20,'LDAP_PRIV','0','enum','0,1','0','This\n        setting is used to enable LDAP Authentication for read-only and read-write groups.<br>It is\n        not yet implemented and should not be set to\n        1.','yes'),(21,'LDAP_RO_FILTERS','','varchar','','None','This variable can be used to\n        specify which hosts will be shown (or NOT shown) to the ldap_ro users. <br>Hosts should be\n        separated by a colon (:) and may include ! (for NOT) and * for a wildcard\n        match<br>Example:<br>192.168.*.*:!192.168.1.*<br>Would allow all hosts in the 192.168.*.*\n        network to be viewed by the ldap_ro group, EXCLUDING the 192.168.1.*\n        subnet.','yes'),(22,'LDAP_RO_GRP','users','varchar','','users','This variable is used to set\n        the LDAP read-only group name, users in this group will have limited access to the\n        site.','yes'),(23,'LDAP_RW_GRP','admins','varchar','','admins','This variable is used to set\n        the LDAP read-write group name, users in this group will have full access to the\n        site.','yes'),(24,'LDAP_SRV','ldap.somewhere.com','varchar','','None','This variable sets\n        the LDAP server name to use if LDAP is\n        enabled.','no'),(25,'MSG_EXPLODE','1','enum','0,1','1','This variable is used to enable or\n        disable message filtering by words when they are\n        displayed.','yes'),(26,'PATH_BASE','/var/www/logzilla','varchar','','/var/www/logzilla/html','This\n        variable is used to set the base path of your LogZilla installation html directory, <b><u>DO\n        NOT</u></b> include a trailing slash<br>Example:\n        /var/www/logzilla/html','no'),(27,'PATH_LOGS','/var/log/logzilla','varchar','','/var/log/logzilla','This\n        variable is used to indicate which directory to store logs in.<br>Note: Be sure the\n        directory exists!','no'),(29,'PROGNAME','LogZilla','varchar','','LogZilla','This variable\n        sets the internal program name and should not be\n        changed.','yes'),(30,'RETENTION','7','int','','30','This variable is used to determine the number of days to keep data in the database. <br>Any data older than this setting will be automatically purged.','no'),(31,'SEQ_DISP','0','enum','0,1','0','This setting is used to\n        enable or disable displaying of Sequence columns in search results.<br>The Sequence field is\n        not very accurate as many systems do not use them. I will probably be getting rid of it\n        completely in a future release.','yes'),(32,'SESS_EXP','3600','varchar','','3600','This\n        variable sets the default session expiration time in\n        seconds.','no'),(33,'SITE_NAME','LogZilla Server','varchar','','LogZilla','This variable\n        sets the Website Name.','no'),(34,'SITE_URL','/','varchar','','/','This variable is used to\n        set the website url, including trailing slash <br>Example:\n        /logs/','no'),(35,'SPX_PORT','3312','varchar','','3312','This variable sets the Sphinx\n        Server port.','no'),(36,'SPX_SRV','127.0.0.1','varchar','','localhost','This variable sets\n        the Sphinx Server address.','no'),(38,'TBL_CACHE','cache','varchar','','cache','This\n        variable is used to set the name of the cache\n        table.','yes'),(39,'TBL_MAIN','logs','varchar','','logs','This variable sets the name of the\n        main table used to store log data.','yes'),(40,'VERSION','4.5','varchar','','','This\n        variable sets the LogZilla version\n        number.','yes'),(41,'TBL_ACTIONS','actions','varchar','','actions','This variable sets the\n        name of the actions table used to store default authentication actions for local\n        users.','yes'),(42,'TBL_USER_ACCESS','user_access','varchar','','user_access','This variable\n        sets the name of the user_access table used to store default access for local\n        users.','yes'),(55,'OPTION_HGRID_SEARCH','LIKE','enum','LIKE, RLIKE','LIKE','This variable\n        is used to set the type of search to perform when filtering the Hosts grid.<br>Using LIKE\n        will speed up searches on large systems<br>Using RLIKE will allow for regular expression\n        searches.','yes'),(44,'CISCO_MNE_PARSE','1','enum','0,1','1','This variable is used to\n        Enable or Disable extraction of messages for Cisco-based events.<br>If enabled, all incoming\n        messages will be reformatted to strip out the syslog mnemonic between the \'%\' and \':\'\n        delimiters.','yes'),(45,'SPX_MEM_LIMIT','256','int','','256','Set the Sphinx Memory limit\n        your liking: The default is 256M<br>\r\nThe max recommended is 1024M<br>\r\n256M will\n        process about 600k rows at a time<br>\r\nSee\n        http://sphinxsearch.com/docs/current.html#conf-mem-limit for more\n        information.','no'),(46,'SPX_MAX_MATCHES','40000','int','','40000','Sets the maximum results to return on a search<br>','yes'),(47,'CACHE_CHART_TOPHOSTS','30','int','','30','Sets the cache timeout (in minutes) for the Top Hosts chart.','no'),(48,'CACHE_CHART_TOPMSGS','60','int','','60','Sets the cache timeout (in minutes) for the Top Messages chart.','no'),(49,'CHART_MPD_DAYS','30','int','','30','Sets the number of days back to display on the Messages Per Day chart.','no'),(50,'CACHE_CHART_MPH','24','int','','24','Sets the number of hours back to display on the Messages Per Hour chart.','no'),(51,'CHART_SOW','Sun','enum','Sun,Mon','Sun','This variable is used to format the chart data on the Messages Per Week chart and is used to indicate the first day of the week for your region. <br>The options are:<ul><li>Sun</li><li>Mon</li></ul><br>','no'),(52,'VERSION_SUB','.426','varchar','','None','Sets the sub-version number.','yes'),(53,'CACHE_CHART_MPW','4','int','','4','Sets the number of weeks back to display on the Messages Per Week chart.','no'),(54,'SHOWCOUNTS','1','enum','0,1','1','This variable enables the portal counts on the main page.<br>\r\nIf you have a large system (> 20m events), you may opt to disable this to increase the page load times.','no'),(57,'PAGINATE','10','int','','10','This option sets the number of items to display on a single Search Results page.','yes'),(58,'TOOLTIP_REPEAT','60','int','','60','This variable sets the time (in minutes) before the same tip will be repeated (tips are show during the main page load).','no'),(59,'TOOLTIP_GLOBAL','1','enum','0,1','1','This setting will enable or disable the Main page Tips on a global level (all users).<br>To disable Tips for an individual user, please edit the \"totd\" value for that user in the \"users\" table.','no'),(60,'LZECS_SYSID','','varchar','','','This sets the system id for your server. This option is used to submit unknown events to the LogZilla Error Classification System.','yes'),(62,'Q_LIMIT','25000','int','','25000','This option sets the limit on the number of messages to be processed before running the batch import to the database.<br>Note that if the Q_TIME kicks in before this, it will supercede this limit.','no'),(63,'Q_TIME','1','int','','1','This option sets the TIME limit on the messages to be processed before running the batch import to the database.<br>Note that if this timer kicks in before the Q_LIMIT, it will supercede the Q_LIMIT.<br>You should increase this number to a higher value for larger systems to improve performance.','no'),(64,'SPX_ENABLE','1','enum','0,1','1','Deprecated. Do not modify.','yes'),(65,'LDAP_DNU_GRP','users','varchar','','users','This option specifies the default group to place new LDAP users into when they don\'t exist locally.','no'),(67,'SPX_ADV','0','enum','0,1','0','No longer necessary in later Sphinx code (post 0.9.9) as all searches now use extended mode.','yes'),(68,'MAILHOST','localhost','varchar','','localhost','This option specifies the mail host to use when sending alerts.','no'),(69,'MAILHOST_PORT','25','int','','25','This option specifies the mail host\'s post to use when sending alerts.','no'),(70,'MAILHOST_USER','','varchar','','','This option specifies the mail host\'s username to use when sending alerts.<br>\r\nLeave this field blank if no username is necessary (like sending from localhost).','no'),(71,'MAILHOST_PASS','','varchar','','','This option specifies the mail host\'s password to use when sending alerts.<br>\r\nLeave this field blank if no username is necessary (like sending from localhost).','no'),(72,'PORTLET_HOSTS_LIMIT','10','int','','10','This option specifies the default number of hosts to display on the main page\'s host portlet.<br>\r\nThe list will contain only the last N hosts that have reported in (sorted by \"lastseen\" column in descending order).<br>\r\nIf there are more hosts than what is set here, you can click the \"Expand\" icon (magnifying glass icon in the top right corner of the portlet) and get a full listing.<br>\r\n<b>For large deployments where thousands of hosts are collected, this is a much more effective solution.</b>','no'),(73,'SPARKLINES','1','enum','0,1','1','This variable is used to enable/disable the Events Per Second ticker on the main page.<br>\r\nThe EPS Ticker is the small graph-like count of the average messages per second entering the server.<br>\r\nBecause the call queries the server every second, some users on large systems may want to disable this feature.','no'),(80,'ARCHIVE_PATH','/var/www/logzilla/exports/','varchar','','/var/www/logzilla/exports/','This variable is used to set the base path of your LogZilla backup directory','no'),(81,'LZECS','0','enum','0,1','0','This variable is used to enable the LogZilla Error Classification System','yes'),(82,'PORTLET_MNE_LIMIT','10','int','','10','This option specifies the default number of Mnemonics to display on the main page\'s mnemonic portlet.<br>\r\nThe list will contain only the last N hosts that have reported in (sorted by \"lastseen\" column in descending order).<br>\r\nIf there are more mnemonics than what is set here, you can click the \"Expand\" icon (magnifying glass icon in the top right corner of the portlet) and get a full listing.<br>\r\n<b>For large deployments where thousands of mnemonics are collected, this is a much more effective solution.</b>','no'),(83,'SNARE','1','enum','0,1','0','This option will enable Snare windows events to be processed.<br>\r\nNote that after enabling Snare, you must restart your syslog daemon so that the db_insert preprocessor will pick up events.','no'),(84,'PORTLET_EID_LIMIT','10','int','','10','This option specifies the default number of Snare EventId\'s to display on the main page\'s EID portlet.<br>\r\nThe list will contain only the last N EventId\'s that have reported in (sorted by \"lastseen\" column in descending order).<br>\r\nIf there are more EID\'s than what is set here, you can click the \"Expand\" icon (magnifying glass icon in the top right corner of the portlet) and get a full listing.<br>\r\n<b>For large deployments where thousands of EID\'s are collected, this is a much more effective solution.</b>','no'),(85,'SNARE_EID_URL','http://eventid.net/display.asp?eventid=','enum','http://eventid.net/display.asp?eventid=,http://www.microsoft.com/technet/support/ee/SearchResults.aspx?Type=1&ID=','http://eventid.net/display.asp?eventid=','This option sets the URL to use when linking Snare/Windows Event ID\'s<br>\r\nThe default is http://eventid.net/display.asp?eventid=<br>\r\nAnother option is http://www.microsoft.com/technet/support/ee/SearchResults.aspx?Type=1&ID=<br>\r\nNote that in both cases, the actual event id is left off after the = character - it will be inserted when results are displayed.','yes'),(86,'FEEDBACK','1','enum','0,1','0','This variable will enable or disable the \"Submit Idea\" button on the bottom right of the screen.<br>\r\nServers with no internet access should disable this.','no'),(87,'LDAP_USERS_RO',NULL,'varchar','','','Comma separated list of user ID\'s that are allowed RO access','yes'),(88,'LDAP_USERS_RW',NULL,'varchar','','','Comma separated list of user ID\'s that are allowed RW access','yes'),(89,'SYSTEM_LOG_FILE','1','enum','0,1','0','Write all audit information to the $LOG_PATH/audit.log file','no'),(90,'SYSTEM_LOG_DB','0','enum','0,1','0','Send all audit information to the LogZilla Database','no'),(93,'SYSTEM_LOG_SYSLOG','0','enum','0,1','0','Write all audit information to syslog.','no'),(94,'PORTLET_PROGRAMS_LIMIT','10','int','','10','This option specifies the default number of Programs to display on the main page\'s program portlet.<br>\r\nThe list will contain only the last N programs that have reported in (sorted by \"lastseen\" column in descending order).<br>\r\nIf there are more Programs than what is set here, you can click the \"Expand\" icon (magnifying glass icon in the top right corner of the portlet) and get a full listing.<br>\r\n<b>For large deployments where thousands of programs are collected, this is a much more effective solution.</b>','no'),(95,'RETENTION_DROPS_HOSTS','0','enum','0,1','0','This option enables/disables pruning of old hosts from the database.','no'),(96,'ARCHIVE_BACKUP','','varchar','','','Command to archive a day to another host<br>\r\n $1 is the archive name with full path w/o .gz<br>\r\nExample: scp $1.gz remotehost:/backup/.','no'),(97,'ARCHIVE_RESTORE','','varchar','','','Command to restore a day from another host<br>\r\n $1 is the archive filename with .gz; $2 is the restore path<br>\r\nExample: scp remotehost:/backup/$1 $2','no'),(98,'RBAC_ALLOW_DEFAULT','1','enum','0,1','1','This option specifies the default behavior when a new user is added to the system.<br>\r\nOptions are:<br>\r\n<ul>\r\n<li>0 - All new users must be given permissions (using the Admin>RBAC menu) to see newly added hosts. (implicit deny)</li>\r\n<li>1 - Allow newly created users to see all new (unassigned) hosts by default. (implicit allow)</li>\r\n</ul>\r\n','no'),(99,'SNMP_TRAPDEST','','varchar','','BLANK (no value)','Sets a destination TRAP hosts for alerts','no'),(100,'SNMP_COMMUNITY','public','varchar','','public','Sets the community for SNMP_TRAPHOST','no'),(101,'SNMP_SENDTRAPS','0','enum','0,1','0','Enables trap forwarding to the host set in SNMP_TRAPHOST.<br>\r\nNote: You must have a license for Email triggers in order for this function to work.','no'),(102,'SPX_CPU_CORES','4\n','int','','8','How many slices used in indexes. After changing a reindex --all -rotate must been done.','no'),(103,'SPX_IDX_DIM','0','int','','0','This option allows the admin to specify the number of days to keep LogZilla indexes in memory. <br>For large servers with plenty of memory, you can increase this value to greatly speed up searches across multiple days.<br>By default, all data older than today are moved to disk-based indexes to save memory usage.<br>To get your current server stats, run $lz/scripts/LZTool -v -r ss.<br>Note that modifying this setting could cause index corruption and may require you to reindex all data.  E.g.: A setting of 0 means that only today\'s data is kept in memory (this is the default), a setting of 1 means that both today and yesterday would be kept in memory.','no'),(104,'TBL_SEV_0_EMERG','FF4040','varchar','','FF4040','Sets the color to display on results tables for individual severity levels','no'),(105,'TBL_SEV_1_CRIT','DA4725','varchar','','DA4725','Sets the color to display on results tables for individual severity levels','no'),(106,'TBL_SEV_2_ALERT','FF897C','varchar','','FF897C','Sets the color to display on results tables for individual severity levels','no'),(107,'TBL_SEV_3_ERROR','FFD660','varchar','','FFD660','Sets the color to display on results tables for individual severity levels','no'),(108,'TBL_SEV_4_WARN','FFF200','varchar','','FFF200','Sets the color to display on results tables for individual severity levels','no'),(109,'TBL_SEV_5_NOTICE','D2D8F9','varchar','','D2D8F9','Sets the color to display on results tables for individual severity levels','no'),(110,'TBL_SEV_6_INFO','CAF100','varchar','','CAF100','Sets the color to display on results tables for individual severity levels','no'),(111,'TBL_SEV_7_DEBUG','ED5394','varchar','','ED5394','Sets the color to display on results tables for individual severity levels','no'),(112,'TBL_SEV_SHOWCOLORS','0','enum','0,1','0','Enable row coloring for severity levels in results table','no');
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

-- Dump completed on 2013-10-11 18:36:13
