import 'dotenv/config';
import { PrismaClient } from '../src/generated/prisma';
import { PrismaPg } from '@prisma/adapter-pg';
import bcrypt from 'bcryptjs';

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('🌱 Seeding database...');

  // 1. Create Plans
  const plans = await Promise.all([
    prisma.plan.upsert({
      where: { name: 'Basic' },
      update: {},
      create: {
        name: 'Basic',
        price: 149.00,
        maxUsers: 3,
        maxContacts: 5000,
        maxCampaigns: 10,
        maxCallsMonth: 2000,
        maxPhoneLines: 1,
        features: {
          csvUpload: true,
          customFields: false,
          apiAccess: false,
          prioritySupport: false,
        },
      },
    }),
    prisma.plan.upsert({
      where: { name: 'Plus' },
      update: {},
      create: {
        name: 'Plus',
        price: 499.00,
        maxUsers: 10,
        maxContacts: 25000,
        maxCampaigns: 50,
        maxCallsMonth: 10000,
        maxPhoneLines: 3,
        features: {
          csvUpload: true,
          customFields: true,
          apiAccess: false,
          prioritySupport: false,
        },
      },
    }),
    prisma.plan.upsert({
      where: { name: 'Pro' },
      update: {},
      create: {
        name: 'Pro',
        price: 1999.00,
        maxUsers: 50,
        maxContacts: 100000,
        maxCampaigns: 200,
        maxCallsMonth: 50000,
        maxPhoneLines: 10,
        features: {
          csvUpload: true,
          customFields: true,
          apiAccess: true,
          prioritySupport: true,
        },
      },
    }),
    prisma.plan.upsert({
      where: { name: 'Enterprise' },
      update: {},
      create: {
        name: 'Enterprise',
        price: 0,
        maxUsers: 999,
        maxContacts: 999999,
        maxCampaigns: 9999,
        maxCallsMonth: 999999,
        maxPhoneLines: 99,
        isCustom: true,
        features: {
          csvUpload: true,
          customFields: true,
          apiAccess: true,
          prioritySupport: true,
          dedicatedSupport: true,
          customIntegrations: true,
        },
      },
    }),
  ]);

  console.log(`✅ Created ${plans.length} plans`);

  // 2. Create test Company
  const company = await prisma.company.upsert({
    where: { cnpj: '00000000000100' },
    update: {},
    create: {
      name: 'Empresa Teste SONNA',
      cnpj: '00000000000100',
      planId: plans[0].id, // Basic plan
    },
  });

  console.log(`✅ Created company: ${company.name}`);

  // 3. Create admin user
  const passwordHash = await bcrypt.hash('Test123456', 12);

  const adminUser = await prisma.user.upsert({
    where: { email: 'admin@sonna.test' },
    update: {},
    create: {
      companyId: company.id,
      email: 'admin@sonna.test',
      passwordHash,
      name: 'Admin SONNA',
      role: 'admin',
      status: 'active',
    },
  });

  console.log(`✅ Created admin user: ${adminUser.email} (password: Test123456)`);

  // 4. Create Help Categories
  const helpCategories = await Promise.all([
    prisma.helpCategory.upsert({
      where: { name: 'Primeiros Passos' },
      update: {},
      create: { name: 'Primeiros Passos', icon: 'rocket', order: 1 },
    }),
    prisma.helpCategory.upsert({
      where: { name: 'Contatos' },
      update: {},
      create: { name: 'Contatos', icon: 'users', order: 2 },
    }),
    prisma.helpCategory.upsert({
      where: { name: 'Campanhas' },
      update: {},
      create: { name: 'Campanhas', icon: 'megaphone', order: 3 },
    }),
    prisma.helpCategory.upsert({
      where: { name: 'Faturamento' },
      update: {},
      create: { name: 'Faturamento', icon: 'credit-card', order: 4 },
    }),
  ]);

  console.log(`✅ Created ${helpCategories.length} help categories`);

  console.log('\n🎉 Seed completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
