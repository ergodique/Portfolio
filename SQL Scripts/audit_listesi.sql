select 'AUDIT '||m.name||decode(u.name,'PUBLIC',' ',' BY '||u.name)||
       decode(nvl(a.success,0)  + (10 * nvl(a.failure,0)),
       1,' BY SESSION WHENEVER SUCCESSFUL ', 
       2,' BY ACCESS WHENEVER SUCCESSFUL ',
       10,' BY SESSION WHENEVER NOT SUCCESSFUL ',
       11,' BY SESSION ',   -- default 
       20, ' BY ACCESS WHENEVER NOT SUCCESSFUL ',
       22, ' BY ACCESS',' /* not possible */ ')||' ;'
 "AUDIT STATEMENT"
        FROM sys.audit$ a, sys.user$ u, sys.stmt_audit_option_map m
        WHERE a.user# = u.user# AND a.option# = m.option#
              and bitand(m.property, 1) != 1  and a.proxy# is null
              and a.user# <> 0
        UNION
select 'AUDIT '||m.name||decode(u1.name,'PUBLIC',' ',' BY '||u1.name)||
       ' ON BEHALF OF '|| decode(u2.name,'SYS','ANY',u2.name)||
       decode(nvl(a.success,0)  + (10 * nvl(a.failure,0)),
       1,' WHENEVER SUCCESSFUL ',
       2,' WHENEVER SUCCESSFUL ',
       10,' WHENEVER NOT SUCCESSFUL ',
       11,' ',   -- default
       20, ' WHENEVER NOT SUCCESSFUL ',
       22, ' ',' /* not possible */ ')||';'
 "AUDIT STATEMENT"
     FROM sys.audit$ a, sys.user$ u1, sys.user$ u2, sys.stmt_audit_option_map m
     WHERE a.user# = u2.user# AND a.option# = m.option# and a.proxy# = u1.user#
              and bitand(m.property, 1) != 1  and a.proxy# is not null 
UNION
select 'AUDIT '||p.name||decode(u.name,'PUBLIC',' ',' BY '||u.name)||
       decode(nvl(a.success,0)  + (10 * nvl(a.failure,0)),
       1,' BY SESSION WHENEVER SUCCESSFUL ',
       2,' BY ACCESS WHENEVER SUCCESSFUL ',
       10,' BY SESSION WHENEVER NOT SUCCESSFUL ',
       11,' BY SESSION ',   -- default
       20, ' BY ACCESS WHENEVER NOT SUCCESSFUL ',
       22, ' BY ACCESS',' /* not possible */ ')||' ;'
 "AUDIT STATEMENT"
        FROM sys.audit$ a, sys.user$ u, sys.system_privilege_map p
        WHERE a.user# = u.user# AND a.option# = -p.privilege
              and bitand(p.property, 1) != 1 and a.proxy# is null
         and a.user# <> 0
UNION
select 'AUDIT '||p.name||decode(u1.name,'PUBLIC',' ',' BY '||u1.name)||
       ' ON BEHALF OF '|| decode(u2.name,'SYS','ANY',u2.name)||
       decode(nvl(a.success,0)  + (10 * nvl(a.failure,0)),
       1,' WHENEVER SUCCESSFUL ',
       2,' WHENEVER SUCCESSFUL ',
       10,' WHENEVER NOT SUCCESSFUL ',
       11,' ',   -- default
       20, ' WHENEVER NOT SUCCESSFUL ',
       22, ' ',' /* not possible */ ')||';'
 "AUDIT STATEMENT"
   FROM sys.audit$ a, sys.user$ u1, sys.user$ u2, sys.system_privilege_map p
   WHERE a.user# = u2.user# AND a.option# = -p.privilege and a.proxy# = u1.user#
              and bitand(p.property, 1) != 1 and a.proxy# is not null 
;