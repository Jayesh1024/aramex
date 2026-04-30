CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.vw_dv_SAT_Customer_OES`
AS
SELECT 
    *
FROM `{{ project_id }}.{{ dataset_id }}.OnlineEnquiries_NEW_dbo_tblCustomer` 