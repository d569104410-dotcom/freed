/* ============================================================
   FREED 2026 - MASTER SQL SCHEMA (FOLLOW-UP ONLY) - RELEASE CLEAN v2
   File         : FREED_MASTER_SCHEMA_FOLLOWUP_UNIFIED_INFERRED_RCFinal_ReleaseClean_v2.sql
   Source       : Inferred Unified RCFinal (conversation-approved pattern)
   Purpose      : Clean deployment/testing-ready edition
   Notes        :
     - Adds structured execution notes
     - Adds optional TEST-ONLY reset block (commented)
     - Adds optional minimal demo seed block (commented)
     - Keeps optional FKs (attachments/vendors) commented
   ============================================================ */


-- ============================================================
-- [OPTIONAL][TEST ONLY] RESET BLOCK (COMMENTED)
-- Use ONLY in a disposable test database after reviewing dependencies.
-- ============================================================
/*
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS workflow_watchers;
DROP TABLE IF EXISTS workflow_delegations;
DROP TABLE IF EXISTS workflow_actions;
DROP TABLE IF EXISTS workflow_instance_steps;
DROP TABLE IF EXISTS workflow_instances;
DROP TABLE IF EXISTS workflow_step_assignees;
DROP TABLE IF EXISTS workflow_definition_steps;
DROP TABLE IF EXISTS workflow_definitions;

DROP TABLE IF EXISTS initiative_stock_request_lines;
DROP TABLE IF EXISTS initiative_stock_requests;
DROP TABLE IF EXISTS warehouses;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS units_of_measure;
DROP TABLE IF EXISTS item_categories;

DROP TABLE IF EXISTS donation_allocations;
DROP TABLE IF EXISTS donor_interactions;
DROP TABLE IF EXISTS collections;
DROP TABLE IF EXISTS donations;
DROP TABLE IF EXISTS pledges;
DROP TABLE IF EXISTS funds;
DROP TABLE IF EXISTS donor_contacts;
DROP TABLE IF EXISTS donors;

DROP TABLE IF EXISTS task_initiative_links;

DROP TABLE IF EXISTS risk_links;
DROP TABLE IF EXISTS risk_mitigations;
DROP TABLE IF EXISTS risk_register;

DROP TABLE IF EXISTS kpi_readings;
DROP TABLE IF EXISTS kpi_targets;
DROP TABLE IF EXISTS kpi_links;
DROP TABLE IF EXISTS kpi_definitions;

DROP TABLE IF EXISTS initiative_goal_links;
DROP TABLE IF EXISTS operational_goals;
DROP TABLE IF EXISTS strategic_goals;
DROP TABLE IF EXISTS strategic_axes;

SET FOREIGN_KEY_CHECKS = 1;
*/

/* ============================================================
   FREED 2026 - MASTER SQL SCHEMA (FOLLOW-UP ONLY) - INFERRED UNIFIED
   File         : FREED_MASTER_SCHEMA_FOLLOWUP_UNIFIED_INFERRED_RCFinal.sql
   Version      : RCFinal-Inferred-Unified-v1
   Database     : MySQL 8.0+
   Charset      : utf8mb4 / utf8mb4_unicode_ci
   ------------------------------------------------------------
   IMPORTANT
   ------------------------------------------------------------
   This unified script is an INFERRED implementation built to match the
   approved architecture and patterns in this conversation:
   - Follow-up + Governance + Linking + Workflow
   - No accounting execution inside FREED
   - No inventory execution inside FREED
   - Optional external reference fields only
   - Internal workflow & approvals fully supported
   ------------------------------------------------------------
   Assumes base/core tables already exist:
   organizations, departments, users, initiatives, tasks, attachments,
   allocations, finance_transactions, vendors (optional)
   ============================================================ */

SET NAMES utf8mb4;
SET time_zone = '+03:00';

-- ============================================================
-- [0] PRECHECK
-- ============================================================
SELECT t.table_name
FROM information_schema.tables t
WHERE t.table_schema = DATABASE()
  AND t.table_name IN (
    'organizations','departments','users','initiatives','tasks',
    'attachments','allocations','finance_transactions','vendors'
  )
ORDER BY t.table_name;

-- ============================================================
-- [1] STRATEGIC PLANNING EXTENSION (INFERRED)
-- ============================================================

CREATE TABLE IF NOT EXISTS strategic_axes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    axis_code VARCHAR(60) NOT NULL,
    name_ar VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NULL,
    description TEXT NULL,
    sort_order INT UNSIGNED NOT NULL DEFAULT 0,
    status ENUM('draft','active','inactive','archived') NOT NULL DEFAULT 'active',
    start_date DATE NULL,
    end_date DATE NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_sa_org_code (organization_id, axis_code),
    UNIQUE KEY uk_sa_org_name_ar (organization_id, name_ar),
    KEY idx_sa_org (organization_id),
    KEY idx_sa_status (status),
    KEY idx_sa_sort (sort_order),
    KEY idx_sa_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS strategic_goals (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    axis_id BIGINT UNSIGNED NOT NULL,
    goal_code VARCHAR(80) NOT NULL,
    title_ar VARCHAR(255) NOT NULL,
    title_en VARCHAR(255) NULL,
    description TEXT NULL,
    baseline_value DECIMAL(18,4) NULL,
    target_value DECIMAL(18,4) NULL,
    unit_label VARCHAR(60) NULL,
    priority ENUM('low','medium','high','critical') NOT NULL DEFAULT 'medium',
    status ENUM('draft','active','on_hold','completed','cancelled','archived') NOT NULL DEFAULT 'active',
    start_date DATE NULL,
    end_date DATE NULL,
    owner_department_id BIGINT UNSIGNED NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_sg_org_code (organization_id, goal_code),
    KEY idx_sg_org (organization_id),
    KEY idx_sg_axis (axis_id),
    KEY idx_sg_owner_dept (owner_department_id),
    KEY idx_sg_status (status),
    KEY idx_sg_priority (priority),
    KEY idx_sg_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS operational_goals (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    strategic_goal_id BIGINT UNSIGNED NOT NULL,
    op_goal_code VARCHAR(80) NOT NULL,
    title_ar VARCHAR(255) NOT NULL,
    title_en VARCHAR(255) NULL,
    description TEXT NULL,
    baseline_value DECIMAL(18,4) NULL,
    target_value DECIMAL(18,4) NULL,
    unit_label VARCHAR(60) NULL,
    status ENUM('draft','active','on_hold','completed','cancelled','archived') NOT NULL DEFAULT 'active',
    priority ENUM('low','medium','high','critical') NOT NULL DEFAULT 'medium',
    owner_department_id BIGINT UNSIGNED NULL,
    owner_user_id BIGINT UNSIGNED NULL,
    start_date DATE NULL,
    end_date DATE NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_og_org_code (organization_id, op_goal_code),
    KEY idx_og_org (organization_id),
    KEY idx_og_strategic_goal (strategic_goal_id),
    KEY idx_og_owner_dept (owner_department_id),
    KEY idx_og_owner_user (owner_user_id),
    KEY idx_og_status (status),
    KEY idx_og_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS initiative_goal_links (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    initiative_id BIGINT UNSIGNED NOT NULL,
    strategic_goal_id BIGINT UNSIGNED NULL,
    operational_goal_id BIGINT UNSIGNED NULL,
    contribution_type ENUM('primary','secondary','supporting') NOT NULL DEFAULT 'primary',
    contribution_weight DECIMAL(8,4) NULL,
    expected_impact_text VARCHAR(255) NULL,
    notes TEXT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    KEY idx_igl_org (organization_id),
    KEY idx_igl_init (initiative_id),
    KEY idx_igl_sg (strategic_goal_id),
    KEY idx_igl_og (operational_goal_id),
    KEY idx_igl_active (is_active),
    KEY idx_igl_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_igl_goal_ref CHECK (
        strategic_goal_id IS NOT NULL OR operational_goal_id IS NOT NULL
    ),
    CONSTRAINT chk_igl_weight CHECK (
        contribution_weight IS NULL OR (contribution_weight >= 0 AND contribution_weight <= 100)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- FKs Strategic
ALTER TABLE strategic_axes
    ADD CONSTRAINT fk_sa_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_sa_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_sa_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE strategic_goals
    ADD CONSTRAINT fk_sg_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_sg_axis FOREIGN KEY (axis_id) REFERENCES strategic_axes(id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_sg_owner_dept FOREIGN KEY (owner_department_id) REFERENCES departments(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_sg_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_sg_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE operational_goals
    ADD CONSTRAINT fk_og_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_og_sg FOREIGN KEY (strategic_goal_id) REFERENCES strategic_goals(id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_og_owner_dept FOREIGN KEY (owner_department_id) REFERENCES departments(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_og_owner_user FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_og_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_og_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE initiative_goal_links
    ADD CONSTRAINT fk_igl_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_igl_init FOREIGN KEY (initiative_id) REFERENCES initiatives(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_igl_sg FOREIGN KEY (strategic_goal_id) REFERENCES strategic_goals(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_igl_og FOREIGN KEY (operational_goal_id) REFERENCES operational_goals(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_igl_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_igl_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

-- ============================================================
-- [2] KPI MODULE (INFERRED)
-- ============================================================

CREATE TABLE IF NOT EXISTS kpi_definitions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    kpi_code VARCHAR(80) NOT NULL,
    name_ar VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NULL,
    description TEXT NULL,
    kpi_type ENUM('output','outcome','impact','efficiency','quality','compliance','financial','custom')
        NOT NULL DEFAULT 'custom',
    unit_type ENUM('number','percent','currency','days','hours','text','score','ratio')
        NOT NULL DEFAULT 'number',
    unit_label VARCHAR(60) NULL,
    formula_text TEXT NULL,
    direction_good ENUM('higher_better','lower_better','target_band') NOT NULL DEFAULT 'higher_better',
    target_min DECIMAL(18,4) NULL,
    target_max DECIMAL(18,4) NULL,
    owner_department_id BIGINT UNSIGNED NULL,
    owner_user_id BIGINT UNSIGNED NULL,
    measurement_frequency ENUM('daily','weekly','monthly','quarterly','semiannual','annual','ad_hoc')
        NOT NULL DEFAULT 'monthly',
    status ENUM('draft','active','inactive','archived') NOT NULL DEFAULT 'active',
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_kd_org_code (organization_id, kpi_code),
    KEY idx_kd_org (organization_id),
    KEY idx_kd_owner_dept (owner_department_id),
    KEY idx_kd_owner_user (owner_user_id),
    KEY idx_kd_status (status),
    KEY idx_kd_freq (measurement_frequency),
    KEY idx_kd_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kpi_links (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    kpi_definition_id BIGINT UNSIGNED NOT NULL,
    link_entity_type ENUM('initiative','strategic_goal','operational_goal','department','task') NOT NULL,
    initiative_id BIGINT UNSIGNED NULL,
    strategic_goal_id BIGINT UNSIGNED NULL,
    operational_goal_id BIGINT UNSIGNED NULL,
    department_id BIGINT UNSIGNED NULL,
    task_id BIGINT UNSIGNED NULL,
    link_role ENUM('primary','secondary','supporting') NOT NULL DEFAULT 'primary',
    weight_percent DECIMAL(8,4) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    KEY idx_kl_org (organization_id),
    KEY idx_kl_kpi (kpi_definition_id),
    KEY idx_kl_type (link_entity_type),
    KEY idx_kl_init (initiative_id),
    KEY idx_kl_sg (strategic_goal_id),
    KEY idx_kl_og (operational_goal_id),
    KEY idx_kl_dept (department_id),
    KEY idx_kl_task (task_id),
    KEY idx_kl_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_kl_weight CHECK (weight_percent IS NULL OR (weight_percent >= 0 AND weight_percent <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kpi_targets (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    kpi_definition_id BIGINT UNSIGNED NOT NULL,
    period_type ENUM('month','quarter','semiannual','year','custom') NOT NULL,
    period_year SMALLINT UNSIGNED NOT NULL,
    period_no TINYINT UNSIGNED NULL,
    period_label VARCHAR(50) NULL,
    period_start DATE NULL,
    period_end DATE NULL,
    target_value DECIMAL(18,4) NOT NULL,
    threshold_green DECIMAL(18,4) NULL,
    threshold_amber DECIMAL(18,4) NULL,
    threshold_red DECIMAL(18,4) NULL,
    baseline_value DECIMAL(18,4) NULL,
    status ENUM('draft','active','locked','archived') NOT NULL DEFAULT 'active',
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_kt_org_kpi_period (organization_id, kpi_definition_id, period_type, period_year, period_no),
    KEY idx_kt_org (organization_id),
    KEY idx_kt_kpi (kpi_definition_id),
    KEY idx_kt_status (status),
    KEY idx_kt_dates (period_start, period_end),
    KEY idx_kt_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kpi_readings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    kpi_definition_id BIGINT UNSIGNED NOT NULL,
    kpi_target_id BIGINT UNSIGNED NULL,
    reading_date DATE NOT NULL,
    period_type ENUM('day','week','month','quarter','semiannual','year','custom') NOT NULL DEFAULT 'month',
    period_year SMALLINT UNSIGNED NULL,
    period_no TINYINT UNSIGNED NULL,
    actual_value DECIMAL(18,4) NULL,
    actual_text VARCHAR(255) NULL,
    variance_value DECIMAL(18,4) NULL,
    achievement_percent DECIMAL(9,4) NULL,
    status_color ENUM('green','amber','red','gray') NOT NULL DEFAULT 'gray',
    collection_method ENUM('manual','import','system','calculated') NOT NULL DEFAULT 'manual',
    source_reference_no VARCHAR(150) NULL,
    evidence_attachment_id BIGINT UNSIGNED NULL,
    entered_by BIGINT UNSIGNED NULL,
    reviewed_by BIGINT UNSIGNED NULL,
    reviewed_at DATETIME NULL,
    note TEXT NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    KEY idx_kr_org (organization_id),
    KEY idx_kr_kpi (kpi_definition_id),
    KEY idx_kr_target (kpi_target_id),
    KEY idx_kr_date (reading_date),
    KEY idx_kr_color (status_color),
    KEY idx_kr_entered_by (entered_by),
    KEY idx_kr_reviewed_by (reviewed_by),
    KEY idx_kr_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- FKs KPI
ALTER TABLE kpi_definitions
    ADD CONSTRAINT fk_kd_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_kd_owner_dept FOREIGN KEY (owner_department_id) REFERENCES departments(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_kd_owner_user FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_kd_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_kd_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE kpi_links
    ADD CONSTRAINT fk_kl_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_kl_kpi FOREIGN KEY (kpi_definition_id) REFERENCES kpi_definitions(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_kl_init FOREIGN KEY (initiative_id) REFERENCES initiatives(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_kl_sg FOREIGN KEY (strategic_goal_id) REFERENCES strategic_goals(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_kl_og FOREIGN KEY (operational_goal_id) REFERENCES operational_goals(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_kl_dept FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_kl_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_kl_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_kl_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE kpi_targets
    ADD CONSTRAINT fk_kt_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_kt_kpi FOREIGN KEY (kpi_definition_id) REFERENCES kpi_definitions(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_kt_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_kt_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE kpi_readings
    ADD CONSTRAINT fk_kr_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_kr_kpi FOREIGN KEY (kpi_definition_id) REFERENCES kpi_definitions(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_kr_target FOREIGN KEY (kpi_target_id) REFERENCES kpi_targets(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_kr_entered_by FOREIGN KEY (entered_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_kr_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL;
-- Optional:
-- ALTER TABLE kpi_readings ADD CONSTRAINT fk_kr_evidence FOREIGN KEY (evidence_attachment_id) REFERENCES attachments(id) ON DELETE SET NULL;

-- ============================================================
-- [3] RISK MODULE (INFERRED)
-- ============================================================

CREATE TABLE IF NOT EXISTS risk_register (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    risk_code VARCHAR(80) NOT NULL,
    title_ar VARCHAR(255) NOT NULL,
    title_en VARCHAR(255) NULL,
    description TEXT NOT NULL,
    risk_category ENUM('strategic','operational','financial','compliance','reputation','technical','hr','other')
        NOT NULL DEFAULT 'operational',
    likelihood_score TINYINT UNSIGNED NOT NULL,
    impact_score TINYINT UNSIGNED NOT NULL,
    risk_score INT UNSIGNED GENERATED ALWAYS AS (likelihood_score * impact_score) STORED,
    severity_level ENUM('low','medium','high','critical') NOT NULL DEFAULT 'medium',
    status ENUM('open','monitoring','mitigating','closed','accepted','transferred') NOT NULL DEFAULT 'open',
    treatment_strategy ENUM('mitigate','avoid','transfer','accept') NOT NULL DEFAULT 'mitigate',
    owner_department_id BIGINT UNSIGNED NULL,
    owner_user_id BIGINT UNSIGNED NULL,
    identified_date DATE NULL,
    review_due_date DATE NULL,
    closed_date DATE NULL,
    external_reference_no VARCHAR(150) NULL,
    note TEXT NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_rr_org_code (organization_id, risk_code),
    KEY idx_rr_org (organization_id),
    KEY idx_rr_category (risk_category),
    KEY idx_rr_status (status),
    KEY idx_rr_severity (severity_level),
    KEY idx_rr_owner_dept (owner_department_id),
    KEY idx_rr_owner_user (owner_user_id),
    KEY idx_rr_review_due (review_due_date),
    KEY idx_rr_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_rr_scores CHECK (
        likelihood_score BETWEEN 1 AND 5 AND impact_score BETWEEN 1 AND 5
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS risk_mitigations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    risk_id BIGINT UNSIGNED NOT NULL,
    mitigation_code VARCHAR(80) NULL,
    action_title_ar VARCHAR(255) NOT NULL,
    action_title_en VARCHAR(255) NULL,
    action_description TEXT NULL,
    action_type ENUM('preventive','detective','corrective','contingency') NOT NULL DEFAULT 'preventive',
    status ENUM('planned','in_progress','done','cancelled','deferred') NOT NULL DEFAULT 'planned',
    owner_user_id BIGINT UNSIGNED NULL,
    owner_department_id BIGINT UNSIGNED NULL,
    related_task_id BIGINT UNSIGNED NULL,
    due_date DATE NULL,
    completed_at DATETIME NULL,
    effectiveness_rating TINYINT UNSIGNED NULL,
    residual_likelihood_score TINYINT UNSIGNED NULL,
    residual_impact_score TINYINT UNSIGNED NULL,
    evidence_attachment_id BIGINT UNSIGNED NULL,
    note TEXT NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    KEY idx_rm_org (organization_id),
    KEY idx_rm_risk (risk_id),
    KEY idx_rm_status (status),
    KEY idx_rm_owner_user (owner_user_id),
    KEY idx_rm_owner_dept (owner_department_id),
    KEY idx_rm_task (related_task_id),
    KEY idx_rm_due (due_date),
    KEY idx_rm_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_rm_effectiveness CHECK (effectiveness_rating IS NULL OR effectiveness_rating BETWEEN 1 AND 5),
    CONSTRAINT chk_rm_residual_scores CHECK (
        (residual_likelihood_score IS NULL OR residual_likelihood_score BETWEEN 1 AND 5)
        AND (residual_impact_score IS NULL OR residual_impact_score BETWEEN 1 AND 5)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS risk_links (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    risk_id BIGINT UNSIGNED NOT NULL,
    link_entity_type ENUM('initiative','strategic_goal','operational_goal','task','kpi') NOT NULL,
    initiative_id BIGINT UNSIGNED NULL,
    strategic_goal_id BIGINT UNSIGNED NULL,
    operational_goal_id BIGINT UNSIGNED NULL,
    task_id BIGINT UNSIGNED NULL,
    kpi_definition_id BIGINT UNSIGNED NULL,
    link_role ENUM('source','affected','monitored_by','related') NOT NULL DEFAULT 'related',
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    note TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    KEY idx_rl_org (organization_id),
    KEY idx_rl_risk (risk_id),
    KEY idx_rl_type (link_entity_type),
    KEY idx_rl_init (initiative_id),
    KEY idx_rl_sg (strategic_goal_id),
    KEY idx_rl_og (operational_goal_id),
    KEY idx_rl_task (task_id),
    KEY idx_rl_kpi (kpi_definition_id),
    KEY idx_rl_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- FKs Risk
ALTER TABLE risk_register
    ADD CONSTRAINT fk_rr_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_rr_owner_dept FOREIGN KEY (owner_department_id) REFERENCES departments(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_rr_owner_user FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_rr_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_rr_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE risk_mitigations
    ADD CONSTRAINT fk_rm_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_rm_risk FOREIGN KEY (risk_id) REFERENCES risk_register(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_rm_owner_user FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_rm_owner_dept FOREIGN KEY (owner_department_id) REFERENCES departments(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_rm_task FOREIGN KEY (related_task_id) REFERENCES tasks(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_rm_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_rm_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;
-- Optional:
-- ALTER TABLE risk_mitigations ADD CONSTRAINT fk_rm_evidence FOREIGN KEY (evidence_attachment_id) REFERENCES attachments(id) ON DELETE SET NULL;

ALTER TABLE risk_links
    ADD CONSTRAINT fk_rl_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_rl_risk FOREIGN KEY (risk_id) REFERENCES risk_register(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_rl_init FOREIGN KEY (initiative_id) REFERENCES initiatives(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_rl_sg FOREIGN KEY (strategic_goal_id) REFERENCES strategic_goals(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_rl_og FOREIGN KEY (operational_goal_id) REFERENCES operational_goals(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_rl_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_rl_kpi FOREIGN KEY (kpi_definition_id) REFERENCES kpi_definitions(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_rl_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

-- ============================================================
-- [4] TASK–INITIATIVE LINKING ENHANCEMENTS (INFERRED)
-- ============================================================

CREATE TABLE IF NOT EXISTS task_initiative_links (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    task_id BIGINT UNSIGNED NOT NULL,
    initiative_id BIGINT UNSIGNED NOT NULL,
    link_role ENUM('primary','secondary','supporting') NOT NULL DEFAULT 'primary',
    linked_by BIGINT UNSIGNED NULL,
    linked_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note TEXT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_til_task_initiative (task_id, initiative_id),
    KEY idx_til_org (organization_id),
    KEY idx_til_task (task_id),
    KEY idx_til_init (initiative_id),
    KEY idx_til_role (link_role),
    KEY idx_til_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE task_initiative_links
    ADD CONSTRAINT fk_til_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_til_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_til_init FOREIGN KEY (initiative_id) REFERENCES initiatives(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_til_linked_by FOREIGN KEY (linked_by) REFERENCES users(id) ON DELETE SET NULL;

-- ============================================================
-- [5] NONPROFIT FINANCE FOLLOW-UP MODULE (INFERRED)
-- ============================================================

CREATE TABLE IF NOT EXISTS donors (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    donor_code VARCHAR(80) NOT NULL,
    donor_type ENUM('individual','institution','company','government','waqf','other') NOT NULL DEFAULT 'individual',
    name_ar VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NULL,
    mobile VARCHAR(30) NULL,
    email VARCHAR(255) NULL,
    city VARCHAR(100) NULL,
    country VARCHAR(100) NULL,
    national_id VARCHAR(30) NULL,
    tax_no VARCHAR(50) NULL,
    status ENUM('active','inactive','blacklisted','archived') NOT NULL DEFAULT 'active',
    preferred_channel ENUM('phone','whatsapp','email','sms','visit','other') NULL,
    assigned_employee_user_id BIGINT UNSIGNED NULL,
    note TEXT NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_donor_org_code (organization_id, donor_code),
    KEY idx_donor_org (organization_id),
    KEY idx_donor_type (donor_type),
    KEY idx_donor_status (status),
    KEY idx_donor_mobile (mobile),
    KEY idx_donor_email (email),
    KEY idx_donor_assigned_user (assigned_employee_user_id),
    KEY idx_donor_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS donor_contacts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    donor_id BIGINT UNSIGNED NOT NULL,
    contact_name VARCHAR(255) NOT NULL,
    job_title VARCHAR(150) NULL,
    mobile VARCHAR(30) NULL,
    email VARCHAR(255) NULL,
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    status ENUM('active','inactive') NOT NULL DEFAULT 'active',
    note TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    KEY idx_dc_org (organization_id),
    KEY idx_dc_donor (donor_id),
    KEY idx_dc_primary (is_primary),
    KEY idx_dc_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS funds (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    fund_code VARCHAR(80) NOT NULL,
    name_ar VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NULL,
    fund_type ENUM('unrestricted','restricted','zakat','waqf','seasonal','project','other')
        NOT NULL DEFAULT 'unrestricted',
    currency_code CHAR(3) NOT NULL DEFAULT 'SAR',
    status ENUM('active','inactive','closed','archived') NOT NULL DEFAULT 'active',
    start_date DATE NULL,
    end_date DATE NULL,
    note TEXT NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_fund_org_code (organization_id, fund_code),
    KEY idx_fund_org (organization_id),
    KEY idx_fund_type (fund_type),
    KEY idx_fund_status (status),
    KEY idx_fund_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pledges (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    pledge_code VARCHAR(80) NOT NULL,
    donor_id BIGINT UNSIGNED NOT NULL,
    fund_id BIGINT UNSIGNED NULL,
    initiative_id BIGINT UNSIGNED NULL,
    amount_pledged DECIMAL(18,2) NOT NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'SAR',
    pledge_date DATE NOT NULL,
    expected_collection_date DATE NULL,
    status ENUM('draft','active','partially_collected','collected','cancelled','expired') NOT NULL DEFAULT 'active',
    external_reference_no VARCHAR(150) NULL,
    note TEXT NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_pledge_org_code (organization_id, pledge_code),
    KEY idx_pledge_org (organization_id),
    KEY idx_pledge_donor (donor_id),
    KEY idx_pledge_fund (fund_id),
    KEY idx_pledge_init (initiative_id),
    KEY idx_pledge_status (status),
    KEY idx_pledge_dates (pledge_date, expected_collection_date),
    KEY idx_pledge_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_pledge_amount CHECK (amount_pledged >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS donations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    donation_code VARCHAR(80) NOT NULL,
    donor_id BIGINT UNSIGNED NOT NULL,
    pledge_id BIGINT UNSIGNED NULL,
    fund_id BIGINT UNSIGNED NULL,
    initiative_id BIGINT UNSIGNED NULL,
    amount DECIMAL(18,2) NOT NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'SAR',
    donation_date DATE NOT NULL,
    payment_channel ENUM('cash','bank_transfer','online','mada','visa','apple_pay','check','other')
        NULL,
    status ENUM('draft','recorded','confirmed','cancelled','refunded','closed') NOT NULL DEFAULT 'recorded',
    external_reference VARCHAR(150) NULL,
    external_reference_no VARCHAR(150) NULL,
    external_system_name VARCHAR(100) NULL,
    followup_status ENUM(
        'new','pending_confirmation','confirmed','partially_realized',
        'realized','cancelled','refunded','closed'
    ) NOT NULL DEFAULT 'new',
    last_followup_at DATETIME NULL,
    finance_transaction_id BIGINT UNSIGNED NULL,
    reference_no VARCHAR(100) NULL,
    note TEXT NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_donation_org_code (organization_id, donation_code),
    KEY idx_donation_org (organization_id),
    KEY idx_donation_donor (donor_id),
    KEY idx_donation_pledge (pledge_id),
    KEY idx_donation_fund (fund_id),
    KEY idx_donation_init (initiative_id),
    KEY idx_donation_date (donation_date),
    KEY idx_donation_status (status),
    KEY idx_donation_fin_tx (finance_transaction_id),
    KEY idx_donation_external_reference_no (external_reference_no),
    KEY idx_donation_external_system_name (external_system_name),
    KEY idx_donation_followup_status (followup_status),
    KEY idx_donation_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_donation_amount CHECK (amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS collections (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    collection_code VARCHAR(80) NOT NULL,
    donation_id BIGINT UNSIGNED NULL,
    pledge_id BIGINT UNSIGNED NULL,
    donor_id BIGINT UNSIGNED NULL,
    fund_id BIGINT UNSIGNED NULL,
    amount_collected DECIMAL(18,2) NOT NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'SAR',
    collection_date DATE NOT NULL,
    status ENUM('recorded','confirmed','cancelled','adjusted','closed') NOT NULL DEFAULT 'recorded',
    reference_no VARCHAR(100) NULL,
    external_reference_no VARCHAR(150) NULL,
    external_system_name VARCHAR(100) NULL,
    reconciliation_status ENUM(
        'not_checked','matched','partially_matched','mismatch','recheck_required'
    ) NOT NULL DEFAULT 'not_checked',
    matched_at DATETIME NULL,
    last_followup_at DATETIME NULL,
    finance_transaction_id BIGINT UNSIGNED NULL,
    note TEXT NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_collection_org_code (organization_id, collection_code),
    KEY idx_collection_org (organization_id),
    KEY idx_collection_donation (donation_id),
    KEY idx_collection_pledge (pledge_id),
    KEY idx_collection_donor (donor_id),
    KEY idx_collection_fund (fund_id),
    KEY idx_collection_date (collection_date),
    KEY idx_collection_status (status),
    KEY idx_collection_fin_tx (finance_transaction_id),
    KEY idx_collection_external_reference_no (external_reference_no),
    KEY idx_collection_external_system_name (external_system_name),
    KEY idx_collection_reconciliation_status (reconciliation_status),
    KEY idx_collection_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_collection_amount CHECK (amount_collected >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS donor_interactions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    donor_id BIGINT UNSIGNED NOT NULL,
    donor_contact_id BIGINT UNSIGNED NULL,
    interaction_type ENUM('call','whatsapp','email','visit','meeting','sms','campaign','other')
        NOT NULL DEFAULT 'call',
    interaction_date DATETIME NOT NULL,
    subject VARCHAR(255) NULL,
    summary TEXT NULL,
    outcome_status ENUM('open','followup_required','completed','no_response','declined','positive')
        NOT NULL DEFAULT 'open',
    next_followup_at DATETIME NULL,
    assigned_to_user_id BIGINT UNSIGNED NULL,
    external_reference_no VARCHAR(150) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    KEY idx_di_org (organization_id),
    KEY idx_di_donor (donor_id),
    KEY idx_di_contact (donor_contact_id),
    KEY idx_di_type (interaction_type),
    KEY idx_di_date (interaction_date),
    KEY idx_di_outcome (outcome_status),
    KEY idx_di_assigned (assigned_to_user_id),
    KEY idx_di_next_followup (next_followup_at),
    KEY idx_di_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS donation_allocations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    donation_id BIGINT UNSIGNED NULL,
    collection_id BIGINT UNSIGNED NULL,
    allocation_id BIGINT UNSIGNED NULL,
    initiative_id BIGINT UNSIGNED NULL,
    fund_id BIGINT UNSIGNED NULL,
    amount_allocated DECIMAL(18,2) NOT NULL,
    allocation_date DATE NOT NULL,
    status ENUM('draft','allocated','reversed','closed') NOT NULL DEFAULT 'allocated',
    external_reference_no VARCHAR(150) NULL,
    note TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    KEY idx_da_org (organization_id),
    KEY idx_da_donation (donation_id),
    KEY idx_da_collection (collection_id),
    KEY idx_da_allocation (allocation_id),
    KEY idx_da_init (initiative_id),
    KEY idx_da_fund (fund_id),
    KEY idx_da_date (allocation_date),
    KEY idx_da_status (status),
    KEY idx_da_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_da_amount CHECK (amount_allocated >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- FKs Finance
ALTER TABLE donors
    ADD CONSTRAINT fk_donor_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_donor_assigned_user FOREIGN KEY (assigned_employee_user_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_donor_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_donor_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE donor_contacts
    ADD CONSTRAINT fk_dc_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_dc_donor FOREIGN KEY (donor_id) REFERENCES donors(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_dc_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_dc_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE funds
    ADD CONSTRAINT fk_fund_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_fund_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_fund_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE pledges
    ADD CONSTRAINT fk_pledge_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_pledge_donor FOREIGN KEY (donor_id) REFERENCES donors(id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_pledge_fund FOREIGN KEY (fund_id) REFERENCES funds(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_pledge_init FOREIGN KEY (initiative_id) REFERENCES initiatives(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_pledge_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_pledge_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE donations
    ADD CONSTRAINT fk_donation_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_donation_donor FOREIGN KEY (donor_id) REFERENCES donors(id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_donation_pledge FOREIGN KEY (pledge_id) REFERENCES pledges(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_donation_fund FOREIGN KEY (fund_id) REFERENCES funds(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_donation_init FOREIGN KEY (initiative_id) REFERENCES initiatives(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_donation_fin_tx FOREIGN KEY (finance_transaction_id) REFERENCES finance_transactions(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_donation_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_donation_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE collections
    ADD CONSTRAINT fk_collection_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_collection_donation FOREIGN KEY (donation_id) REFERENCES donations(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_collection_pledge FOREIGN KEY (pledge_id) REFERENCES pledges(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_collection_donor FOREIGN KEY (donor_id) REFERENCES donors(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_collection_fund FOREIGN KEY (fund_id) REFERENCES funds(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_collection_fin_tx FOREIGN KEY (finance_transaction_id) REFERENCES finance_transactions(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_collection_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_collection_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE donor_interactions
    ADD CONSTRAINT fk_di_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_di_donor FOREIGN KEY (donor_id) REFERENCES donors(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_di_contact FOREIGN KEY (donor_contact_id) REFERENCES donor_contacts(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_di_assigned_user FOREIGN KEY (assigned_to_user_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_di_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_di_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE donation_allocations
    ADD CONSTRAINT fk_da_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_da_donation FOREIGN KEY (donation_id) REFERENCES donations(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_da_collection FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_da_allocation FOREIGN KEY (allocation_id) REFERENCES allocations(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_da_init FOREIGN KEY (initiative_id) REFERENCES initiatives(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_da_fund FOREIGN KEY (fund_id) REFERENCES funds(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_da_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_da_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

-- ============================================================
-- [6] INVENTORY FOLLOW-UP REQUESTS MODULE (FOLLOW-UP ONLY)
-- ============================================================

CREATE TABLE IF NOT EXISTS item_categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    parent_id BIGINT UNSIGNED NULL,
    category_code VARCHAR(60) NOT NULL,
    name_ar VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NULL,
    description TEXT NULL,
    sort_order INT UNSIGNED NOT NULL DEFAULT 0,
    status ENUM('active','inactive','archived') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_ic_org_code (organization_id, category_code),
    UNIQUE KEY uk_ic_org_name_ar (organization_id, name_ar),
    KEY idx_ic_org (organization_id),
    KEY idx_ic_parent (parent_id),
    KEY idx_ic_status (status),
    KEY idx_ic_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS units_of_measure (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    unit_code VARCHAR(30) NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    name_en VARCHAR(100) NULL,
    symbol VARCHAR(20) NULL,
    decimals_allowed TINYINT(1) NOT NULL DEFAULT 0,
    status ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_uom_org_code (organization_id, unit_code),
    UNIQUE KEY uk_uom_org_name_ar (organization_id, name_ar),
    KEY idx_uom_org (organization_id),
    KEY idx_uom_status (status),
    KEY idx_uom_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    item_code VARCHAR(80) NOT NULL,
    sku VARCHAR(100) NULL,
    barcode VARCHAR(100) NULL,
    category_id BIGINT UNSIGNED NULL,
    base_uom_id BIGINT UNSIGNED NOT NULL,
    name_ar VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NULL,
    description TEXT NULL,
    item_type ENUM('stock','consumable','asset','service','in_kind_package','other') NOT NULL DEFAULT 'stock',
    tracking_type ENUM('none','batch','serial','expiry') NOT NULL DEFAULT 'none',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    is_donatable TINYINT(1) NOT NULL DEFAULT 0,
    is_distributable TINYINT(1) NOT NULL DEFAULT 1,
    requires_approval TINYINT(1) NOT NULL DEFAULT 0,
    reorder_level DECIMAL(16,4) NULL,
    max_stock_level DECIMAL(16,4) NULL,
    standard_cost DECIMAL(14,4) NULL,
    currency_code CHAR(3) NULL DEFAULT 'SAR',
    preferred_vendor_id BIGINT UNSIGNED NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_item_org_code (organization_id, item_code),
    UNIQUE KEY uk_item_org_sku (organization_id, sku),
    UNIQUE KEY uk_item_org_barcode (organization_id, barcode),
    KEY idx_item_org (organization_id),
    KEY idx_item_category (category_id),
    KEY idx_item_uom (base_uom_id),
    KEY idx_item_vendor (preferred_vendor_id),
    KEY idx_item_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_item_stock_levels CHECK (
        (reorder_level IS NULL OR reorder_level >= 0)
        AND (max_stock_level IS NULL OR max_stock_level >= 0)
        AND (standard_cost IS NULL OR standard_cost >= 0)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS warehouses (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    warehouse_code VARCHAR(60) NOT NULL,
    name_ar VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NULL,
    warehouse_type ENUM('main','branch','mobile','temporary','program','other') NOT NULL DEFAULT 'main',
    department_id BIGINT UNSIGNED NULL,
    manager_user_id BIGINT UNSIGNED NULL,
    country VARCHAR(100) NULL,
    city VARCHAR(100) NULL,
    address TEXT NULL,
    is_default TINYINT(1) NOT NULL DEFAULT 0,
    allows_negative_stock TINYINT(1) NOT NULL DEFAULT 0,
    status ENUM('active','inactive','closed','archived') NOT NULL DEFAULT 'active',
    notes TEXT NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_wh_org_code (organization_id, warehouse_code),
    UNIQUE KEY uk_wh_org_name_ar (organization_id, name_ar),
    KEY idx_wh_org (organization_id),
    KEY idx_wh_dept (department_id),
    KEY idx_wh_manager (manager_user_id),
    KEY idx_wh_status (status),
    KEY idx_wh_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS initiative_stock_requests (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    request_code VARCHAR(80) NOT NULL,
    external_request_ref VARCHAR(150) NULL,
    external_issue_ref VARCHAR(150) NULL,
    initiative_id BIGINT UNSIGNED NOT NULL,
    task_id BIGINT UNSIGNED NULL,
    requester_user_id BIGINT UNSIGNED NOT NULL,
    requester_department_id BIGINT UNSIGNED NULL,
    preferred_warehouse_id BIGINT UNSIGNED NULL,
    need_by_date DATE NULL,
    request_date DATE NOT NULL,
    priority ENUM('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
    status ENUM('draft','submitted','under_review','approved','partially_issued','issued','rejected','cancelled') NOT NULL DEFAULT 'draft',
    external_status_text VARCHAR(255) NULL,
    followup_status ENUM('not_sent','sent_to_external','acknowledged','in_process','partially_fulfilled','fulfilled','rejected','cancelled','closed')
        NOT NULL DEFAULT 'not_sent',
    last_followup_at DATETIME NULL,
    approved_by BIGINT UNSIGNED NULL,
    approved_at DATETIME NULL,
    rejection_reason TEXT NULL,
    note TEXT NULL,
    external_note TEXT NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_isr_org_code (organization_id, request_code),
    KEY idx_isr_org (organization_id),
    KEY idx_isr_init (initiative_id),
    KEY idx_isr_task (task_id),
    KEY idx_isr_requester (requester_user_id),
    KEY idx_isr_req_dept (requester_department_id),
    KEY idx_isr_wh (preferred_warehouse_id),
    KEY idx_isr_status (status),
    KEY idx_isr_followup_status (followup_status),
    KEY idx_isr_external_request_ref (external_request_ref),
    KEY idx_isr_external_issue_ref (external_issue_ref),
    KEY idx_isr_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS initiative_stock_request_lines (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    request_id BIGINT UNSIGNED NOT NULL,
    item_id BIGINT UNSIGNED NOT NULL,
    uom_id BIGINT UNSIGNED NOT NULL,
    requested_qty DECIMAL(16,4) NOT NULL,
    approved_qty DECIMAL(16,4) NULL,
    issued_qty DECIMAL(16,4) NOT NULL DEFAULT 0.0000,
    purpose_text VARCHAR(255) NULL,
    note TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_isrl_request_item (request_id, item_id),
    KEY idx_isrl_org (organization_id),
    KEY idx_isrl_request (request_id),
    KEY idx_isrl_item (item_id),
    KEY idx_isrl_uom (uom_id),
    KEY idx_isrl_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_isrl_qtys CHECK (
        requested_qty > 0
        AND (approved_qty IS NULL OR approved_qty >= 0)
        AND issued_qty >= 0
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE item_categories
    ADD CONSTRAINT fk_ic_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_ic_parent FOREIGN KEY (parent_id) REFERENCES item_categories(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_ic_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_ic_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE units_of_measure
    ADD CONSTRAINT fk_uom_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_uom_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_uom_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE items
    ADD CONSTRAINT fk_item_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_item_category FOREIGN KEY (category_id) REFERENCES item_categories(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_item_uom FOREIGN KEY (base_uom_id) REFERENCES units_of_measure(id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_item_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_item_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;
-- Optional if vendors exists:
-- ALTER TABLE items ADD CONSTRAINT fk_item_vendor FOREIGN KEY (preferred_vendor_id) REFERENCES vendors(id) ON DELETE SET NULL;

ALTER TABLE warehouses
    ADD CONSTRAINT fk_wh_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wh_dept FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wh_manager FOREIGN KEY (manager_user_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wh_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wh_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE initiative_stock_requests
    ADD CONSTRAINT fk_isr_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_isr_init FOREIGN KEY (initiative_id) REFERENCES initiatives(id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_isr_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_isr_requester FOREIGN KEY (requester_user_id) REFERENCES users(id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_isr_req_dept FOREIGN KEY (requester_department_id) REFERENCES departments(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_isr_wh FOREIGN KEY (preferred_warehouse_id) REFERENCES warehouses(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_isr_approved_by FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_isr_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_isr_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE initiative_stock_request_lines
    ADD CONSTRAINT fk_isrl_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_isrl_request FOREIGN KEY (request_id) REFERENCES initiative_stock_requests(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_isrl_item FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_isrl_uom FOREIGN KEY (uom_id) REFERENCES units_of_measure(id) ON DELETE RESTRICT;

-- ============================================================
-- [7] WORKFLOW & APPROVALS MODULE
-- ============================================================

CREATE TABLE IF NOT EXISTS workflow_definitions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    workflow_code VARCHAR(80) NOT NULL,
    name_ar VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NULL,
    description TEXT NULL,
    entity_type VARCHAR(100) NOT NULL,
    version_no INT UNSIGNED NOT NULL DEFAULT 1,
    trigger_mode ENUM('manual','on_create','on_status_change','scheduled','api') NOT NULL DEFAULT 'manual',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    is_default TINYINT(1) NOT NULL DEFAULT 0,
    allow_parallel_steps TINYINT(1) NOT NULL DEFAULT 0,
    allow_delegation TINYINT(1) NOT NULL DEFAULT 1,
    allow_return_back TINYINT(1) NOT NULL DEFAULT 1,
    auto_close_on_final_approval TINYINT(1) NOT NULL DEFAULT 1,
    conditions_json JSON NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_wd_org_code_ver (organization_id, workflow_code, version_no),
    KEY idx_wd_org (organization_id),
    KEY idx_wd_entity (entity_type),
    KEY idx_wd_active (is_active),
    KEY idx_wd_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS workflow_definition_steps (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    workflow_definition_id BIGINT UNSIGNED NOT NULL,
    step_code VARCHAR(80) NOT NULL,
    step_name_ar VARCHAR(255) NOT NULL,
    step_name_en VARCHAR(255) NULL,
    step_order INT UNSIGNED NOT NULL,
    step_type ENUM('approval','review','verification','data_entry','notification','finalization') NOT NULL DEFAULT 'approval',
    approval_mode ENUM('any_one','all','majority','sequence') NOT NULL DEFAULT 'any_one',
    min_approvals_required INT UNSIGNED NULL,
    is_mandatory TINYINT(1) NOT NULL DEFAULT 1,
    is_final_step TINYINT(1) NOT NULL DEFAULT 0,
    sla_hours INT UNSIGNED NULL,
    escalation_after_hours INT UNSIGNED NULL,
    can_approve TINYINT(1) NOT NULL DEFAULT 1,
    can_reject TINYINT(1) NOT NULL DEFAULT 1,
    can_return_for_edit TINYINT(1) NOT NULL DEFAULT 1,
    can_comment_only TINYINT(1) NOT NULL DEFAULT 1,
    can_delegate TINYINT(1) NOT NULL DEFAULT 1,
    entry_conditions_json JSON NULL,
    exit_conditions_json JSON NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_wds_wf_step_code (workflow_definition_id, step_code),
    UNIQUE KEY uk_wds_wf_step_order (workflow_definition_id, step_order),
    KEY idx_wds_org (organization_id),
    KEY idx_wds_wf (workflow_definition_id),
    KEY idx_wds_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_wds_orders CHECK (step_order >= 1),
    CONSTRAINT chk_wds_min_approvals CHECK (min_approvals_required IS NULL OR min_approvals_required >= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS workflow_step_assignees (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    workflow_definition_step_id BIGINT UNSIGNED NOT NULL,
    assignee_type ENUM('user','department','role_code') NOT NULL,
    user_id BIGINT UNSIGNED NULL,
    department_id BIGINT UNSIGNED NULL,
    role_code VARCHAR(100) NULL,
    assignment_mode ENUM('required','optional','backup','escalation') NOT NULL DEFAULT 'required',
    sort_order INT UNSIGNED NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    KEY idx_wsa_org (organization_id),
    KEY idx_wsa_step (workflow_definition_step_id),
    KEY idx_wsa_user (user_id),
    KEY idx_wsa_dept (department_id),
    KEY idx_wsa_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_wsa_target CHECK (
        (assignee_type='user' AND user_id IS NOT NULL AND department_id IS NULL AND role_code IS NULL)
        OR (assignee_type='department' AND department_id IS NOT NULL AND user_id IS NULL AND role_code IS NULL)
        OR (assignee_type='role_code' AND role_code IS NOT NULL AND user_id IS NULL AND department_id IS NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS workflow_instances (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    instance_code VARCHAR(100) NOT NULL,
    workflow_definition_id BIGINT UNSIGNED NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id BIGINT UNSIGNED NOT NULL,
    entity_code VARCHAR(100) NULL,
    title_snapshot VARCHAR(255) NULL,
    payload_snapshot_json JSON NULL,
    current_step_id BIGINT UNSIGNED NULL,
    current_status ENUM('draft','running','waiting_action','approved','rejected','returned','cancelled','expired','closed')
        NOT NULL DEFAULT 'draft',
    started_at DATETIME NULL,
    due_at DATETIME NULL,
    closed_at DATETIME NULL,
    initiated_by BIGINT UNSIGNED NULL,
    final_decision_by BIGINT UNSIGNED NULL,
    final_decision_note TEXT NULL,
    priority ENUM('low','medium','high','critical') NOT NULL DEFAULT 'medium',
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_wi_org_instance_code (organization_id, instance_code),
    KEY idx_wi_org (organization_id),
    KEY idx_wi_wf (workflow_definition_id),
    KEY idx_wi_entity (entity_type, entity_id),
    KEY idx_wi_status (current_status),
    KEY idx_wi_current_step (current_step_id),
    KEY idx_wi_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS workflow_instance_steps (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    workflow_instance_id BIGINT UNSIGNED NOT NULL,
    workflow_definition_step_id BIGINT UNSIGNED NOT NULL,
    step_order INT UNSIGNED NOT NULL,
    step_name_ar VARCHAR(255) NOT NULL,
    step_type ENUM('approval','review','verification','data_entry','notification','finalization') NOT NULL DEFAULT 'approval',
    status ENUM('pending','active','waiting','approved','rejected','returned','skipped','cancelled','expired')
        NOT NULL DEFAULT 'pending',
    assigned_to_user_id BIGINT UNSIGNED NULL,
    assigned_to_department_id BIGINT UNSIGNED NULL,
    assigned_role_code VARCHAR(100) NULL,
    started_at DATETIME NULL,
    due_at DATETIME NULL,
    acted_at DATETIME NULL,
    approvals_received INT UNSIGNED NOT NULL DEFAULT 0,
    approvals_required INT UNSIGNED NULL,
    action_summary ENUM('none','approved','rejected','returned','skipped','expired') NOT NULL DEFAULT 'none',
    action_note TEXT NULL,
    escalation_level INT UNSIGNED NOT NULL DEFAULT 0,
    escalated_at DATETIME NULL,
    metadata_json JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    KEY idx_wis_org (organization_id),
    KEY idx_wis_instance (workflow_instance_id),
    KEY idx_wis_def_step (workflow_definition_step_id),
    KEY idx_wis_status (status),
    KEY idx_wis_due_at (due_at),
    KEY idx_wis_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS workflow_actions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    workflow_instance_id BIGINT UNSIGNED NOT NULL,
    workflow_instance_step_id BIGINT UNSIGNED NULL,
    action_type ENUM('submit','approve','reject','return_for_edit','comment','assign','delegate','cancel','reopen','escalate','expire','system_transition')
        NOT NULL,
    actor_user_id BIGINT UNSIGNED NULL,
    actor_department_id BIGINT UNSIGNED NULL,
    from_status VARCHAR(50) NULL,
    to_status VARCHAR(50) NULL,
    decision_note TEXT NULL,
    action_payload_json JSON NULL,
    attachment_id BIGINT UNSIGNED NULL,
    action_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(64) NULL,
    user_agent VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    KEY idx_wa_org (organization_id),
    KEY idx_wa_instance (workflow_instance_id),
    KEY idx_wa_step (workflow_instance_step_id),
    KEY idx_wa_actor_user (actor_user_id),
    KEY idx_wa_action_at (action_at),
    KEY idx_wa_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS workflow_delegations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    delegator_user_id BIGINT UNSIGNED NOT NULL,
    delegate_user_id BIGINT UNSIGNED NOT NULL,
    entity_type VARCHAR(100) NULL,
    workflow_code VARCHAR(80) NULL,
    valid_from DATETIME NOT NULL,
    valid_to DATETIME NOT NULL,
    reason TEXT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    updated_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    KEY idx_wdleg_org (organization_id),
    KEY idx_wdleg_delegator (delegator_user_id),
    KEY idx_wdleg_delegate (delegate_user_id),
    KEY idx_wdleg_active (is_active),
    KEY idx_wdleg_validity (valid_from, valid_to),
    KEY idx_wdleg_demo (demo_marker, demo_dataset_id),
    CONSTRAINT chk_wdleg_dates CHECK (valid_to >= valid_from)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS workflow_watchers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id BIGINT UNSIGNED NOT NULL,
    workflow_instance_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    watch_role ENUM('observer','notified','cc','auditor') NOT NULL DEFAULT 'observer',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    demo_marker TINYINT(1) NOT NULL DEFAULT 0,
    demo_dataset_id VARCHAR(50) NULL,
    UNIQUE KEY uk_ww_instance_user (workflow_instance_id, user_id),
    KEY idx_ww_org (organization_id),
    KEY idx_ww_user (user_id),
    KEY idx_ww_demo (demo_marker, demo_dataset_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE workflow_definitions
    ADD CONSTRAINT fk_wdef_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wdef_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wdef_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE workflow_definition_steps
    ADD CONSTRAINT fk_wds_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wds_wf FOREIGN KEY (workflow_definition_id) REFERENCES workflow_definitions(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wds_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wds_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE workflow_step_assignees
    ADD CONSTRAINT fk_wsa_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wsa_step FOREIGN KEY (workflow_definition_step_id) REFERENCES workflow_definition_steps(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wsa_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wsa_dept FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wsa_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wsa_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE workflow_instances
    ADD CONSTRAINT fk_wi_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wi_wf FOREIGN KEY (workflow_definition_id) REFERENCES workflow_definitions(id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_wi_initiated_by FOREIGN KEY (initiated_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wi_final_decision_by FOREIGN KEY (final_decision_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wi_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wi_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE workflow_instance_steps
    ADD CONSTRAINT fk_wis_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wis_instance FOREIGN KEY (workflow_instance_id) REFERENCES workflow_instances(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wis_def_step FOREIGN KEY (workflow_definition_step_id) REFERENCES workflow_definition_steps(id) ON DELETE RESTRICT,
    ADD CONSTRAINT fk_wis_user FOREIGN KEY (assigned_to_user_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wis_dept FOREIGN KEY (assigned_to_department_id) REFERENCES departments(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wis_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wis_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE workflow_actions
    ADD CONSTRAINT fk_wa_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wa_instance FOREIGN KEY (workflow_instance_id) REFERENCES workflow_instances(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wa_step FOREIGN KEY (workflow_instance_step_id) REFERENCES workflow_instance_steps(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wa_actor_user FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wa_actor_dept FOREIGN KEY (actor_department_id) REFERENCES departments(id) ON DELETE SET NULL;

ALTER TABLE workflow_delegations
    ADD CONSTRAINT fk_wdleg_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wdleg_delegator FOREIGN KEY (delegator_user_id) REFERENCES users(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wdleg_delegate FOREIGN KEY (delegate_user_id) REFERENCES users(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_wdleg_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_wdleg_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE workflow_watchers
    ADD CONSTRAINT fk_ww_org FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_ww_instance FOREIGN KEY (workflow_instance_id) REFERENCES workflow_instances(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_ww_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_ww_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

-- Deferred circular FK
ALTER TABLE workflow_instances
    ADD CONSTRAINT fk_wi_current_step FOREIGN KEY (current_step_id) REFERENCES workflow_instance_steps(id) ON DELETE SET NULL;

-- Optional if attachments exists:
-- ALTER TABLE workflow_actions ADD CONSTRAINT fk_wa_attachment FOREIGN KEY (attachment_id) REFERENCES attachments(id) ON DELETE SET NULL;

-- ============================================================
-- [8] POSTCHECK
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

SELECT c.table_name, c.column_name
FROM information_schema.columns c
WHERE c.table_schema = DATABASE()
  AND (
    (c.table_name='donations' AND c.column_name IN ('external_reference_no','external_system_name','followup_status','last_followup_at'))
    OR
    (c.table_name='collections' AND c.column_name IN ('external_reference_no','external_system_name','reconciliation_status','matched_at','last_followup_at'))
    OR
    (c.table_name='initiative_stock_requests' AND c.column_name IN ('external_request_ref','external_issue_ref','followup_status'))
  )
ORDER BY c.table_name, c.column_name;

/* ============================================================
   EXCLUDED TABLES (APPROVED SCOPE)
   - warehouse_bins / stock_movements / stock_counts / initiative_stock_issues / stock_reservations
   - external_systems / integration_* / webhooks
   - persons / person_roles / employee_profiles / fundraiser_profiles / trainee_profiles / beneficiary_profiles
   ============================================================ */


-- ============================================================
-- [OPTIONAL] MINIMAL DEMO SEED (COMMENTED)
-- Purpose: quick smoke test for links/FKs in a sandbox.
-- IMPORTANT: Requires existing core rows in:
-- organizations(id), users(id), departments(id), initiatives(id), tasks(id)
-- Review IDs before enabling.
-- ============================================================
/*
-- Example IDs (CHANGE THESE)
SET @org_id = 1;
SET @user_id = 1;
SET @dept_id = 1;
SET @initiative_id = 1;
SET @task_id = 1;

-- Strategic
INSERT INTO strategic_axes (organization_id, axis_code, name_ar, sort_order, created_by)
VALUES (@org_id, 'AX-001', 'المحور المؤسسي', 1, @user_id);

SET @axis_id = LAST_INSERT_ID();

INSERT INTO strategic_goals (organization_id, axis_id, goal_code, title_ar, priority, owner_department_id, created_by)
VALUES (@org_id, @axis_id, 'SG-001', 'رفع كفاءة التشغيل', 'high', @dept_id, @user_id);

SET @sg_id = LAST_INSERT_ID();

INSERT INTO operational_goals (organization_id, strategic_goal_id, op_goal_code, title_ar, owner_department_id, owner_user_id, created_by)
VALUES (@org_id, @sg_id, 'OG-001', 'تقليل زمن الإنجاز', @dept_id, @user_id, @user_id);

SET @og_id = LAST_INSERT_ID();

INSERT INTO initiative_goal_links (organization_id, initiative_id, strategic_goal_id, operational_goal_id, contribution_type, contribution_weight, created_by)
VALUES (@org_id, @initiative_id, @sg_id, @og_id, 'primary', 100, @user_id);

-- KPI
INSERT INTO kpi_definitions (organization_id, kpi_code, name_ar, kpi_type, unit_type, owner_department_id, owner_user_id, created_by)
VALUES (@org_id, 'KPI-001', 'نسبة الإنجاز', 'performance', 'percent', @dept_id, @user_id, @user_id);

SET @kpi_id = LAST_INSERT_ID();

INSERT INTO kpi_links (organization_id, kpi_definition_id, link_entity_type, operational_goal_id, link_role, weight_percent, created_by)
VALUES (@org_id, @kpi_id, 'operational_goal', @og_id, 'primary', 100, @user_id);

INSERT INTO kpi_targets (organization_id, kpi_definition_id, period_type, period_year, period_no, target_value, created_by)
VALUES (@org_id, @kpi_id, 'quarter', YEAR(CURDATE()), 1, 85, @user_id);

SET @kpi_target_id = LAST_INSERT_ID();

INSERT INTO kpi_readings (organization_id, kpi_definition_id, kpi_target_id, reading_date, period_type, actual_value, achievement_percent, status_color, entered_by)
VALUES (@org_id, @kpi_id, @kpi_target_id, CURDATE(), 'quarter', 78, 91.7647, 'amber', @user_id);

-- Risk
INSERT INTO risk_register (organization_id, risk_code, title_ar, description, risk_category, likelihood_score, impact_score, severity_level, owner_department_id, owner_user_id, created_by)
VALUES (@org_id, 'RISK-001', 'تأخر تنفيذ المبادرة', 'احتمال تأخر زمني يؤثر على المستهدفات', 'operational', 3, 4, 'high', @dept_id, @user_id, @user_id);

SET @risk_id = LAST_INSERT_ID();

INSERT INTO risk_mitigations (organization_id, risk_id, action_title_ar, action_type, status, owner_user_id, owner_department_id, related_task_id, created_by)
VALUES (@org_id, @risk_id, 'خطة متابعة أسبوعية', 'preventive', 'planned', @user_id, @dept_id, @task_id, @user_id);

INSERT INTO risk_links (organization_id, risk_id, link_entity_type, initiative_id, link_role, is_primary, created_by)
VALUES (@org_id, @risk_id, 'initiative', @initiative_id, 'affected', 1, @user_id);

-- Finance Follow-up
INSERT INTO donors (organization_id, donor_code, donor_type, name_ar, mobile, status, assigned_employee_user_id, created_by)
VALUES (@org_id, 'DON-001', 'individual', 'متبرع تجريبي', '0500000000', 'active', @user_id, @user_id);

SET @donor_id = LAST_INSERT_ID();

INSERT INTO funds (organization_id, fund_code, name_ar, fund_type, created_by)
VALUES (@org_id, 'FUND-001', 'الصندوق العام', 'unrestricted', @user_id);

SET @fund_id = LAST_INSERT_ID();

INSERT INTO pledges (organization_id, pledge_code, donor_id, fund_id, initiative_id, amount_pledged, pledge_date, status, created_by)
VALUES (@org_id, 'PL-001', @donor_id, @fund_id, @initiative_id, 10000, CURDATE(), 'active', @user_id);

SET @pledge_id = LAST_INSERT_ID();

INSERT INTO donations (organization_id, donation_code, donor_id, pledge_id, fund_id, initiative_id, amount, donation_date, status, followup_status, created_by)
VALUES (@org_id, 'DN-001', @donor_id, @pledge_id, @fund_id, @initiative_id, 5000, CURDATE(), 'recorded', 'pending_confirmation', @user_id);

SET @donation_id = LAST_INSERT_ID();

INSERT INTO collections (organization_id, collection_code, donation_id, pledge_id, donor_id, fund_id, amount_collected, collection_date, status, reconciliation_status, created_by)
VALUES (@org_id, 'COL-001', @donation_id, @pledge_id, @donor_id, @fund_id, 5000, CURDATE(), 'recorded', 'not_checked', @user_id);

-- Inventory Follow-up
INSERT INTO item_categories (organization_id, category_code, name_ar, created_by)
VALUES (@org_id, 'CAT-001', 'مواد تشغيلية', @user_id);

SET @cat_id = LAST_INSERT_ID();

INSERT INTO units_of_measure (organization_id, unit_code, name_ar, symbol, created_by)
VALUES (@org_id, 'PCS', 'قطعة', 'pc', @user_id);

SET @uom_id = LAST_INSERT_ID();

INSERT INTO items (organization_id, item_code, category_id, base_uom_id, name_ar, item_type, created_by)
VALUES (@org_id, 'ITM-001', @cat_id, @uom_id, 'مادة تجريبية', 'stock', @user_id);

SET @item_id = LAST_INSERT_ID();

INSERT INTO warehouses (organization_id, warehouse_code, name_ar, warehouse_type, department_id, manager_user_id, created_by)
VALUES (@org_id, 'WH-001', 'المستودع الرئيسي', 'main', @dept_id, @user_id, @user_id);

SET @wh_id = LAST_INSERT_ID();

INSERT INTO initiative_stock_requests (
  organization_id, request_code, initiative_id, task_id, requester_user_id, requester_department_id,
  preferred_warehouse_id, request_date, priority, status, followup_status, created_by
) VALUES (
  @org_id, 'ISR-001', @initiative_id, @task_id, @user_id, @dept_id,
  @wh_id, CURDATE(), 'medium', 'draft', 'not_sent', @user_id
);

SET @isr_id = LAST_INSERT_ID();

INSERT INTO initiative_stock_request_lines (organization_id, request_id, item_id, uom_id, requested_qty)
VALUES (@org_id, @isr_id, @item_id, @uom_id, 10);

-- Workflow
INSERT INTO workflow_definitions (organization_id, workflow_code, name_ar, entity_type, version_no, is_active, created_by)
VALUES (@org_id, 'WF-ISR-APPROVAL', 'اعتماد طلبات المواد', 'initiative_stock_request', 1, 1, @user_id);

SET @wf_id = LAST_INSERT_ID();

INSERT INTO workflow_definition_steps (organization_id, workflow_definition_id, step_code, step_name_ar, step_order, step_type, is_mandatory, created_by)
VALUES (@org_id, @wf_id, 'STEP-1', 'مراجعة المسؤول', 1, 'approval', 1, @user_id);

SET @wfs_id = LAST_INSERT_ID();

INSERT INTO workflow_step_assignees (organization_id, workflow_definition_step_id, assignee_type, user_id, assignment_mode, created_by)
VALUES (@org_id, @wfs_id, 'user', @user_id, 'required', @user_id);

INSERT INTO workflow_instances (
  organization_id, instance_code, workflow_definition_id, entity_type, entity_id,
  current_status, initiated_by, created_by
) VALUES (
  @org_id, 'WFI-001', @wf_id, 'initiative_stock_request', @isr_id,
  'running', @user_id, @user_id
);

SET @wfi_id = LAST_INSERT_ID();

INSERT INTO workflow_instance_steps (
  organization_id, workflow_instance_id, workflow_definition_step_id, step_order,
  step_name_ar, step_type, status, assigned_to_user_id, created_by
) VALUES (
  @org_id, @wfi_id, @wfs_id, 1, 'مراجعة المسؤول', 'approval', 'active', @user_id, @user_id
);

SET @wfis_id = LAST_INSERT_ID();

UPDATE workflow_instances SET current_step_id = @wfis_id WHERE id = @wfi_id;

INSERT INTO workflow_actions (
  organization_id, workflow_instance_id, workflow_instance_step_id, action_type, actor_user_id,
  from_status, to_status, decision_note
) VALUES (
  @org_id, @wfi_id, @wfis_id, 'comment', @user_id,
  'running', 'waiting_action', 'اختبار أولي لسير العمل'
);
*/


-- ============================================================
-- [9] RELEASE CLEAN v2 - EXECUTION CHECKLIST (COMMENTS)
-- ============================================================
/*
1) نفّذ أولاً على قاعدة اختبار (Sandbox).
2) تأكد من وجود الجداول الأساسية المرجعية:
   organizations, users, departments, initiatives, tasks
   + allocations, finance_transactions (للوحدة المالية)
3) إذا لم توجد finance_transactions أو allocations:
   - علّق قيود FK المرتبطة بها مؤقتًا (fk_donation_fin_tx, fk_collection_fin_tx, fk_da_allocation)
4) إذا لم توجد attachments أو vendors:
   - اترك قيودها الاختيارية معلقة كما هي (مقصود).
5) بعد النجاح، فعّل Minimal Demo Seed (اختياري) لاختبار الربط سريعًا.
*/
