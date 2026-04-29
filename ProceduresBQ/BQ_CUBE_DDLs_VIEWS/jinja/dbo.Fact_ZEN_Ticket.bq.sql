CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_ZEN_Ticket`
	AS SELECT * FROM `{{ project_id }}.{{ dataset_id }}.dv_SAT_ZEN_Ticket`