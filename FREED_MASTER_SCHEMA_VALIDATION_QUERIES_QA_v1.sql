/* ============================================================
   FREED 2026 - VALIDATION QUERIES (QA PACK) - v1
   File    : FREED_MASTER_SCHEMA_VALIDATION_QUERIES_QA_v1.sql
   Purpose : Post-install validation for inferred unified schema
   Scope   : Structural checks + data quality checks (safe SELECTs only)
   ============================================================ */

SET NAMES utf8mb4;
SET time_zone = '+03:00';

-- ============================================================
-- [A] STRUCTURE - TABLE PRESENCE
-- ============================================================
SELECT t.table_name
FROM information_schema.tables t
WHERE t.table_schema = DATABASE()
  AND t.table_name IN (
    'strategic_axes','strategic_goals','operational_goals','initiative_goal_links',
    'kpi_definitions','kpi_links','kpi_targets','kpi_readings',
    'risk_register','risk_mitigations','risk_links',
    'task_initiative_links',
    'donors','donor_contacts','funds','pledges','donations','collections','donor_interactions','donation_allocations',
    'item_categories','units_of_measure','items','warehouses','initiative_stock_requests','initiative_stock_request_lines',
    'workflow_definitions','workflow_definition_steps','workflow_step_assignees','workflow_instances',
    'workflow_instance_steps','workflow_actions','workflow_delegations','workflow_watchers'
  )
ORDER BY t.table_name;

-- ============================================================
-- [B] STRUCTURE - FOREIGN KEYS SNAPSHOT
-- ============================================================
SELECT rc.table_name, rc.constraint_name, rc.referenced_table_name
FROM information_schema.referential_constraints rc
WHERE rc.constraint_schema = DATABASE()
  AND rc.table_name IN (
    'strategic_axes','strategic_goals','operational_goals','initiative_goal_links',
    'kpi_definitions','kpi_links','kpi_targets','kpi_readings',
    'risk_register','risk_mitigations','risk_links',
    'task_initiative_links',
    'donors','donor_contacts','funds','pledges','donations','collections','donor_interactions','donation_allocations',
    'item_categories','units_of_measure','items','warehouses','initiative_stock_requests','initiative_stock_request_lines',
    'workflow_definitions','workflow_definition_steps','workflow_step_assignees','workflow_instances',
    'workflow_instance_steps','workflow_actions','workflow_delegations','workflow_watchers'
  )
ORDER BY rc.table_name, rc.constraint_name;

-- ============================================================
-- [C] DATA QUALITY - STRATEGIC / KPI / RISK
-- ============================================================

-- Orphan-like semantic issue: kpi_links entity_type mismatch vs populated column(s)
SELECT id, organization_id, link_entity_type, initiative_id, strategic_goal_id, operational_goal_id, department_id, task_id
FROM kpi_links
WHERE
  (link_entity_type='initiative' AND initiative_id IS NULL)
  OR (link_entity_type='strategic_goal' AND strategic_goal_id IS NULL)
  OR (link_entity_type='operational_goal' AND operational_goal_id IS NULL)
  OR (link_entity_type='department' AND department_id IS NULL)
  OR (link_entity_type='task' AND task_id IS NULL);

-- Multiple targets same KPI/period uniqueness should prevent duplicates; this query verifies no hidden issues
SELECT organization_id, kpi_definition_id, period_type, period_year, period_no, COUNT(*) AS cnt
FROM kpi_targets
GROUP BY organization_id, kpi_definition_id, period_type, period_year, period_no
HAVING COUNT(*) > 1;

-- Risk mitigations completed without completed_at
SELECT id, risk_id, status, completed_at
FROM risk_mitigations
WHERE status='done' AND completed_at IS NULL;

-- Residual scores partially filled (recommended to complete both or none)
SELECT id, risk_id, residual_likelihood_score, residual_impact_score
FROM risk_mitigations
WHERE (residual_likelihood_score IS NULL AND residual_impact_score IS NOT NULL)
   OR (residual_likelihood_score IS NOT NULL AND residual_impact_score IS NULL);

-- ============================================================
-- [D] DATA QUALITY - FINANCE FOLLOW-UP
-- ============================================================

-- Donations linked to different donor than pledge donor (semantic mismatch)
SELECT d.id AS donation_id, d.donor_id AS donation_donor_id, p.id AS pledge_id, p.donor_id AS pledge_donor_id
FROM donations d
JOIN pledges p ON p.id = d.pledge_id
WHERE d.pledge_id IS NOT NULL
  AND d.donor_id <> p.donor_id;

-- Collections linked to donation but donor mismatch (if both present)
SELECT c.id AS collection_id, c.donation_id, c.donor_id AS collection_donor_id, d.donor_id AS donation_donor_id
FROM collections c
JOIN donations d ON d.id = c.donation_id
WHERE c.donation_id IS NOT NULL
  AND c.donor_id IS NOT NULL
  AND c.donor_id <> d.donor_id;

-- Donation allocations with both donation_id and collection_id NULL (likely invalid record)
SELECT id, organization_id, allocation_id, initiative_id, fund_id, amount_allocated
FROM donation_allocations
WHERE donation_id IS NULL AND collection_id IS NULL;

-- ============================================================
-- [E] DATA QUALITY - INVENTORY FOLLOW-UP
-- ============================================================

-- Requests in issued/partially_issued status without any lines
SELECT r.id, r.request_code, r.status
FROM initiative_stock_requests r
LEFT JOIN initiative_stock_request_lines l ON l.request_id = r.id
WHERE r.status IN ('partially_issued','issued')
GROUP BY r.id, r.request_code, r.status
HAVING COUNT(l.id) = 0;

-- Lines with issued_qty > approved_qty when approved_qty exists (review)
SELECT id, request_id, requested_qty, approved_qty, issued_qty
FROM initiative_stock_request_lines
WHERE approved_qty IS NOT NULL
  AND issued_qty > approved_qty;

-- ============================================================
-- [F] DATA QUALITY - WORKFLOW
-- ============================================================

-- Current step must belong to same workflow instance
SELECT wi.id AS workflow_instance_id, wi.current_step_id, wis.workflow_instance_id AS current_step_parent_instance
FROM workflow_instances wi
LEFT JOIN workflow_instance_steps wis ON wis.id = wi.current_step_id
WHERE wi.current_step_id IS NOT NULL
  AND (wis.id IS NULL OR wis.workflow_instance_id <> wi.id);

-- Active instance with no instance steps (review)
SELECT wi.id, wi.instance_code, wi.current_status
FROM workflow_instances wi
LEFT JOIN workflow_instance_steps wis ON wis.workflow_instance_id = wi.id
WHERE wi.current_status IN ('running','waiting_action')
GROUP BY wi.id, wi.instance_code, wi.current_status
HAVING COUNT(wis.id)=0;

-- Delegations expired but still active
SELECT id, delegator_user_id, delegate_user_id, valid_from, valid_to, is_active
FROM workflow_delegations
WHERE is_active = 1
  AND valid_to < NOW();

-- ============================================================
-- [G] SUMMARY COUNTS (OPTIONAL)
-- ============================================================
SELECT 'strategic_axes' AS table_name, COUNT(*) AS row_count FROM strategic_axes
UNION ALL SELECT 'strategic_goals', COUNT(*) FROM strategic_goals
UNION ALL SELECT 'operational_goals', COUNT(*) FROM operational_goals
UNION ALL SELECT 'kpi_definitions', COUNT(*) FROM kpi_definitions
UNION ALL SELECT 'risk_register', COUNT(*) FROM risk_register
UNION ALL SELECT 'donors', COUNT(*) FROM donors
UNION ALL SELECT 'funds', COUNT(*) FROM funds
UNION ALL SELECT 'initiative_stock_requests', COUNT(*) FROM initiative_stock_requests
UNION ALL SELECT 'workflow_instances', COUNT(*) FROM workflow_instances
UNION ALL SELECT 'workflow_actions', COUNT(*) FROM workflow_actions;
