-- CreateEnum
CREATE TYPE "Role" AS ENUM ('admin', 'operator', 'viewer');

-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('active', 'inactive', 'pending_invite');

-- CreateEnum
CREATE TYPE "ContactStatus" AS ENUM ('active', 'inactive', 'dnc', 'invalid');

-- CreateEnum
CREATE TYPE "CampaignStatus" AS ENUM ('draft', 'scheduled', 'running', 'paused', 'completed', 'cancelled');

-- CreateEnum
CREATE TYPE "CallOutcome" AS ENUM ('success', 'no_answer', 'busy', 'voicemail', 'failed', 'callback_requested', 'dnc_requested');

-- CreateEnum
CREATE TYPE "CustomFieldType" AS ENUM ('text', 'number', 'boolean', 'date');

-- CreateEnum
CREATE TYPE "TemplateCategory" AS ENUM ('cobranca', 'vendas', 'pesquisa', 'confirmacao', 'notificacao');

-- CreateTable
CREATE TABLE "plans" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "price" DECIMAL(10,2) NOT NULL,
    "max_users" INTEGER NOT NULL,
    "max_contacts" INTEGER NOT NULL,
    "max_campaigns_month" INTEGER NOT NULL,
    "max_calls_month" INTEGER NOT NULL,
    "max_phone_lines" INTEGER NOT NULL,
    "features" JSONB NOT NULL DEFAULT '{}',
    "is_custom" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "plans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "companies" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "cnpj" TEXT,
    "plan_id" TEXT NOT NULL,
    "stripe_customer_id" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "timezone" TEXT NOT NULL DEFAULT 'America/Sao_Paulo',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "companies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "company_id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" "Role" NOT NULL DEFAULT 'operator',
    "status" "UserStatus" NOT NULL DEFAULT 'active',
    "invite_token" TEXT,
    "invite_expires_at" TIMESTAMP(3),
    "reset_token" TEXT,
    "reset_expires_at" TIMESTAMP(3),
    "session_version" INTEGER NOT NULL DEFAULT 1,
    "last_login_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tags" (
    "id" TEXT NOT NULL,
    "company_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "color" TEXT NOT NULL DEFAULT '#6B7280',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tags_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "custom_fields" (
    "id" TEXT NOT NULL,
    "company_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "type" "CustomFieldType" NOT NULL DEFAULT 'text',
    "is_required" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "custom_fields_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "contacts" (
    "id" TEXT NOT NULL,
    "company_id" TEXT NOT NULL,
    "full_name" TEXT NOT NULL,
    "primary_phone" TEXT NOT NULL,
    "secondary_phone" TEXT,
    "email" TEXT,
    "organization" TEXT,
    "status" "ContactStatus" NOT NULL DEFAULT 'active',
    "notes" TEXT,
    "last_contact_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "contacts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "contact_tags" (
    "contact_id" TEXT NOT NULL,
    "tag_id" TEXT NOT NULL,

    CONSTRAINT "contact_tags_pkey" PRIMARY KEY ("contact_id","tag_id")
);

-- CreateTable
CREATE TABLE "contact_field_values" (
    "id" TEXT NOT NULL,
    "contact_id" TEXT NOT NULL,
    "custom_field_id" TEXT NOT NULL,
    "value" TEXT NOT NULL,

    CONSTRAINT "contact_field_values_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "templates" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "category" "TemplateCategory" NOT NULL,
    "is_global" BOOLEAN NOT NULL DEFAULT true,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "template_versions" (
    "id" TEXT NOT NULL,
    "template_id" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "steps" JSONB NOT NULL,
    "variables" JSONB NOT NULL DEFAULT '[]',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "template_versions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "company_templates" (
    "id" TEXT NOT NULL,
    "company_id" TEXT NOT NULL,
    "template_id" TEXT NOT NULL,
    "assigned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "company_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "phone_lines" (
    "id" TEXT NOT NULL,
    "company_id" TEXT NOT NULL,
    "phone_number" TEXT NOT NULL,
    "retell_agent_id" TEXT,
    "label" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "phone_lines_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "campaigns" (
    "id" TEXT NOT NULL,
    "company_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "template_version_id" TEXT NOT NULL,
    "phone_line_id" TEXT NOT NULL,
    "created_by_id" TEXT NOT NULL,
    "status" "CampaignStatus" NOT NULL DEFAULT 'draft',
    "scheduled_at" TIMESTAMP(3),
    "started_at" TIMESTAMP(3),
    "completed_at" TIMESTAMP(3),
    "max_retries" INTEGER NOT NULL DEFAULT 3,
    "retry_interval_min" INTEGER NOT NULL DEFAULT 60,
    "concurrent_calls" INTEGER NOT NULL DEFAULT 1,
    "total_contacts" INTEGER NOT NULL DEFAULT 0,
    "completed_calls" INTEGER NOT NULL DEFAULT 0,
    "successful_calls" INTEGER NOT NULL DEFAULT 0,
    "failed_calls" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "campaigns_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "campaign_contacts" (
    "id" TEXT NOT NULL,
    "campaign_id" TEXT NOT NULL,
    "contact_id" TEXT NOT NULL,
    "outcome" "CallOutcome",
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "last_call_at" TIMESTAMP(3),
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "campaign_contacts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "campaign_tags" (
    "campaign_id" TEXT NOT NULL,
    "tag_id" TEXT NOT NULL,

    CONSTRAINT "campaign_tags_pkey" PRIMARY KEY ("campaign_id","tag_id")
);

-- CreateTable
CREATE TABLE "call_logs" (
    "id" TEXT NOT NULL,
    "campaign_id" TEXT NOT NULL,
    "contact_id" TEXT NOT NULL,
    "retell_call_id" TEXT,
    "phone_number_used" TEXT NOT NULL,
    "outcome" "CallOutcome",
    "duration_seconds" INTEGER,
    "transcript" JSONB,
    "sentiment" TEXT,
    "intent_detected" TEXT,
    "retell_raw_response" JSONB,
    "started_at" TIMESTAMP(3),
    "ended_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "call_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" TEXT NOT NULL,
    "company_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "entity" TEXT NOT NULL,
    "entity_id" TEXT,
    "details" JSONB,
    "ip_address" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "usage_records" (
    "id" TEXT NOT NULL,
    "company_id" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "calls" INTEGER NOT NULL DEFAULT 0,
    "minutes" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "usage_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "help_categories" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "icon" TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "help_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "help_articles" (
    "id" TEXT NOT NULL,
    "category_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "is_published" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "help_articles_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "plans_name_key" ON "plans"("name");

-- CreateIndex
CREATE UNIQUE INDEX "companies_cnpj_key" ON "companies"("cnpj");

-- CreateIndex
CREATE UNIQUE INDEX "companies_stripe_customer_id_key" ON "companies"("stripe_customer_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_invite_token_key" ON "users"("invite_token");

-- CreateIndex
CREATE UNIQUE INDEX "users_reset_token_key" ON "users"("reset_token");

-- CreateIndex
CREATE INDEX "users_company_id_idx" ON "users"("company_id");

-- CreateIndex
CREATE INDEX "tags_company_id_idx" ON "tags"("company_id");

-- CreateIndex
CREATE UNIQUE INDEX "tags_company_id_name_key" ON "tags"("company_id", "name");

-- CreateIndex
CREATE INDEX "custom_fields_company_id_idx" ON "custom_fields"("company_id");

-- CreateIndex
CREATE UNIQUE INDEX "custom_fields_company_id_name_key" ON "custom_fields"("company_id", "name");

-- CreateIndex
CREATE INDEX "contacts_company_id_idx" ON "contacts"("company_id");

-- CreateIndex
CREATE INDEX "contacts_company_id_status_idx" ON "contacts"("company_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "contacts_primary_phone_company_id_key" ON "contacts"("primary_phone", "company_id");

-- CreateIndex
CREATE UNIQUE INDEX "contact_field_values_contact_id_custom_field_id_key" ON "contact_field_values"("contact_id", "custom_field_id");

-- CreateIndex
CREATE UNIQUE INDEX "template_versions_template_id_version_key" ON "template_versions"("template_id", "version");

-- CreateIndex
CREATE UNIQUE INDEX "company_templates_company_id_template_id_key" ON "company_templates"("company_id", "template_id");

-- CreateIndex
CREATE UNIQUE INDEX "phone_lines_phone_number_key" ON "phone_lines"("phone_number");

-- CreateIndex
CREATE INDEX "phone_lines_company_id_idx" ON "phone_lines"("company_id");

-- CreateIndex
CREATE INDEX "campaigns_company_id_idx" ON "campaigns"("company_id");

-- CreateIndex
CREATE INDEX "campaigns_company_id_status_idx" ON "campaigns"("company_id", "status");

-- CreateIndex
CREATE INDEX "campaign_contacts_campaign_id_idx" ON "campaign_contacts"("campaign_id");

-- CreateIndex
CREATE UNIQUE INDEX "campaign_contacts_campaign_id_contact_id_key" ON "campaign_contacts"("campaign_id", "contact_id");

-- CreateIndex
CREATE UNIQUE INDEX "call_logs_retell_call_id_key" ON "call_logs"("retell_call_id");

-- CreateIndex
CREATE INDEX "call_logs_campaign_id_idx" ON "call_logs"("campaign_id");

-- CreateIndex
CREATE INDEX "call_logs_contact_id_idx" ON "call_logs"("contact_id");

-- CreateIndex
CREATE INDEX "audit_logs_company_id_idx" ON "audit_logs"("company_id");

-- CreateIndex
CREATE INDEX "audit_logs_company_id_entity_idx" ON "audit_logs"("company_id", "entity");

-- CreateIndex
CREATE INDEX "usage_records_company_id_idx" ON "usage_records"("company_id");

-- CreateIndex
CREATE UNIQUE INDEX "usage_records_company_id_date_key" ON "usage_records"("company_id", "date");

-- CreateIndex
CREATE UNIQUE INDEX "help_categories_name_key" ON "help_categories"("name");

-- CreateIndex
CREATE INDEX "help_articles_category_id_idx" ON "help_articles"("category_id");

-- AddForeignKey
ALTER TABLE "companies" ADD CONSTRAINT "companies_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tags" ADD CONSTRAINT "tags_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "custom_fields" ADD CONSTRAINT "custom_fields_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contacts" ADD CONSTRAINT "contacts_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contact_tags" ADD CONSTRAINT "contact_tags_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contact_tags" ADD CONSTRAINT "contact_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "tags"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contact_field_values" ADD CONSTRAINT "contact_field_values_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contact_field_values" ADD CONSTRAINT "contact_field_values_custom_field_id_fkey" FOREIGN KEY ("custom_field_id") REFERENCES "custom_fields"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "template_versions" ADD CONSTRAINT "template_versions_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "templates"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "company_templates" ADD CONSTRAINT "company_templates_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "company_templates" ADD CONSTRAINT "company_templates_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "templates"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "phone_lines" ADD CONSTRAINT "phone_lines_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_template_version_id_fkey" FOREIGN KEY ("template_version_id") REFERENCES "template_versions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_phone_line_id_fkey" FOREIGN KEY ("phone_line_id") REFERENCES "phone_lines"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaigns" ADD CONSTRAINT "campaigns_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaign_contacts" ADD CONSTRAINT "campaign_contacts_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaign_contacts" ADD CONSTRAINT "campaign_contacts_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaign_tags" ADD CONSTRAINT "campaign_tags_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "campaign_tags" ADD CONSTRAINT "campaign_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "tags"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "call_logs" ADD CONSTRAINT "call_logs_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "campaigns"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "call_logs" ADD CONSTRAINT "call_logs_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "contacts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "usage_records" ADD CONSTRAINT "usage_records_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "help_articles" ADD CONSTRAINT "help_articles_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "help_categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;
