----------------------------------------------------------------------------
--                                                                         -
-- Purpose:     Dynamically zip a process's trace file                     -
--                                                                         -
-- Synopsis:    @trc_zip                                                   -
--                                                                         -
-- Description: This script creates a named pipe in place of the process's -
--              trace file and spawns a gzip process to compress it.       -
--                                                                         -
----------------------------------------------------------------------------

COLUMN trc_file new_value trc_file noprint
COLUMN zip_file new_value zip_file noprint

SELECT p.VALUE || '/ora_' || u.spid || '.trc' trc_file,
       p.VALUE || '/ora_' || u.spid || '.trc.gz' zip_file
FROM   sys.v_$session s,
       sys.v_$process u,
       sys.v_$parameter p
WHERE  s.audsid = USERENV('SESSIONID')
  AND  u.addr = s.paddr
  AND  p.NAME = 'user_dump_dest'
/

SET define :
host mknod :trc_file p && nohup gzip < :trc_file > :zip_file &
SET define &

ALTER SESSION SET max_dump_file_size = UNLIMITED
/