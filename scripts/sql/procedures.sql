DROP PROCEDURE IF EXISTS `log_arch_hr_proc`; 
DROP PROCEDURE IF EXISTS `log_arch_daily_proc`; 
DROP PROCEDURE IF EXISTS `cleanup`;
DROP PROCEDURE IF EXISTS `manage_logs_partitions`;
DROP PROCEDURE IF EXISTS `debug`;
DROP FUNCTION IF EXISTS `get_current_date`;

DELIMITER $$

-- ===============================================================================================

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

-- ===============================================================================================

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

-- ===============================================================================================

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

-- ===============================================================================================

-- This should be called at least once a week, but better to call it every night
-- It creates new partitions for 10 following days - of course only if they are not 
-- created yet. It also checks if table 'logs' has partitioning set at all - and if
-- not, then proper 'alter table' is performed to add partitioning.
-- 
-- It is safe to call this procedure many times, as it checks for existing partitions 
-- before creating new ones - so it can be call during installation or during tests.
CREATE DEFINER=`root`@`localhost` PROCEDURE `manage_logs_partitions`()
BEGIN

    DECLARE max_part_name, part_name varchar(20);
    DECLARE date_from, date_to, d date;
    DECLARE days int;
    DECLARE part_list, part_def varchar(1024);

    SELECT max(partition_name) 
    INTO max_part_name
    FROM information_schema.partitions
    WHERE table_name = 'logs' AND table_schema = database();

    IF isnull(max_part_name) THEN
        SET date_from = get_current_date();
    ELSE
        SET date_from = greatest( get_current_date(), 
            str_to_date(max_part_name, 'p%Y%m%d' ) + interval 1 day );
    END IF;

    SET date_to = get_current_date() + INTERVAL 9 day;

    -- call debug( concat('date_from=', date_from, ', date_to=', date_to ) ); 

    SET d = date_from;
    WHILE d <= date_to DO
        SET part_name = date_format( d, 'p%Y%m%d' );
        SET days = to_days(d);
        SET part_def = concat( 'PARTITION ', part_name, ' VALUES LESS THAN (', days, ')' );
        IF isnull(max_part_name) THEN
            SET part_list = concat_ws( ',', part_list, part_def );
        ELSE
            SET @sql = concat( 'ALTER TABLE logs ADD PARTITION ( ', part_def, ' )' );
            -- call debug( concat( 'DOING stmt=[', @sql, ']' ) );
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END IF;
        SET d = d + interval 1 day;
    END WHILE;
            
    IF ! isnull(part_list) THEN
        SET @sql = concat( 'ALTER TABLE logs PARTITION BY RANGE ( TO_DAYS(lo) ) ',
            '( ', part_list, ' )' );
        -- call debug( concat( 'DOING stmt=[', @sql, ']' ) );
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;

END$$

-- ===============================================================================================

-- Helper for debugging, adds given message to the session variable, which can be later on
-- examined in perl code and displayed to the developer
CREATE PROCEDURE debug( msg varchar(2560) )
BEGIN
    SET @debug_msg = concat( @debug_msg, msg, '\n' );
END$$

-- This is used by tests to mock current date - if session variable is set (by test), 
-- then value of this variable is used - while on production (when this variable is not set)
-- it returns standard current_date() value.
CREATE FUNCTION get_current_date() RETURNS date
BEGIN
    RETURN coalesce( @test_current_date, current_date() );
END$$

-- ===============================================================================================

DELIMITER ;
