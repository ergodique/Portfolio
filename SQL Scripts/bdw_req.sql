alter system set undo_retention = 10800 scope=both;

alter system set db_writer_processes = 2 scope=spfile;

alter system set db_files = 8192 scope=spfile;

alter system set parallel_execution_message_size = 4096 scope=spfile;

alter system set open_cursors = 600 scope=spfile;

alter system set processes = 300 scope=spfile;

alter system set fast_start_mttr_target = 300 scope=spfile;

alter system set resource_limit = TRUE scope=spfile;

alter system set star_transformation_enabled = TRUE scope=spfile;