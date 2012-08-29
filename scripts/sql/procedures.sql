DROP PROCEDURE IF EXISTS `log_arch_hr_proc`; 
DROP PROCEDURE IF EXISTS `log_arch_daily_proc`; 
DROP PROCEDURE IF EXISTS `cleanup`;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `log_arch_hr_proc`()
BEGIN
	DECLARE yesterday varchar(20) DEFAULT DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL -1 DAY), '%Y%m%d');
	DECLARE hmin, hmax int DEFAULT 0;      
	DECLARE arch_hour_start int DEFAULT hour(now())-1;
	DECLARE arch_hour_stop int DEFAULT hour(now());


       SELECT min(id) into hmin FROM logs WHERE (lo>=date_add(date(curdate()),interval arch_hour_start hour));
       SELECT max(id) into hmax FROM logs WHERE (lo<date_add(date(curdate()),interval arch_hour_stop hour));

	if (arch_hour_start < 0) then select 23 into arch_hour_start;
	end if;

       SET @s = CONCAT('CREATE OR REPLACE VIEW log_arch_hr_',arch_hour_start,' AS SELECT * FROM logs where id>=',hmin,' AND id<=',hmax);
       PREPARE stmt FROM @s;
       EXECUTE stmt;
       DEALLOCATE PREPARE stmt;
	delete from sph_counter WHERE counter_id=3;
       INSERT INTO sph_counter (counter_id,max_id,index_name) VALUES (3,1,CONCAT('log_arch_hr_',arch_hour_start));
       update sph_counter set max_id=hmax where counter_id=1;
END$$

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `log_arch_daily_proc`()
BEGIN
	declare mini int unsigned default 0;
	declare maxi int unsigned default 0;

	set @yesterday = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL -1 DAY), '%Y%m%d');

	SELECT min(id) into mini FROM logs where date(lo)=@yesterday;
	SELECT max(id) into maxi FROM logs where date(lo)=@yesterday;

	SET @s =
		CONCAT('CREATE OR REPLACE VIEW log_arch_day_',@yesterday,' AS SELECT * FROM logs where id>=',mini,' AND id<=',maxi);
	PREPARE stmt FROM @s;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;

	delete from sph_counter WHERE counter_id=4;
	INSERT INTO sph_counter (counter_id,max_id,index_name) VALUES (4,maxi,CONCAT('log_arch_day_',@yesterday));
END$$

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `cleanup`()
BEGIN

 DECLARE drop_hosts INT(1);
    Insert into hosts (host,lastseen,seen)  (select host, max(lo),sum(counter) from logs group by host) ON DUPLICATE KEY 
     update `seen` = ( SELECT SUM(`logs`.`counter`) FROM `logs` WHERE `logs`.`host` = `hosts`.`host` ),  
      lastseen = (select max(lo) from logs WHERE `logs`.`host` = `hosts`.`host` ), hidden = 'false';
    SELECT value into drop_hosts from settings WHERE name="RETENTION_DROPS_HOSTS";
    IF drop_hosts then
    delete from `hosts`   
    WHERE `hosts`.`seen` = 0;
    else
    update `hosts` set hidden='true'  
    WHERE  `hosts`.`seen` = 0;
    end if;

    UPDATE `mne` SET `seen` = ( SELECT SUM(`logs`.`counter`) FROM `logs` WHERE `logs`.`mne` = `mne`.`crc` ),  
      lastseen = (select max(lo) from logs WHERE `logs`.`mne` = `mne`.`crc` );
	update `mne` set hidden='false'; 
    update `mne` set hidden='true'   
    WHERE `mne`.`seen` = 0;

    UPDATE `snare_eid` SET `seen` = ( SELECT SUM(`logs`.`counter`) FROM `logs` WHERE `logs`.`eid` = `snare_eid`.`eid` ),  
      lastseen = (select max(lo) from logs WHERE `logs`.`eid` = `snare_eid`.`eid`);
    update `snare_eid` set hidden='false';
    update `snare_eid` set hidden='true' 
    WHERE `snare_eid`.`seen` = 0;

    UPDATE `programs` SET `seen` = ( SELECT SUM(`logs`.`counter`) FROM `logs` WHERE `logs`.`program` = `programs`.`crc` ),  
      lastseen = (select max(lo) from logs WHERE `logs`.`program` = `programs`.`crc`);
    update `programs` set hidden='false'; 
    update `programs` set hidden='true' 
    WHERE `programs`.`seen` = 0;
    
	select @s := concat('drop view ', group_concat(table_name SEPARATOR ','))
	from information_schema.views
	where table_name like '%search_results';

	prepare stmt from @s;
	execute stmt;
	drop prepare stmt;

END$$

