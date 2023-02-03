 grant all privilege to icmadmin;                                     
 grant connect, execute any procedure to icmconct; 
 grant all privilege to rmadmin;   

create tablespace OBJINDX                                                
   datafile '/oradata/oraint01/OLINT/RM/data/objndx_01.dbf'       
   size 30M reuse                                                       
   autoextend on next 30M maxsize 120M                                  
   extent management local autoallocate;                                

 create tablespace OBJECTS                                              
   datafile '/oradata/oraint01/OLINT/RM/data/objects_01.dbf'      
   size 50M reuse                                                       
   autoextend on next 50M maxsize UNLIMITED                             
   extent management local autoallocate;                                

 create tablespace SMS                                                
   datafile '/oradata/oraint01/OLINT/RM/data/sms_01.dbf'          
   size 2M  reuse                                                       
   autoextend on next 2M maxsize UNLIMITED                              
   extent management local autoallocate;                                

 create tablespace BLOBS                                                
   datafile '/oradata/oraint01/OLINT/RM/data/blobs_01.dbf'        
   size 50M reuse                                                       
   autoextend on next 50M maxsize UNLIMITED                             
   extent management local autoallocate;                                

 create tablespace REPLICAS                                             
   datafile '/oradata/oraint01/OLINT/RM/data/replicas_01.dbf'     
   size 10M reuse                                                       
   autoextend on next 10M maxsize 1000M                                 
   extent management local autoallocate;                                

 create tablespace TRACKING                                             
   datafile '/oradata/oraint01/OLINT/RM/data/tracking_01.dbf'     
   size 2M reuse                                                        
   autoextend on next 2M maxsize 250M                                   
   extent management local autoallocate;                                

 create tablespace VALIDATEITM                                             
   datafile '/oradata/oraint01/OLINT/RM/data/validateitm_01.dbf'  
   size 10M reuse                                                       
   autoextend on next 10M maxsize 250M                                  
   extent management local autoallocate;  