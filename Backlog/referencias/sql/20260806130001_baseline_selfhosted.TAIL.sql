SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

CREATE OR REPLACE TRIGGER "cascade_pause_on_deactivate" BEFORE UPDATE OF "is_active" ON "org_blips"."workflows" FOR EACH ROW EXECUTE FUNCTION "org_blips"."cascade_pause_campaigns_on_workflow_deactivate"();



CREATE OR REPLACE TRIGGER "check_filter_definition_not_in_blocklist_rule" BEFORE DELETE ON "org_blips"."filter_definitions" FOR EACH ROW EXECUTE FUNCTION "org_blips"."_check_filter_definition_not_in_blocklist_rule"();



CREATE OR REPLACE TRIGGER "check_filter_rule_filter_definition_exists" BEFORE INSERT OR UPDATE OF "filter_definition_id" ON "org_blips"."blocklist_filter_rules" FOR EACH ROW EXECUTE FUNCTION "org_blips"."_check_filter_rule_filter_definition_exists"();



CREATE OR REPLACE TRIGGER "contact_seals_scope_check" BEFORE INSERT OR UPDATE OF "seal_id" ON "org_blips"."contact_seals" FOR EACH ROW EXECUTE FUNCTION "org_blips"."enforce_seal_scope"('contact');



CREATE OR REPLACE TRIGGER "contract_seals_scope_check" BEFORE INSERT OR UPDATE OF "seal_id" ON "org_blips"."contract_seals" FOR EACH ROW EXECUTE FUNCTION "org_blips"."enforce_seal_scope"('contract');



CREATE OR REPLACE TRIGGER "supply_seals_scope_check" BEFORE INSERT OR UPDATE OF "seal_id" ON "org_blips"."supply_seals" FOR EACH ROW EXECUTE FUNCTION "org_blips"."enforce_seal_scope"('supply');



CREATE OR REPLACE TRIGGER "supply_title_seals_scope_check" BEFORE INSERT OR UPDATE OF "seal_id" ON "org_blips"."supply_title_seals" FOR EACH ROW EXECUTE FUNCTION "org_blips"."enforce_seal_scope"('supply_title');



CREATE OR REPLACE TRIGGER "title_seals_scope_check" BEFORE INSERT OR UPDATE OF "seal_id" ON "org_blips"."title_seals" FOR EACH ROW EXECUTE FUNCTION "org_blips"."enforce_seal_scope"('title');



CREATE OR REPLACE TRIGGER "tr_sync_is_blocked_legacy" AFTER INSERT OR DELETE OR UPDATE ON "org_blips"."blocklist" FOR EACH ROW EXECUTE FUNCTION "org_blips"."tr_fn_sync_is_blocked_legacy"();



CREATE OR REPLACE TRIGGER "tr_sync_is_blocked_v2" AFTER INSERT OR DELETE OR UPDATE ON "org_blips"."blocklist_entries" FOR EACH ROW EXECUTE FUNCTION "org_blips"."tr_fn_sync_is_blocked_v2"();



CREATE OR REPLACE TRIGGER "trg_action_override_guard" BEFORE INSERT OR UPDATE ON "org_blips"."actions" FOR EACH ROW EXECUTE FUNCTION "org_blips"."enforce_action_override_guard"();



CREATE OR REPLACE TRIGGER "trg_ai_agents_seed_funnel_stages" AFTER INSERT ON "org_blips"."ai_agents" FOR EACH ROW EXECUTE FUNCTION "org_blips"."seed_default_funnel_stages"();



COMMENT ON TRIGGER "trg_ai_agents_seed_funnel_stages" ON "org_blips"."ai_agents" IS 'Todo agente novo nasce com os 4 estagios canonicos de funil (IAF-3989). Ver seed_default_funnel_stages().';



CREATE OR REPLACE TRIGGER "trg_ai_agents_tombstone_protect" BEFORE INSERT OR UPDATE ON "org_blips"."ai_agents" FOR EACH ROW EXECUTE FUNCTION "public"."ai_agents_protect_tombstone"();



CREATE OR REPLACE TRIGGER "trg_ai_versions_block_deleted_agent" BEFORE INSERT OR UPDATE ON "org_blips"."ai_versions" FOR EACH ROW EXECUTE FUNCTION "public"."ai_versions_block_deleted_agent"();



CREATE OR REPLACE TRIGGER "trg_audit_filter_conditions" AFTER UPDATE ON "org_blips"."filter_definitions" FOR EACH ROW EXECUTE FUNCTION "org_blips"."audit_filter_conditions_change"();



CREATE OR REPLACE TRIGGER "trg_audit_filter_deletion" BEFORE DELETE ON "org_blips"."filter_definitions" FOR EACH ROW EXECUTE FUNCTION "org_blips"."audit_filter_deletion"();



CREATE OR REPLACE TRIGGER "trg_calculate_days_overdue" BEFORE INSERT OR UPDATE OF "due_date", "status" ON "org_blips"."titles" FOR EACH ROW EXECUTE FUNCTION "org_blips"."calculate_title_days_overdue"();



CREATE OR REPLACE TRIGGER "trg_contact_assignments_updated_at" BEFORE UPDATE ON "org_blips"."contact_assignments" FOR EACH ROW EXECUTE FUNCTION "public"."update_contact_assignments_updated_at"();



CREATE OR REPLACE TRIGGER "trg_contact_document_type" BEFORE INSERT OR UPDATE OF "document", "document_type" ON "org_blips"."contacts" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_contact_document_type"();



CREATE OR REPLACE TRIGGER "trg_contact_summary_refresh" AFTER UPDATE ON "org_blips"."contacts" FOR EACH ROW EXECUTE FUNCTION "org_blips"."trigger_refresh_contact_on_update"();



CREATE OR REPLACE TRIGGER "trg_contract_summary_refresh" AFTER INSERT OR DELETE OR UPDATE ON "org_blips"."contracts" FOR EACH ROW EXECUTE FUNCTION "org_blips"."trigger_refresh_contract_summary"();



CREATE OR REPLACE TRIGGER "trg_filter_target_entity_coherent" BEFORE INSERT OR UPDATE OF "conditions", "target_entity" ON "org_blips"."filter_definitions" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_filter_target_entity"();



CREATE OR REPLACE TRIGGER "trg_filter_usage_scope_immutable" BEFORE UPDATE OF "usage_scope" ON "org_blips"."filter_definitions" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_filter_usage_scope_immutable"();



CREATE OR REPLACE TRIGGER "trg_rag_documents_updated_at" BEFORE UPDATE ON "org_blips"."rag_documents" FOR EACH ROW EXECUTE FUNCTION "org_blips"."rag_documents_updated_at"();



CREATE OR REPLACE TRIGGER "trg_seal_catalog_updated_at" BEFORE UPDATE ON "org_blips"."seal_catalog" FOR EACH ROW EXECUTE FUNCTION "org_blips"."set_seal_catalog_updated_at"();



CREATE OR REPLACE TRIGGER "trg_supply_calculate_days_overdue" BEFORE INSERT OR UPDATE OF "due_date", "status" ON "org_blips"."supply_titles" FOR EACH ROW EXECUTE FUNCTION "org_blips"."calculate_supply_title_days_overdue"();



CREATE OR REPLACE TRIGGER "trg_supply_title_status_history" AFTER UPDATE OF "status", "removed_at" ON "org_blips"."supply_titles" FOR EACH ROW WHEN (((("old"."status")::"text" IS DISTINCT FROM ("new"."status")::"text") OR ("old"."removed_at" IS DISTINCT FROM "new"."removed_at"))) EXECUTE FUNCTION "public"."fn_supply_title_status_history"();



CREATE OR REPLACE TRIGGER "trg_sync_campaign_workflows" AFTER INSERT OR UPDATE OF "target_reguas" ON "org_blips"."campaigns" FOR EACH ROW EXECUTE FUNCTION "org_blips"."sync_campaign_workflows"();



CREATE OR REPLACE TRIGGER "trg_sync_workflow_assignment_filters" BEFORE INSERT OR UPDATE OF "assignment_filters" ON "org_blips"."workflows" FOR EACH ROW EXECUTE FUNCTION "public"."sync_workflow_assignment_filters"();



CREATE OR REPLACE TRIGGER "trg_title_status_history" AFTER UPDATE OF "status", "removed_at" ON "org_blips"."titles" FOR EACH ROW WHEN (((("old"."status")::"text" IS DISTINCT FROM ("new"."status")::"text") OR ("old"."removed_at" IS DISTINCT FROM "new"."removed_at"))) EXECUTE FUNCTION "public"."fn_title_status_history"();



CREATE OR REPLACE TRIGGER "trg_title_summary_refresh" AFTER INSERT OR DELETE OR UPDATE ON "org_blips"."titles" FOR EACH ROW EXECUTE FUNCTION "org_blips"."trigger_refresh_title_summary"();



CREATE OR REPLACE TRIGGER "trg_update_workflow_steps_count" AFTER INSERT OR DELETE ON "org_blips"."workflow_steps" FOR EACH ROW EXECUTE FUNCTION "org_blips"."update_workflow_steps_count"();



CREATE OR REPLACE TRIGGER "trigger_update_contract_totals" AFTER INSERT OR DELETE OR UPDATE ON "org_blips"."titles" FOR EACH ROW EXECUTE FUNCTION "org_blips"."update_contract_totals"();



CREATE OR REPLACE TRIGGER "trigger_update_supply_totals" AFTER INSERT OR DELETE OR UPDATE ON "org_blips"."supply_titles" FOR EACH ROW EXECUTE FUNCTION "org_blips"."update_supply_totals"();



CREATE OR REPLACE TRIGGER "update_actions_updated_at" BEFORE UPDATE ON "org_blips"."actions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_blocked_dates_updated_at" BEFORE UPDATE ON "org_blips"."blocked_dates" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_blocklist_entries_updated_at" BEFORE UPDATE ON "org_blips"."blocklist_entries" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_blocklist_filter_rules_updated_at" BEFORE UPDATE ON "org_blips"."blocklist_filter_rules" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_blocklist_updated_at" BEFORE UPDATE ON "org_blips"."blocklist" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_campaigns_updated_at" BEFORE UPDATE ON "org_blips"."campaigns" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_channel_costs_updated_at" BEFORE UPDATE ON "org_blips"."channel_costs" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_channel_rate_limits_updated_at" BEFORE UPDATE ON "org_blips"."channel_rate_limits" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_contact_emails_updated_at" BEFORE UPDATE ON "org_blips"."contact_emails" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_contact_phones_updated_at" BEFORE UPDATE ON "org_blips"."contact_phones" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_contacts_updated_at" BEFORE UPDATE ON "org_blips"."contacts" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_contracts_updated_at" BEFORE UPDATE ON "org_blips"."contracts" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_custom_fields_updated_at" BEFORE UPDATE ON "org_blips"."custom_field_definitions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_data_sources_updated_at" BEFORE UPDATE ON "org_blips"."data_sources" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_etl_pipelines_updated_at" BEFORE UPDATE ON "org_blips"."etl_pipelines" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_filter_definitions_updated_at" BEFORE UPDATE ON "org_blips"."filter_definitions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_integration_secrets_updated_at" BEFORE UPDATE ON "org_blips"."integration_secrets" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_integrations_updated_at" BEFORE UPDATE ON "org_blips"."integrations" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_portfolio_integrations_updated_at" BEFORE UPDATE ON "org_blips"."portfolio_integrations" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_standard_values_updated_at" BEFORE UPDATE ON "org_blips"."standard_values" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_supplies_updated_at" BEFORE UPDATE ON "org_blips"."supplies" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_supply_titles_updated_at" BEFORE UPDATE ON "org_blips"."supply_titles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_titles_updated_at" BEFORE UPDATE ON "org_blips"."titles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_workflow_executions_updated_at" BEFORE UPDATE ON "org_blips"."workflow_executions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_workflow_steps_updated_at" BEFORE UPDATE ON "org_blips"."workflow_steps" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_workflows_updated_at" BEFORE UPDATE ON "org_blips"."workflows" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "cascade_pause_on_deactivate" BEFORE UPDATE OF "is_active" ON "org_finza"."workflows" FOR EACH ROW EXECUTE FUNCTION "org_finza"."cascade_pause_campaigns_on_workflow_deactivate"();



CREATE OR REPLACE TRIGGER "check_filter_definition_not_in_blocklist_rule" BEFORE DELETE ON "org_finza"."filter_definitions" FOR EACH ROW EXECUTE FUNCTION "org_finza"."_check_filter_definition_not_in_blocklist_rule"();



CREATE OR REPLACE TRIGGER "check_filter_rule_filter_definition_exists" BEFORE INSERT OR UPDATE OF "filter_definition_id" ON "org_finza"."blocklist_filter_rules" FOR EACH ROW EXECUTE FUNCTION "org_finza"."_check_filter_rule_filter_definition_exists"();



CREATE OR REPLACE TRIGGER "contact_seals_scope_check" BEFORE INSERT OR UPDATE OF "seal_id" ON "org_finza"."contact_seals" FOR EACH ROW EXECUTE FUNCTION "org_finza"."enforce_seal_scope"('contact');



CREATE OR REPLACE TRIGGER "contract_seals_scope_check" BEFORE INSERT OR UPDATE OF "seal_id" ON "org_finza"."contract_seals" FOR EACH ROW EXECUTE FUNCTION "org_finza"."enforce_seal_scope"('contract');



CREATE OR REPLACE TRIGGER "supply_seals_scope_check" BEFORE INSERT OR UPDATE OF "seal_id" ON "org_finza"."supply_seals" FOR EACH ROW EXECUTE FUNCTION "org_finza"."enforce_seal_scope"('supply');



CREATE OR REPLACE TRIGGER "supply_title_seals_scope_check" BEFORE INSERT OR UPDATE OF "seal_id" ON "org_finza"."supply_title_seals" FOR EACH ROW EXECUTE FUNCTION "org_finza"."enforce_seal_scope"('supply_title');



CREATE OR REPLACE TRIGGER "title_seals_scope_check" BEFORE INSERT OR UPDATE OF "seal_id" ON "org_finza"."title_seals" FOR EACH ROW EXECUTE FUNCTION "org_finza"."enforce_seal_scope"('title');



CREATE OR REPLACE TRIGGER "tr_sync_is_blocked_legacy" AFTER INSERT OR DELETE OR UPDATE ON "org_finza"."blocklist" FOR EACH ROW EXECUTE FUNCTION "org_finza"."tr_fn_sync_is_blocked_legacy"();



CREATE OR REPLACE TRIGGER "tr_sync_is_blocked_v2" AFTER INSERT OR DELETE OR UPDATE ON "org_finza"."blocklist_entries" FOR EACH ROW EXECUTE FUNCTION "org_finza"."tr_fn_sync_is_blocked_v2"();



CREATE OR REPLACE TRIGGER "trg_action_override_guard" BEFORE INSERT OR UPDATE ON "org_finza"."actions" FOR EACH ROW EXECUTE FUNCTION "org_finza"."enforce_action_override_guard"();



CREATE OR REPLACE TRIGGER "trg_ai_agents_seed_funnel_stages" AFTER INSERT ON "org_finza"."ai_agents" FOR EACH ROW EXECUTE FUNCTION "org_finza"."seed_default_funnel_stages"();



COMMENT ON TRIGGER "trg_ai_agents_seed_funnel_stages" ON "org_finza"."ai_agents" IS 'Todo agente novo nasce com os 4 estagios canonicos de funil (IAF-3989). Ver seed_default_funnel_stages().';



CREATE OR REPLACE TRIGGER "trg_ai_agents_tombstone_protect" BEFORE INSERT OR UPDATE ON "org_finza"."ai_agents" FOR EACH ROW EXECUTE FUNCTION "public"."ai_agents_protect_tombstone"();



CREATE OR REPLACE TRIGGER "trg_ai_versions_block_deleted_agent" BEFORE INSERT OR UPDATE ON "org_finza"."ai_versions" FOR EACH ROW EXECUTE FUNCTION "public"."ai_versions_block_deleted_agent"();



CREATE OR REPLACE TRIGGER "trg_audit_filter_conditions" AFTER UPDATE ON "org_finza"."filter_definitions" FOR EACH ROW EXECUTE FUNCTION "org_finza"."audit_filter_conditions_change"();



CREATE OR REPLACE TRIGGER "trg_audit_filter_deletion" BEFORE DELETE ON "org_finza"."filter_definitions" FOR EACH ROW EXECUTE FUNCTION "org_finza"."audit_filter_deletion"();



CREATE OR REPLACE TRIGGER "trg_calculate_days_overdue" BEFORE INSERT OR UPDATE OF "due_date", "status" ON "org_finza"."titles" FOR EACH ROW EXECUTE FUNCTION "org_finza"."calculate_title_days_overdue"();



CREATE OR REPLACE TRIGGER "trg_contact_assignments_updated_at" BEFORE UPDATE ON "org_finza"."contact_assignments" FOR EACH ROW EXECUTE FUNCTION "public"."update_contact_assignments_updated_at"();



CREATE OR REPLACE TRIGGER "trg_contact_document_type" BEFORE INSERT OR UPDATE OF "document", "document_type" ON "org_finza"."contacts" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_contact_document_type"();



CREATE OR REPLACE TRIGGER "trg_contact_summary_refresh" AFTER UPDATE ON "org_finza"."contacts" FOR EACH ROW EXECUTE FUNCTION "org_finza"."trigger_refresh_contact_on_update"();



CREATE OR REPLACE TRIGGER "trg_contract_summary_refresh" AFTER INSERT OR DELETE OR UPDATE ON "org_finza"."contracts" FOR EACH ROW EXECUTE FUNCTION "org_finza"."trigger_refresh_contract_summary"();



CREATE OR REPLACE TRIGGER "trg_filter_target_entity_coherent" BEFORE INSERT OR UPDATE OF "conditions", "target_entity" ON "org_finza"."filter_definitions" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_filter_target_entity"();



CREATE OR REPLACE TRIGGER "trg_filter_usage_scope_immutable" BEFORE UPDATE OF "usage_scope" ON "org_finza"."filter_definitions" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_filter_usage_scope_immutable"();



CREATE OR REPLACE TRIGGER "trg_rag_documents_updated_at" BEFORE UPDATE ON "org_finza"."rag_documents" FOR EACH ROW EXECUTE FUNCTION "org_finza"."rag_documents_updated_at"();



CREATE OR REPLACE TRIGGER "trg_seal_catalog_updated_at" BEFORE UPDATE ON "org_finza"."seal_catalog" FOR EACH ROW EXECUTE FUNCTION "org_finza"."set_seal_catalog_updated_at"();



CREATE OR REPLACE TRIGGER "trg_supply_calculate_days_overdue" BEFORE INSERT OR UPDATE OF "due_date", "status" ON "org_finza"."supply_titles" FOR EACH ROW EXECUTE FUNCTION "org_finza"."calculate_supply_title_days_overdue"();



CREATE OR REPLACE TRIGGER "trg_supply_title_status_history" AFTER UPDATE OF "status", "removed_at" ON "org_finza"."supply_titles" FOR EACH ROW WHEN (((("old"."status")::"text" IS DISTINCT FROM ("new"."status")::"text") OR ("old"."removed_at" IS DISTINCT FROM "new"."removed_at"))) EXECUTE FUNCTION "public"."fn_supply_title_status_history"();



CREATE OR REPLACE TRIGGER "trg_sync_campaign_workflows" AFTER INSERT OR UPDATE OF "target_reguas" ON "org_finza"."campaigns" FOR EACH ROW EXECUTE FUNCTION "org_finza"."sync_campaign_workflows"();



CREATE OR REPLACE TRIGGER "trg_sync_workflow_assignment_filters" BEFORE INSERT OR UPDATE OF "assignment_filters" ON "org_finza"."workflows" FOR EACH ROW EXECUTE FUNCTION "public"."sync_workflow_assignment_filters"();



CREATE OR REPLACE TRIGGER "trg_title_status_history" AFTER UPDATE OF "status", "removed_at" ON "org_finza"."titles" FOR EACH ROW WHEN (((("old"."status")::"text" IS DISTINCT FROM ("new"."status")::"text") OR ("old"."removed_at" IS DISTINCT FROM "new"."removed_at"))) EXECUTE FUNCTION "public"."fn_title_status_history"();



CREATE OR REPLACE TRIGGER "trg_title_summary_refresh" AFTER INSERT OR DELETE OR UPDATE ON "org_finza"."titles" FOR EACH ROW EXECUTE FUNCTION "org_finza"."trigger_refresh_title_summary"();



CREATE OR REPLACE TRIGGER "trg_update_workflow_steps_count" AFTER INSERT OR DELETE ON "org_finza"."workflow_steps" FOR EACH ROW EXECUTE FUNCTION "org_finza"."update_workflow_steps_count"();



CREATE OR REPLACE TRIGGER "trigger_update_contract_totals" AFTER INSERT OR DELETE OR UPDATE ON "org_finza"."titles" FOR EACH ROW EXECUTE FUNCTION "org_finza"."update_contract_totals"();



CREATE OR REPLACE TRIGGER "trigger_update_supply_totals" AFTER INSERT OR DELETE OR UPDATE ON "org_finza"."supply_titles" FOR EACH ROW EXECUTE FUNCTION "org_finza"."update_supply_totals"();



CREATE OR REPLACE TRIGGER "update_actions_updated_at" BEFORE UPDATE ON "org_finza"."actions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_blocked_dates_updated_at" BEFORE UPDATE ON "org_finza"."blocked_dates" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_blocklist_entries_updated_at" BEFORE UPDATE ON "org_finza"."blocklist_entries" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_blocklist_filter_rules_updated_at" BEFORE UPDATE ON "org_finza"."blocklist_filter_rules" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_blocklist_updated_at" BEFORE UPDATE ON "org_finza"."blocklist" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_campaigns_updated_at" BEFORE UPDATE ON "org_finza"."campaigns" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_channel_costs_updated_at" BEFORE UPDATE ON "org_finza"."channel_costs" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_channel_rate_limits_updated_at" BEFORE UPDATE ON "org_finza"."channel_rate_limits" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_contact_emails_updated_at" BEFORE UPDATE ON "org_finza"."contact_emails" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_contact_phones_updated_at" BEFORE UPDATE ON "org_finza"."contact_phones" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_contacts_updated_at" BEFORE UPDATE ON "org_finza"."contacts" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_contracts_updated_at" BEFORE UPDATE ON "org_finza"."contracts" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_custom_fields_updated_at" BEFORE UPDATE ON "org_finza"."custom_field_definitions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_data_sources_updated_at" BEFORE UPDATE ON "org_finza"."data_sources" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_etl_pipelines_updated_at" BEFORE UPDATE ON "org_finza"."etl_pipelines" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_filter_definitions_updated_at" BEFORE UPDATE ON "org_finza"."filter_definitions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_integration_secrets_updated_at" BEFORE UPDATE ON "org_finza"."integration_secrets" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_integrations_updated_at" BEFORE UPDATE ON "org_finza"."integrations" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_portfolio_integrations_updated_at" BEFORE UPDATE ON "org_finza"."portfolio_integrations" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_standard_values_updated_at" BEFORE UPDATE ON "org_finza"."standard_values" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_supplies_updated_at" BEFORE UPDATE ON "org_finza"."supplies" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_supply_titles_updated_at" BEFORE UPDATE ON "org_finza"."supply_titles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_titles_updated_at" BEFORE UPDATE ON "org_finza"."titles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_workflow_executions_updated_at" BEFORE UPDATE ON "org_finza"."workflow_executions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_workflow_steps_updated_at" BEFORE UPDATE ON "org_finza"."workflow_steps" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_workflows_updated_at" BEFORE UPDATE ON "org_finza"."workflows" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "on_organization_created" AFTER INSERT ON "public"."organizations" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_setup_org_schema"();



CREATE OR REPLACE TRIGGER "trg_prevent_protected_org_deletion" BEFORE DELETE ON "public"."organizations" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_protected_org_deletion"();



COMMENT ON TRIGGER "trg_prevent_protected_org_deletion" ON "public"."organizations" IS 'M010: bloqueia DELETE de orgs protegidas e exige super_admin. Ver function comment.';



CREATE OR REPLACE TRIGGER "trg_prevent_protected_org_slug_rename" BEFORE UPDATE OF "slug" ON "public"."organizations" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_protected_org_slug_rename"();



COMMENT ON TRIGGER "trg_prevent_protected_org_slug_rename" ON "public"."organizations" IS 'M046: bloqueia UPDATE de slug protegido (blips) ou squat de slug protegido. Ver function comment.';



CREATE OR REPLACE TRIGGER "trigger_org_secrets_updated_at" BEFORE UPDATE ON "public"."organization_secrets" FOR EACH ROW EXECUTE FUNCTION "public"."update_org_secrets_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_organization_created" AFTER INSERT ON "public"."organizations" FOR EACH ROW EXECUTE FUNCTION "public"."on_organization_created"();



CREATE OR REPLACE TRIGGER "trigger_setup_org_moved_tables" AFTER INSERT ON "public"."organizations" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_setup_org_moved_tables"();



CREATE OR REPLACE TRIGGER "trigger_setup_org_tables" AFTER INSERT ON "public"."organizations" FOR EACH ROW EXECUTE FUNCTION "public"."on_organization_created"();



CREATE OR REPLACE TRIGGER "trigger_setup_webhook_retry_queue" AFTER INSERT ON "public"."organizations" FOR EACH ROW EXECUTE FUNCTION "public"."setup_webhook_retry_queue"();



CREATE OR REPLACE TRIGGER "update_marketplace_integrations_updated_at" BEFORE UPDATE ON "public"."marketplace_integrations" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_org_marketplace_updated_at" BEFORE UPDATE ON "public"."organization_marketplace_integrations" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_org_users_updated_at" BEFORE UPDATE ON "public"."organization_users" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_organizations_updated_at" BEFORE UPDATE ON "public"."organizations" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "org_blips"."a2a_closure_config"
    ADD CONSTRAINT "a2a_closure_config_agent_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_blips"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."actions"
    ADD CONSTRAINT "actions_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "org_blips"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."actions"
    ADD CONSTRAINT "actions_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."actions"
    ADD CONSTRAINT "actions_contract_id_fkey" FOREIGN KEY ("contract_id") REFERENCES "org_blips"."contracts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."actions"
    ADD CONSTRAINT "actions_integration_id_fkey" FOREIGN KEY ("integration_id") REFERENCES "org_blips"."integrations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."actions_interaction_logs"
    ADD CONSTRAINT "actions_interaction_logs_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_blips"."ai_agents"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."actions_interaction_logs"
    ADD CONSTRAINT "actions_interaction_logs_transfer_tag_id_fkey" FOREIGN KEY ("transfer_tag_id") REFERENCES "org_blips"."transfer_tags"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."actions"
    ADD CONSTRAINT "actions_supply_id_fkey" FOREIGN KEY ("supply_id") REFERENCES "org_blips"."supplies"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."actions"
    ADD CONSTRAINT "actions_supply_title_id_fkey" FOREIGN KEY ("supply_title_id") REFERENCES "org_blips"."supply_titles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."actions"
    ADD CONSTRAINT "actions_title_id_fkey" FOREIGN KEY ("title_id") REFERENCES "org_blips"."titles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."actions"
    ADD CONSTRAINT "actions_workflow_execution_id_fkey" FOREIGN KEY ("workflow_execution_id") REFERENCES "org_blips"."workflow_executions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."actions"
    ADD CONSTRAINT "actions_workflow_step_id_fkey" FOREIGN KEY ("workflow_step_id") REFERENCES "org_blips"."workflow_steps"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."agent_allowed_tags"
    ADD CONSTRAINT "agent_allowed_tags_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_blips"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."agent_allowed_tags"
    ADD CONSTRAINT "agent_allowed_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "org_blips"."tag_catalog"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."agent_call_logs"
    ADD CONSTRAINT "agent_call_logs_protocol_fkey" FOREIGN KEY ("protocol") REFERENCES "org_blips"."ai_protocols"("protocol") ON DELETE SET NULL NOT VALID;



ALTER TABLE ONLY "org_blips"."agent_call_logs"
    ADD CONSTRAINT "agent_call_logs_receiving_agent_id_fkey" FOREIGN KEY ("receiving_agent_id") REFERENCES "org_blips"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."ai_business_rules"
    ADD CONSTRAINT "ai_business_rules_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_blips"."ai_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."ai_conversations"
    ADD CONSTRAINT "ai_conversations_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "org_blips"."actions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_blips"."ai_agents"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_protocol_fkey" FOREIGN KEY ("protocol") REFERENCES "org_blips"."ai_protocols"("protocol") ON DELETE RESTRICT NOT VALID;



ALTER TABLE ONLY "org_blips"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_stage_id_fkey" FOREIGN KEY ("stage_id") REFERENCES "org_blips"."ai_funnel_stages"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_transfer_tag_id_fkey" FOREIGN KEY ("transfer_tag_id") REFERENCES "org_blips"."transfer_tags"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_trigger_message_id_fkey" FOREIGN KEY ("trigger_message_id") REFERENCES "org_blips"."ai_messages"("id") ON DELETE SET NULL NOT VALID;



ALTER TABLE ONLY "org_blips"."ai_funnel_stages"
    ADD CONSTRAINT "ai_funnel_stages_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_blips"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."ai_funnel_stages"
    ADD CONSTRAINT "ai_funnel_stages_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_blips"."ai_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."ai_guidelines"
    ADD CONSTRAINT "ai_guidelines_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_blips"."ai_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."actions_interaction_logs"
    ADD CONSTRAINT "ai_interaction_logs_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "org_blips"."actions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."actions_interaction_logs"
    ADD CONSTRAINT "ai_interaction_logs_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."actions_interaction_logs"
    ADD CONSTRAINT "ai_interaction_logs_funnel_stage_id_fkey" FOREIGN KEY ("funnel_stage_id") REFERENCES "org_blips"."ai_funnel_stages"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."actions_interaction_logs"
    ADD CONSTRAINT "ai_interaction_logs_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_blips"."ai_versions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."ai_messages"
    ADD CONSTRAINT "ai_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "org_blips"."ai_conversations"("id") ON DELETE RESTRICT NOT VALID;



ALTER TABLE ONLY "org_blips"."ai_messages"
    ADD CONSTRAINT "ai_messages_protocol_fkey" FOREIGN KEY ("protocol") REFERENCES "org_blips"."ai_protocols"("protocol") ON DELETE RESTRICT NOT VALID;



ALTER TABLE ONLY "org_blips"."ai_playground_messages"
    ADD CONSTRAINT "ai_playground_messages_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "org_blips"."ai_playground_sessions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."ai_playground_messages"
    ADD CONSTRAINT "ai_playground_messages_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_blips"."ai_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."ai_playground_sessions"
    ADD CONSTRAINT "ai_playground_sessions_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_blips"."ai_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."ai_prompts"
    ADD CONSTRAINT "ai_prompts_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_blips"."ai_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."ai_protocol_finalizations"
    ADD CONSTRAINT "ai_protocol_finalizations_protocol_fkey" FOREIGN KEY ("protocol") REFERENCES "org_blips"."ai_protocols"("protocol") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."ai_protocol_status_log"
    ADD CONSTRAINT "ai_protocol_status_log_protocol_fkey" FOREIGN KEY ("protocol") REFERENCES "org_blips"."ai_protocols"("protocol") ON DELETE RESTRICT NOT VALID;



ALTER TABLE ONLY "org_blips"."ai_protocols"
    ADD CONSTRAINT "ai_protocols_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "org_blips"."ai_conversations"("id") ON DELETE RESTRICT NOT VALID;



ALTER TABLE ONLY "org_blips"."ai_versions"
    ADD CONSTRAINT "ai_versions_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_blips"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."audit_logs"
    ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."blocklist"
    ADD CONSTRAINT "blocklist_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."campaign_execution_candidates"
    ADD CONSTRAINT "campaign_execution_candidates_run_id_fkey" FOREIGN KEY ("run_id") REFERENCES "org_blips"."campaign_execution_runs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."campaign_logs"
    ADD CONSTRAINT "campaign_logs_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "org_blips"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."campaign_workflows"
    ADD CONSTRAINT "campaign_workflows_added_by_fkey" FOREIGN KEY ("added_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "org_blips"."campaign_workflows"
    ADD CONSTRAINT "campaign_workflows_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "org_blips"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."campaign_workflows"
    ADD CONSTRAINT "campaign_workflows_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "org_blips"."workflows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."contact_assignments"
    ADD CONSTRAINT "contact_assignments_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."contact_emails"
    ADD CONSTRAINT "contact_emails_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."contact_phones"
    ADD CONSTRAINT "contact_phones_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."contact_seals"
    ADD CONSTRAINT "contact_seals_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."contact_seals"
    ADD CONSTRAINT "contact_seals_seal_id_fkey" FOREIGN KEY ("seal_id") REFERENCES "org_blips"."seal_catalog"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."contact_summaries"
    ADD CONSTRAINT "contact_summaries_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."contract_seals"
    ADD CONSTRAINT "contract_seals_contract_id_fkey" FOREIGN KEY ("contract_id") REFERENCES "org_blips"."contracts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."contract_seals"
    ADD CONSTRAINT "contract_seals_seal_id_fkey" FOREIGN KEY ("seal_id") REFERENCES "org_blips"."seal_catalog"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."contracts"
    ADD CONSTRAINT "contracts_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."etl_job_runs"
    ADD CONSTRAINT "etl_job_runs_data_source_id_fkey" FOREIGN KEY ("data_source_id") REFERENCES "org_blips"."data_sources"("id");



ALTER TABLE ONLY "org_blips"."etl_job_runs"
    ADD CONSTRAINT "etl_job_runs_pipeline_id_fkey" FOREIGN KEY ("pipeline_id") REFERENCES "org_blips"."etl_pipelines"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."etl_pipelines"
    ADD CONSTRAINT "etl_pipelines_data_source_id_fkey" FOREIGN KEY ("data_source_id") REFERENCES "org_blips"."data_sources"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."etl_batch_jobs"
    ADD CONSTRAINT "fk_batch_job_run" FOREIGN KEY ("job_run_id") REFERENCES "org_blips"."etl_job_runs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."contract_portfolios"
    ADD CONSTRAINT "fk_contract_portfolios_contract" FOREIGN KEY ("contract_id") REFERENCES "org_blips"."contracts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."contract_portfolios"
    ADD CONSTRAINT "fk_contract_portfolios_portfolio" FOREIGN KEY ("portfolio_id") REFERENCES "org_blips"."portfolios"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."etl_job_errors"
    ADD CONSTRAINT "fk_job_run" FOREIGN KEY ("job_run_id") REFERENCES "org_blips"."etl_job_runs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."workflows"
    ADD CONSTRAINT "fk_org_blips_workflows_draft_version" FOREIGN KEY ("current_draft_version_id") REFERENCES "org_blips"."workflow_versions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."workflows"
    ADD CONSTRAINT "fk_org_blips_workflows_published_version" FOREIGN KEY ("current_published_version_id") REFERENCES "org_blips"."workflow_versions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."portfolio_integrations"
    ADD CONSTRAINT "fk_portfolio_integrations_integration" FOREIGN KEY ("integration_id") REFERENCES "org_blips"."integrations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."portfolio_integrations"
    ADD CONSTRAINT "fk_portfolio_integrations_portfolio" FOREIGN KEY ("portfolio_id") REFERENCES "org_blips"."portfolios"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."portfolios"
    ADD CONSTRAINT "fk_portfolios_filter_definition" FOREIGN KEY ("filter_definition_id") REFERENCES "org_blips"."filter_definitions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."etl_source_snapshots"
    ADD CONSTRAINT "fk_snapshots_contact" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."etl_source_snapshots"
    ADD CONSTRAINT "fk_snapshots_contract" FOREIGN KEY ("contract_id") REFERENCES "org_blips"."contracts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."etl_source_snapshots"
    ADD CONSTRAINT "fk_snapshots_data_source" FOREIGN KEY ("data_source_id") REFERENCES "org_blips"."data_sources"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."etl_source_snapshots"
    ADD CONSTRAINT "fk_snapshots_job_run" FOREIGN KEY ("job_run_id") REFERENCES "org_blips"."etl_job_runs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."etl_source_snapshots"
    ADD CONSTRAINT "fk_snapshots_pipeline" FOREIGN KEY ("pipeline_id") REFERENCES "org_blips"."etl_pipelines"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."etl_source_snapshots"
    ADD CONSTRAINT "fk_snapshots_title" FOREIGN KEY ("title_id") REFERENCES "org_blips"."titles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."titles"
    ADD CONSTRAINT "fk_titles_negativation_action" FOREIGN KEY ("negativation_action_id") REFERENCES "org_blips"."actions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."titles"
    ADD CONSTRAINT "fk_titles_notification_action" FOREIGN KEY ("notification_action_id") REFERENCES "org_blips"."actions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."titles"
    ADD CONSTRAINT "fk_titles_owner_pipeline" FOREIGN KEY ("owner_pipeline_id") REFERENCES "org_blips"."etl_pipelines"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."inbound_webhooks"
    ADD CONSTRAINT "inbound_webhooks_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."inbound_webhooks"
    ADD CONSTRAINT "inbound_webhooks_contract_id_fkey" FOREIGN KEY ("contract_id") REFERENCES "org_blips"."contracts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."inbound_webhooks"
    ADD CONSTRAINT "inbound_webhooks_title_id_fkey" FOREIGN KEY ("title_id") REFERENCES "org_blips"."titles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."integration_secrets"
    ADD CONSTRAINT "integration_secrets_integration_id_fkey" FOREIGN KEY ("integration_id") REFERENCES "org_blips"."integrations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."message_templates"
    ADD CONSTRAINT "message_templates_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "org_blips"."rag_chunks"
    ADD CONSTRAINT "rag_chunks_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "org_blips"."rag_documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."rag_documents"
    ADD CONSTRAINT "rag_documents_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_blips"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."rag_documents"
    ADD CONSTRAINT "rag_documents_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "org_blips"."rag_documents"
    ADD CONSTRAINT "rag_documents_filter_definition_id_fkey" FOREIGN KEY ("filter_definition_id") REFERENCES "org_blips"."filter_definitions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "org_blips"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_campaign_log_id_fkey" FOREIGN KEY ("campaign_log_id") REFERENCES "org_blips"."campaign_logs"("id") ON DELETE SET NULL NOT VALID;



ALTER TABLE ONLY "org_blips"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_contract_id_fkey" FOREIGN KEY ("contract_id") REFERENCES "org_blips"."contracts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_title_id_fkey" FOREIGN KEY ("title_id") REFERENCES "org_blips"."titles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "org_blips"."workflows"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_workflow_step_id_fkey" FOREIGN KEY ("workflow_step_id") REFERENCES "org_blips"."workflow_steps"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."supplies"
    ADD CONSTRAINT "supplies_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."supply_seals"
    ADD CONSTRAINT "supply_seals_seal_id_fkey" FOREIGN KEY ("seal_id") REFERENCES "org_blips"."seal_catalog"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."supply_seals"
    ADD CONSTRAINT "supply_seals_supply_id_fkey" FOREIGN KEY ("supply_id") REFERENCES "org_blips"."supplies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."supply_title_seals"
    ADD CONSTRAINT "supply_title_seals_seal_id_fkey" FOREIGN KEY ("seal_id") REFERENCES "org_blips"."seal_catalog"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."supply_title_seals"
    ADD CONSTRAINT "supply_title_seals_supply_title_id_fkey" FOREIGN KEY ("supply_title_id") REFERENCES "org_blips"."supply_titles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."supply_titles"
    ADD CONSTRAINT "supply_titles_owner_pipeline_id_fkey" FOREIGN KEY ("owner_pipeline_id") REFERENCES "org_blips"."etl_pipelines"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."supply_titles"
    ADD CONSTRAINT "supply_titles_supply_id_fkey" FOREIGN KEY ("supply_id") REFERENCES "org_blips"."supplies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."title_seals"
    ADD CONSTRAINT "title_seals_seal_id_fkey" FOREIGN KEY ("seal_id") REFERENCES "org_blips"."seal_catalog"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."title_seals"
    ADD CONSTRAINT "title_seals_title_id_fkey" FOREIGN KEY ("title_id") REFERENCES "org_blips"."titles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."titles"
    ADD CONSTRAINT "titles_attributed_action_id_fkey" FOREIGN KEY ("attributed_action_id") REFERENCES "org_blips"."actions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."titles"
    ADD CONSTRAINT "titles_contract_id_fkey" FOREIGN KEY ("contract_id") REFERENCES "org_blips"."contracts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."transfer_reprocess_audit"
    ADD CONSTRAINT "transfer_reprocess_audit_batch_id_fkey" FOREIGN KEY ("batch_id") REFERENCES "org_blips"."transfer_reprocess_batches"("batch_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "org_blips"."transfer_reprocess_results"
    ADD CONSTRAINT "transfer_reprocess_results_batch_id_fkey" FOREIGN KEY ("batch_id") REFERENCES "org_blips"."transfer_reprocess_batches"("batch_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "org_blips"."transfer_tag_type_periods"
    ADD CONSTRAINT "transfer_tag_type_periods_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "org_blips"."transfer_tags"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."transfer_tags"
    ADD CONSTRAINT "transfer_tags_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_blips"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."workflow_audit_logs"
    ADD CONSTRAINT "workflow_audit_logs_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "org_blips"."workflows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."workflow_executions"
    ADD CONSTRAINT "workflow_executions_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_blips"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."workflow_executions"
    ADD CONSTRAINT "workflow_executions_contract_id_fkey" FOREIGN KEY ("contract_id") REFERENCES "org_blips"."contracts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_blips"."workflow_executions"
    ADD CONSTRAINT "workflow_executions_current_step_id_fkey" FOREIGN KEY ("current_step_id") REFERENCES "org_blips"."workflow_steps"("id");



ALTER TABLE ONLY "org_blips"."workflow_executions"
    ADD CONSTRAINT "workflow_executions_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "org_blips"."workflows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."workflow_steps"
    ADD CONSTRAINT "workflow_steps_false_next_step_id_fkey" FOREIGN KEY ("false_next_step_id") REFERENCES "org_blips"."workflow_steps"("id");



ALTER TABLE ONLY "org_blips"."workflow_steps"
    ADD CONSTRAINT "workflow_steps_integration_id_fkey" FOREIGN KEY ("integration_id") REFERENCES "public"."marketplace_integrations"("id");



ALTER TABLE ONLY "org_blips"."workflow_steps"
    ADD CONSTRAINT "workflow_steps_next_step_id_fkey" FOREIGN KEY ("next_step_id") REFERENCES "org_blips"."workflow_steps"("id");



ALTER TABLE ONLY "org_blips"."workflow_steps"
    ADD CONSTRAINT "workflow_steps_true_next_step_id_fkey" FOREIGN KEY ("true_next_step_id") REFERENCES "org_blips"."workflow_steps"("id");



ALTER TABLE ONLY "org_blips"."workflow_steps"
    ADD CONSTRAINT "workflow_steps_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "org_blips"."workflows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."workflow_versions"
    ADD CONSTRAINT "workflow_versions_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "org_blips"."workflows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_blips"."workflows"
    ADD CONSTRAINT "workflows_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "org_blips"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."a2a_closure_config"
    ADD CONSTRAINT "a2a_closure_config_agent_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_finza"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."actions"
    ADD CONSTRAINT "actions_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "org_finza"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."actions"
    ADD CONSTRAINT "actions_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."actions"
    ADD CONSTRAINT "actions_contract_id_fkey" FOREIGN KEY ("contract_id") REFERENCES "org_finza"."contracts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."actions"
    ADD CONSTRAINT "actions_integration_id_fkey" FOREIGN KEY ("integration_id") REFERENCES "org_finza"."integrations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."actions_interaction_logs"
    ADD CONSTRAINT "actions_interaction_logs_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_finza"."ai_agents"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."actions_interaction_logs"
    ADD CONSTRAINT "actions_interaction_logs_transfer_tag_id_fkey" FOREIGN KEY ("transfer_tag_id") REFERENCES "org_finza"."transfer_tags"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."actions"
    ADD CONSTRAINT "actions_supply_id_fkey" FOREIGN KEY ("supply_id") REFERENCES "org_finza"."supplies"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."actions"
    ADD CONSTRAINT "actions_supply_title_id_fkey" FOREIGN KEY ("supply_title_id") REFERENCES "org_finza"."supply_titles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."actions"
    ADD CONSTRAINT "actions_title_id_fkey" FOREIGN KEY ("title_id") REFERENCES "org_finza"."titles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."actions"
    ADD CONSTRAINT "actions_workflow_execution_id_fkey" FOREIGN KEY ("workflow_execution_id") REFERENCES "org_finza"."workflow_executions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."actions"
    ADD CONSTRAINT "actions_workflow_step_id_fkey" FOREIGN KEY ("workflow_step_id") REFERENCES "org_finza"."workflow_steps"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."agent_allowed_tags"
    ADD CONSTRAINT "agent_allowed_tags_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_finza"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."agent_allowed_tags"
    ADD CONSTRAINT "agent_allowed_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "org_finza"."tag_catalog"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."agent_call_logs"
    ADD CONSTRAINT "agent_call_logs_protocol_fkey" FOREIGN KEY ("protocol") REFERENCES "org_finza"."ai_protocols"("protocol") ON DELETE SET NULL NOT VALID;



ALTER TABLE ONLY "org_finza"."agent_call_logs"
    ADD CONSTRAINT "agent_call_logs_receiving_agent_id_fkey" FOREIGN KEY ("receiving_agent_id") REFERENCES "org_finza"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."ai_business_rules"
    ADD CONSTRAINT "ai_business_rules_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_finza"."ai_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."ai_conversations"
    ADD CONSTRAINT "ai_conversations_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "org_finza"."actions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_finza"."ai_agents"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_protocol_fkey" FOREIGN KEY ("protocol") REFERENCES "org_finza"."ai_protocols"("protocol") ON DELETE RESTRICT NOT VALID;



ALTER TABLE ONLY "org_finza"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_stage_id_fkey" FOREIGN KEY ("stage_id") REFERENCES "org_finza"."ai_funnel_stages"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_transfer_tag_id_fkey" FOREIGN KEY ("transfer_tag_id") REFERENCES "org_finza"."transfer_tags"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."ai_funnel_events"
    ADD CONSTRAINT "ai_funnel_events_trigger_message_id_fkey" FOREIGN KEY ("trigger_message_id") REFERENCES "org_finza"."ai_messages"("id") ON DELETE SET NULL NOT VALID;



ALTER TABLE ONLY "org_finza"."ai_funnel_stages"
    ADD CONSTRAINT "ai_funnel_stages_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_finza"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."ai_funnel_stages"
    ADD CONSTRAINT "ai_funnel_stages_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_finza"."ai_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."ai_guidelines"
    ADD CONSTRAINT "ai_guidelines_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_finza"."ai_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."actions_interaction_logs"
    ADD CONSTRAINT "ai_interaction_logs_action_id_fkey" FOREIGN KEY ("action_id") REFERENCES "org_finza"."actions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."actions_interaction_logs"
    ADD CONSTRAINT "ai_interaction_logs_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."actions_interaction_logs"
    ADD CONSTRAINT "ai_interaction_logs_funnel_stage_id_fkey" FOREIGN KEY ("funnel_stage_id") REFERENCES "org_finza"."ai_funnel_stages"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."actions_interaction_logs"
    ADD CONSTRAINT "ai_interaction_logs_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_finza"."ai_versions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."ai_messages"
    ADD CONSTRAINT "ai_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "org_finza"."ai_conversations"("id") ON DELETE RESTRICT NOT VALID;



ALTER TABLE ONLY "org_finza"."ai_messages"
    ADD CONSTRAINT "ai_messages_protocol_fkey" FOREIGN KEY ("protocol") REFERENCES "org_finza"."ai_protocols"("protocol") ON DELETE RESTRICT NOT VALID;



ALTER TABLE ONLY "org_finza"."ai_playground_messages"
    ADD CONSTRAINT "ai_playground_messages_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "org_finza"."ai_playground_sessions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."ai_playground_messages"
    ADD CONSTRAINT "ai_playground_messages_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_finza"."ai_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."ai_playground_sessions"
    ADD CONSTRAINT "ai_playground_sessions_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_finza"."ai_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."ai_prompts"
    ADD CONSTRAINT "ai_prompts_version_id_fkey" FOREIGN KEY ("version_id") REFERENCES "org_finza"."ai_versions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."ai_protocol_finalizations"
    ADD CONSTRAINT "ai_protocol_finalizations_protocol_fkey" FOREIGN KEY ("protocol") REFERENCES "org_finza"."ai_protocols"("protocol") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."ai_protocol_status_log"
    ADD CONSTRAINT "ai_protocol_status_log_protocol_fkey" FOREIGN KEY ("protocol") REFERENCES "org_finza"."ai_protocols"("protocol") ON DELETE RESTRICT NOT VALID;



ALTER TABLE ONLY "org_finza"."ai_protocols"
    ADD CONSTRAINT "ai_protocols_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "org_finza"."ai_conversations"("id") ON DELETE RESTRICT NOT VALID;



ALTER TABLE ONLY "org_finza"."ai_versions"
    ADD CONSTRAINT "ai_versions_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_finza"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."audit_logs"
    ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."blocklist"
    ADD CONSTRAINT "blocklist_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."campaign_execution_candidates"
    ADD CONSTRAINT "campaign_execution_candidates_run_id_fkey" FOREIGN KEY ("run_id") REFERENCES "org_finza"."campaign_execution_runs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."campaign_logs"
    ADD CONSTRAINT "campaign_logs_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "org_finza"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."campaign_workflows"
    ADD CONSTRAINT "campaign_workflows_added_by_fkey" FOREIGN KEY ("added_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "org_finza"."campaign_workflows"
    ADD CONSTRAINT "campaign_workflows_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "org_finza"."campaigns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."campaign_workflows"
    ADD CONSTRAINT "campaign_workflows_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "org_finza"."workflows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."contact_assignments"
    ADD CONSTRAINT "contact_assignments_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."contact_emails"
    ADD CONSTRAINT "contact_emails_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."contact_phones"
    ADD CONSTRAINT "contact_phones_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."contact_seals"
    ADD CONSTRAINT "contact_seals_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."contact_seals"
    ADD CONSTRAINT "contact_seals_seal_id_fkey" FOREIGN KEY ("seal_id") REFERENCES "org_finza"."seal_catalog"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."contact_summaries"
    ADD CONSTRAINT "contact_summaries_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."contract_seals"
    ADD CONSTRAINT "contract_seals_contract_id_fkey" FOREIGN KEY ("contract_id") REFERENCES "org_finza"."contracts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."contract_seals"
    ADD CONSTRAINT "contract_seals_seal_id_fkey" FOREIGN KEY ("seal_id") REFERENCES "org_finza"."seal_catalog"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."contracts"
    ADD CONSTRAINT "contracts_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."etl_job_runs"
    ADD CONSTRAINT "etl_job_runs_data_source_id_fkey" FOREIGN KEY ("data_source_id") REFERENCES "org_finza"."data_sources"("id");



ALTER TABLE ONLY "org_finza"."etl_job_runs"
    ADD CONSTRAINT "etl_job_runs_pipeline_id_fkey" FOREIGN KEY ("pipeline_id") REFERENCES "org_finza"."etl_pipelines"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."etl_pipelines"
    ADD CONSTRAINT "etl_pipelines_data_source_id_fkey" FOREIGN KEY ("data_source_id") REFERENCES "org_finza"."data_sources"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."etl_batch_jobs"
    ADD CONSTRAINT "fk_batch_job_run" FOREIGN KEY ("job_run_id") REFERENCES "org_finza"."etl_job_runs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."contract_portfolios"
    ADD CONSTRAINT "fk_contract_portfolios_contract" FOREIGN KEY ("contract_id") REFERENCES "org_finza"."contracts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."contract_portfolios"
    ADD CONSTRAINT "fk_contract_portfolios_portfolio" FOREIGN KEY ("portfolio_id") REFERENCES "org_finza"."portfolios"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."etl_job_errors"
    ADD CONSTRAINT "fk_job_run" FOREIGN KEY ("job_run_id") REFERENCES "org_finza"."etl_job_runs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."workflows"
    ADD CONSTRAINT "fk_org_finza_workflows_draft_version" FOREIGN KEY ("current_draft_version_id") REFERENCES "org_finza"."workflow_versions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."workflows"
    ADD CONSTRAINT "fk_org_finza_workflows_published_version" FOREIGN KEY ("current_published_version_id") REFERENCES "org_finza"."workflow_versions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."portfolio_integrations"
    ADD CONSTRAINT "fk_portfolio_integrations_integration" FOREIGN KEY ("integration_id") REFERENCES "org_finza"."integrations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."portfolio_integrations"
    ADD CONSTRAINT "fk_portfolio_integrations_portfolio" FOREIGN KEY ("portfolio_id") REFERENCES "org_finza"."portfolios"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."portfolios"
    ADD CONSTRAINT "fk_portfolios_filter_definition" FOREIGN KEY ("filter_definition_id") REFERENCES "org_finza"."filter_definitions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."etl_source_snapshots"
    ADD CONSTRAINT "fk_snapshots_contact" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."etl_source_snapshots"
    ADD CONSTRAINT "fk_snapshots_contract" FOREIGN KEY ("contract_id") REFERENCES "org_finza"."contracts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."etl_source_snapshots"
    ADD CONSTRAINT "fk_snapshots_data_source" FOREIGN KEY ("data_source_id") REFERENCES "org_finza"."data_sources"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."etl_source_snapshots"
    ADD CONSTRAINT "fk_snapshots_job_run" FOREIGN KEY ("job_run_id") REFERENCES "org_finza"."etl_job_runs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."etl_source_snapshots"
    ADD CONSTRAINT "fk_snapshots_pipeline" FOREIGN KEY ("pipeline_id") REFERENCES "org_finza"."etl_pipelines"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."etl_source_snapshots"
    ADD CONSTRAINT "fk_snapshots_title" FOREIGN KEY ("title_id") REFERENCES "org_finza"."titles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."titles"
    ADD CONSTRAINT "fk_titles_negativation_action" FOREIGN KEY ("negativation_action_id") REFERENCES "org_finza"."actions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."titles"
    ADD CONSTRAINT "fk_titles_notification_action" FOREIGN KEY ("notification_action_id") REFERENCES "org_finza"."actions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."titles"
    ADD CONSTRAINT "fk_titles_owner_pipeline" FOREIGN KEY ("owner_pipeline_id") REFERENCES "org_finza"."etl_pipelines"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."inbound_webhooks"
    ADD CONSTRAINT "inbound_webhooks_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."inbound_webhooks"
    ADD CONSTRAINT "inbound_webhooks_contract_id_fkey" FOREIGN KEY ("contract_id") REFERENCES "org_finza"."contracts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."inbound_webhooks"
    ADD CONSTRAINT "inbound_webhooks_title_id_fkey" FOREIGN KEY ("title_id") REFERENCES "org_finza"."titles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."integration_secrets"
    ADD CONSTRAINT "integration_secrets_integration_id_fkey" FOREIGN KEY ("integration_id") REFERENCES "org_finza"."integrations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."message_templates"
    ADD CONSTRAINT "message_templates_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "org_finza"."rag_chunks"
    ADD CONSTRAINT "rag_chunks_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "org_finza"."rag_documents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."rag_documents"
    ADD CONSTRAINT "rag_documents_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_finza"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."rag_documents"
    ADD CONSTRAINT "rag_documents_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "org_finza"."rag_documents"
    ADD CONSTRAINT "rag_documents_filter_definition_id_fkey" FOREIGN KEY ("filter_definition_id") REFERENCES "org_finza"."filter_definitions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "org_finza"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_campaign_log_id_fkey" FOREIGN KEY ("campaign_log_id") REFERENCES "org_finza"."campaign_logs"("id") ON DELETE SET NULL NOT VALID;



ALTER TABLE ONLY "org_finza"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_contract_id_fkey" FOREIGN KEY ("contract_id") REFERENCES "org_finza"."contracts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_title_id_fkey" FOREIGN KEY ("title_id") REFERENCES "org_finza"."titles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "org_finza"."workflows"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."skipped_actions_log"
    ADD CONSTRAINT "skipped_actions_log_workflow_step_id_fkey" FOREIGN KEY ("workflow_step_id") REFERENCES "org_finza"."workflow_steps"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."supplies"
    ADD CONSTRAINT "supplies_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."supply_seals"
    ADD CONSTRAINT "supply_seals_seal_id_fkey" FOREIGN KEY ("seal_id") REFERENCES "org_finza"."seal_catalog"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."supply_seals"
    ADD CONSTRAINT "supply_seals_supply_id_fkey" FOREIGN KEY ("supply_id") REFERENCES "org_finza"."supplies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."supply_title_seals"
    ADD CONSTRAINT "supply_title_seals_seal_id_fkey" FOREIGN KEY ("seal_id") REFERENCES "org_finza"."seal_catalog"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."supply_title_seals"
    ADD CONSTRAINT "supply_title_seals_supply_title_id_fkey" FOREIGN KEY ("supply_title_id") REFERENCES "org_finza"."supply_titles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."supply_titles"
    ADD CONSTRAINT "supply_titles_owner_pipeline_id_fkey" FOREIGN KEY ("owner_pipeline_id") REFERENCES "org_finza"."etl_pipelines"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."supply_titles"
    ADD CONSTRAINT "supply_titles_supply_id_fkey" FOREIGN KEY ("supply_id") REFERENCES "org_finza"."supplies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."title_seals"
    ADD CONSTRAINT "title_seals_seal_id_fkey" FOREIGN KEY ("seal_id") REFERENCES "org_finza"."seal_catalog"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."title_seals"
    ADD CONSTRAINT "title_seals_title_id_fkey" FOREIGN KEY ("title_id") REFERENCES "org_finza"."titles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."titles"
    ADD CONSTRAINT "titles_attributed_action_id_fkey" FOREIGN KEY ("attributed_action_id") REFERENCES "org_finza"."actions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."titles"
    ADD CONSTRAINT "titles_contract_id_fkey" FOREIGN KEY ("contract_id") REFERENCES "org_finza"."contracts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."transfer_event_reclass_audit"
    ADD CONSTRAINT "transfer_event_reclass_audit_batch_id_fkey" FOREIGN KEY ("batch_id") REFERENCES "org_finza"."transfer_event_reclass_batches"("batch_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "org_finza"."transfer_tag_type_periods"
    ADD CONSTRAINT "transfer_tag_type_periods_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "org_finza"."transfer_tags"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."transfer_tags"
    ADD CONSTRAINT "transfer_tags_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "org_finza"."ai_agents"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."transfer_type_reclass_audit"
    ADD CONSTRAINT "transfer_type_reclass_audit_batch_id_fkey" FOREIGN KEY ("batch_id") REFERENCES "org_finza"."transfer_type_reclass_batches"("batch_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "org_finza"."workflow_audit_logs"
    ADD CONSTRAINT "workflow_audit_logs_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "org_finza"."workflows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."workflow_executions"
    ADD CONSTRAINT "workflow_executions_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "org_finza"."contacts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."workflow_executions"
    ADD CONSTRAINT "workflow_executions_contract_id_fkey" FOREIGN KEY ("contract_id") REFERENCES "org_finza"."contracts"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "org_finza"."workflow_executions"
    ADD CONSTRAINT "workflow_executions_current_step_id_fkey" FOREIGN KEY ("current_step_id") REFERENCES "org_finza"."workflow_steps"("id");



ALTER TABLE ONLY "org_finza"."workflow_executions"
    ADD CONSTRAINT "workflow_executions_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "org_finza"."workflows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."workflow_steps"
    ADD CONSTRAINT "workflow_steps_false_next_step_id_fkey" FOREIGN KEY ("false_next_step_id") REFERENCES "org_finza"."workflow_steps"("id");



ALTER TABLE ONLY "org_finza"."workflow_steps"
    ADD CONSTRAINT "workflow_steps_integration_id_fkey" FOREIGN KEY ("integration_id") REFERENCES "public"."marketplace_integrations"("id");



ALTER TABLE ONLY "org_finza"."workflow_steps"
    ADD CONSTRAINT "workflow_steps_next_step_id_fkey" FOREIGN KEY ("next_step_id") REFERENCES "org_finza"."workflow_steps"("id");



ALTER TABLE ONLY "org_finza"."workflow_steps"
    ADD CONSTRAINT "workflow_steps_true_next_step_id_fkey" FOREIGN KEY ("true_next_step_id") REFERENCES "org_finza"."workflow_steps"("id");



ALTER TABLE ONLY "org_finza"."workflow_steps"
    ADD CONSTRAINT "workflow_steps_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "org_finza"."workflows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."workflow_versions"
    ADD CONSTRAINT "workflow_versions_workflow_id_fkey" FOREIGN KEY ("workflow_id") REFERENCES "org_finza"."workflows"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "org_finza"."workflows"
    ADD CONSTRAINT "workflows_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "org_finza"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."api_keys"
    ADD CONSTRAINT "api_keys_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."changelog_reactions"
    ADD CONSTRAINT "changelog_reactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."changelog_seen"
    ADD CONSTRAINT "changelog_seen_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."changelog_views"
    ADD CONSTRAINT "changelog_views_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."edge_function_call_logs"
    ADD CONSTRAINT "edge_function_call_logs_caller_api_key_id_fkey" FOREIGN KEY ("caller_api_key_id") REFERENCES "public"."api_keys"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."organization_marketplace_integrations"
    ADD CONSTRAINT "organization_marketplace_integrations_integration_id_fkey" FOREIGN KEY ("integration_id") REFERENCES "public"."marketplace_integrations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organization_marketplace_integrations"
    ADD CONSTRAINT "organization_marketplace_integrations_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organization_role_changes"
    ADD CONSTRAINT "organization_role_changes_changed_by_fkey" FOREIGN KEY ("changed_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."organization_role_changes"
    ADD CONSTRAINT "organization_role_changes_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organization_role_changes"
    ADD CONSTRAINT "organization_role_changes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organization_secrets"
    ADD CONSTRAINT "organization_secrets_integration_id_fkey" FOREIGN KEY ("integration_id") REFERENCES "public"."organization_marketplace_integrations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organization_secrets"
    ADD CONSTRAINT "organization_secrets_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organization_users"
    ADD CONSTRAINT "organization_users_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organization_users"
    ADD CONSTRAINT "organization_users_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."super_admins"
    ADD CONSTRAINT "super_admins_granted_by_fkey" FOREIGN KEY ("granted_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."super_admins"
    ADD CONSTRAINT "super_admins_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_invitations"
    ADD CONSTRAINT "user_invitations_invited_by_fkey" FOREIGN KEY ("invited_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."user_invitations"
    ADD CONSTRAINT "user_invitations_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



CREATE POLICY "Blips users can access actions" ON "org_blips"."actions" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access audit_logs" ON "org_blips"."audit_logs" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access campaigns" ON "org_blips"."campaigns" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access contact_assignments" ON "org_blips"."contact_assignments" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access contact_emails" ON "org_blips"."contact_emails" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access contact_phones" ON "org_blips"."contact_phones" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access contacts" ON "org_blips"."contacts" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access contracts" ON "org_blips"."contracts" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access custom_field_definitions" ON "org_blips"."custom_field_definitions" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access data_sources" ON "org_blips"."data_sources" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access etl_job_runs" ON "org_blips"."etl_job_runs" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access etl_pipelines" ON "org_blips"."etl_pipelines" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access filter_definitions" ON "org_blips"."filter_definitions" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access inbound_webhooks" ON "org_blips"."inbound_webhooks" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access titles" ON "org_blips"."titles" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access workflow_executions" ON "org_blips"."workflow_executions" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access workflow_steps" ON "org_blips"."workflow_steps" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Blips users can access workflows" ON "org_blips"."workflows" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "Users can insert report_schedules" ON "org_blips"."report_schedules" FOR INSERT WITH CHECK (true);



ALTER TABLE "org_blips"."a2a_closure_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."actions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."actions_dlq" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."actions_interaction_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."agent_allowed_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."agent_audit_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."agent_call_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."agent_llm_configs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."agent_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."agent_proposal_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."agent_proposals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."agent_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_agents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_backfill_checkpoint" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_backfill_quarantine" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_business_rules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_funnel_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_funnel_stages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_guidelines" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_ingestion_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_playground_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_playground_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_prompts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_protocol_status_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_protocols" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."ai_versions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."audit_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "blips_users_access_actions" ON "org_blips"."actions" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_ai_business_rules" ON "org_blips"."ai_business_rules" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_ai_funnel_stages" ON "org_blips"."ai_funnel_stages" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_ai_guidelines" ON "org_blips"."ai_guidelines" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_ai_playground_messages" ON "org_blips"."ai_playground_messages" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_ai_prompts" ON "org_blips"."ai_prompts" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_ai_versions" ON "org_blips"."ai_versions" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_audit_logs" ON "org_blips"."audit_logs" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_blocklist" ON "org_blips"."blocklist" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_blocklist_entries" ON "org_blips"."blocklist_entries" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_blocklist_filter_rules" ON "org_blips"."blocklist_filter_rules" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_blocklist_history" ON "org_blips"."blocklist_history" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_campaign_logs" ON "org_blips"."campaign_logs" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_campaigns" ON "org_blips"."campaigns" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_contact_emails" ON "org_blips"."contact_emails" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_contact_phones" ON "org_blips"."contact_phones" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_contact_summaries" ON "org_blips"."contact_summaries" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_contacts" ON "org_blips"."contacts" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_contracts" ON "org_blips"."contracts" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_custom_field_definitions" ON "org_blips"."custom_field_definitions" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_data_sources" ON "org_blips"."data_sources" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_etl_job_errors" ON "org_blips"."etl_job_errors" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_etl_job_runs" ON "org_blips"."etl_job_runs" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_etl_pipelines" ON "org_blips"."etl_pipelines" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_etl_source_snapshots" ON "org_blips"."etl_source_snapshots" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_filter_definitions" ON "org_blips"."filter_definitions" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_inbound_webhooks" ON "org_blips"."inbound_webhooks" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_integration_secrets" ON "org_blips"."integration_secrets" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_integrations" ON "org_blips"."integrations" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_message_templates" ON "org_blips"."message_templates" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_portfolios" ON "org_blips"."portfolios" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_titles" ON "org_blips"."titles" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_workflow_executions" ON "org_blips"."workflow_executions" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_workflow_steps" ON "org_blips"."workflow_steps" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_workflows" ON "org_blips"."workflows" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "blips_users_can_access_custom_variables" ON "org_blips"."custom_variables" USING ("org_blips"."user_belongs_to_org"());



ALTER TABLE "org_blips"."blocked_dates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."blocklist" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."blocklist_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."blocklist_filter_rules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."blocklist_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."campaign_execution_candidates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."campaign_execution_runs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."campaign_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."campaign_workflows" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."campaigns" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."channel_costs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."channel_rate_counts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."channel_rate_limits" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."contact_assignments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."contact_emails" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."contact_phones" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."contact_seals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."contact_summaries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."contacts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."contract_portfolios" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."contract_seals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."contracts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."conversation_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."custom_field_definitions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."custom_variables" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."data_source_skills" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."data_sources" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."etl_batch_jobs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."etl_job_errors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."etl_job_runs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."etl_pipelines" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."etl_source_snapshots" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."filter_definitions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."inbound_webhooks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."integration_secrets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."integrations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."message_templates" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "org_admin_owner_access" ON "org_blips"."integration_secrets" TO "authenticated" USING (("public"."is_org_admin_or_owner"('00000000-0000-0000-0000-000000000001'::"uuid") OR "public"."is_super_admin"("auth"."uid"()))) WITH CHECK (("public"."is_org_admin_or_owner"('00000000-0000-0000-0000-000000000001'::"uuid") OR "public"."is_super_admin"("auth"."uid"())));



CREATE POLICY "org_admin_owner_access" ON "org_blips"."report_schedules" TO "authenticated" USING (("public"."is_org_admin_or_owner"('00000000-0000-0000-0000-000000000001'::"uuid") OR "public"."is_super_admin"("auth"."uid"()))) WITH CHECK (("public"."is_org_admin_or_owner"('00000000-0000-0000-0000-000000000001'::"uuid") OR "public"."is_super_admin"("auth"."uid"())));



CREATE POLICY "org_member_access" ON "org_blips"."contact_summaries" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_member_access" ON "org_blips"."etl_job_errors" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_member_access" ON "org_blips"."integrations" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_member_access" ON "org_blips"."portfolio_integrations" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_member_access" ON "org_blips"."sending_controls" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_actions_dlq" ON "org_blips"."actions_dlq" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_allowed_tags" ON "org_blips"."agent_allowed_tags" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_audit_logs" ON "org_blips"."agent_audit_logs" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_call_logs" ON "org_blips"."agent_call_logs" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_llm_configs" ON "org_blips"."agent_llm_configs" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_messages" ON "org_blips"."agent_messages" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_proposal_items" ON "org_blips"."agent_proposal_items" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_proposals" ON "org_blips"."agent_proposals" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_sessions" ON "org_blips"."agent_sessions" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_ai_agents" ON "org_blips"."ai_agents" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_ai_playground_sessions" ON "org_blips"."ai_playground_sessions" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_blocked_dates" ON "org_blips"."blocked_dates" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_campaign_execution_candidates" ON "org_blips"."campaign_execution_candidates" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_campaign_execution_runs" ON "org_blips"."campaign_execution_runs" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_campaign_workflows" ON "org_blips"."campaign_workflows" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_channel_costs" ON "org_blips"."channel_costs" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_channel_rate_counts" ON "org_blips"."channel_rate_counts" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_channel_rate_limits" ON "org_blips"."channel_rate_limits" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_contact_seals" ON "org_blips"."contact_seals" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_contract_portfolios" ON "org_blips"."contract_portfolios" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_contract_seals" ON "org_blips"."contract_seals" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_conversation_tags" ON "org_blips"."conversation_tags" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_data_source_skills" ON "org_blips"."data_source_skills" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_etl_batch_jobs" ON "org_blips"."etl_batch_jobs" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_rag_chunks" ON "org_blips"."rag_chunks" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_rag_documents" ON "org_blips"."rag_documents" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_seal_catalog" ON "org_blips"."seal_catalog" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_skipped_actions_log" ON "org_blips"."skipped_actions_log" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_supplies" ON "org_blips"."supplies" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_supply_seals" ON "org_blips"."supply_seals" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_supply_title_seals" ON "org_blips"."supply_title_seals" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_supply_title_status_history" ON "org_blips"."supply_title_status_history" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_supply_titles" ON "org_blips"."supply_titles" TO "authenticated" USING ("org_blips"."user_belongs_to_org"()) WITH CHECK ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_tag_catalog" ON "org_blips"."tag_catalog" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_title_seals" ON "org_blips"."title_seals" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_transfer_tag_type_periods" ON "org_blips"."transfer_tag_type_periods" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_transfer_tags" ON "org_blips"."transfer_tags" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_webhook_retry_queue" ON "org_blips"."webhook_retry_queue" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_workflow_audit_logs" ON "org_blips"."workflow_audit_logs" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_access_workflow_versions" ON "org_blips"."workflow_versions" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_select_actions_interaction_logs" ON "org_blips"."actions_interaction_logs" FOR SELECT TO "authenticated" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_backfill_checkpoint" ON "org_blips"."ai_backfill_checkpoint" FOR SELECT TO "authenticated" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_backfill_quarantine" ON "org_blips"."ai_backfill_quarantine" FOR SELECT TO "authenticated" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_conversations" ON "org_blips"."ai_conversations" FOR SELECT TO "authenticated" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_funnel_events" ON "org_blips"."ai_funnel_events" FOR SELECT TO "authenticated" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_ingestion_events" ON "org_blips"."ai_ingestion_events" FOR SELECT TO "authenticated" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_messages" ON "org_blips"."ai_messages" FOR SELECT TO "authenticated" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_protocol_status_log" ON "org_blips"."ai_protocol_status_log" FOR SELECT TO "authenticated" USING ("org_blips"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_protocols" ON "org_blips"."ai_protocols" FOR SELECT TO "authenticated" USING ("org_blips"."user_belongs_to_org"());



ALTER TABLE "org_blips"."portfolio_integrations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."portfolios" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."rag_chunks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."rag_documents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."report_schedules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."seal_catalog" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."sending_controls" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "service_role_full_access" ON "org_blips"."contact_summaries" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service_role_full_access" ON "org_blips"."etl_job_errors" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service_role_full_access" ON "org_blips"."integration_secrets" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service_role_full_access" ON "org_blips"."integrations" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service_role_full_access" ON "org_blips"."portfolio_integrations" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service_role_full_access" ON "org_blips"."report_schedules" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service_role_full_access" ON "org_blips"."sending_controls" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "org_blips"."skipped_actions_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."supplies" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."supply_seals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."supply_title_seals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."supply_title_status_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."supply_titles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."tag_catalog" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."title_seals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."title_status_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."titles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."transfer_reprocess_audit" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."transfer_reprocess_batches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."transfer_reprocess_results" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."transfer_tag_type_periods" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."transfer_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."webhook_retry_queue" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."workflow_audit_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."workflow_executions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."workflow_steps" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."workflow_versions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_blips"."workflows" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Blips users can access actions" ON "org_finza"."actions" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access audit_logs" ON "org_finza"."audit_logs" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access campaigns" ON "org_finza"."campaigns" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access contact_assignments" ON "org_finza"."contact_assignments" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access contact_emails" ON "org_finza"."contact_emails" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access contact_phones" ON "org_finza"."contact_phones" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access contacts" ON "org_finza"."contacts" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access contracts" ON "org_finza"."contracts" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access custom_field_definitions" ON "org_finza"."custom_field_definitions" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access data_sources" ON "org_finza"."data_sources" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access etl_job_runs" ON "org_finza"."etl_job_runs" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access etl_pipelines" ON "org_finza"."etl_pipelines" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access filter_definitions" ON "org_finza"."filter_definitions" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access inbound_webhooks" ON "org_finza"."inbound_webhooks" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access titles" ON "org_finza"."titles" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access workflow_executions" ON "org_finza"."workflow_executions" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access workflow_steps" ON "org_finza"."workflow_steps" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "Blips users can access workflows" ON "org_finza"."workflows" USING ("org_finza"."user_belongs_to_org"());



ALTER TABLE "org_finza"."a2a_closure_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."actions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."actions_dlq" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."actions_interaction_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."agent_allowed_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."agent_audit_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."agent_call_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."agent_llm_configs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."agent_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."agent_proposal_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."agent_proposals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."agent_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_agents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_backfill_checkpoint" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_backfill_quarantine" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_business_rules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_funnel_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_funnel_stages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_guidelines" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_ingestion_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_playground_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_playground_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_prompts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_protocol_status_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_protocols" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."ai_versions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."audit_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "blips_users_access_actions" ON "org_finza"."actions" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_ai_business_rules" ON "org_finza"."ai_business_rules" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_ai_funnel_stages" ON "org_finza"."ai_funnel_stages" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_ai_guidelines" ON "org_finza"."ai_guidelines" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_ai_playground_messages" ON "org_finza"."ai_playground_messages" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_ai_prompts" ON "org_finza"."ai_prompts" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_ai_versions" ON "org_finza"."ai_versions" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_audit_logs" ON "org_finza"."audit_logs" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_blocklist" ON "org_finza"."blocklist" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_blocklist_entries" ON "org_finza"."blocklist_entries" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_blocklist_filter_rules" ON "org_finza"."blocklist_filter_rules" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_blocklist_history" ON "org_finza"."blocklist_history" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_campaign_logs" ON "org_finza"."campaign_logs" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_campaigns" ON "org_finza"."campaigns" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_contact_emails" ON "org_finza"."contact_emails" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_contact_phones" ON "org_finza"."contact_phones" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_contact_summaries" ON "org_finza"."contact_summaries" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_contacts" ON "org_finza"."contacts" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_contracts" ON "org_finza"."contracts" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_custom_field_definitions" ON "org_finza"."custom_field_definitions" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_data_sources" ON "org_finza"."data_sources" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_etl_job_errors" ON "org_finza"."etl_job_errors" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_etl_job_runs" ON "org_finza"."etl_job_runs" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_etl_pipelines" ON "org_finza"."etl_pipelines" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_etl_source_snapshots" ON "org_finza"."etl_source_snapshots" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_filter_definitions" ON "org_finza"."filter_definitions" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_inbound_webhooks" ON "org_finza"."inbound_webhooks" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_integration_secrets" ON "org_finza"."integration_secrets" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_integrations" ON "org_finza"."integrations" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_message_templates" ON "org_finza"."message_templates" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_portfolios" ON "org_finza"."portfolios" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_titles" ON "org_finza"."titles" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_workflow_executions" ON "org_finza"."workflow_executions" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_workflow_steps" ON "org_finza"."workflow_steps" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_access_workflows" ON "org_finza"."workflows" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "blips_users_can_access_custom_variables" ON "org_finza"."custom_variables" USING ("org_finza"."user_belongs_to_org"());



ALTER TABLE "org_finza"."blocked_dates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."blocklist" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."blocklist_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."blocklist_filter_rules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."blocklist_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."campaign_execution_candidates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."campaign_execution_runs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."campaign_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."campaign_workflows" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."campaigns" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."channel_costs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."channel_rate_counts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."channel_rate_limits" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."contact_assignments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."contact_emails" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."contact_phones" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."contact_seals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."contact_summaries" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "contact_summaries_member_access" ON "org_finza"."contact_summaries" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "contact_summaries_service_role_full_access" ON "org_finza"."contact_summaries" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "org_finza"."contacts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."contract_portfolios" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."contract_seals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."contracts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."conversation_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."custom_field_definitions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."custom_variables" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."data_source_skills" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."data_sources" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."etl_batch_jobs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."etl_job_errors" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "etl_job_errors_member_access" ON "org_finza"."etl_job_errors" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "etl_job_errors_service_role_full_access" ON "org_finza"."etl_job_errors" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "org_finza"."etl_job_runs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."etl_pipelines" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."etl_source_snapshots" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."filter_definitions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."inbound_webhooks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."integration_secrets" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "integration_secrets_admin_owner_access" ON "org_finza"."integration_secrets" TO "authenticated" USING (("public"."is_org_admin_or_owner"(( SELECT "organizations"."id"
   FROM "public"."organizations"
  WHERE (("organizations"."slug")::"text" = 'blips'::"text"))) OR "public"."is_super_admin"("auth"."uid"()))) WITH CHECK (("public"."is_org_admin_or_owner"(( SELECT "organizations"."id"
   FROM "public"."organizations"
  WHERE (("organizations"."slug")::"text" = 'blips'::"text"))) OR "public"."is_super_admin"("auth"."uid"())));



CREATE POLICY "integration_secrets_service_role_full_access" ON "org_finza"."integration_secrets" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "org_finza"."integrations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "integrations_member_access" ON "org_finza"."integrations" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "integrations_service_role_full_access" ON "org_finza"."integrations" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "org_finza"."message_templates" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "org_users_access_actions_dlq" ON "org_finza"."actions_dlq" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_allowed_tags" ON "org_finza"."agent_allowed_tags" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_audit_logs" ON "org_finza"."agent_audit_logs" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_call_logs" ON "org_finza"."agent_call_logs" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_llm_configs" ON "org_finza"."agent_llm_configs" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_messages" ON "org_finza"."agent_messages" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_proposal_items" ON "org_finza"."agent_proposal_items" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_proposals" ON "org_finza"."agent_proposals" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_agent_sessions" ON "org_finza"."agent_sessions" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_ai_agents" ON "org_finza"."ai_agents" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_ai_playground_sessions" ON "org_finza"."ai_playground_sessions" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_blocked_dates" ON "org_finza"."blocked_dates" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_campaign_execution_candidates" ON "org_finza"."campaign_execution_candidates" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_campaign_execution_runs" ON "org_finza"."campaign_execution_runs" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_campaign_workflows" ON "org_finza"."campaign_workflows" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_channel_costs" ON "org_finza"."channel_costs" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_channel_rate_counts" ON "org_finza"."channel_rate_counts" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_channel_rate_limits" ON "org_finza"."channel_rate_limits" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_contact_seals" ON "org_finza"."contact_seals" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_contract_portfolios" ON "org_finza"."contract_portfolios" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_contract_seals" ON "org_finza"."contract_seals" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_conversation_tags" ON "org_finza"."conversation_tags" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_data_source_skills" ON "org_finza"."data_source_skills" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_etl_batch_jobs" ON "org_finza"."etl_batch_jobs" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_rag_chunks" ON "org_finza"."rag_chunks" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_rag_documents" ON "org_finza"."rag_documents" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_seal_catalog" ON "org_finza"."seal_catalog" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_skipped_actions_log" ON "org_finza"."skipped_actions_log" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_standard_values" ON "org_finza"."standard_values" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_supplies" ON "org_finza"."supplies" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_supply_seals" ON "org_finza"."supply_seals" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_supply_title_seals" ON "org_finza"."supply_title_seals" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_supply_title_status_history" ON "org_finza"."supply_title_status_history" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_supply_titles" ON "org_finza"."supply_titles" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_tag_catalog" ON "org_finza"."tag_catalog" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_title_seals" ON "org_finza"."title_seals" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_transfer_tag_type_periods" ON "org_finza"."transfer_tag_type_periods" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_transfer_tags" ON "org_finza"."transfer_tags" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_webhook_retry_queue" ON "org_finza"."webhook_retry_queue" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_workflow_audit_logs" ON "org_finza"."workflow_audit_logs" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_access_workflow_versions" ON "org_finza"."workflow_versions" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_select_actions_interaction_logs" ON "org_finza"."actions_interaction_logs" FOR SELECT TO "authenticated" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_backfill_checkpoint" ON "org_finza"."ai_backfill_checkpoint" FOR SELECT TO "authenticated" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_backfill_quarantine" ON "org_finza"."ai_backfill_quarantine" FOR SELECT TO "authenticated" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_conversations" ON "org_finza"."ai_conversations" FOR SELECT TO "authenticated" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_funnel_events" ON "org_finza"."ai_funnel_events" FOR SELECT TO "authenticated" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_ingestion_events" ON "org_finza"."ai_ingestion_events" FOR SELECT TO "authenticated" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_messages" ON "org_finza"."ai_messages" FOR SELECT TO "authenticated" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_protocol_status_log" ON "org_finza"."ai_protocol_status_log" FOR SELECT TO "authenticated" USING ("org_finza"."user_belongs_to_org"());



CREATE POLICY "org_users_select_ai_protocols" ON "org_finza"."ai_protocols" FOR SELECT TO "authenticated" USING ("org_finza"."user_belongs_to_org"());



ALTER TABLE "org_finza"."portfolio_integrations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "portfolio_integrations_member_access" ON "org_finza"."portfolio_integrations" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "portfolio_integrations_service_role_full_access" ON "org_finza"."portfolio_integrations" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "org_finza"."portfolios" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."rag_chunks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."rag_documents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."report_schedules" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "report_schedules_admin_owner_access" ON "org_finza"."report_schedules" TO "authenticated" USING (("public"."is_org_admin_or_owner"(( SELECT "organizations"."id"
   FROM "public"."organizations"
  WHERE (("organizations"."slug")::"text" = 'blips'::"text"))) OR "public"."is_super_admin"("auth"."uid"()))) WITH CHECK (("public"."is_org_admin_or_owner"(( SELECT "organizations"."id"
   FROM "public"."organizations"
  WHERE (("organizations"."slug")::"text" = 'blips'::"text"))) OR "public"."is_super_admin"("auth"."uid"())));



CREATE POLICY "report_schedules_service_role_full_access" ON "org_finza"."report_schedules" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "org_finza"."seal_catalog" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."sending_controls" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sending_controls_member_access" ON "org_finza"."sending_controls" TO "authenticated" USING ("org_finza"."user_belongs_to_org"()) WITH CHECK ("org_finza"."user_belongs_to_org"());



CREATE POLICY "sending_controls_service_role_full_access" ON "org_finza"."sending_controls" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "org_finza"."skipped_actions_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."standard_values" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."supplies" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."supply_seals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."supply_title_seals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."supply_title_status_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."supply_titles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."tag_catalog" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."title_seals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."title_status_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."titles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."transfer_event_reclass_audit" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."transfer_event_reclass_batches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."transfer_tag_type_periods" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."transfer_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."transfer_type_reclass_audit" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."transfer_type_reclass_batches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."webhook_retry_queue" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."workflow_audit_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."workflow_executions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."workflow_steps" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."workflow_versions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "org_finza"."workflows" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Admins can create invitations" ON "public"."user_invitations" FOR INSERT WITH CHECK (("organization_id" IN ( SELECT "organization_users"."organization_id"
   FROM "public"."organization_users"
  WHERE (("organization_users"."user_id" = "auth"."uid"()) AND (("organization_users"."role")::"text" = ANY ((ARRAY['owner'::character varying, 'admin'::character varying])::"text"[])) AND ("organization_users"."is_active" = true)))));



CREATE POLICY "Admins can delete invitations" ON "public"."user_invitations" FOR DELETE USING (("organization_id" IN ( SELECT "organization_users"."organization_id"
   FROM "public"."organization_users"
  WHERE (("organization_users"."user_id" = "auth"."uid"()) AND (("organization_users"."role")::"text" = ANY ((ARRAY['owner'::character varying, 'admin'::character varying])::"text"[])) AND ("organization_users"."is_active" = true)))));



CREATE POLICY "Admins can manage api keys" ON "public"."api_keys" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "Admins can manage org integrations" ON "public"."organization_marketplace_integrations" USING (("organization_id" IN ( SELECT "organization_users"."organization_id"
   FROM "public"."organization_users"
  WHERE (("organization_users"."user_id" = "auth"."uid"()) AND (("organization_users"."role")::"text" = ANY ((ARRAY['owner'::character varying, 'admin'::character varying])::"text"[])) AND ("organization_users"."is_active" = true)))));



CREATE POLICY "Admins can manage org secrets" ON "public"."organization_secrets" USING (("organization_id" IN ( SELECT "organization_users"."organization_id"
   FROM "public"."organization_users"
  WHERE (("organization_users"."user_id" = "auth"."uid"()) AND (("organization_users"."role")::"text" = ANY ((ARRAY['owner'::character varying, 'admin'::character varying])::"text"[])) AND ("organization_users"."is_active" = true)))));



CREATE POLICY "Admins can update invitations" ON "public"."user_invitations" FOR UPDATE USING (("organization_id" IN ( SELECT "organization_users"."organization_id"
   FROM "public"."organization_users"
  WHERE (("organization_users"."user_id" = "auth"."uid"()) AND (("organization_users"."role")::"text" = ANY ((ARRAY['owner'::character varying, 'admin'::character varying])::"text"[])) AND ("organization_users"."is_active" = true))))) WITH CHECK (("organization_id" IN ( SELECT "organization_users"."organization_id"
   FROM "public"."organization_users"
  WHERE (("organization_users"."user_id" = "auth"."uid"()) AND (("organization_users"."role")::"text" = ANY ((ARRAY['owner'::character varying, 'admin'::character varying])::"text"[])) AND ("organization_users"."is_active" = true)))));



CREATE POLICY "Admins can view invitations" ON "public"."user_invitations" FOR SELECT USING (("organization_id" IN ( SELECT "organization_users"."organization_id"
   FROM "public"."organization_users"
  WHERE (("organization_users"."user_id" = "auth"."uid"()) AND (("organization_users"."role")::"text" = ANY ((ARRAY['owner'::character varying, 'admin'::character varying])::"text"[])) AND ("organization_users"."is_active" = true)))));



CREATE POLICY "Anyone can read marketplace integrations" ON "public"."marketplace_integrations" FOR SELECT USING (true);



CREATE POLICY "Anyone can read roles" ON "public"."roles_permissions" FOR SELECT USING (true);



CREATE POLICY "Only service_role can manage super_admins" ON "public"."super_admins" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Org members can view their org logs" ON "public"."edge_function_call_logs" FOR SELECT USING ((("org_slug" IS NULL) OR ("org_slug" IN ( SELECT "o"."slug"
   FROM ("public"."organizations" "o"
     JOIN "public"."organization_users" "m" ON (("m"."organization_id" = "o"."id")))
  WHERE (("m"."user_id" = "auth"."uid"()) AND ("m"."is_active" = true))))));



CREATE POLICY "Service role full access to secrets" ON "public"."organization_secrets" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Super admins can create organizations" ON "public"."organizations" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_super_admin"("auth"."uid"()));



CREATE POLICY "Super admins can delete organizations" ON "public"."organizations" FOR DELETE TO "authenticated" USING ("public"."is_super_admin"("auth"."uid"()));



CREATE POLICY "Users can view org integrations" ON "public"."organization_marketplace_integrations" FOR SELECT USING (("organization_id" IN ( SELECT "organization_users"."organization_id"
   FROM "public"."organization_users"
  WHERE (("organization_users"."user_id" = "auth"."uid"()) AND ("organization_users"."is_active" = true)))));



ALTER TABLE "public"."a2a_closure_dispatches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ai_feature_flags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ai_metric_hotfix_backups" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ai_report_export_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ai_retention_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."api_keys" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "api_keys_select_super_admin" ON "public"."api_keys" FOR SELECT TO "authenticated" USING ("public"."is_super_admin"("auth"."uid"()));



COMMENT ON POLICY "api_keys_select_super_admin" ON "public"."api_keys" IS 'Key universal (2026-06-03): SELECT limitado a super_admin. Keys nao tem mais org binding.';



CREATE POLICY "api_keys_update_super_admin" ON "public"."api_keys" FOR UPDATE TO "authenticated" USING ("public"."is_super_admin"("auth"."uid"())) WITH CHECK ("public"."is_super_admin"("auth"."uid"()));



COMMENT ON POLICY "api_keys_update_super_admin" ON "public"."api_keys" IS 'Key universal (2026-06-03): UPDATE (soft-delete is_active=false) limitado a super_admin.';



ALTER TABLE "public"."changelog_reactions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "changelog_reactions_delete_own" ON "public"."changelog_reactions" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "changelog_reactions_insert_own" ON "public"."changelog_reactions" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "changelog_reactions_select_authenticated" ON "public"."changelog_reactions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "changelog_reactions_update_own" ON "public"."changelog_reactions" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."changelog_seen" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "changelog_seen_delete_own" ON "public"."changelog_seen" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "changelog_seen_insert_own" ON "public"."changelog_seen" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "changelog_seen_select_own" ON "public"."changelog_seen" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."changelog_views" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "changelog_views_delete_own" ON "public"."changelog_views" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "changelog_views_insert_own" ON "public"."changelog_views" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "changelog_views_select_authenticated" ON "public"."changelog_views" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "changelog_views_update_own" ON "public"."changelog_views" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."chat_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chat_state" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."edge_function_call_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."email_rotation" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."health_check_alerts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."historic_dalila" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "invitations_select_org_members" ON "public"."user_invitations" FOR SELECT TO "authenticated" USING (("organization_id" IN ( SELECT "public"."get_user_org_ids"() AS "get_user_org_ids")));



ALTER TABLE "public"."kiara_processing_lock" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."marketplace_integrations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mcp_cross_org_read_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mv_refresh_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mv_refresh_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."n8n_chat_histories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "org_users_delete_by_admin_or_self" ON "public"."organization_users" FOR DELETE TO "authenticated" USING ((("user_id" = "auth"."uid"()) OR "public"."is_org_admin_or_owner"("organization_id")));



CREATE POLICY "org_users_insert_blocked" ON "public"."organization_users" FOR INSERT TO "authenticated" WITH CHECK (false);



COMMENT ON POLICY "org_users_insert_blocked" ON "public"."organization_users" IS 'M015 (feat/IAF-176, 2026-05-26): bloqueia INSERT direto via authenticated. INSERT permitido apenas via RPC public.accept_invitation (SECURITY DEFINER) ou via service_role (mantida pela policy service_role_all_org_users). Substitui org_users_insert_own (with_check=user_id=auth.uid()) que permitia priv escalation: atacante autenticado se vinculava como owner a qualquer org.';



CREATE POLICY "org_users_select_org_members" ON "public"."organization_users" FOR SELECT TO "authenticated" USING (("organization_id" IN ( SELECT "public"."get_user_org_ids"() AS "get_user_org_ids")));



CREATE POLICY "org_users_update_admin_no_self_promote" ON "public"."organization_users" FOR UPDATE TO "authenticated" USING ((("user_id" = "auth"."uid"()) OR "public"."is_org_admin_or_owner"("organization_id") OR "public"."is_super_admin"("auth"."uid"()))) WITH CHECK (((("user_id" = "auth"."uid"()) AND (("role")::"text" = (( SELECT "ou"."role"
   FROM "public"."organization_users" "ou"
  WHERE (("ou"."user_id" = "auth"."uid"()) AND ("ou"."organization_id" = "organization_users"."organization_id"))))::"text")) OR (("user_id" <> "auth"."uid"()) AND "public"."is_org_admin_or_owner"("organization_id")) OR "public"."is_super_admin"("auth"."uid"())));



COMMENT ON POLICY "org_users_update_admin_no_self_promote" ON "public"."organization_users" IS 'M015 (feat/IAF-176, 2026-05-26): UPDATE em organization_users. Self pode atualizar a propria linha mas NAO mudar role (bloqueia auto-promotion). Admin/owner muda role de OUTROS users na mesma org. Super_admin bypassa. Substitui org_users_update_by_admin_or_self que permitia admin promover-se a owner via UPDATE em propria linha.';



ALTER TABLE "public"."organization_marketplace_integrations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."organization_role_changes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."organization_secrets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."organization_users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."organizations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "orgs_select_member_or_super_admin" ON "public"."organizations" FOR SELECT TO "authenticated" USING ((("id" IN ( SELECT "organization_users"."organization_id"
   FROM "public"."organization_users"
  WHERE ("organization_users"."user_id" = "auth"."uid"()))) OR "public"."is_super_admin"("auth"."uid"())));



COMMENT ON POLICY "orgs_select_member_or_super_admin" ON "public"."organizations" IS 'M014 (feat/IAF-176, 2026-05-26): limita SELECT a orgs onde user e membro (via organization_users) ou super_admin. Substitui orgs_select_authenticated (qual=true) que permitia reconnaissance cross-tenant de todas orgs.';



CREATE POLICY "orgs_update_admin_or_owner_or_super_admin" ON "public"."organizations" FOR UPDATE TO "authenticated" USING ((("id" IN ( SELECT "organization_users"."organization_id"
   FROM "public"."organization_users"
  WHERE (("organization_users"."user_id" = "auth"."uid"()) AND (("organization_users"."role")::"text" = ANY ((ARRAY['owner'::character varying, 'admin'::character varying])::"text"[]))))) OR "public"."is_super_admin"("auth"."uid"()))) WITH CHECK ((("id" IN ( SELECT "organization_users"."organization_id"
   FROM "public"."organization_users"
  WHERE (("organization_users"."user_id" = "auth"."uid"()) AND (("organization_users"."role")::"text" = ANY ((ARRAY['owner'::character varying, 'admin'::character varying])::"text"[]))))) OR "public"."is_super_admin"("auth"."uid"())));



COMMENT ON POLICY "orgs_update_admin_or_owner_or_super_admin" ON "public"."organizations" IS 'M014 (feat/IAF-176, 2026-05-26): limita UPDATE a owner/admin da org ou super_admin. Substitui orgs_update_authenticated (qual=true) que permitia qualquer authenticated alterar nome/slug/custom_domain de outras orgs.';



ALTER TABLE "public"."project_config" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "role_changes_select_admin_or_super" ON "public"."organization_role_changes" FOR SELECT TO "authenticated" USING (("public"."is_org_admin_or_owner"("organization_id") OR "public"."is_super_admin"("auth"."uid"())));



CREATE POLICY "role_changes_service_role_all" ON "public"."organization_role_changes" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."roles_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."scheduled_report_deliveries" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "service_role full access" ON "public"."edge_function_call_logs" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "service_role_all_org_users" ON "public"."organization_users" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service_role_all_orgs" ON "public"."organizations" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."super_admins" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_invitations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_invitations_delete" ON "public"."user_invitations" FOR DELETE TO "authenticated" USING (("public"."is_org_admin_or_owner"("organization_id") OR "public"."is_super_admin"("auth"."uid"())));



CREATE POLICY "user_invitations_insert" ON "public"."user_invitations" FOR INSERT TO "authenticated" WITH CHECK (("public"."is_org_admin_or_owner"("organization_id") OR "public"."is_super_admin"("auth"."uid"())));



CREATE POLICY "user_invitations_select" ON "public"."user_invitations" FOR SELECT TO "authenticated" USING (("public"."is_org_admin_or_owner"("organization_id") OR "public"."is_super_admin"("auth"."uid"()) OR ("lower"(("email")::"text") = "lower"(COALESCE("auth"."email"(), ''::"text")))));



COMMENT ON POLICY "user_invitations_select" ON "public"."user_invitations" IS 'M-A13 (feat/IAF-176, 2026-05-26): SELECT de convites. Admin/owner da org ve invites da org; super_admin ve tudo; user ve invites do proprio email. Usa auth.email() (le do JWT) em vez de SELECT em auth.users — a role authenticated nao tem SELECT em auth.users, o que causava 42501.';



CREATE POLICY "user_invitations_service_role" ON "public"."user_invitations" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "user_invitations_update" ON "public"."user_invitations" FOR UPDATE TO "authenticated" USING (("public"."is_org_admin_or_owner"("organization_id") OR "public"."is_super_admin"("auth"."uid"()))) WITH CHECK (("public"."is_org_admin_or_owner"("organization_id") OR "public"."is_super_admin"("auth"."uid"())));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;
SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";
GRANT USAGE ON SCHEMA "public" TO "airbyte_readonly";






GRANT USAGE ON SCHEMA "org_blips" TO "authenticated";
GRANT USAGE ON SCHEMA "org_blips" TO "service_role";
GRANT USAGE ON SCHEMA "org_blips" TO "anon";
GRANT USAGE ON SCHEMA "org_blips" TO "airbyte_readonly";



GRANT USAGE ON SCHEMA "org_finza" TO "authenticated";
GRANT USAGE ON SCHEMA "org_finza" TO "service_role";
GRANT USAGE ON SCHEMA "org_finza" TO "anon";
GRANT USAGE ON SCHEMA "org_finza" TO "airbyte_readonly";



GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_in"("cstring", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_in"("cstring", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_in"("cstring", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_in"("cstring", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_out"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_out"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_out"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_out"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_recv"("internal", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_recv"("internal", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_recv"("internal", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_recv"("internal", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_send"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_send"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_send"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_send"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_typmod_in"("cstring"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_typmod_in"("cstring"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_typmod_in"("cstring"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_typmod_in"("cstring"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_in"("cstring", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_in"("cstring", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_in"("cstring", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_in"("cstring", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_out"("public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_out"("public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_out"("public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_out"("public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_recv"("internal", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_recv"("internal", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_recv"("internal", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_recv"("internal", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_send"("public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_send"("public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_send"("public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_send"("public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_typmod_in"("cstring"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_typmod_in"("cstring"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_typmod_in"("cstring"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_typmod_in"("cstring"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_in"("cstring", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_in"("cstring", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_in"("cstring", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_in"("cstring", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_out"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_out"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_out"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_out"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_recv"("internal", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_recv"("internal", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_recv"("internal", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_recv"("internal", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_send"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_send"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_send"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_send"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_typmod_in"("cstring"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_typmod_in"("cstring"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_typmod_in"("cstring"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_typmod_in"("cstring"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_halfvec"(real[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(real[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(real[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(real[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(real[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(real[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(real[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(real[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_vector"(real[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_vector"(real[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_vector"(real[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_vector"(real[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_halfvec"(double precision[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(double precision[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(double precision[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(double precision[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(double precision[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(double precision[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(double precision[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(double precision[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_vector"(double precision[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_vector"(double precision[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_vector"(double precision[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_vector"(double precision[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_halfvec"(integer[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(integer[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(integer[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(integer[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(integer[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(integer[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(integer[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(integer[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_vector"(integer[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_vector"(integer[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_vector"(integer[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_vector"(integer[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_halfvec"(numeric[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(numeric[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(numeric[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_halfvec"(numeric[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(numeric[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(numeric[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(numeric[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_sparsevec"(numeric[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."array_to_vector"(numeric[], integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."array_to_vector"(numeric[], integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."array_to_vector"(numeric[], integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."array_to_vector"(numeric[], integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_to_float4"("public"."halfvec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_to_float4"("public"."halfvec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_to_float4"("public"."halfvec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_to_float4"("public"."halfvec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec"("public"."halfvec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec"("public"."halfvec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec"("public"."halfvec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec"("public"."halfvec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_to_sparsevec"("public"."halfvec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_to_sparsevec"("public"."halfvec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_to_sparsevec"("public"."halfvec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_to_sparsevec"("public"."halfvec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_to_vector"("public"."halfvec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_to_vector"("public"."halfvec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_to_vector"("public"."halfvec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_to_vector"("public"."halfvec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_to_halfvec"("public"."sparsevec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_to_halfvec"("public"."sparsevec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_to_halfvec"("public"."sparsevec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_to_halfvec"("public"."sparsevec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec"("public"."sparsevec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec"("public"."sparsevec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec"("public"."sparsevec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec"("public"."sparsevec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_to_vector"("public"."sparsevec", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_to_vector"("public"."sparsevec", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_to_vector"("public"."sparsevec", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_to_vector"("public"."sparsevec", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_to_float4"("public"."vector", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_to_float4"("public"."vector", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_to_float4"("public"."vector", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_to_float4"("public"."vector", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_to_halfvec"("public"."vector", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_to_halfvec"("public"."vector", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_to_halfvec"("public"."vector", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_to_halfvec"("public"."vector", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_to_sparsevec"("public"."vector", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_to_sparsevec"("public"."vector", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_to_sparsevec"("public"."vector", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_to_sparsevec"("public"."vector", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector"("public"."vector", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector"("public"."vector", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."vector"("public"."vector", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector"("public"."vector", integer, boolean) TO "service_role";















































































































































































































GRANT ALL ON FUNCTION "org_blips"."check_and_increment_rate_limit"("p_channel" character varying, "p_count" integer) TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."check_contact_cooldown"("p_contact_id" "uuid", "p_action_type" character varying, "p_cooldown_hours" integer) TO "authenticated";
GRANT ALL ON FUNCTION "org_blips"."check_contact_cooldown"("p_contact_id" "uuid", "p_action_type" character varying, "p_cooldown_hours" integer) TO "service_role";



GRANT ALL ON TABLE "org_blips"."actions" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."actions" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."actions" TO "airbyte_readonly";



GRANT ALL ON FUNCTION "org_blips"."claim_pending_actions"("p_worker_id" character varying, "p_batch_size" integer, "p_lock_duration_minutes" integer) TO "authenticated";
GRANT ALL ON FUNCTION "org_blips"."claim_pending_actions"("p_worker_id" character varying, "p_batch_size" integer, "p_lock_duration_minutes" integer) TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."cleanup_old_rate_windows"() TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."cleanup_stale_locks"("p_older_than_minutes" integer) TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."evaluate_regua_contacts_batch"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_regua_conditions" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "org_blips"."evaluate_regua_contacts_batch"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_regua_conditions" "jsonb") TO "anon";



GRANT ALL ON FUNCTION "org_blips"."get_action_stats"("p_since" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "org_blips"."get_action_stats"("p_since" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."get_channel_rate_status"("p_channel" character varying) TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."get_dlq_summary"() TO "authenticated";
GRANT ALL ON FUNCTION "org_blips"."get_dlq_summary"() TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."get_filtered_action_stats"("p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_campaign_id" "uuid", "p_action_types" "text"[], "p_statuses" "text"[], "p_exclude_test" boolean, "p_days_overdue_min" integer, "p_days_overdue_max" integer, "p_source" "text", "p_search" "text") TO "authenticated";
GRANT ALL ON FUNCTION "org_blips"."get_filtered_action_stats"("p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_campaign_id" "uuid", "p_action_types" "text"[], "p_statuses" "text"[], "p_exclude_test" boolean, "p_days_overdue_min" integer, "p_days_overdue_max" integer, "p_source" "text", "p_search" "text") TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."get_queue_health"() TO "authenticated";
GRANT ALL ON FUNCTION "org_blips"."get_queue_health"() TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."get_repique_actions"("p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "org_blips"."get_repique_actions"("p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."lock_actions_for_processing"("p_limit" integer, "p_processor_id" character varying, "p_lock_duration_seconds" integer) TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."log_skipped_action"("p_contact_id" "uuid", "p_skip_reason" character varying, "p_workflow_id" "uuid", "p_workflow_step_id" "uuid", "p_campaign_id" "uuid", "p_campaign_log_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_action_type" character varying, "p_channel" character varying, "p_skip_details" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "org_blips"."log_skipped_action"("p_contact_id" "uuid", "p_skip_reason" character varying, "p_workflow_id" "uuid", "p_workflow_step_id" "uuid", "p_campaign_id" "uuid", "p_campaign_log_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_action_type" character varying, "p_channel" character varying, "p_skip_details" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."maintenance_actions_table"() TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."move_to_dlq"("p_action_id" "uuid", "p_failure_reason" "text") TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."process_action_failure"("p_action_id" "uuid", "p_error_message" "text", "p_worker_id" character varying) TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."release_action_lock"("p_action_id" "uuid", "p_new_status" character varying, "p_response" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."release_action_locks"("p_action_ids" "uuid"[], "p_processor_id" character varying) TO "service_role";



GRANT ALL ON FUNCTION "org_blips"."reprocess_from_dlq"("p_dlq_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."check_and_increment_rate_limit"("p_channel" character varying, "p_count" integer) TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."check_contact_cooldown"("p_contact_id" "uuid", "p_action_type" character varying, "p_cooldown_hours" integer) TO "authenticated";
GRANT ALL ON FUNCTION "org_finza"."check_contact_cooldown"("p_contact_id" "uuid", "p_action_type" character varying, "p_cooldown_hours" integer) TO "service_role";



GRANT ALL ON TABLE "org_finza"."actions" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."actions" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."actions" TO "airbyte_readonly";



GRANT ALL ON FUNCTION "org_finza"."claim_pending_actions"("p_worker_id" character varying, "p_batch_size" integer, "p_lock_duration_minutes" integer) TO "authenticated";
GRANT ALL ON FUNCTION "org_finza"."claim_pending_actions"("p_worker_id" character varying, "p_batch_size" integer, "p_lock_duration_minutes" integer) TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."cleanup_old_rate_windows"() TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."cleanup_stale_locks"("p_older_than_minutes" integer) TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."evaluate_regua_contacts_batch"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_regua_conditions" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "org_finza"."evaluate_regua_contacts_batch"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_regua_conditions" "jsonb") TO "anon";



GRANT ALL ON FUNCTION "org_finza"."get_action_stats"("p_since" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "org_finza"."get_action_stats"("p_since" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."get_channel_rate_status"("p_channel" character varying) TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."get_dlq_summary"() TO "authenticated";
GRANT ALL ON FUNCTION "org_finza"."get_dlq_summary"() TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."get_filtered_action_stats"("p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_campaign_id" "uuid", "p_action_types" "text"[], "p_statuses" "text"[], "p_exclude_test" boolean, "p_days_overdue_min" integer, "p_days_overdue_max" integer, "p_source" "text", "p_search" "text") TO "authenticated";
GRANT ALL ON FUNCTION "org_finza"."get_filtered_action_stats"("p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_campaign_id" "uuid", "p_action_types" "text"[], "p_statuses" "text"[], "p_exclude_test" boolean, "p_days_overdue_min" integer, "p_days_overdue_max" integer, "p_source" "text", "p_search" "text") TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."get_queue_health"() TO "authenticated";
GRANT ALL ON FUNCTION "org_finza"."get_queue_health"() TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."get_repique_actions"("p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "org_finza"."get_repique_actions"("p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."lock_actions_for_processing"("p_limit" integer, "p_processor_id" character varying, "p_lock_duration_seconds" integer) TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."log_skipped_action"("p_contact_id" "uuid", "p_skip_reason" character varying, "p_workflow_id" "uuid", "p_workflow_step_id" "uuid", "p_campaign_id" "uuid", "p_campaign_log_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_action_type" character varying, "p_channel" character varying, "p_skip_details" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "org_finza"."log_skipped_action"("p_contact_id" "uuid", "p_skip_reason" character varying, "p_workflow_id" "uuid", "p_workflow_step_id" "uuid", "p_campaign_id" "uuid", "p_campaign_log_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_action_type" character varying, "p_channel" character varying, "p_skip_details" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."maintenance_actions_table"() TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."move_to_dlq"("p_action_id" "uuid", "p_failure_reason" "text") TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."process_action_failure"("p_action_id" "uuid", "p_error_message" "text", "p_worker_id" character varying) TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."release_action_lock"("p_action_id" "uuid", "p_new_status" character varying, "p_response" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."release_action_locks"("p_action_ids" "uuid"[], "p_processor_id" character varying) TO "service_role";



GRANT ALL ON FUNCTION "org_finza"."reprocess_from_dlq"("p_dlq_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_agent_call_lock_key"("p_schema_name" "text", "p_source" "text", "p_source_event_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_agent_call_lock_key"("p_schema_name" "text", "p_source" "text", "p_source_event_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_agent_call_payload_diff"("p_existing" "jsonb", "p_incoming" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_agent_call_payload_diff"("p_existing" "jsonb", "p_incoming" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_agent_type_composition"("p_schema_name" "text", "p_from" "date", "p_to" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_agent_type_composition"("p_schema_name" "text", "p_from" "date", "p_to" "date") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_backfill_phone_digits"("p_raw" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_backfill_phone_digits"("p_raw" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_content_retention_days"("p_schema_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_content_retention_days"("p_schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_content_retention_days"("p_schema_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_ingest_text"("p_field" "text", "p_value" "text", "p_required" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_ingest_text"("p_field" "text", "p_value" "text", "p_required" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_ingest_uuid"("p_field" "text", "p_value" "text", "p_required" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_ingest_uuid"("p_field" "text", "p_value" "text", "p_required" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_lock_key"("p_namespace" "text", "p_schema_name" "text", "p_key" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_lock_key"("p_namespace" "text", "p_schema_name" "text", "p_key" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_merge_accuracy"("p_a" "jsonb", "p_b" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_merge_accuracy"("p_a" "jsonb", "p_b" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_merge_accuracy"("p_a" "jsonb", "p_b" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_merge_funnel"("p_a" "jsonb", "p_b" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_merge_funnel"("p_a" "jsonb", "p_b" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_merge_funnel"("p_a" "jsonb", "p_b" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_merge_keyed_array"("p_a" "jsonb", "p_b" "jsonb", "p_keys" "text"[], "p_sums" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_merge_keyed_array"("p_a" "jsonb", "p_b" "jsonb", "p_keys" "text"[], "p_sums" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_merge_keyed_array"("p_a" "jsonb", "p_b" "jsonb", "p_keys" "text"[], "p_sums" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_merge_numeric_object"("p_a" "jsonb", "p_b" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_merge_numeric_object"("p_a" "jsonb", "p_b" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_merge_numeric_object"("p_a" "jsonb", "p_b" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_merge_transfer_slice"("p_a" "jsonb", "p_b" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_merge_transfer_slice"("p_a" "jsonb", "p_b" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_merge_transfer_slice"("p_a" "jsonb", "p_b" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_merge_transfers"("p_a" "jsonb", "p_b" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_merge_transfers"("p_a" "jsonb", "p_b" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_merge_transfers"("p_a" "jsonb", "p_b" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260717091100"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260717091100"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260717091100"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260717091600"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260717091600"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260717091600"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260720110000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260720110000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260720110000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260720150000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260720150000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260720150000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260722200000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260722200000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260722200000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260723100000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260723100000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260723100000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260723160000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260723160000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260723160000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260730210000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260730210000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_perf_base_agents_20260730210000"("p_schema_name" character varying, "p_agent_ids" "uuid"[], "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_section_applicability"("p_agent_type" "text", "p_agent_id" "uuid", "p_by_agent_type" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_section_applicability"("p_agent_type" "text", "p_agent_id" "uuid", "p_by_agent_type" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_section_applicability"("p_agent_type" "text", "p_agent_id" "uuid", "p_by_agent_type" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_snapshot_bucket_date"("p_ts" timestamp with time zone, "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_snapshot_bucket_date"("p_ts" timestamp with time zone, "p_granularity" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_snapshot_bucket_date"("p_ts" timestamp with time zone, "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_snapshot_bucket_date"("p_ts" timestamp with time zone, "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_snapshot_bucket_label"("p_bucket" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_snapshot_bucket_label"("p_bucket" "date", "p_granularity" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_snapshot_bucket_label"("p_bucket" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_snapshot_bucket_label"("p_bucket" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_snapshot_bucket_series"("p_from" "date", "p_to_excl" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_snapshot_bucket_series"("p_from" "date", "p_to_excl" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_snapshot_bucket_series"("p_from" "date", "p_to_excl" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_snapshot_invariant"("p_metric_key" "text", "p_code" "text", "p_section" "text", "p_expected" bigint, "p_actual" bigint, "p_message" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_snapshot_invariant"("p_metric_key" "text", "p_code" "text", "p_section" "text", "p_expected" bigint, "p_actual" bigint, "p_message" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_snapshot_invariant"("p_metric_key" "text", "p_code" "text", "p_section" "text", "p_expected" bigint, "p_actual" bigint, "p_message" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_snapshot_mark_not_applicable"("p_snapshot" "jsonb", "p_path" "text"[], "p_reason" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_snapshot_mark_not_applicable"("p_snapshot" "jsonb", "p_path" "text"[], "p_reason" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_snapshot_mark_not_applicable"("p_snapshot" "jsonb", "p_path" "text"[], "p_reason" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_snapshot_mark_partial"("p_snapshot" "jsonb", "p_path" "text"[], "p_data" "jsonb", "p_reason" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_snapshot_mark_partial"("p_snapshot" "jsonb", "p_path" "text"[], "p_data" "jsonb", "p_reason" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_snapshot_mark_partial"("p_snapshot" "jsonb", "p_path" "text"[], "p_data" "jsonb", "p_reason" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_snapshot_sum_total"("p_arr" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_snapshot_sum_total"("p_arr" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_snapshot_sum_total"("p_arr" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_transfer_events_scoped"("p_schema_name" character varying, "p_from" timestamp with time zone, "p_to_exclusive" timestamp with time zone, "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_transfer_events_scoped"("p_schema_name" character varying, "p_from" timestamp with time zone, "p_to_exclusive" timestamp with time zone, "p_agent_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_transfer_events_scoped_agents"("p_schema_name" character varying, "p_from" timestamp with time zone, "p_to_exclusive" timestamp with time zone, "p_agent_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_transfer_events_scoped_agents"("p_schema_name" character varying, "p_from" timestamp with time zone, "p_to_exclusive" timestamp with time zone, "p_agent_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_transfer_events_scoped_agents"("p_schema_name" character varying, "p_from" timestamp with time zone, "p_to_exclusive" timestamp with time zone, "p_agent_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."_ai_transfer_protocol_first"("p_schema_name" character varying, "p_from" timestamp with time zone, "p_to_exclusive" timestamp with time zone, "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_ai_transfer_protocol_first"("p_schema_name" character varying, "p_from" timestamp with time zone, "p_to_exclusive" timestamp with time zone, "p_agent_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ai_transfer_protocol_first_agents"("p_schema_name" character varying, "p_from" timestamp with time zone, "p_to_exclusive" timestamp with time zone, "p_agent_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."_ai_transfer_protocol_first_agents"("p_schema_name" character varying, "p_from" timestamp with time zone, "p_to_exclusive" timestamp with time zone, "p_agent_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ai_transfer_protocol_first_agents"("p_schema_name" character varying, "p_from" timestamp with time zone, "p_to_exclusive" timestamp with time zone, "p_agent_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."_assert_caller_belongs_to_schema"("p_schema" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_assert_caller_belongs_to_schema"("p_schema" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_assert_caller_belongs_to_schema"("p_schema" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_assert_caller_is_org_admin"("p_schema" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_assert_caller_is_org_admin"("p_schema" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_assert_caller_is_org_admin"("p_schema" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_assert_caller_is_org_admin"("p_schema" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_assert_service_role_only"("p_fn" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_assert_service_role_only"("p_fn" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_cron_dow_matches"("p_field" "text", "p_dow" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_cron_dow_matches"("p_field" "text", "p_dow" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."_cron_dow_matches"("p_field" "text", "p_dow" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_cron_dow_matches"("p_field" "text", "p_dow" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."_cron_part_matches"("p_part" "text", "p_value" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_cron_part_matches"("p_part" "text", "p_value" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."_cron_part_matches"("p_part" "text", "p_value" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_cron_part_matches"("p_part" "text", "p_value" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_accuracy_metrics_base_20260723160000"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_accuracy_metrics_base_20260723160000"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_get_ai_accuracy_metrics_base_20260723160000"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_internal_accuracy_v1"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_internal_accuracy_v1"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260717091100"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260717091100"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260717091600"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260717091600"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260720110000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260720110000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260720150000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260720150000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260720150000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260722200000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260722200000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260722200000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260723100000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260723100000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260723100000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260723160000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260723160000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260723160000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260730210000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260730210000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260730210000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260803120000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260803120000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260803120000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260805100000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260805100000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260805100000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260812140000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260812140000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_get_ai_performance_snapshot_v1_base_20260812140000"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."a2a_agent_eligibility_sql"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."a2a_agent_eligibility_sql"() TO "service_role";



GRANT ALL ON FUNCTION "public"."a2a_closure_slot"("p_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."a2a_closure_slot"("p_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."a2a_closure_slot"("p_at" timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."a2a_closure_slot_for"("p_at" timestamp with time zone, "p_interval_minutes" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."a2a_closure_slot_for"("p_at" timestamp with time zone, "p_interval_minutes" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."a2a_default_webhook_url"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."a2a_default_webhook_url"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."a2a_default_webhook_url"() TO "service_role";



GRANT ALL ON FUNCTION "public"."accept_invitation"("p_invitation_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."accept_invitation"("p_invitation_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."accept_invitation"("p_invitation_token" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."add_active_workflow_step"("p_execution_id" "uuid", "p_step_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."add_active_workflow_step"("p_execution_id" "uuid", "p_step_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_active_workflow_step"("p_execution_id" "uuid", "p_step_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."add_api_enhancement_columns"("schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."add_api_enhancement_columns"("schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_api_enhancement_columns"("schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."add_broadcast_columns_to_org"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."add_broadcast_columns_to_org"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_broadcast_columns_to_org"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."add_broadcast_multi_filter_columns"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."add_broadcast_multi_filter_columns"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_broadcast_multi_filter_columns"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."add_days_overdue_to_org"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."add_days_overdue_to_org"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_days_overdue_to_org"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_is_scheduled_to_pipelines"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."add_is_scheduled_to_pipelines"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_is_scheduled_to_pipelines"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."add_titles_unique_constraint"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."add_titles_unique_constraint"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_titles_unique_constraint"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."aggregate_etl_batch_metrics"("p_schema_name" character varying, "p_job_run_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."aggregate_etl_batch_metrics"("p_schema_name" character varying, "p_job_run_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."aggregate_etl_batch_metrics"("p_schema_name" character varying, "p_job_run_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ai_agents_protect_tombstone"() TO "anon";
GRANT ALL ON FUNCTION "public"."ai_agents_protect_tombstone"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ai_agents_protect_tombstone"() TO "service_role";



GRANT ALL ON FUNCTION "public"."ai_versions_block_deleted_agent"() TO "anon";
GRANT ALL ON FUNCTION "public"."ai_versions_block_deleted_agent"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ai_versions_block_deleted_agent"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."api_key_has_capability"("p_api_key_id" "uuid", "p_capability" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."api_key_has_capability"("p_api_key_id" "uuid", "p_capability" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."apply_actions_audit_indexes"("p_org_slug" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."apply_actions_audit_indexes"("p_org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."apply_rls_to_all_orgs"() TO "anon";
GRANT ALL ON FUNCTION "public"."apply_rls_to_all_orgs"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."apply_rls_to_all_orgs"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."assert_mv_refresh_tenant"("p_schema_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."assert_mv_refresh_tenant"("p_schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."assert_mv_refresh_tenant"("p_schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."assert_mv_refresh_tenant"("p_schema_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."backfill_ai_messages"("p_schema_name" "text", "p_dry_run" boolean, "p_batch_size" integer, "p_max_batches" integer, "p_reset_checkpoint" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."backfill_ai_messages"("p_schema_name" "text", "p_dry_run" boolean, "p_batch_size" integer, "p_max_batches" integer, "p_reset_checkpoint" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."backfill_ai_protocol_conversations"("p_schema_name" "text", "p_dry_run" boolean, "p_batch_size" integer, "p_max_batches" integer, "p_reset_checkpoint" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."backfill_ai_protocol_conversations"("p_schema_name" "text", "p_dry_run" boolean, "p_batch_size" integer, "p_max_batches" integer, "p_reset_checkpoint" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."binary_quantize"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_contract_totals"("org_slug" "text", "contract_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_contract_totals"("org_slug" "text", "contract_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_contract_totals"("org_slug" "text", "contract_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."campaign_pipeline_apply_rules"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."campaign_pipeline_apply_rules"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."campaign_pipeline_apply_rules"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."campaign_pipeline_cleanup"("p_schema_name" "text", "p_retention_days" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."campaign_pipeline_cleanup"("p_schema_name" "text", "p_retention_days" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."campaign_pipeline_cleanup"("p_schema_name" "text", "p_retention_days" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."campaign_pipeline_create_actions"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."campaign_pipeline_create_actions"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."campaign_pipeline_create_actions"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."campaign_pipeline_cross_dedup"("p_schema_name" "text", "p_run_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."campaign_pipeline_cross_dedup"("p_schema_name" "text", "p_run_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."campaign_pipeline_cross_dedup"("p_schema_name" "text", "p_run_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."campaign_pipeline_fetch_titles"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."campaign_pipeline_fetch_titles"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."campaign_pipeline_fetch_titles"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."campaign_pipeline_match_titles"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."campaign_pipeline_match_titles"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."campaign_pipeline_match_titles"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."campaign_pipeline_resolve_contacts"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."campaign_pipeline_resolve_contacts"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."campaign_pipeline_resolve_contacts"("p_schema_name" "text", "p_run_id" "uuid", "p_batch_size" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."can_view_changelog_people"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."can_view_changelog_people"() TO "anon";
GRANT ALL ON FUNCTION "public"."can_view_changelog_people"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."can_view_changelog_people"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_campaign_dedup"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_step_ids" "uuid"[], "p_integration_ids" "uuid"[], "p_cooldown_cutoff" timestamp with time zone, "p_today_start" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."check_campaign_dedup"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_step_ids" "uuid"[], "p_integration_ids" "uuid"[], "p_cooldown_cutoff" timestamp with time zone, "p_today_start" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_campaign_dedup"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_step_ids" "uuid"[], "p_integration_ids" "uuid"[], "p_cooldown_cutoff" timestamp with time zone, "p_today_start" timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."check_contact_in_filters"("p_schema_name" "text", "p_contact_id" "uuid", "p_filter_ids" "uuid"[], "p_filter_logic" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."check_contact_in_filters"("p_schema_name" "text", "p_contact_id" "uuid", "p_filter_ids" "uuid"[], "p_filter_logic" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_contact_in_filters"("p_schema_name" "text", "p_contact_id" "uuid", "p_filter_ids" "uuid"[], "p_filter_logic" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."check_etl_job_completion"("p_schema_name" character varying, "p_job_run_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."check_etl_job_completion"("p_schema_name" character varying, "p_job_run_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_etl_job_completion"("p_schema_name" character varying, "p_job_run_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."claim_a2a_dispatches"("p_limit" integer, "p_lease_seconds" integer, "p_owner" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."claim_a2a_dispatches"("p_limit" integer, "p_lease_seconds" integer, "p_owner" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."claim_etl_batch"("p_schema_name" character varying, "p_job_run_id" "uuid", "p_worker_id" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."claim_etl_batch"("p_schema_name" character varying, "p_job_run_id" "uuid", "p_worker_id" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."claim_etl_batch"("p_schema_name" character varying, "p_job_run_id" "uuid", "p_worker_id" character varying) TO "service_role";



REVOKE ALL ON FUNCTION "public"."claim_scheduled_report_delivery"("p_schema_name" "text", "p_schedule_id" "uuid", "p_report_type" "text", "p_scheduled_for" "date", "p_period_start" "date", "p_period_end_exclusive" "date", "p_trigger_kind" "text", "p_max_attempts" integer, "p_stale_after_minutes" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."claim_scheduled_report_delivery"("p_schema_name" "text", "p_schedule_id" "uuid", "p_report_type" "text", "p_scheduled_for" "date", "p_period_start" "date", "p_period_end_exclusive" "date", "p_trigger_kind" "text", "p_max_attempts" integer, "p_stale_after_minutes" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_conversation_logs"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_conversation_logs"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_conversation_logs"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_old_etl_snapshots"("p_schema_name" character varying, "p_days_to_keep" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_old_etl_snapshots"("p_schema_name" character varying, "p_days_to_keep" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_old_etl_snapshots"("p_schema_name" character varying, "p_days_to_keep" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_old_health_alerts"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_old_health_alerts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_old_health_alerts"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."close_a2a_dispatches_for_protocol"("p_schema_name" "text", "p_protocol" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."close_a2a_dispatches_for_protocol"("p_schema_name" "text", "p_protocol" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."compile_filter_to_sql_v2"("p_conditions" "jsonb", "p_schema_name" "text", "p_target_entity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."compile_filter_to_sql_v2"("p_conditions" "jsonb", "p_schema_name" "text", "p_target_entity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."compile_filter_to_sql_v2"("p_conditions" "jsonb", "p_schema_name" "text", "p_target_entity" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."complete_etl_batch"("p_schema_name" character varying, "p_batch_id" "uuid", "p_metrics" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."complete_etl_batch"("p_schema_name" character varying, "p_batch_id" "uuid", "p_metrics" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."complete_etl_batch"("p_schema_name" character varying, "p_batch_id" "uuid", "p_metrics" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."complete_workflow_step"("p_execution_id" "uuid", "p_step_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."complete_workflow_step"("p_execution_id" "uuid", "p_step_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."complete_workflow_step"("p_execution_id" "uuid", "p_step_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cosine_distance"("public"."vector", "public"."vector") TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_api_key"("p_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_api_key"("p_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_api_key"("p_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_blocklist_sync_trigger"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_blocklist_sync_trigger"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_blocklist_sync_trigger"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_blocklist_table"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_blocklist_table"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_blocklist_table"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_contact_assignments_table"("schema_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_contact_assignments_table"("schema_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_contact_assignments_table"("schema_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_contract_portfolios_table"("schema_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_contract_portfolios_table"("schema_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_contract_portfolios_table"("schema_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_contract_summaries_table"("schema_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_contract_summaries_table"("schema_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_contract_summaries_table"("schema_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_etl_batch_jobs_table"("schema_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_etl_batch_jobs_table"("schema_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_etl_batch_jobs_table"("schema_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_etl_snapshot"("p_schema_name" character varying, "p_job_run_id" "uuid", "p_pipeline_id" "uuid", "p_data_source_id" "uuid", "p_row_index" integer, "p_raw_data" "jsonb", "p_batch_id" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_etl_snapshot"("p_schema_name" character varying, "p_job_run_id" "uuid", "p_pipeline_id" "uuid", "p_data_source_id" "uuid", "p_row_index" integer, "p_raw_data" "jsonb", "p_batch_id" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_etl_snapshot"("p_schema_name" character varying, "p_job_run_id" "uuid", "p_pipeline_id" "uuid", "p_data_source_id" "uuid", "p_row_index" integer, "p_raw_data" "jsonb", "p_batch_id" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_etl_snapshots_table"("schema_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_etl_snapshots_table"("schema_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_etl_snapshots_table"("schema_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_get_contacts_summary_rpc"("schema_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_get_contacts_summary_rpc"("schema_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_get_contacts_summary_rpc"("schema_name" character varying) TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_manual_client"("p_schema_name" "text", "p_contact" "jsonb", "p_contract" "jsonb", "p_titles" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_manual_client"("p_schema_name" "text", "p_contact" "jsonb", "p_contract" "jsonb", "p_titles" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_manual_client"("p_schema_name" "text", "p_contact" "jsonb", "p_contract" "jsonb", "p_titles" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_mv_supply_titles_base"("schema_name" character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_mv_supply_titles_base"("schema_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_mv_titles_base"("schema_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_mv_titles_base"("schema_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_mv_titles_base"("schema_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_org_action_processing_rpcs"("schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_org_action_processing_rpcs"("schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_org_action_processing_rpcs"("schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_org_get_action_stats"("schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_org_get_action_stats"("schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_org_get_action_stats"("schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_org_get_repique_actions"("schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_org_get_repique_actions"("schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_org_get_repique_actions"("schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_org_maintenance_functions"("schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_org_maintenance_functions"("schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_org_maintenance_functions"("schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_org_repique_index"("schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_org_repique_index"("schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_org_repique_index"("schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_org_schema"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_org_schema"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_org_schema"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_org_schema"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_org_schema"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_org_schema"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_org_user_belongs_function"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_org_user_belongs_function"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_org_user_belongs_function"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_org_vw_actions_ready"("schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_org_vw_actions_ready"("schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_org_vw_actions_ready"("schema_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_org_with_template"("p_slug" "text", "p_name" "text", "p_user_id" "uuid", "p_template_sql" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_org_with_template"("p_slug" "text", "p_name" "text", "p_user_id" "uuid", "p_template_sql" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_org_with_template"("p_slug" "text", "p_name" "text", "p_user_id" "uuid", "p_template_sql" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_org_with_template"("p_slug" "text", "p_name" "text", "p_user_id" "uuid", "p_template_sql" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_portfolio_integrations_table"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_portfolio_integrations_table"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_portfolio_integrations_table"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_portfolios_table"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_portfolios_table"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_portfolios_table"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_vw_contract_portfolios"("schema_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."create_vw_contract_portfolios"("schema_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_vw_contract_portfolios"("schema_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_vw_titles_live"("schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_vw_titles_live"("schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_vw_titles_live"("schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_webhook_retry_queue"("schema_name" "text", "org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_webhook_retry_queue"("schema_name" "text", "org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_webhook_retry_queue"("schema_name" "text", "org_slug" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."cron_due"("p_cron" "text", "p_last_run" timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."cron_due"("p_cron" "text", "p_last_run" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."cron_due"("p_cron" "text", "p_last_run" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."cron_due"("p_cron" "text", "p_last_run" timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."cross_org_resolve_customer"("p_contact_id" "uuid", "p_contract_id" "uuid", "p_document" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."cross_org_resolve_customer"("p_contact_id" "uuid", "p_contract_id" "uuid", "p_document" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."decrypt_llm_key"("p_ciphertext" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."decrypt_llm_key"("p_ciphertext" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."delete_ai_agent_v1"("p_schema_name" "text", "p_agent_id" "uuid", "p_confirmation_slug" "text", "p_execute" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."delete_ai_agent_v1"("p_schema_name" "text", "p_agent_id" "uuid", "p_confirmation_slug" "text", "p_execute" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_ai_agent_v1"("p_schema_name" "text", "p_agent_id" "uuid", "p_confirmation_slug" "text", "p_execute" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."delete_dispatch_batch_pending"("p_schema_name" "text", "p_batch_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."delete_dispatch_batch_pending"("p_schema_name" "text", "p_batch_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_dispatch_batch_pending"("p_schema_name" "text", "p_batch_id" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_integration_secrets"("p_org_id" "uuid", "p_integration_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."delete_integration_secrets"("p_org_id" "uuid", "p_integration_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_integration_secrets"("p_org_id" "uuid", "p_integration_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."derive_filter_target_entity"("p_conditions" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."derive_filter_target_entity"("p_conditions" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."derive_filter_target_entity"("p_conditions" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."encrypt_llm_key"("p_plaintext" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."encrypt_llm_key"("p_plaintext" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."encrypt_llm_key"("p_plaintext" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."enforce_contact_document_type"() TO "anon";
GRANT ALL ON FUNCTION "public"."enforce_contact_document_type"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enforce_contact_document_type"() TO "service_role";



GRANT ALL ON FUNCTION "public"."enforce_filter_target_entity"() TO "anon";
GRANT ALL ON FUNCTION "public"."enforce_filter_target_entity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enforce_filter_target_entity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."enforce_filter_usage_scope_immutable"() TO "anon";
GRANT ALL ON FUNCTION "public"."enforce_filter_usage_scope_immutable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enforce_filter_usage_scope_immutable"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."enqueue_a2a_closures"("p_slot" timestamp with time zone, "p_default_inactivity_hours" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."enqueue_a2a_closures"("p_slot" timestamp with time zone, "p_default_inactivity_hours" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."ensure_filter_cache_columns"("p_schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ensure_filter_cache_columns"("p_schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ensure_filter_cache_columns"("p_schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."ensure_org_columns"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."ensure_org_columns"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."ensure_org_columns"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."evaluate_campaign_preview_batch"("p_schema_name" "text", "p_campaign_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."evaluate_campaign_preview_batch"("p_schema_name" "text", "p_campaign_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."evaluate_campaign_preview_batch"("p_schema_name" "text", "p_campaign_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."evaluate_filter_conditions_preview"("p_schema_name" "text", "p_conditions" "jsonb", "p_limit" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."evaluate_filter_conditions_preview"("p_schema_name" "text", "p_conditions" "jsonb", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."evaluate_filter_conditions_preview"("p_schema_name" "text", "p_conditions" "jsonb", "p_limit" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."evaluate_filters_batch"("p_schema_name" "text", "p_filter_ids" "uuid"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."evaluate_filters_batch"("p_schema_name" "text", "p_filter_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."evaluate_filters_batch"("p_schema_name" "text", "p_filter_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."evaluate_portfolio_membership"("p_schema_name" "text", "p_portfolio_ids" "uuid"[], "p_contact_ids" "uuid"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."evaluate_portfolio_membership"("p_schema_name" "text", "p_portfolio_ids" "uuid"[], "p_contact_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."evaluate_portfolio_membership"("p_schema_name" "text", "p_portfolio_ids" "uuid"[], "p_contact_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."evaluate_portfolios_batch"("p_schema_name" "text", "p_portfolio_ids" "uuid"[], "p_update_cache" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."evaluate_portfolios_batch"("p_schema_name" "text", "p_portfolio_ids" "uuid"[], "p_update_cache" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."evaluate_portfolios_batch"("p_schema_name" "text", "p_portfolio_ids" "uuid"[], "p_update_cache" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."evaluate_regua_conditions_batch"("p_schema_name" "text", "p_regua_conditions" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."evaluate_regua_conditions_batch"("p_schema_name" "text", "p_regua_conditions" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."evaluate_regua_conditions_batch"("p_schema_name" "text", "p_regua_conditions" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."evaluate_regua_contacts_batch"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_regua_conditions" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."evaluate_regua_contacts_batch"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_regua_conditions" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."evaluate_regua_contacts_batch"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_regua_conditions" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."evaluate_workflow_membership"("p_schema_name" "text", "p_workflow_ids" "uuid"[], "p_contact_ids" "uuid"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."evaluate_workflow_membership"("p_schema_name" "text", "p_workflow_ids" "uuid"[], "p_contact_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."evaluate_workflow_membership"("p_schema_name" "text", "p_workflow_ids" "uuid"[], "p_contact_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."evaluate_workflow_stats_batch"("p_schema_name" "text", "p_workflow_ids" "uuid"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."evaluate_workflow_stats_batch"("p_schema_name" "text", "p_workflow_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."evaluate_workflow_stats_batch"("p_schema_name" "text", "p_workflow_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."excluded_status_sql_list"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."excluded_status_sql_list"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."excluded_status_sql_list"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."exec_sql"("sql" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."exec_sql"("sql" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."exec_sql_select"("sql_query" "text", "params" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."exec_sql_select"("sql_query" "text", "params" "text"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."expire_blocklist_entries_logged"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."expire_blocklist_entries_logged"() TO "service_role";



GRANT ALL ON FUNCTION "public"."expose_org_schema_async"("schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."expose_org_schema_async"("schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."expose_org_schema_async"("schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."fail_etl_batch"("p_schema_name" character varying, "p_batch_id" "uuid", "p_error_message" "text", "p_should_retry" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."fail_etl_batch"("p_schema_name" character varying, "p_batch_id" "uuid", "p_error_message" "text", "p_should_retry" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."fail_etl_batch"("p_schema_name" character varying, "p_batch_id" "uuid", "p_error_message" "text", "p_should_retry" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."filter_blocked_action_ids"("p_schema" "text", "p_candidates" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."filter_blocked_action_ids"("p_schema" "text", "p_candidates" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."filter_blocked_action_ids"("p_schema" "text", "p_candidates" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."finalize_ai_backfill_v2"("p_schema_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."finalize_ai_backfill_v2"("p_schema_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."finalize_ai_protocol"("p_schema_name" "text", "p_protocol" "text", "p_agent_slug" "text", "p_expected_revision" bigint, "p_source_event_id" "text", "p_tags" "text"[], "p_occurred_at" timestamp with time zone, "p_added_by" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."finalize_ai_protocol"("p_schema_name" "text", "p_protocol" "text", "p_agent_slug" "text", "p_expected_revision" bigint, "p_source_event_id" "text", "p_tags" "text"[], "p_occurred_at" timestamp with time zone, "p_added_by" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."fix_days_overdue_negative"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."fix_days_overdue_negative"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."fix_days_overdue_negative"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."fix_views_status_values"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."fix_views_status_values"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."fix_views_status_values"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."fix_vw_contacts_enriched_canonical"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."fix_vw_contacts_enriched_canonical"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."fix_vw_contacts_enriched_canonical"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."fix_vw_contacts_enriched_max_days_overdue"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."fix_vw_contacts_enriched_max_days_overdue"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."fix_vw_contacts_enriched_max_days_overdue"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."fix_vw_contacts_enriched_status"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."fix_vw_contacts_enriched_status"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."fix_vw_contacts_enriched_status"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_supply_title_status_history"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_supply_title_status_history"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_supply_title_status_history"() TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_title_status_history"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_title_status_history"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_title_status_history"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_a2a_closure_settings"("p_schema_name" "text", "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_a2a_closure_settings"("p_schema_name" "text", "p_agent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_a2a_closure_settings"("p_schema_name" "text", "p_agent_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_a2a_closure_test_target"("p_schema_name" "text", "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_a2a_closure_test_target"("p_schema_name" "text", "p_agent_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_a2a_dispatch_queue_health"("p_stale_minutes" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_a2a_dispatch_queue_health"("p_stale_minutes" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_action_block_matches"("p_schema" "text", "p_contact_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_contact_document" character varying, "p_channel" "text", "p_recipient" "text", "p_supply_id" "uuid", "p_supply_title_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_action_block_matches"("p_schema" "text", "p_contact_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_contact_document" character varying, "p_channel" "text", "p_recipient" "text", "p_supply_id" "uuid", "p_supply_title_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_action_block_matches"("p_schema" "text", "p_contact_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_contact_document" character varying, "p_channel" "text", "p_recipient" "text", "p_supply_id" "uuid", "p_supply_title_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_action_contact_ids"("p_schema_name" "text", "p_mode" "text", "p_from" timestamp with time zone, "p_to" timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_action_contact_ids"("p_schema_name" "text", "p_mode" "text", "p_from" timestamp with time zone, "p_to" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_action_contact_ids"("p_schema_name" "text", "p_mode" "text", "p_from" timestamp with time zone, "p_to" timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_action_frequency_timeline"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_granularity" "text", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_action_frequency_timeline"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_granularity" "text", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_action_frequency_timeline"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_granularity" "text", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_actions_timeline"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_granularity" character varying, "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_actions_timeline"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_granularity" character varying, "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_actions_timeline"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_granularity" character varying, "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_agent_call_metrics"("p_schema_name" character varying, "p_receiving_agent_id" "uuid", "p_from" timestamp with time zone, "p_to" timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_agent_call_metrics"("p_schema_name" character varying, "p_receiving_agent_id" "uuid", "p_from" timestamp with time zone, "p_to" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_agent_call_metrics"("p_schema_name" character varying, "p_receiving_agent_id" "uuid", "p_from" timestamp with time zone, "p_to" timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_ai_accuracy_metrics"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_ai_accuracy_metrics"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_ai_accuracy_metrics"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_ai_agents_overview_v1"("p_schema_name" character varying, "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_ai_agents_overview_v1"("p_schema_name" character varying, "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_ai_agents_overview_v1"("p_schema_name" character varying, "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_ai_conversation_counts"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_ai_conversation_counts"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_ai_conversation_counts"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_ai_conversation_protocol_summaries_v1"("p_schema_name" "text", "p_agent_id" "uuid", "p_is_a2a" boolean, "p_search" "text", "p_from" "date", "p_to" "date", "p_limit" integer, "p_cursor" "text", "p_tags" "text"[], "p_stages" "text"[], "p_phone" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_ai_conversation_protocol_summaries_v1"("p_schema_name" "text", "p_agent_id" "uuid", "p_is_a2a" boolean, "p_search" "text", "p_from" "date", "p_to" "date", "p_limit" integer, "p_cursor" "text", "p_tags" "text"[], "p_stages" "text"[], "p_phone" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_ai_conversation_protocol_summaries_v1"("p_schema_name" "text", "p_agent_id" "uuid", "p_is_a2a" boolean, "p_search" "text", "p_from" "date", "p_to" "date", "p_limit" integer, "p_cursor" "text", "p_tags" "text"[], "p_stages" "text"[], "p_phone" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_ai_dashboard_stats"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_ai_dashboard_stats"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_ai_dashboard_stats"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_ai_feature_flags"("p_schema_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_ai_feature_flags"("p_schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_ai_feature_flags"("p_schema_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_ai_interaction_metrics_v1"("p_schema_name" "text", "p_from" "date", "p_to" "date", "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_ai_interaction_metrics_v1"("p_schema_name" "text", "p_from" "date", "p_to" "date", "p_agent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_ai_interaction_metrics_v1"("p_schema_name" "text", "p_from" "date", "p_to" "date", "p_agent_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_ai_performance_snapshot_v1"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_ai_performance_snapshot_v1"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_ai_performance_snapshot_v1"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_granularity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_ai_protocol_conversation"("p_schema_name" "text", "p_protocol" "text", "p_agent_slug" "text", "p_limit" integer, "p_cursor" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_ai_protocol_conversation"("p_schema_name" "text", "p_protocol" "text", "p_agent_slug" "text", "p_limit" integer, "p_cursor" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_ai_protocol_conversation"("p_schema_name" "text", "p_protocol" "text", "p_agent_slug" "text", "p_limit" integer, "p_cursor" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_auth_user_email"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_auth_user_email"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_auth_user_email"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_auth_user_name"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_auth_user_name"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_auth_user_name"("p_user_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_changelog_engagement"("p_entry_ids" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_changelog_engagement"("p_entry_ids" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."get_changelog_engagement"("p_entry_ids" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_changelog_engagement"("p_entry_ids" "text"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_changelog_reactors"("p_entry_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_changelog_reactors"("p_entry_id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_changelog_reactors"("p_entry_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_changelog_reactors"("p_entry_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_changelog_viewers"("p_entry_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_changelog_viewers"("p_entry_id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_changelog_viewers"("p_entry_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_changelog_viewers"("p_entry_id" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_contact_action_stats"("p_schema_name" "text", "p_contact_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."get_contact_action_stats"("p_schema_name" "text", "p_contact_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_contact_action_stats"("p_schema_name" "text", "p_contact_ids" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_contact_summary"("org_slug" "text", "p_contact_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_contact_summary"("org_slug" "text", "p_contact_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_contact_summary"("org_slug" "text", "p_contact_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_contacts_with_recent_actions"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_action_type" "text", "p_integration_id" "uuid", "p_since" timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_contacts_with_recent_actions"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_action_type" "text", "p_integration_id" "uuid", "p_since" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_contacts_with_recent_actions"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_action_type" "text", "p_integration_id" "uuid", "p_since" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_current_org_schema"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_current_org_schema"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_current_org_schema"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_dashboard_kpis_json"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_dashboard_kpis_json"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_dashboard_kpis_json"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_dashboard_kpis_v2"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_dashboard_kpis_v2"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_dashboard_kpis_v2"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_datasource_secret"("p_org_id" "uuid", "p_data_source_id" "uuid", "p_secret_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_datasource_secret"("p_org_id" "uuid", "p_data_source_id" "uuid", "p_secret_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_datasource_secret"("p_org_id" "uuid", "p_data_source_id" "uuid", "p_secret_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_dispatch_batch_actions"("p_schema_name" "text", "p_batch_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_dispatch_batch_actions"("p_schema_name" "text", "p_batch_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_dispatch_batch_actions"("p_schema_name" "text", "p_batch_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_dispatch_history"("p_schema_name" "text", "p_limit" integer, "p_offset" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_dispatch_history"("p_schema_name" "text", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_dispatch_history"("p_schema_name" "text", "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_etl_job_failed_snapshots"("p_schema_name" character varying, "p_job_run_id" "uuid", "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_etl_job_failed_snapshots"("p_schema_name" character varying, "p_job_run_id" "uuid", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_etl_job_failed_snapshots"("p_schema_name" character varying, "p_job_run_id" "uuid", "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_etl_job_snapshot_stats"("p_schema_name" character varying, "p_job_run_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_etl_job_snapshot_stats"("p_schema_name" character varying, "p_job_run_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_etl_job_snapshot_stats"("p_schema_name" character varying, "p_job_run_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_etl_snapshots_by_entity"("p_schema_name" character varying, "p_entity_type" character varying, "p_entity_id" "uuid", "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_etl_snapshots_by_entity"("p_schema_name" character varying, "p_entity_type" character varying, "p_entity_id" "uuid", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_etl_snapshots_by_entity"("p_schema_name" character varying, "p_entity_type" character varying, "p_entity_id" "uuid", "p_limit" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_filter_contact_ids"("p_schema_name" "text", "p_filter_ids" "uuid"[], "p_filter_logic" "text", "p_contact_ids" "uuid"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_filter_contact_ids"("p_schema_name" "text", "p_filter_ids" "uuid"[], "p_filter_logic" "text", "p_contact_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_filter_contact_ids"("p_schema_name" "text", "p_filter_ids" "uuid"[], "p_filter_logic" "text", "p_contact_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_filter_contacts_paginated"("p_schema_name" "text", "p_filter_id" "uuid", "p_page" integer, "p_page_size" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_filter_contacts_paginated"("p_schema_name" "text", "p_filter_id" "uuid", "p_page" integer, "p_page_size" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_filter_contacts_paginated"("p_schema_name" "text", "p_filter_id" "uuid", "p_page" integer, "p_page_size" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_filter_contacts_paginated"("p_schema_name" "text", "p_filter_id" "uuid", "p_page" integer, "p_page_size" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_filter_target_ids"("p_schema_name" "text", "p_filter_ids" "uuid"[], "p_filter_logic" "text", "p_target_entity" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_filter_target_ids"("p_schema_name" "text", "p_filter_ids" "uuid"[], "p_filter_logic" "text", "p_target_entity" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_filter_target_ids"("p_schema_name" "text", "p_filter_ids" "uuid"[], "p_filter_logic" "text", "p_target_entity" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_funnel_data"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_funnel_data"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_funnel_data"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_funnel_metrics"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_funnel_metrics"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_funnel_metrics"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_funnel_transition_matrix"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_funnel_transition_matrix"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_funnel_transition_matrix"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_invitation_by_token"("p_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_invitation_by_token"("p_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_invitation_by_token"("p_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_invitation_by_token"("p_token" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_kanban_data"("p_schema_name" "text", "p_view_mode" "text", "p_filter_id" "uuid", "p_portfolio_id" "uuid", "p_assigned_user_id" "uuid", "p_search_term" "text", "p_buckets" "jsonb", "p_detail_bucket_id" "text", "p_limit" integer, "p_offset" integer, "p_order_by" "text", "p_contact_ids" "uuid"[], "p_exclude_contact_ids" "uuid"[], "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_workflow_ids" "uuid"[], "p_workflows_logic" "text", "p_include_no_workflow" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_kanban_data"("p_schema_name" "text", "p_view_mode" "text", "p_filter_id" "uuid", "p_portfolio_id" "uuid", "p_assigned_user_id" "uuid", "p_search_term" "text", "p_buckets" "jsonb", "p_detail_bucket_id" "text", "p_limit" integer, "p_offset" integer, "p_order_by" "text", "p_contact_ids" "uuid"[], "p_exclude_contact_ids" "uuid"[], "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_workflow_ids" "uuid"[], "p_workflows_logic" "text", "p_include_no_workflow" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_kanban_data"("p_schema_name" "text", "p_view_mode" "text", "p_filter_id" "uuid", "p_portfolio_id" "uuid", "p_assigned_user_id" "uuid", "p_search_term" "text", "p_buckets" "jsonb", "p_detail_bucket_id" "text", "p_limit" integer, "p_offset" integer, "p_order_by" "text", "p_contact_ids" "uuid"[], "p_exclude_contact_ids" "uuid"[], "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_workflow_ids" "uuid"[], "p_workflows_logic" "text", "p_include_no_workflow" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_max_overdue_title_per_contact"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_entity_kind" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_max_overdue_title_per_contact"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_entity_kind" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_max_overdue_title_per_contact"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_entity_kind" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_max_overdue_title_per_contract"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_entity_kind" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_max_overdue_title_per_contract"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_entity_kind" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_max_overdue_title_per_contract"("p_schema_name" "text", "p_contact_ids" "uuid"[], "p_entity_kind" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_mv_refresh_settings"("p_schema_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_mv_refresh_settings"("p_schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_mv_refresh_settings"("p_schema_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_mv_refresh_status"("p_schema_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_mv_refresh_status"("p_schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_mv_refresh_status"("p_schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_org_schema"("org_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_org_schema"("org_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_org_schema"("org_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_organization_secret"("p_org_id" "uuid", "p_integration_id" "uuid", "p_secret_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_organization_secret"("p_org_id" "uuid", "p_integration_id" "uuid", "p_secret_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_organization_secret"("p_org_id" "uuid", "p_integration_id" "uuid", "p_secret_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_payment_health"("p_schema_name" "text", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_entity_kind" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_payment_health"("p_schema_name" "text", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_entity_kind" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_payment_health"("p_schema_name" "text", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_entity_kind" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_payment_health"("p_schema_name" "text", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_start_date" "date", "p_end_date" "date", "p_entity_kind" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_payment_health"("p_schema_name" "text", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_start_date" "date", "p_end_date" "date", "p_entity_kind" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_payment_health"("p_schema_name" "text", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_start_date" "date", "p_end_date" "date", "p_entity_kind" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_portfolio_contact_ids"("p_schema_name" "text", "p_filter_id" "uuid", "p_portfolio_id" "uuid", "p_assigned_user_id" "uuid", "p_search_term" "text", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_workflow_ids" "uuid"[], "p_workflows_logic" "text", "p_include_no_workflow" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_portfolio_contact_ids"("p_schema_name" "text", "p_filter_id" "uuid", "p_portfolio_id" "uuid", "p_assigned_user_id" "uuid", "p_search_term" "text", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_workflow_ids" "uuid"[], "p_workflows_logic" "text", "p_include_no_workflow" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_portfolio_contact_ids"("p_schema_name" "text", "p_filter_id" "uuid", "p_portfolio_id" "uuid", "p_assigned_user_id" "uuid", "p_search_term" "text", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_workflow_ids" "uuid"[], "p_workflows_logic" "text", "p_include_no_workflow" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_portfolio_kpis"("p_schema_name" "text", "p_filter_id" "uuid", "p_portfolio_id" "uuid", "p_assigned_user_id" "uuid", "p_search_term" "text", "p_contact_ids" "uuid"[], "p_exclude_contact_ids" "uuid"[], "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_workflow_ids" "uuid"[], "p_workflows_logic" "text", "p_include_no_workflow" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_portfolio_kpis"("p_schema_name" "text", "p_filter_id" "uuid", "p_portfolio_id" "uuid", "p_assigned_user_id" "uuid", "p_search_term" "text", "p_contact_ids" "uuid"[], "p_exclude_contact_ids" "uuid"[], "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_workflow_ids" "uuid"[], "p_workflows_logic" "text", "p_include_no_workflow" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_portfolio_kpis"("p_schema_name" "text", "p_filter_id" "uuid", "p_portfolio_id" "uuid", "p_assigned_user_id" "uuid", "p_search_term" "text", "p_contact_ids" "uuid"[], "p_exclude_contact_ids" "uuid"[], "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_workflow_ids" "uuid"[], "p_workflows_logic" "text", "p_include_no_workflow" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_project_setting"("p_key" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_project_setting"("p_key" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_protocol_status_counts"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_protocol_status_counts"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_protocol_status_counts"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_protocol_status_transitions"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_protocol_status_transitions"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_protocol_status_transitions"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_agent_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_repique_dashboard_json"("p_schema_name" "text", "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_repique_dashboard_json"("p_schema_name" "text", "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_repique_dashboard_json"("p_schema_name" "text", "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_limit" integer, "p_offset" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_report_delivery_status"("p_schema_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_report_delivery_status"("p_schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_report_delivery_status"("p_schema_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_report_manual_test_status"("p_schema_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_report_manual_test_status"("p_schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_report_manual_test_status"("p_schema_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_step_conversion_data"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_channel" "text", "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_step_conversion_data"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_channel" "text", "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_step_conversion_data"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_portfolio_ids" "uuid"[], "p_filter_ids" "uuid"[], "p_channel" "text", "p_portfolio_combinator" "text", "p_filter_combinator" "text", "p_entity_kind" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_stuck_report_deliveries"("p_stale_minutes" integer, "p_max_attempts" integer, "p_since_hours" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_stuck_report_deliveries"("p_stale_minutes" integer, "p_max_attempts" integer, "p_since_hours" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_tag_metrics"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_granularity" "text", "p_agent_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_tag_metrics"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_granularity" "text", "p_agent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_tag_metrics"("p_schema_name" character varying, "p_start_date" "date", "p_end_date" "date", "p_granularity" "text", "p_agent_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_transfer_drilldown"("p_schema_name" character varying, "p_agent_id" "uuid", "p_type" "text", "p_from" timestamp with time zone, "p_to" timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_transfer_drilldown"("p_schema_name" character varying, "p_agent_id" "uuid", "p_type" "text", "p_from" timestamp with time zone, "p_to" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_transfer_drilldown"("p_schema_name" character varying, "p_agent_id" "uuid", "p_type" "text", "p_from" timestamp with time zone, "p_to" timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_transfer_drilldown_v2"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_transfer_tag_id" "uuid", "p_transfer_type" "text", "p_unclassified" boolean, "p_unit" "text", "p_cursor" "text", "p_limit" integer, "p_as_of" timestamp with time zone, "p_metric_key" "text", "p_tag_filter_mode" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_transfer_drilldown_v2"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_transfer_tag_id" "uuid", "p_transfer_type" "text", "p_unclassified" boolean, "p_unit" "text", "p_cursor" "text", "p_limit" integer, "p_as_of" timestamp with time zone, "p_metric_key" "text", "p_tag_filter_mode" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_transfer_drilldown_v2"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" "date", "p_to_exclusive" "date", "p_transfer_tag_id" "uuid", "p_transfer_type" "text", "p_unclassified" boolean, "p_unit" "text", "p_cursor" "text", "p_limit" integer, "p_as_of" timestamp with time zone, "p_metric_key" "text", "p_tag_filter_mode" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_transfer_metrics"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" timestamp with time zone, "p_to" timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_transfer_metrics"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" timestamp with time zone, "p_to" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_transfer_metrics"("p_schema_name" character varying, "p_agent_id" "uuid", "p_from" timestamp with time zone, "p_to" timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_transfer_tag_type_at"("p_schema_name" character varying, "p_tag_id" "uuid", "p_at" timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_transfer_tag_type_at"("p_schema_name" character varying, "p_tag_id" "uuid", "p_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_transfer_tag_type_at"("p_schema_name" character varying, "p_tag_id" "uuid", "p_at" timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_unseen_changelog"("p_entry_ids" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_unseen_changelog"("p_entry_ids" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."get_unseen_changelog"("p_entry_ids" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_unseen_changelog"("p_entry_ids" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_org_ids"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_org_ids"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_org_ids"() TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."grant_service_role_to_org"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."grant_service_role_to_org"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."grant_service_role_to_org"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_accum"(double precision[], "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_accum"(double precision[], "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_accum"(double precision[], "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_accum"(double precision[], "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_add"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_add"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_add"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_add"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_avg"(double precision[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_avg"(double precision[]) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_avg"(double precision[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_avg"(double precision[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_cmp"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_cmp"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_cmp"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_cmp"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_combine"(double precision[], double precision[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_combine"(double precision[], double precision[]) TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_combine"(double precision[], double precision[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_combine"(double precision[], double precision[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_concat"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_concat"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_concat"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_concat"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_eq"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_eq"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_eq"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_eq"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_ge"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_ge"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_ge"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_ge"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_gt"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_gt"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_gt"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_gt"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_l2_squared_distance"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_l2_squared_distance"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_l2_squared_distance"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_l2_squared_distance"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_le"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_le"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_le"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_le"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_lt"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_lt"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_lt"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_lt"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_mul"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_mul"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_mul"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_mul"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_ne"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_ne"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_ne"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_ne"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_negative_inner_product"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_negative_inner_product"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_negative_inner_product"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_negative_inner_product"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_spherical_distance"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_spherical_distance"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_spherical_distance"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_spherical_distance"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."halfvec_sub"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."halfvec_sub"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."halfvec_sub"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."halfvec_sub"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."hamming_distance"(bit, bit) TO "postgres";
GRANT ALL ON FUNCTION "public"."hamming_distance"(bit, bit) TO "anon";
GRANT ALL ON FUNCTION "public"."hamming_distance"(bit, bit) TO "authenticated";
GRANT ALL ON FUNCTION "public"."hamming_distance"(bit, bit) TO "service_role";



GRANT ALL ON FUNCTION "public"."hnsw_bit_support"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."hnsw_bit_support"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."hnsw_bit_support"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hnsw_bit_support"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."hnsw_halfvec_support"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."hnsw_halfvec_support"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."hnsw_halfvec_support"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hnsw_halfvec_support"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."hnsw_sparsevec_support"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."hnsw_sparsevec_support"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."hnsw_sparsevec_support"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hnsw_sparsevec_support"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."hnswhandler"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."hnswhandler"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."hnswhandler"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."hnswhandler"("internal") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ingest_ai_event_v2"("p_schema_name" "text", "p_event" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ingest_ai_event_v2"("p_schema_name" "text", "p_event" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."ingest_ai_message_batch_v2"("p_schema_name" "text", "p_events" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ingest_ai_message_batch_v2"("p_schema_name" "text", "p_events" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."inner_product"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."inner_product"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."inner_product"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."inner_product"("public"."vector", "public"."vector") TO "service_role";



REVOKE ALL ON FUNCTION "public"."invoke_edge_function"("p_name" "text", "p_body" "jsonb", "p_timeout_ms" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."invoke_edge_function"("p_name" "text", "p_body" "jsonb", "p_timeout_ms" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."invoke_edge_function_get"("p_path" "text", "p_timeout_ms" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."invoke_edge_function_get"("p_path" "text", "p_timeout_ms" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_action_blocked"("p_schema" "text", "p_contact_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_contact_document" character varying, "p_channel" "text", "p_recipient" "text", "p_supply_id" "uuid", "p_supply_title_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_action_blocked"("p_schema" "text", "p_contact_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_contact_document" character varying, "p_channel" "text", "p_recipient" "text", "p_supply_id" "uuid", "p_supply_title_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_action_blocked"("p_schema" "text", "p_contact_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_contact_document" character varying, "p_channel" "text", "p_recipient" "text", "p_supply_id" "uuid", "p_supply_title_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_org_admin_or_owner"("org_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_org_admin_or_owner"("org_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_org_admin_or_owner"("org_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_reserved_org_slug"("p_slug" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_reserved_org_slug"("p_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."is_reserved_org_slug"("p_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_reserved_org_slug"("p_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_super_admin"("user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_super_admin"("user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_super_admin"("user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_workflow_execution_complete"("p_execution_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_workflow_execution_complete"("p_execution_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_workflow_execution_complete"("p_execution_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."ivfflat_bit_support"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ivfflat_bit_support"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ivfflat_bit_support"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ivfflat_bit_support"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ivfflat_halfvec_support"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ivfflat_halfvec_support"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ivfflat_halfvec_support"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ivfflat_halfvec_support"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ivfflathandler"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ivfflathandler"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ivfflathandler"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ivfflathandler"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."jaccard_distance"(bit, bit) TO "postgres";
GRANT ALL ON FUNCTION "public"."jaccard_distance"(bit, bit) TO "anon";
GRANT ALL ON FUNCTION "public"."jaccard_distance"(bit, bit) TO "authenticated";
GRANT ALL ON FUNCTION "public"."jaccard_distance"(bit, bit) TO "service_role";



GRANT ALL ON FUNCTION "public"."l1_distance"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l1_distance"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l1_distance"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l1_distance"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_distance"("public"."halfvec", "public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."halfvec", "public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."halfvec", "public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."halfvec", "public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_distance"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_distance"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_distance"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_norm"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_norm"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_norm"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_norm"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_norm"("public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_norm"("public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_norm"("public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_norm"("public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."l2_normalize"("public"."vector") TO "service_role";



REVOKE ALL ON FUNCTION "public"."list_mv_refresh_runs"("p_schema_name" "text", "p_limit" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."list_mv_refresh_runs"("p_schema_name" "text", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."list_mv_refresh_runs"("p_schema_name" "text", "p_limit" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."list_playground_messages"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_limit" integer, "p_offset" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."list_playground_messages"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_limit" integer, "p_offset" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."list_playground_messages_v2"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_limit" integer, "p_offset" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."list_playground_messages_v2"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."list_playground_messages_v2"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_limit" integer, "p_offset" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."list_playground_sessions"("p_schema_name" character varying, "p_version_id" "uuid", "p_limit" integer, "p_offset" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."list_playground_sessions"("p_schema_name" character varying, "p_version_id" "uuid", "p_limit" integer, "p_offset" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."list_playground_sessions_v2"("p_schema_name" character varying, "p_version_id" "uuid", "p_limit" integer, "p_offset" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."list_playground_sessions_v2"("p_schema_name" character varying, "p_version_id" "uuid", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."list_playground_sessions_v2"("p_schema_name" character varying, "p_version_id" "uuid", "p_limit" integer, "p_offset" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."log_agent_call_v2"("p_schema_name" "text", "p_receiving_agent_id" "uuid", "p_requesting_agent" "text", "p_protocol" "text", "p_requesting_agent_id" "uuid", "p_requesting_agent_slug" "text", "p_requesting_org_slug" "text", "p_source" "text", "p_source_event_id" "text", "p_metadata" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."log_agent_call_v2"("p_schema_name" "text", "p_receiving_agent_id" "uuid", "p_requesting_agent" "text", "p_protocol" "text", "p_requesting_agent_id" "uuid", "p_requesting_agent_slug" "text", "p_requesting_org_slug" "text", "p_source" "text", "p_source_event_id" "text", "p_metadata" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."log_ai_report_export"("p_schema_name" "text", "p_snapshot_id" "text", "p_snapshot_hash" "text", "p_scope" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."log_ai_report_export"("p_schema_name" "text", "p_snapshot_id" "text", "p_snapshot_hash" "text", "p_scope" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_ai_report_export"("p_schema_name" "text", "p_snapshot_id" "text", "p_snapshot_hash" "text", "p_scope" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."log_mcp_cross_org_read"("p_api_key_id" "uuid", "p_request_org_slug" "text", "p_tool_name" "text", "p_outcome" "text", "p_coverage" "text", "p_orgs_probed" integer, "p_orgs_failed" integer, "p_total_matches" integer, "p_contact_id" "uuid", "p_contract_id" "uuid", "p_document" "text", "p_duration_ms" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."log_mcp_cross_org_read"("p_api_key_id" "uuid", "p_request_org_slug" "text", "p_tool_name" "text", "p_outcome" "text", "p_coverage" "text", "p_orgs_probed" integer, "p_orgs_failed" integer, "p_total_matches" integer, "p_contact_id" "uuid", "p_contract_id" "uuid", "p_document" "text", "p_duration_ms" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."log_mv_refresh"("p_schema_name" character varying, "p_trigger_source" character varying, "p_job_run_id" "uuid", "p_success" boolean, "p_message" "text", "p_duration_ms" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."log_mv_refresh"("p_schema_name" character varying, "p_trigger_source" character varying, "p_job_run_id" "uuid", "p_success" boolean, "p_message" "text", "p_duration_ms" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_mv_refresh"("p_schema_name" character varying, "p_trigger_source" character varying, "p_job_run_id" "uuid", "p_success" boolean, "p_message" "text", "p_duration_ms" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."mark_a2a_dispatch"("p_id" "uuid", "p_status" "text", "p_http_status" integer, "p_error_code" "text", "p_error_detail" "text", "p_retry_after_seconds" integer, "p_attempted" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mark_a2a_dispatch"("p_id" "uuid", "p_status" "text", "p_http_status" integer, "p_error_code" "text", "p_error_detail" "text", "p_retry_after_seconds" integer, "p_attempted" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."mark_changelog_seen"("p_entry_ids" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mark_changelog_seen"("p_entry_ids" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."mark_changelog_seen"("p_entry_ids" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_changelog_seen"("p_entry_ids" "text"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."mark_scheduled_report_delivery"("p_delivery_id" "uuid", "p_status" "text", "p_snapshot_id" "text", "p_snapshot_hash" "text", "p_export_id" "uuid", "p_recipient_count" integer, "p_provider_message_id" "text", "p_error_code" "text", "p_error_detail" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mark_scheduled_report_delivery"("p_delivery_id" "uuid", "p_status" "text", "p_snapshot_id" "text", "p_snapshot_hash" "text", "p_export_id" "uuid", "p_recipient_count" integer, "p_provider_message_id" "text", "p_error_code" "text", "p_error_detail" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mcp_cross_org_rate_limit_ok"("p_api_key_id" "uuid", "p_max_per_window" integer, "p_window_seconds" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mcp_cross_org_rate_limit_ok"("p_api_key_id" "uuid", "p_max_per_window" integer, "p_window_seconds" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."norm_phone"("p" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."norm_phone"("p" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."norm_phone"("p" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."on_organization_created"() TO "anon";
GRANT ALL ON FUNCTION "public"."on_organization_created"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."on_organization_created"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."persist_playground_message"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_role" "text", "p_content" "text", "p_request_id" "text", "p_session_id" "uuid", "p_metadata" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."persist_playground_message"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_role" "text", "p_content" "text", "p_request_id" "text", "p_session_id" "uuid", "p_metadata" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."persist_playground_message_v2"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_role" "text", "p_content" "text", "p_request_id" "text", "p_session_id" "uuid", "p_metadata" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."persist_playground_message_v2"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_role" "text", "p_content" "text", "p_request_id" "text", "p_session_id" "uuid", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."populate_contract_portfolios"("schema_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."populate_contract_portfolios"("schema_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."populate_contract_portfolios"("schema_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."prevent_protected_org_deletion"() TO "anon";
GRANT ALL ON FUNCTION "public"."prevent_protected_org_deletion"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."prevent_protected_org_deletion"() TO "service_role";



GRANT ALL ON FUNCTION "public"."prevent_protected_org_slug_rename"() TO "anon";
GRANT ALL ON FUNCTION "public"."prevent_protected_org_slug_rename"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."prevent_protected_org_slug_rename"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."preview_broadcast_audience"("p_schema" "text", "p_workflow_id" "uuid", "p_repique_enabled" boolean, "p_campaign_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."preview_broadcast_audience"("p_schema" "text", "p_workflow_id" "uuid", "p_repique_enabled" boolean, "p_campaign_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."preview_broadcast_audience"("p_schema" "text", "p_workflow_id" "uuid", "p_repique_enabled" boolean, "p_campaign_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."process_mv_refresh"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."process_mv_refresh"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."process_mv_refresh"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."reap_abandoned_a2a_dispatches"("p_ttl_minutes" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."reap_abandoned_a2a_dispatches"("p_ttl_minutes" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."recalc_contact_is_blocked"("p_schema_name" "text", "p_contact_id" "uuid", "p_document" character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."recalc_contact_is_blocked"("p_schema_name" "text", "p_contact_id" "uuid", "p_document" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."reconcile_etl_supplies"("p_schema_name" "text", "p_job_run_id" "uuid", "p_data_source_id" "uuid", "p_pipeline_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."reconcile_etl_supplies"("p_schema_name" "text", "p_job_run_id" "uuid", "p_data_source_id" "uuid", "p_pipeline_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."reconcile_etl_supplies"("p_schema_name" "text", "p_job_run_id" "uuid", "p_data_source_id" "uuid", "p_pipeline_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."reconcile_etl_titles"("p_schema_name" "text", "p_job_run_id" "uuid", "p_data_source_id" "uuid", "p_pipeline_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."reconcile_etl_titles"("p_schema_name" "text", "p_job_run_id" "uuid", "p_data_source_id" "uuid", "p_pipeline_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."reconcile_etl_titles"("p_schema_name" "text", "p_job_run_id" "uuid", "p_data_source_id" "uuid", "p_pipeline_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."record_changelog_view"("p_entry_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."record_changelog_view"("p_entry_id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."record_changelog_view"("p_entry_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."record_changelog_view"("p_entry_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."redact_ai_message_content"("p_schema_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."redact_ai_message_content"("p_schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."redact_ai_message_content"("p_schema_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."reencrypt_llm_keys_safe"("p_schema_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."reencrypt_llm_keys_safe"("p_schema_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."refresh_all_mv_titles_base"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."refresh_all_mv_titles_base"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."refresh_mv_titles_base"("p_schema_name" character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."refresh_mv_titles_base"("p_schema_name" character varying) TO "service_role";



REVOKE ALL ON FUNCTION "public"."refresh_mv_titles_base_logged"("p_schema_name" character varying, "p_trigger_source" character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."refresh_mv_titles_base_logged"("p_schema_name" character varying, "p_trigger_source" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."remove_segment_from_contacts"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."remove_segment_from_contacts"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."remove_segment_from_contacts"("org_slug" character varying) TO "service_role";



REVOKE ALL ON FUNCTION "public"."request_mv_refresh_now"("p_schema_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."request_mv_refresh_now"("p_schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."request_mv_refresh_now"("p_schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."restore_workflow_steps"("p_schema_name" "text", "p_workflow_id" "uuid", "p_steps" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."restore_workflow_steps"("p_schema_name" "text", "p_workflow_id" "uuid", "p_steps" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."restore_workflow_steps"("p_schema_name" "text", "p_workflow_id" "uuid", "p_steps" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."revalidate_a2a_dispatch"("p_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."revalidate_a2a_dispatch"("p_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."save_organization_secret"("p_org_id" "uuid", "p_integration_id" "uuid", "p_data_source_id" "uuid", "p_secret_name" "text", "p_secret_value" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."save_organization_secret"("p_org_id" "uuid", "p_integration_id" "uuid", "p_data_source_id" "uuid", "p_secret_name" "text", "p_secret_value" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."save_organization_secret"("p_org_id" "uuid", "p_integration_id" "uuid", "p_data_source_id" "uuid", "p_secret_name" "text", "p_secret_value" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."search_actions"("p_schema_name" "text", "p_search" "text", "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_campaign_id" "uuid", "p_action_types" "text"[], "p_statuses" "text"[], "p_exclude_test" boolean, "p_days_overdue_min" integer, "p_days_overdue_max" integer, "p_source" "text", "p_limit" integer, "p_offset" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."search_actions"("p_schema_name" "text", "p_search" "text", "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_campaign_id" "uuid", "p_action_types" "text"[], "p_statuses" "text"[], "p_exclude_test" boolean, "p_days_overdue_min" integer, "p_days_overdue_max" integer, "p_source" "text", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_actions"("p_schema_name" "text", "p_search" "text", "p_start_date" timestamp with time zone, "p_end_date" timestamp with time zone, "p_campaign_id" "uuid", "p_action_types" "text"[], "p_statuses" "text"[], "p_exclude_test" boolean, "p_days_overdue_min" integer, "p_days_overdue_max" integer, "p_source" "text", "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."seed_action_status_standard_values"("p_organization_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."seed_action_status_standard_values"("p_organization_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."seed_action_status_standard_values"("p_organization_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."seed_standard_status_values"("p_organization_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."seed_standard_status_values"("p_organization_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."seed_standard_status_values"("p_organization_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_agent_allowed_tags"("p_schema_name" "text", "p_agent_id" "uuid", "p_mode" "text", "p_tag_ids" "uuid"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_agent_allowed_tags"("p_schema_name" "text", "p_agent_id" "uuid", "p_mode" "text", "p_tag_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_agent_allowed_tags"("p_schema_name" "text", "p_agent_id" "uuid", "p_mode" "text", "p_tag_ids" "uuid"[]) TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_ai_feature_flag"("p_schema_name" "text", "p_flag" "text", "p_enabled" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_ai_feature_flag"("p_schema_name" "text", "p_flag" "text", "p_enabled" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_ai_feature_flag"("p_schema_name" "text", "p_flag" "text", "p_enabled" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "postgres";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "anon";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_org_context"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."set_org_context"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_org_context"("org_slug" character varying) TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_transfer_tag_type"("p_schema_name" character varying, "p_tag_id" "uuid", "p_type" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_transfer_tag_type"("p_schema_name" character varying, "p_tag_id" "uuid", "p_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_transfer_tag_type"("p_schema_name" character varying, "p_tag_id" "uuid", "p_type" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_user_role_in_org"("p_user_id" "uuid", "p_organization_id" "uuid", "p_role" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."set_user_role_in_org"("p_user_id" "uuid", "p_organization_id" "uuid", "p_role" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_user_role_in_org"("p_user_id" "uuid", "p_organization_id" "uuid", "p_role" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."setup_blocklist_v2_rls"("p_org_slug" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."setup_blocklist_v2_rls"("p_org_slug" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."setup_blocklist_v2_tables"("p_org_slug" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."setup_blocklist_v2_tables"("p_org_slug" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."setup_contact_is_blocked_triggers"("p_org_slug" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."setup_contact_is_blocked_triggers"("p_org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_mv_refresh_trigger"("p_schema_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."setup_mv_refresh_trigger"("p_schema_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_mv_refresh_trigger"("p_schema_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_agent_tables"("schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_agent_tables"("schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_agent_tables"("schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_ai_tables"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_ai_tables"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_ai_tables"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_campaign_workflow_nn"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_campaign_workflow_nn"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_campaign_workflow_nn"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_complete"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_complete"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_complete"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_contact_assignments"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_contact_assignments"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_contact_assignments"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_dlq_system"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_dlq_system"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_dlq_system"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_functions"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_functions"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_functions"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_moved_tables"("p_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_moved_tables"("p_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_moved_tables"("p_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_queue_indexes"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_queue_indexes"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_queue_indexes"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_queue_system"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_queue_system"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_queue_system"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_rag_tables"("p_schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_rag_tables"("p_schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_rag_tables"("p_schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_rate_limits"("schema_name" "text", "org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_rate_limits"("schema_name" "text", "org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_rate_limits"("schema_name" "text", "org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_rls_policies"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_rls_policies"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_rls_policies"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_tables"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_tables"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_tables"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_tables"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_tables"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_tables"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_views"("org_slug" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_views"("org_slug" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_views"("org_slug" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_org_workflow_versioning"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_org_workflow_versioning"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_org_workflow_versioning"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_webhook_retry_queue"() TO "anon";
GRANT ALL ON FUNCTION "public"."setup_webhook_retry_queue"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_webhook_retry_queue"() TO "service_role";



GRANT ALL ON FUNCTION "public"."setup_workflow_cascade_trigger"("p_schema_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."setup_workflow_cascade_trigger"("p_schema_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_workflow_cascade_trigger"("p_schema_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."show_limit"() TO "postgres";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "anon";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_cmp"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_cmp"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_cmp"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_cmp"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_eq"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_eq"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_eq"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_eq"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_ge"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_ge"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_ge"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_ge"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_gt"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_gt"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_gt"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_gt"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_l2_squared_distance"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_l2_squared_distance"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_l2_squared_distance"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_l2_squared_distance"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_le"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_le"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_le"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_le"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_lt"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_lt"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_lt"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_lt"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_ne"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_ne"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_ne"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_ne"("public"."sparsevec", "public"."sparsevec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sparsevec_negative_inner_product"("public"."sparsevec", "public"."sparsevec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sparsevec_negative_inner_product"("public"."sparsevec", "public"."sparsevec") TO "anon";
GRANT ALL ON FUNCTION "public"."sparsevec_negative_inner_product"("public"."sparsevec", "public"."sparsevec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sparsevec_negative_inner_product"("public"."sparsevec", "public"."sparsevec") TO "service_role";



REVOKE ALL ON FUNCTION "public"."start_playground_session"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_agent_id" "uuid", "p_agent_slug" "text", "p_scenario" "text", "p_mode" "text", "p_selected_contract_id" "uuid", "p_selected_contact_id" "uuid", "p_webhook_url" "text", "p_context_snapshot" "jsonb", "p_created_by" "uuid", "p_metadata" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."start_playground_session"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_agent_id" "uuid", "p_agent_slug" "text", "p_scenario" "text", "p_mode" "text", "p_selected_contract_id" "uuid", "p_selected_contact_id" "uuid", "p_webhook_url" "text", "p_context_snapshot" "jsonb", "p_created_by" "uuid", "p_metadata" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."start_playground_session_v2"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_agent_id" "uuid", "p_agent_slug" "text", "p_scenario" "text", "p_mode" "text", "p_selected_contract_id" "uuid", "p_selected_contact_id" "uuid", "p_webhook_url" "text", "p_context_snapshot" "jsonb", "p_created_by" "uuid", "p_metadata" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."start_playground_session_v2"("p_schema_name" character varying, "p_conversation_id" "text", "p_version_id" "uuid", "p_agent_id" "uuid", "p_agent_slug" "text", "p_scenario" "text", "p_mode" "text", "p_selected_contract_id" "uuid", "p_selected_contact_id" "uuid", "p_webhook_url" "text", "p_context_snapshot" "jsonb", "p_created_by" "uuid", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."subvector"("public"."halfvec", integer, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."subvector"("public"."halfvec", integer, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."subvector"("public"."halfvec", integer, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."subvector"("public"."halfvec", integer, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."subvector"("public"."vector", integer, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."subvector"("public"."vector", integer, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."subvector"("public"."vector", integer, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."subvector"("public"."vector", integer, integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."sync_blocklist_filter_rule"("p_schema" "text", "p_rule_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."sync_blocklist_filter_rule"("p_schema" "text", "p_rule_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_blocklist_filter_rule"("p_schema" "text", "p_rule_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."sync_blocklist_filter_rules_logged"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."sync_blocklist_filter_rules_logged"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_workflow_assignment_filters"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_workflow_assignment_filters"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_workflow_assignment_filters"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."toggle_changelog_reaction"("p_entry_id" "text", "p_emoji" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."toggle_changelog_reaction"("p_entry_id" "text", "p_emoji" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."toggle_changelog_reaction"("p_entry_id" "text", "p_emoji" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."toggle_changelog_reaction"("p_entry_id" "text", "p_emoji" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_create_org_schema"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_create_org_schema"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_create_org_schema"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_setup_org_moved_tables"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_setup_org_moved_tables"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_setup_org_moved_tables"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_setup_org_schema"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_setup_org_schema"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_setup_org_schema"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."update_a2a_closure_settings"("p_schema_name" "text", "p_agent_id" "uuid", "p_webhook_url" "text", "p_enabled" boolean, "p_inactivity_hours" integer, "p_updated_by" "text", "p_scan_interval_minutes" integer, "p_dispatch_interval_minutes" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_a2a_closure_settings"("p_schema_name" "text", "p_agent_id" "uuid", "p_webhook_url" "text", "p_enabled" boolean, "p_inactivity_hours" integer, "p_updated_by" "text", "p_scan_interval_minutes" integer, "p_dispatch_interval_minutes" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_a2a_closure_settings"("p_schema_name" "text", "p_agent_id" "uuid", "p_webhook_url" "text", "p_enabled" boolean, "p_inactivity_hours" integer, "p_updated_by" "text", "p_scan_interval_minutes" integer, "p_dispatch_interval_minutes" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."update_all_orgs_titles_days_overdue"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_all_orgs_titles_days_overdue"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_contact_assignments_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_contact_assignments_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_contact_assignments_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_days_overdue"("org_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_days_overdue"("org_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_days_overdue"("org_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_etl_snapshot_failed"("p_schema_name" character varying, "p_snapshot_id" "uuid", "p_error_message" "text", "p_error_details" "jsonb", "p_validation_errors" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."update_etl_snapshot_failed"("p_schema_name" character varying, "p_snapshot_id" "uuid", "p_error_message" "text", "p_error_details" "jsonb", "p_validation_errors" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_etl_snapshot_failed"("p_schema_name" character varying, "p_snapshot_id" "uuid", "p_error_message" "text", "p_error_details" "jsonb", "p_validation_errors" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_etl_snapshot_processed"("p_schema_name" character varying, "p_snapshot_id" "uuid", "p_normalized_data" "jsonb", "p_contact_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_dedup_action" character varying, "p_existing_entity_id" "uuid", "p_transformation_log" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."update_etl_snapshot_processed"("p_schema_name" character varying, "p_snapshot_id" "uuid", "p_normalized_data" "jsonb", "p_contact_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_dedup_action" character varying, "p_existing_entity_id" "uuid", "p_transformation_log" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_etl_snapshot_processed"("p_schema_name" character varying, "p_snapshot_id" "uuid", "p_normalized_data" "jsonb", "p_contact_id" "uuid", "p_contract_id" "uuid", "p_title_id" "uuid", "p_dedup_action" character varying, "p_existing_entity_id" "uuid", "p_transformation_log" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_etl_snapshot_skipped"("p_schema_name" character varying, "p_snapshot_id" "uuid", "p_reason" "text", "p_existing_entity_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."update_etl_snapshot_skipped"("p_schema_name" character varying, "p_snapshot_id" "uuid", "p_reason" "text", "p_existing_entity_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_etl_snapshot_skipped"("p_schema_name" character varying, "p_snapshot_id" "uuid", "p_reason" "text", "p_existing_entity_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."update_mv_refresh_settings"("p_schema_name" "text", "p_schedule_cron" "text", "p_enabled" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_mv_refresh_settings"("p_schema_name" "text", "p_schedule_cron" "text", "p_enabled" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_mv_refresh_settings"("p_schema_name" "text", "p_schedule_cron" "text", "p_enabled" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_org_secrets_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_org_secrets_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_org_secrets_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."update_playground_webhook_config_v2"("p_schema_name" character varying, "p_version_id" "uuid", "p_webhook_url" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_playground_webhook_config_v2"("p_schema_name" character varying, "p_version_id" "uuid", "p_webhook_url" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."update_playground_webhook_config_v3"("p_schema_name" character varying, "p_version_id" "uuid", "p_webhook_url" "text", "p_response_timeout_ms" integer, "p_response_mode" "text", "p_context_fields" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_playground_webhook_config_v3"("p_schema_name" character varying, "p_version_id" "uuid", "p_webhook_url" "text", "p_response_timeout_ms" integer, "p_response_mode" "text", "p_context_fields" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_setup_org_tables_view_fix"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_setup_org_tables_view_fix"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_setup_org_tables_view_fix"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."update_vw_collection_portfolio_v2"("p_schema_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_vw_collection_portfolio_v2"("p_schema_name" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."upsert_protocol_status"("p_schema_name" character varying, "p_protocol" "text", "p_status" "text", "p_agent_id" "uuid", "p_contact_id" "uuid", "p_phone" "text", "p_conversation_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."upsert_protocol_status"("p_schema_name" character varying, "p_protocol" "text", "p_status" "text", "p_agent_id" "uuid", "p_contact_id" "uuid", "p_phone" "text", "p_conversation_id" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_accum"(double precision[], "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_accum"(double precision[], "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_accum"(double precision[], "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_accum"(double precision[], "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_add"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_add"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_add"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_add"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_avg"(double precision[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_avg"(double precision[]) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_avg"(double precision[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_avg"(double precision[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_cmp"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_cmp"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_cmp"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_cmp"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_combine"(double precision[], double precision[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_combine"(double precision[], double precision[]) TO "anon";
GRANT ALL ON FUNCTION "public"."vector_combine"(double precision[], double precision[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_combine"(double precision[], double precision[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_concat"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_concat"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_concat"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_concat"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_dims"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_dims"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_dims"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_dims"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_dims"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_dims"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_dims"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_dims"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_eq"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_eq"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_eq"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_eq"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_ge"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_ge"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_ge"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_ge"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_gt"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_gt"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_gt"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_gt"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_l2_squared_distance"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_l2_squared_distance"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_l2_squared_distance"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_l2_squared_distance"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_le"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_le"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_le"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_le"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_lt"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_lt"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_lt"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_lt"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_mul"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_mul"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_mul"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_mul"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_ne"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_ne"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_ne"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_ne"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_negative_inner_product"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_negative_inner_product"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_negative_inner_product"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_negative_inner_product"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_norm"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_norm"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_norm"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_norm"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_spherical_distance"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_spherical_distance"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_spherical_distance"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_spherical_distance"("public"."vector", "public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."vector_sub"("public"."vector", "public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."vector_sub"("public"."vector", "public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."vector_sub"("public"."vector", "public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vector_sub"("public"."vector", "public"."vector") TO "service_role";



REVOKE ALL ON FUNCTION "public"."verify_ai_hardening_v2"("p_schema_name" "text", "p_require_back2" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."verify_ai_hardening_v2"("p_schema_name" "text", "p_require_back2" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "service_role";












GRANT ALL ON FUNCTION "public"."avg"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."avg"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."avg"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."avg"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."avg"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."avg"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."avg"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."avg"("public"."vector") TO "service_role";



GRANT ALL ON FUNCTION "public"."sum"("public"."halfvec") TO "postgres";
GRANT ALL ON FUNCTION "public"."sum"("public"."halfvec") TO "anon";
GRANT ALL ON FUNCTION "public"."sum"("public"."halfvec") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sum"("public"."halfvec") TO "service_role";



GRANT ALL ON FUNCTION "public"."sum"("public"."vector") TO "postgres";
GRANT ALL ON FUNCTION "public"."sum"("public"."vector") TO "anon";
GRANT ALL ON FUNCTION "public"."sum"("public"."vector") TO "authenticated";
GRANT ALL ON FUNCTION "public"."sum"("public"."vector") TO "service_role";



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;
SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;















GRANT ALL ON TABLE "org_blips"."_migr_finza_id3783_audit" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."_migr_finza_id3783_audit" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."_migr_finza_id3783_audit" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."a2a_closure_config" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."a2a_closure_config" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."actions_dlq" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."actions_dlq" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."actions_dlq" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."actions_interaction_logs" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."actions_interaction_logs" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_blips"."actions_interaction_logs" TO "authenticated";



GRANT ALL ON TABLE "org_blips"."actions_sync" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."actions_sync" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."actions_sync" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."agent_allowed_tags" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."agent_allowed_tags" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."agent_allowed_tags" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."agent_audit_logs" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."agent_audit_logs" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."agent_audit_logs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."agent_call_logs" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."agent_call_logs" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."agent_call_logs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."agent_llm_configs" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."agent_llm_configs" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."agent_llm_configs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."agent_messages" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."agent_messages" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."agent_messages" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."agent_proposal_items" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."agent_proposal_items" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."agent_proposal_items" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."agent_proposals" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."agent_proposals" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."agent_proposals" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."agent_sessions" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."agent_sessions" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."agent_sessions" TO "airbyte_readonly";



GRANT SELECT,INSERT,REFERENCES,TRIGGER,MAINTAIN,UPDATE ON TABLE "org_blips"."ai_agents" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."ai_agents" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_agents" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."ai_backfill_checkpoint" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_backfill_checkpoint" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_blips"."ai_backfill_checkpoint" TO "authenticated";



GRANT ALL ON TABLE "org_blips"."ai_backfill_quarantine" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_backfill_quarantine" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_blips"."ai_backfill_quarantine" TO "authenticated";



GRANT ALL ON TABLE "org_blips"."ai_business_rules" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."ai_business_rules" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_business_rules" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."ai_conversations" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_conversations" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_blips"."ai_conversations" TO "authenticated";



GRANT ALL ON TABLE "org_blips"."ai_funnel_events" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_funnel_events" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_blips"."ai_funnel_events" TO "authenticated";



GRANT ALL ON TABLE "org_blips"."ai_funnel_stages" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."ai_funnel_stages" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_funnel_stages" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."ai_guidelines" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."ai_guidelines" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_guidelines" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."ai_ingestion_events" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_ingestion_events" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_blips"."ai_ingestion_events" TO "authenticated";



GRANT ALL ON TABLE "org_blips"."ai_messages" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_messages" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_blips"."ai_messages" TO "authenticated";



GRANT ALL ON TABLE "org_blips"."ai_playground_messages" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."ai_playground_messages" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_playground_messages" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."ai_playground_sessions" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."ai_playground_sessions" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_playground_sessions" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."ai_prompts" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."ai_prompts" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_prompts" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."ai_protocol_finalizations" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."ai_protocol_finalizations" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_protocol_finalizations" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."ai_protocol_status_log" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_protocol_status_log" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_blips"."ai_protocol_status_log" TO "authenticated";



GRANT ALL ON TABLE "org_blips"."ai_protocols" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_protocols" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_blips"."ai_protocols" TO "authenticated";



GRANT ALL ON TABLE "org_blips"."ai_versions" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."ai_versions" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."ai_versions" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."audit_logs" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."audit_logs" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."audit_logs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."blocked_dates" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."blocked_dates" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."blocked_dates" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."blocklist" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."blocklist" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."blocklist" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."blocklist_entries" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."blocklist_entries" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."blocklist_entries" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."blocklist_filter_rules" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."blocklist_filter_rules" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."blocklist_filter_rules" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."blocklist_history" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."blocklist_history" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."blocklist_history" TO "airbyte_readonly";



GRANT SELECT,USAGE ON SEQUENCE "org_blips"."blocklist_history_id_seq" TO "authenticated";
GRANT SELECT,USAGE ON SEQUENCE "org_blips"."blocklist_history_id_seq" TO "service_role";



GRANT ALL ON TABLE "org_blips"."campaign_execution_candidates" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."campaign_execution_candidates" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."campaign_execution_candidates" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."campaign_execution_runs" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."campaign_execution_runs" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."campaign_execution_runs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."campaign_logs" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."campaign_logs" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."campaign_logs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."campaign_workflows" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."campaign_workflows" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."campaign_workflows" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."campaigns" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."campaigns" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."campaigns" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."channel_costs" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."channel_costs" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."channel_costs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."channel_rate_counts" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."channel_rate_counts" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."channel_rate_counts" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."channel_rate_limits" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."channel_rate_limits" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."channel_rate_limits" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."contact_assignments" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."contact_assignments" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."contact_assignments" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."contact_emails" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."contact_emails" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."contact_emails" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."contact_phones" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."contact_phones" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."contact_phones" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."contact_seals" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."contact_seals" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."contact_seals" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."contact_summaries" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."contact_summaries" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."contact_summaries" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."contacts" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."contacts" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."contacts" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."contract_portfolios" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."contract_portfolios" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."contract_portfolios" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."contract_seals" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."contract_seals" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."contract_seals" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."contracts" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."contracts" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."contracts" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."conversation_tags" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."conversation_tags" TO "airbyte_readonly";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "org_blips"."conversation_tags" TO "authenticated";



GRANT ALL ON TABLE "org_blips"."custom_field_definitions" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."custom_field_definitions" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."custom_field_definitions" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."custom_variables" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."custom_variables" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."custom_variables" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."data_source_skills" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."data_source_skills" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."data_source_skills" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."data_sources" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."data_sources" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."data_sources" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."etl_batch_jobs" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."etl_batch_jobs" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."etl_batch_jobs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."etl_job_errors" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."etl_job_errors" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."etl_job_errors" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."etl_job_runs" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."etl_job_runs" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."etl_job_runs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."etl_pipelines" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."etl_pipelines" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."etl_pipelines" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."etl_source_snapshots" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."etl_source_snapshots" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."etl_source_snapshots" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."filter_definitions" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."filter_definitions" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."filter_definitions" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."inbound_webhooks" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."inbound_webhooks" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."inbound_webhooks" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."integration_secrets" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."integration_secrets" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."integration_secrets" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."integrations" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."integrations" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."integrations" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."message_templates" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."message_templates" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."message_templates" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."supplies" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."supplies" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."supplies" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."supply_seals" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."supply_seals" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."supply_seals" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."supply_title_seals" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."supply_title_seals" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."supply_title_seals" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."supply_titles" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."supply_titles" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."supply_titles" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."mv_supply_titles_base" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."mv_supply_titles_base" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."mv_supply_titles_base" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."portfolios" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."portfolios" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."portfolios" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."title_seals" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."title_seals" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."title_seals" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."titles" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."titles" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."titles" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."mv_titles_base" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."mv_titles_base" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."mv_titles_base" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."portfolio_integrations" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."portfolio_integrations" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."portfolio_integrations" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."rag_chunks" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."rag_chunks" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."rag_chunks" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."rag_documents" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."rag_documents" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."rag_documents" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."report_schedules" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."report_schedules" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."report_schedules" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."seal_catalog" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."seal_catalog" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."seal_catalog" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."sending_controls" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."sending_controls" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."sending_controls" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."skipped_actions_log" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."skipped_actions_log" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."skipped_actions_log" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."standard_values" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."standard_values" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."standard_values" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."supply_title_status_history" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."supply_title_status_history" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."supply_title_status_history" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."tag_catalog" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."tag_catalog" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."tag_catalog" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."title_status_history" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."title_status_history" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."title_status_history" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."transfer_reprocess_audit" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."transfer_reprocess_audit" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."transfer_reprocess_batches" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."transfer_reprocess_batches" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."transfer_reprocess_results" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."transfer_reprocess_results" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."transfer_tag_type_periods" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."transfer_tag_type_periods" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."transfer_tag_type_periods" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."transfer_tags" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."transfer_tags" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."transfer_tags" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."vw_actions_ready" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."vw_actions_ready" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."vw_actions_ready" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."vw_collection_portfolio" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."vw_collection_portfolio" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."vw_collection_portfolio" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."vw_contacts_enriched" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."vw_contacts_enriched" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."vw_contacts_enriched" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."vw_contacts_full" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."vw_contacts_full" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."vw_contacts_full" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."vw_contract_portfolios" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."vw_contract_portfolios" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."vw_contract_portfolios" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."vw_contracts_full" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."vw_contracts_full" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."vw_contracts_full" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."vw_processing_metrics" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."vw_processing_metrics" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."vw_processing_metrics" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."vw_skipped_actions_summary" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."vw_skipped_actions_summary" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."vw_skipped_actions_summary" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."vw_titles_full" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."vw_titles_full" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."vw_titles_full" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."vw_titles_live" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."vw_titles_live" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."vw_titles_live" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."webhook_retry_queue" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."webhook_retry_queue" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."webhook_retry_queue" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."workflow_audit_logs" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."workflow_audit_logs" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."workflow_audit_logs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."workflow_executions" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."workflow_executions" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."workflow_executions" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."workflow_steps" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."workflow_steps" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."workflow_steps" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."workflow_versions" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."workflow_versions" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."workflow_versions" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_blips"."workflows" TO "authenticated";
GRANT ALL ON TABLE "org_blips"."workflows" TO "service_role";
GRANT SELECT ON TABLE "org_blips"."workflows" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."a2a_closure_config" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."a2a_closure_config" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."actions_dlq" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."actions_dlq" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."actions_dlq" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."actions_interaction_logs" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."actions_interaction_logs" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_finza"."actions_interaction_logs" TO "authenticated";



GRANT ALL ON TABLE "org_finza"."actions_sync" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."actions_sync" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."actions_sync" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."agent_allowed_tags" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."agent_allowed_tags" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."agent_allowed_tags" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."agent_audit_logs" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."agent_audit_logs" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."agent_audit_logs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."agent_call_logs" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."agent_call_logs" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."agent_call_logs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."agent_llm_configs" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."agent_llm_configs" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."agent_llm_configs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."agent_messages" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."agent_messages" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."agent_messages" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."agent_proposal_items" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."agent_proposal_items" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."agent_proposal_items" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."agent_proposals" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."agent_proposals" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."agent_proposals" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."agent_sessions" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."agent_sessions" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."agent_sessions" TO "airbyte_readonly";



GRANT SELECT,INSERT,REFERENCES,TRIGGER,MAINTAIN,UPDATE ON TABLE "org_finza"."ai_agents" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."ai_agents" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_agents" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."ai_backfill_checkpoint" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_backfill_checkpoint" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_finza"."ai_backfill_checkpoint" TO "authenticated";



GRANT ALL ON TABLE "org_finza"."ai_backfill_quarantine" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_backfill_quarantine" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_finza"."ai_backfill_quarantine" TO "authenticated";



GRANT ALL ON TABLE "org_finza"."ai_business_rules" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."ai_business_rules" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_business_rules" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."ai_conversations" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_conversations" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_finza"."ai_conversations" TO "authenticated";



GRANT ALL ON TABLE "org_finza"."ai_funnel_events" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_funnel_events" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_finza"."ai_funnel_events" TO "authenticated";



GRANT ALL ON TABLE "org_finza"."ai_funnel_stages" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."ai_funnel_stages" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_funnel_stages" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."ai_guidelines" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."ai_guidelines" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_guidelines" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."ai_ingestion_events" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_ingestion_events" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_finza"."ai_ingestion_events" TO "authenticated";



GRANT ALL ON TABLE "org_finza"."ai_messages" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_messages" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_finza"."ai_messages" TO "authenticated";



GRANT ALL ON TABLE "org_finza"."ai_playground_messages" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."ai_playground_messages" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_playground_messages" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."ai_playground_sessions" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."ai_playground_sessions" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_playground_sessions" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."ai_prompts" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."ai_prompts" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_prompts" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."ai_protocol_finalizations" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."ai_protocol_finalizations" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_protocol_finalizations" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."ai_protocol_status_log" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_protocol_status_log" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_finza"."ai_protocol_status_log" TO "authenticated";



GRANT ALL ON TABLE "org_finza"."ai_protocols" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_protocols" TO "airbyte_readonly";
GRANT SELECT ON TABLE "org_finza"."ai_protocols" TO "authenticated";



GRANT ALL ON TABLE "org_finza"."ai_versions" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."ai_versions" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."ai_versions" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."audit_logs" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."audit_logs" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."audit_logs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."blocked_dates" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."blocked_dates" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."blocked_dates" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."blocklist" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."blocklist" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."blocklist" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."blocklist_entries" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."blocklist_entries" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."blocklist_entries" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."blocklist_filter_rules" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."blocklist_filter_rules" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."blocklist_filter_rules" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."blocklist_history" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."blocklist_history" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."blocklist_history" TO "airbyte_readonly";



GRANT SELECT,USAGE ON SEQUENCE "org_finza"."blocklist_history_id_seq" TO "authenticated";
GRANT SELECT,USAGE ON SEQUENCE "org_finza"."blocklist_history_id_seq" TO "service_role";



GRANT ALL ON TABLE "org_finza"."campaign_execution_candidates" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."campaign_execution_candidates" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."campaign_execution_candidates" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."campaign_execution_runs" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."campaign_execution_runs" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."campaign_execution_runs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."campaign_logs" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."campaign_logs" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."campaign_logs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."campaign_workflows" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."campaign_workflows" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."campaign_workflows" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."campaigns" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."campaigns" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."campaigns" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."channel_costs" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."channel_costs" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."channel_costs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."channel_rate_counts" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."channel_rate_counts" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."channel_rate_counts" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."channel_rate_limits" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."channel_rate_limits" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."channel_rate_limits" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."contact_assignments" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."contact_assignments" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."contact_assignments" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."contact_emails" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."contact_emails" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."contact_emails" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."contact_phones" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."contact_phones" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."contact_phones" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."contact_seals" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."contact_seals" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."contact_seals" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."contact_summaries" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."contact_summaries" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."contact_summaries" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."contacts" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."contacts" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."contacts" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."contract_portfolios" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."contract_portfolios" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."contract_portfolios" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."contract_seals" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."contract_seals" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."contract_seals" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."contracts" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."contracts" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."contracts" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."conversation_tags" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."conversation_tags" TO "airbyte_readonly";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "org_finza"."conversation_tags" TO "authenticated";



GRANT ALL ON TABLE "org_finza"."custom_field_definitions" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."custom_field_definitions" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."custom_field_definitions" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."custom_variables" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."custom_variables" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."custom_variables" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."data_source_skills" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."data_source_skills" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."data_source_skills" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."data_sources" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."data_sources" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."data_sources" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."etl_batch_jobs" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."etl_batch_jobs" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."etl_batch_jobs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."etl_job_errors" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."etl_job_errors" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."etl_job_errors" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."etl_job_runs" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."etl_job_runs" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."etl_job_runs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."etl_pipelines" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."etl_pipelines" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."etl_pipelines" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."etl_source_snapshots" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."etl_source_snapshots" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."etl_source_snapshots" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."filter_definitions" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."filter_definitions" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."filter_definitions" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."inbound_webhooks" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."inbound_webhooks" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."inbound_webhooks" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."integration_secrets" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."integration_secrets" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."integration_secrets" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."integrations" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."integrations" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."integrations" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."message_templates" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."message_templates" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."message_templates" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."supplies" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."supplies" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."supplies" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."supply_seals" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."supply_seals" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."supply_seals" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."supply_title_seals" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."supply_title_seals" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."supply_title_seals" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."supply_titles" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."supply_titles" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."supply_titles" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."mv_supply_titles_base" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."mv_supply_titles_base" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."mv_supply_titles_base" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."portfolios" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."portfolios" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."portfolios" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."title_seals" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."title_seals" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."title_seals" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."titles" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."titles" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."titles" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."mv_titles_base" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."mv_titles_base" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."mv_titles_base" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."portfolio_integrations" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."portfolio_integrations" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."portfolio_integrations" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."rag_chunks" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."rag_chunks" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."rag_chunks" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."rag_documents" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."rag_documents" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."rag_documents" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."report_schedules" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."report_schedules" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."report_schedules" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."seal_catalog" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."seal_catalog" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."seal_catalog" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."sending_controls" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."sending_controls" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."sending_controls" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."skipped_actions_log" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."skipped_actions_log" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."skipped_actions_log" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."standard_values" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."standard_values" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."standard_values" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."supply_title_status_history" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."supply_title_status_history" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."supply_title_status_history" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."tag_catalog" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."tag_catalog" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."tag_catalog" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."title_status_history" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."title_status_history" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."title_status_history" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."transfer_event_reclass_audit" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."transfer_event_reclass_audit" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."transfer_event_reclass_batches" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."transfer_event_reclass_batches" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."transfer_tag_type_periods" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."transfer_tag_type_periods" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."transfer_tag_type_periods" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."transfer_tags" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."transfer_tags" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."transfer_tags" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."transfer_type_reclass_audit" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."transfer_type_reclass_audit" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."transfer_type_reclass_batches" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."transfer_type_reclass_batches" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."vw_actions_ready" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."vw_actions_ready" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."vw_actions_ready" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."vw_collection_portfolio" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."vw_collection_portfolio" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."vw_collection_portfolio" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."vw_contacts_enriched" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."vw_contacts_enriched" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."vw_contacts_enriched" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."vw_contacts_full" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."vw_contacts_full" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."vw_contacts_full" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."vw_contract_portfolios" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."vw_contract_portfolios" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."vw_contract_portfolios" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."vw_contracts_full" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."vw_contracts_full" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."vw_contracts_full" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."vw_processing_metrics" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."vw_processing_metrics" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."vw_processing_metrics" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."vw_skipped_actions_summary" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."vw_skipped_actions_summary" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."vw_skipped_actions_summary" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."vw_titles_full" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."vw_titles_full" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."vw_titles_full" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."vw_titles_live" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."vw_titles_live" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."vw_titles_live" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."webhook_retry_queue" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."webhook_retry_queue" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."webhook_retry_queue" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."workflow_audit_logs" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."workflow_audit_logs" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."workflow_audit_logs" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."workflow_executions" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."workflow_executions" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."workflow_executions" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."workflow_steps" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."workflow_steps" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."workflow_steps" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."workflow_versions" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."workflow_versions" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."workflow_versions" TO "airbyte_readonly";



GRANT ALL ON TABLE "org_finza"."workflows" TO "authenticated";
GRANT ALL ON TABLE "org_finza"."workflows" TO "service_role";
GRANT SELECT ON TABLE "org_finza"."workflows" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."a2a_closure_dispatches" TO "service_role";
GRANT SELECT ON TABLE "public"."a2a_closure_dispatches" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."ai_feature_flags" TO "service_role";
GRANT SELECT ON TABLE "public"."ai_feature_flags" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."ai_metric_hotfix_backups" TO "service_role";
GRANT SELECT ON TABLE "public"."ai_metric_hotfix_backups" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."ai_report_export_log" TO "service_role";
GRANT SELECT ON TABLE "public"."ai_report_export_log" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."ai_retention_config" TO "service_role";
GRANT SELECT ON TABLE "public"."ai_retention_config" TO "airbyte_readonly";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."api_keys" TO "anon";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."api_keys" TO "authenticated";
GRANT ALL ON TABLE "public"."api_keys" TO "service_role";
GRANT SELECT ON TABLE "public"."api_keys" TO "airbyte_readonly";



GRANT SELECT("id") ON TABLE "public"."api_keys" TO "authenticated";



GRANT SELECT("name") ON TABLE "public"."api_keys" TO "authenticated";



GRANT SELECT("created_at") ON TABLE "public"."api_keys" TO "authenticated";



GRANT SELECT("last_used_at") ON TABLE "public"."api_keys" TO "authenticated";



GRANT SELECT("created_by") ON TABLE "public"."api_keys" TO "authenticated";



GRANT SELECT("is_active") ON TABLE "public"."api_keys" TO "authenticated";



GRANT SELECT("key_hash") ON TABLE "public"."api_keys" TO "authenticated";



GRANT SELECT("key_prefix") ON TABLE "public"."api_keys" TO "authenticated";



GRANT ALL ON TABLE "public"."changelog_reactions" TO "anon";
GRANT ALL ON TABLE "public"."changelog_reactions" TO "authenticated";
GRANT ALL ON TABLE "public"."changelog_reactions" TO "service_role";
GRANT SELECT ON TABLE "public"."changelog_reactions" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."changelog_seen" TO "anon";
GRANT ALL ON TABLE "public"."changelog_seen" TO "authenticated";
GRANT ALL ON TABLE "public"."changelog_seen" TO "service_role";
GRANT SELECT ON TABLE "public"."changelog_seen" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."changelog_views" TO "anon";
GRANT ALL ON TABLE "public"."changelog_views" TO "authenticated";
GRANT ALL ON TABLE "public"."changelog_views" TO "service_role";
GRANT SELECT ON TABLE "public"."changelog_views" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."chat_messages" TO "service_role";
GRANT SELECT ON TABLE "public"."chat_messages" TO "airbyte_readonly";



GRANT ALL ON SEQUENCE "public"."chat_messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."chat_messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."chat_messages_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."chat_state" TO "service_role";
GRANT SELECT ON TABLE "public"."chat_state" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."edge_function_call_logs" TO "anon";
GRANT ALL ON TABLE "public"."edge_function_call_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."edge_function_call_logs" TO "service_role";
GRANT SELECT ON TABLE "public"."edge_function_call_logs" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."email_rotation" TO "service_role";
GRANT SELECT ON TABLE "public"."email_rotation" TO "airbyte_readonly";



GRANT ALL ON SEQUENCE "public"."email_rotation_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."email_rotation_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."email_rotation_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."health_check_alerts" TO "anon";
GRANT ALL ON TABLE "public"."health_check_alerts" TO "authenticated";
GRANT ALL ON TABLE "public"."health_check_alerts" TO "service_role";
GRANT SELECT ON TABLE "public"."health_check_alerts" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."historic_dalila" TO "service_role";
GRANT SELECT ON TABLE "public"."historic_dalila" TO "airbyte_readonly";



GRANT ALL ON SEQUENCE "public"."historic_dalila_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."historic_dalila_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."historic_dalila_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."kiara_processing_lock" TO "service_role";
GRANT SELECT ON TABLE "public"."kiara_processing_lock" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."luna_users" TO "anon";
GRANT ALL ON TABLE "public"."luna_users" TO "authenticated";
GRANT ALL ON TABLE "public"."luna_users" TO "service_role";
GRANT SELECT ON TABLE "public"."luna_users" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."marketplace_integrations" TO "anon";
GRANT ALL ON TABLE "public"."marketplace_integrations" TO "authenticated";
GRANT ALL ON TABLE "public"."marketplace_integrations" TO "service_role";
GRANT SELECT ON TABLE "public"."marketplace_integrations" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."mcp_cross_org_read_log" TO "service_role";
GRANT SELECT ON TABLE "public"."mcp_cross_org_read_log" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."mv_refresh_config" TO "anon";
GRANT ALL ON TABLE "public"."mv_refresh_config" TO "authenticated";
GRANT ALL ON TABLE "public"."mv_refresh_config" TO "service_role";
GRANT SELECT ON TABLE "public"."mv_refresh_config" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."mv_refresh_log" TO "service_role";
GRANT SELECT ON TABLE "public"."mv_refresh_log" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."n8n_chat_histories" TO "service_role";
GRANT SELECT ON TABLE "public"."n8n_chat_histories" TO "airbyte_readonly";



GRANT ALL ON SEQUENCE "public"."n8n_chat_histories_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."n8n_chat_histories_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."n8n_chat_histories_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."n8n_teste_luna" TO "anon";
GRANT ALL ON TABLE "public"."n8n_teste_luna" TO "authenticated";
GRANT ALL ON TABLE "public"."n8n_teste_luna" TO "service_role";
GRANT SELECT ON TABLE "public"."n8n_teste_luna" TO "airbyte_readonly";



GRANT ALL ON SEQUENCE "public"."n8n_teste_luna_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."n8n_teste_luna_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."n8n_teste_luna_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."organization_marketplace_integrations" TO "anon";
GRANT ALL ON TABLE "public"."organization_marketplace_integrations" TO "authenticated";
GRANT ALL ON TABLE "public"."organization_marketplace_integrations" TO "service_role";
GRANT SELECT ON TABLE "public"."organization_marketplace_integrations" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."organization_role_changes" TO "anon";
GRANT ALL ON TABLE "public"."organization_role_changes" TO "authenticated";
GRANT ALL ON TABLE "public"."organization_role_changes" TO "service_role";
GRANT SELECT ON TABLE "public"."organization_role_changes" TO "airbyte_readonly";



GRANT ALL ON SEQUENCE "public"."organization_role_changes_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."organization_role_changes_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."organization_role_changes_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."organization_secrets" TO "anon";
GRANT ALL ON TABLE "public"."organization_secrets" TO "authenticated";
GRANT ALL ON TABLE "public"."organization_secrets" TO "service_role";
GRANT SELECT ON TABLE "public"."organization_secrets" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."organization_users" TO "anon";
GRANT ALL ON TABLE "public"."organization_users" TO "authenticated";
GRANT ALL ON TABLE "public"."organization_users" TO "service_role";
GRANT SELECT ON TABLE "public"."organization_users" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."organization_users_with_email" TO "anon";
GRANT ALL ON TABLE "public"."organization_users_with_email" TO "authenticated";
GRANT ALL ON TABLE "public"."organization_users_with_email" TO "service_role";
GRANT SELECT ON TABLE "public"."organization_users_with_email" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."organizations" TO "anon";
GRANT ALL ON TABLE "public"."organizations" TO "authenticated";
GRANT ALL ON TABLE "public"."organizations" TO "service_role";
GRANT SELECT ON TABLE "public"."organizations" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."project_config" TO "anon";
GRANT ALL ON TABLE "public"."project_config" TO "authenticated";
GRANT ALL ON TABLE "public"."project_config" TO "service_role";
GRANT SELECT ON TABLE "public"."project_config" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."roles_permissions" TO "anon";
GRANT ALL ON TABLE "public"."roles_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."roles_permissions" TO "service_role";
GRANT SELECT ON TABLE "public"."roles_permissions" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."scheduled_report_deliveries" TO "service_role";
GRANT SELECT ON TABLE "public"."scheduled_report_deliveries" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."sku_catalogo" TO "anon";
GRANT ALL ON TABLE "public"."sku_catalogo" TO "authenticated";
GRANT ALL ON TABLE "public"."sku_catalogo" TO "service_role";
GRANT SELECT ON TABLE "public"."sku_catalogo" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."socorro_messages" TO "anon";
GRANT ALL ON TABLE "public"."socorro_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."socorro_messages" TO "service_role";
GRANT SELECT ON TABLE "public"."socorro_messages" TO "airbyte_readonly";



GRANT ALL ON SEQUENCE "public"."socorro_messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."socorro_messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."socorro_messages_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."socorro_users" TO "anon";
GRANT ALL ON TABLE "public"."socorro_users" TO "authenticated";
GRANT ALL ON TABLE "public"."socorro_users" TO "service_role";
GRANT SELECT ON TABLE "public"."socorro_users" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."super_admins" TO "anon";
GRANT ALL ON TABLE "public"."super_admins" TO "authenticated";
GRANT ALL ON TABLE "public"."super_admins" TO "service_role";
GRANT SELECT ON TABLE "public"."super_admins" TO "airbyte_readonly";



GRANT ALL ON TABLE "public"."user_invitations" TO "anon";
GRANT ALL ON TABLE "public"."user_invitations" TO "authenticated";
GRANT ALL ON TABLE "public"."user_invitations" TO "service_role";
GRANT SELECT ON TABLE "public"."user_invitations" TO "airbyte_readonly";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "org_blips" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "org_blips" GRANT ALL ON TABLES TO "service_role";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "org_blips" GRANT SELECT ON TABLES TO "airbyte_readonly";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "org_finza" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "org_finza" GRANT ALL ON TABLES TO "service_role";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "org_finza" GRANT SELECT ON TABLES TO "airbyte_readonly";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT ON TABLES TO "airbyte_readonly";































