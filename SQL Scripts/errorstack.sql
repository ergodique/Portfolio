select spid from v$process where addr in (select paddr from v$session where sid=&X);

errorstack:

sqlplus / as sysdba
oradebug setospid <spid>
oradebug unlimit
oradebug dump errorstack 1 
oradebug dump errorstack 1 
oradebug dump errorstack 3



systemstate:

oradebug setmypid
oradebug unlimit
oradebug -g all hanganalyze 3
oradebug -g all dump systemstate 266

hata verirse yada tamamlanmazsa

oradebug setmypid
oradebug unlimit;
oradebug dump systemstate 10


sqlplus ba�lant�s� yap�lamazsa:
-----------------------------------------------
sqlplus -prelim / as sysdba
oradebug setmypid
oradebug unlimit;
oradebug dump systemstate 10


PMON , bekleyen ve bekleten baz� process ler i�in a�a��daki i�lem
pstack <spid> > 1
pstack <spid> > 2
pstack <spid>  >3
