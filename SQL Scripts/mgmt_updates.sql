select * from sysman.mgmt_targets
   where host_name = 'dbracora01.isbank'
   
update sysman.mgmt_targets
   set emd_url='http://dbracora01.isbank:1830/emd/main/'
      where host_name = 'dbracora01.isbank'
	  
commit

rollback
--   where target_guid='5390606ED01E79FFBE2E59B744BDCE6A'

select * from sysman.mgmt_targets_delete 
   where target_guid='5390606ED01E79FFBE2E59B744BDCE6A'

--select * from sysman.mgmt_targets_delete 
--  where target_guid='03993D0A5ACEA84E6564FFBDD3337C20'

update sysman.mgmt_targets_delete
  set emd_url='http://dbracora02.isbank:1831/emd/main/'
  where target_guid='5390606ED01E79FFBE2E59B744BDCE6A'
  
commit


Insert into sysman.mgmt_targets_delete
   (TARGET_NAME, TARGET_TYPE, TARGET_GUID, EMD_URL, TIMEZONE_REGION, DELETE_REQUEST_TIME, DELETE_COMPLETE_TIME, LAST_UPDATED_TIME)
 Values
   ('ORADWH', 'rac_database', '03993D0A5ACEA84E6564FFBDD3337C20', 'http://dbracora01.isbank:1830/emd/main/', 'Turkey', TO_DATE('05/20/2005 15:36:29', 'MM/DD/YYYY HH24:MI:SS'), TO_DATE('05/20/2005 15:50:04', 'MM/DD/YYYY HH24:MI:SS'), TO_DATE('05/20/2005 15:36:29', 'MM/DD/YYYY HH24:MI:SS'))

   
   
select a.*, b.* from sysman.mgmt_targets b, sysman.mgmt_credentials2 a 
where b.target_guid=a.assoc_target_guid
and b.host_name='dbracora02.isbank'


