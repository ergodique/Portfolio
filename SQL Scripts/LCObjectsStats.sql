
REM 
REM  Filename: LCObjectsStats.sql
REM
REM   This will breakdown the pinned and non-pinned objects 
REM    in the library cache and sum up the memory required
REM    for each type of object
REM
REM    If you see large objects listed that are not pinned, 
REM    they can cause fragmentation over time if they get
REM    flushed out and reloaded.
REM
REM    Runs on 8i/9i/9.2/10g

col kept format a5
col type format a20
col memory format 999,999,999,999,999

select kept, type, sum(sharable_mem) memory
from v$db_object_cache
group by kept, type
order by 1, 3 desc;

/*----------------------------------------------------------------------

KEPT  TYPE                               MEMORY
---------- ------------------------------- --------------------
NO       CLUSTER                                     1,600
NO       CURSOR                               2,257,525
NO       INDEX                                         20,712
NO       NON-EXISTENT                          1,729
NO       NOT LOADED                                     0
NO       PACKAGE                               504,431
NO       PACKAGE BODY                   146,860
NO       PUB_SUB                                    2,020
NO       QUEUE                                       12,813
NO       SEQUENCE                                    867
NO       TABLE                                      231,758
NO       TRIGGER                                      5,984
NO       TYPE                                             4,463
NO       VIEW                                           69,750
YES     CLUSTER                                     8,317
YES     INDEX                                           3,046
YES     TABLE                                        33,904

*/