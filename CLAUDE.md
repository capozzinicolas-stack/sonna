# CLAUDE.md — SONNA Platform

## Quem sou eu (contexto do projeto)

SONNA é uma plataforma SaaS multi-tenant de automação de chamadas outbound com IA conversacional. Permite que empresas façam upload de listas de contatos, selecionem templates de conversação pré-configurados, disparem campanhas de chamadas automatizadas via voz IA (Retell), e recebam resultados estruturados.

## Stack Técnico

- **Backend**: Node.js + Express + TypeScript + Prisma ORM + PostgreSQL
- **Frontend**: Next.js 14 (App Router) + TypeScript + Tailwind CSS + shadcn/ui
- **Database**: PostgreSQL (Neon ou Supabase free tier)
- **Job Queue**: pg-boss (usa PostgreSQL, sem Redis)
- **Email**: Resend.com (free tier)
- **Charts**: Recharts
- **Tables**: TanStack Table (server-side pagination)
- **Forms**: React Hook Form + Zod
- **State**: Zustand (global) + React Query (server state)
- **Deploy**: Render.com (backend) + Vercel (frontend)

## Estrutura do Monorepo

```
sonna/
├── backend/
│   ├── src/
│   │   ├── config/           # DB, env, stripe, retell configs
│   │   ├── middleware/        # auth, rbac, company, audit, errorHandler
│   │   ├── modules/          # feature modules (auth, users, contacts, etc.)
│   │   │   └── {module}/     # routes.ts, controller.ts, service.ts, validators.ts
│   │   ├── jobs/             # pg-boss job definitions
│   │   ├── utils/            # helpers, validators, email service
│   │   └── index.ts          # Express app entry point
│   ├── prisma/
│   │   ├── schema.prisma
│   │   ├── migrations/
│   │   └── seed.ts
│   ├── package.json
│   └── tsconfig.json
├── frontend/
│   ├── src/
│   │   ├── app/              # Next.js App Router
│   │   │   ├── (auth)/       # login, registro, reset-senha
│   │   │   └── (dashboard)/  # layout protegido com nav
│   │   ├── components/       # ui/, layout/, shared/, feature-specific
│   │   ├── lib/              # api client, auth, utils
│   │   ├── hooks/            # custom hooks
│   │   └── types/            # TypeScript types
│   ├── package.json
│   └── tsconfig.json
└── docs/
    └── PRD.md                # PRD completo (referência)
```

## Regras INVIOLÁVEIS

1. **IDIOMA**: Toda UI em PT-BR (labels, mensagens, placeholders, erros). Código em inglês.
2. **MULTI-TENANT**: TODA query ao banco DEVE filtrar por `company_id`. Sem exceções. Nunca retornar dados de outra empresa.
3. **RBAC**: Todo endpoint deve usar middleware `@roles()`. Roles: admin, operator, viewer.
4. **TIMEZONE**: Default `America/Sao_Paulo`. Armazenar UTC no banco, converter na UI.
5. **SENHAS**: bcrypt com cost factor 12. Nunca logar senhas.
6. **API KEYS**: Stripe e Retell keys NUNCA no frontend. Sempre em variáveis de ambiente backend.
7. **PAGINAÇÃO**: Server-side, 50 items/page default. Nunca carregar todos registros.
8. **SOFT DELETE**: Contatos nunca são deletados fisicamente. Use campo `status`.
9. **VALIDAÇÃO**: Zod no backend (validators.ts) + Zod no frontend (form schemas). Duplicar validações.
10. **ERROS**: Nunca expor stack traces ao cliente. Formato padrão: `{ success: false, error: { code, message, details } }`.

## Padrão de Módulo Backend

Cada módulo segue esta estrutura:

```typescript
// routes.ts — define rotas Express
import { Router } from 'express';
import { authenticate, authorize } from '../../middleware/auth';
import { controller } from './controller';

const router = Router();
router.get('/', authenticate, authorize(['admin', 'operator', 'viewer']), controller.list);
router.post('/', authenticate, authorize(['admin', 'operator']), controller.create);
export default router;

// controller.ts — extrai params, chama service, retorna response
// service.ts — lógica de negócio, queries Prisma (SEMPRE filtra company_id)
// validators.ts — schemas Zod para request body/params
```

## Padrão de Response API

```typescript
// Sucesso
{ success: true, data: {...}, meta: { page: 1, per_page: 50, total: 230 } }

// Erro
{ success: false, error: { code: "VALIDATION_ERROR", message: "...", details: [...] } }
```

## Padrão de Página Frontend

```typescript
// Cada página usa:
// 1. React Query para fetch de dados (useQuery/useMutation)
// 2. Zustand para estado global (auth, user, company)
// 3. shadcn/ui para componentes
// 4. Zod + React Hook Form para forms
// 5. TanStack Table para tabelas com server-side pagination
```

## Integrações Externas

### Retell AI (chamadas de voz)
- Base URL: `https://api.retellai.com`
- Auth: `Authorization: Bearer {RETELL_API_KEY}`
- Endpoint principal: `POST /v2/create-phone-call`
- Webhook SONNA recebe em: `POST /api/v1/webhooks/retell`
- Validar webhook signature antes de processar
- Retry: 3x com exponential backoff (2s, 4s, 8s)

### Stripe (billing)
- Webhook SONNA recebe em: `POST /api/v1/webhooks/stripe`
- Events: invoice.paid, invoice.payment_failed, customer.subscription.updated
- Usage records: batch diário (NUNCA por chamada individual)
- Apenas Admin pode ver/modificar billing

## Variáveis de Ambiente (.env)

```
# Backend
DATABASE_URL=postgresql://...
JWT_SECRET=...
JWT_REFRESH_SECRET=...
RETELL_API_KEY=...
STRIPE_SECRET_KEY=...
STRIPE_WEBHOOK_SECRET=...
RESEND_API_KEY=...
FRONTEND_URL=http://localhost:3000
PORT=3001

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:3001/api/v1
```

## Comandos Úteis

```bash
# Backend
cd backend && npm run dev          # inicia dev server
npx prisma migrate dev             # aplicar migrations
npx prisma studio                  # GUI do banco
npx prisma db seed                 # rodar seed

# Frontend
cd frontend && npm run dev         # inicia Next.js
npx shadcn@latest add [component] # adicionar componente shadcn
```

## O que NÃO fazer

- NÃO usar ORMs alternativos (Drizzle, TypeORM). Usar Prisma.
- NÃO usar Redux, MobX. Usar Zustand + React Query.
- NÃO criar API routes no Next.js. O backend é Express separado.
- NÃO usar CSS modules. Usar Tailwind.
- NÃO instalar UI library completa (MUI, Ant). Usar shadcn/ui.
- NÃO fazer queries sem company_id. NUNCA.
- NÃO expor provedor de telefonia (Retell) na UI. Chamar de "Linha SONNA".
- NÃO colocar lógica de negócio no controller. Colocar no service.
- NÃO fazer cálculos pesados na UI. Usar tabelas pré-agregadas ou backend.
