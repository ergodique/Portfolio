select 'NOAUDIT '||m.name||decode(u.name,'PUBLIC',' ',' BY '||u.name)||
              decode(nvl(a.success,0)  + (10 * nvl(a.failure,0)),
       1,' WHENEVER SUCCESSFUL ',
       2,' WHENEVER SUCCESSFUL ',
       10,' WHENEVER NOT SUCCESSFUL ',
       11,' ', 
       20, ' WHENEVER NOT SUCCESSFUL ',
       22, ' ',' /* not possible */ ')||' ;'
 "NOAUDIT STATEMENT"
        FROM sys.audit$ a, sys.user$ u, sys.stmt_audit_option_map m
        WHERE a.user# = u.user# AND a.option# = m.option#
              and bitand(m.property, 1) != 1 and a.proxy# is null
              and a.user# <> 0
UNION
select 'NOAUDIT '||m.name||decode(u1.name,'PUBLIC',' ',' BY '||u1.name)||
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
select 'NOAUDIT '||p.name||decode(u.name,'PUBLIC',' ',' BY '||u.name)||
       decode(nvl(a.success,0)  + (10 * nvl(a.failure,0)),
       1,' WHENEVER SUCCESSFUL ',
       2,' WHENEVER SUCCESSFUL ',
       10,' WHENEVER NOT SUCCESSFUL ',
       11,' ',   -- default
       20, ' WHENEVER NOT SUCCESSFUL ',
       22, ' ',' /* not possible */ ')||' ;'
 "NOAUDIT STATEMENT"
        FROM sys.audit$ a, sys.user$ u, sys.system_privilege_map p
        WHERE a.user# = u.user# AND a.option# = -p.privilege
              and bitand(p.property, 1) != 1  and a.proxy# is null
              and a.user# <> 0
UNION
select 'NOAUDIT '||p.name||decode(u1.name,'PUBLIC',' ',' BY '||u1.name)||
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
              and bitand(p.property, 1) != 1 and a.proxy# is not null;

select unique 
 '-- Please correct the problem described in note 455565.1:'
 ||chr(13)||chr(10)||
 'delete from sys.audit$ where user#=0 and proxy# is null;'
 ||chr(13)||chr(10)||'commit;'
 from sys.audit$  where user#=0 and proxy# is null;

select '-- Please correct the problem described in bug 6636804:'
  ||chr(13)||chr(10)||
  'update sys.STMT_AUDIT_OPTION_MAP set option#=234'
  ||chr(13)||chr(10)||' where name =''ON COMMIT REFRESH'';'
  ||chr(13)||chr(10)||'commit;'
  from  sys.STMT_AUDIT_OPTION_MAP where option#=229 and name ='ON COMMIT REFRESH';

select
 '-- Please correct the problem described in bug 6124447:'
 ||chr(13)||chr(10)||
 'noaudit truncate;'
 from sys.audit$ where option#=155;