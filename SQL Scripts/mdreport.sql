alter session set current_schema=MDREPORT;

ALTER TABLE REPORTLEAD ADD (
  CONSTRAINT FK_LEADLKUPSTATUS 
 FOREIGN KEY (STATUSID) 
 REFERENCES REPORTLOOKUPVALUE (ID));

ALTER TABLE REPORTLEAD ADD (
  CONSTRAINT FK_LEADLKUPSTATE 
 FOREIGN KEY (STATEID) 
 REFERENCES REPORTLOOKUPVALUE (ID));

ALTER TABLE REPORTLEAD ADD (
  CONSTRAINT FK_LEADUSERINFO1 
 FOREIGN KEY (ASSIGNEDUSERID) 
 REFERENCES REPORTUSERINFO (USERID));

ALTER TABLE REPORTLEAD ADD (
  CONSTRAINT FK_LEADUSERINFO2 
 FOREIGN KEY (CREATEUSERID) 
 REFERENCES REPORTUSERINFO (USERID));

ALTER TABLE REPORTLEAD ADD (
  CONSTRAINT FK_CAMPCODE 
 FOREIGN KEY (CAMPAIGNCODE) 
 REFERENCES REPORTCAMPAIGN (CAMPAIGNCODE));

ALTER TABLE REPORTLEAD ADD (
  CONSTRAINT FK_BRACODE 
 FOREIGN KEY (BRANCHCODE) 
 REFERENCES REPORTBRANCH (CODE));

ALTER TABLE REPORTLEAD ADD (
  CONSTRAINT FK_LEADPARTYROLE 
 FOREIGN KEY (PARTYROLEID) 
 REFERENCES REPORTPARTYROLE (ID));

ALTER TABLE REPORTLEAD ADD (
  CONSTRAINT FK_LEADCUSTNUMBER 
 FOREIGN KEY (CUSTOMERNUMBER) 
 REFERENCES REPORTCUSTOMER (CUSTOMERNUMBER));


ALTER TABLE REPORTLEAD ADD (
  CONSTRAINT FK_ORIGBRACODE 
 FOREIGN KEY (ORIGBRANCHCODE) 
 REFERENCES RERPORTBRANCH (CODE));

ALTER TABLE REPORTLEADHISTORY ADD (
  CONSTRAINT FK_LEADHISTUSRINFO 
 FOREIGN KEY (USERID) 
 REFERENCES REPORTUSERINFO (USERID));

ALTER TABLE REPORTLEADHISTORY ADD (
  CONSTRAINT FK_LEADHISTLEAD 
 FOREIGN KEY (LEADID) 
 REFERENCES REPORTLEAD (PARTYROLEID)
    ON DELETE CASCADE);