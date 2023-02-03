alter system set processes = 600 scope=spfile;

alter system set sessions = 600 scope=spfile;

alter system set db_files = 600 scope=spfile;

alter system set session_cached_cursors = 400 scope=spfile;

alter system set open_cursors = 600 scope=spfile;

alter system set cursor_sharing = 'SIMILAR' scope=spfile;

alter system set log_archive_dest_1 = 'LOCATION=/ocfs/arch01/RACPR' scope=both;

alter tablespace users rename to users_old;

instance_groups

parallel_instance_group

select * from v$parameter

