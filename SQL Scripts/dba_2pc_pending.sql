select * from DBA_2PC_PENDING where state='prepared'

select 'rollback force '''||local_tran_id||''';' from DBA_2PC_PENDING where state='prepared'