# GUIA DE EJECUCIÓN — Cómo usar el PRD con Claude Code

## El problema que resolvemos

El PRD tiene 2.400+ líneas. Claude Code tiene contexto limitado (~200k tokens, pero pierde efectividad con documentos enormes). Si le tiras todo junto, se confunde, inventa cosas, o ignora detalles.

**La solución**: alimentar a Claude Code por tickets, con contexto progresivo.

---

## Arquitectura de la ejecución

```
sonna/
├── CLAUDE.md          ← Claude Code lee esto AUTOMÁTICAMENTE en cada sesión
├── docs/
│   ├── PRD.md         ← PRD completo (referencia, Claude Code puede leerlo si se lo pides)
│   └── tickets/       ← Un archivo por ticket (contexto específico)
│       ├── M1-01.md
│       ├── M1-02.md
│       └── ...
├── backend/
└── frontend/
```

**CLAUDE.md** es el ancla. Claude Code lo lee siempre. Contiene reglas, stack, estructura. No cambies este archivo sin razón.

**docs/PRD.md** es la referencia completa. Solo le pides a Claude Code que lo lea cuando necesita contexto amplio.

**docs/tickets/** son las instrucciones específicas por ticket. Es lo que le pasas a Claude Code sesión por sesión.

---

## Regla de oro: Un ticket = una sesión de Claude Code

No mezcles tickets. No pidas "haz M1-01, M1-02 y M1-03 juntos". Termina uno, valida, y sigue con el siguiente.

---

## Fase 0: Setup inicial

### Sesión 1 — Crear el proyecto

Prompt para Claude Code:
```
Lee el archivo CLAUDE.md para entender el proyecto.

Ejecuta el ticket M1-01: Setup del Proyecto.

Crea la estructura de monorepo con:
- /backend: Express + TypeScript + Prisma (sin schema aún)
- /frontend: Next.js 14 App Router + TypeScript + Tailwind + shadcn/ui

Instala todas dependencias listadas en CLAUDE.md.
Configura .env.example con todas variables.
Crea health check GET /api/health que retorna { status: "ok" }.

Cuando termines, verifica que:
1. cd backend && npm run dev → server inicia sin errores en puerto 3001
2. cd frontend && npm run dev → Next.js inicia sin errores en puerto 3000
3. GET http://localhost:3001/api/health retorna 200
```

**STOP**: Verificar los 3 checkpoints antes de continuar.

---

### Sesión 2 — Schema del banco

Prompt para Claude Code:
```
Lee CLAUDE.md y luego lee docs/PRD.md sección E (Modelo de Datos).

Ejecuta el ticket M1-02: Schema del Banco de Datos.

Crea el schema.prisma completo con TODAS las entidades:
Plan, Company, User, Tag, CustomField, Contact, ContactFieldValue,
contact_tags, Template, TemplateVersion, CompanyTemplate, PhoneLine,
Campaign, CampaignContact, CampaignTag, CallLog, AuditLog,
UsageRecord, HelpCategory, HelpArticle.

Incluye:
- Todos los enums (Role, UserStatus, ContactStatus, CampaignStatus, etc.)
- Índices en company_id de todas las tablas
- Unique constraints: email en User, (primary_phone + company_id) en Contact
- Relaciones correctas con onDelete rules

Después crea seed.ts con:
- 4 Plans (Basic $149, Plus $499, Pro $1999, Enterprise custom)
- 1 Company de prueba (plan Basic)
- 1 Admin user (admin@sonna.test / Test123456)

Ejecuta: npx prisma migrate dev --name init
Ejecuta: npx prisma db seed
Verifica con: npx prisma studio
```

**STOP**: Verificar en Prisma Studio que todas las tablas existen y el seed funcionó.

---

## Fase 1: Auth + Users + Contacts

### Sesión 3 — Auth (registro + login)

Prompt para Claude Code:
```
Lee CLAUDE.md.
Lee docs/PRD.md sección C1 (Auth & Multi-tenancy) completa.

Implementa los tickets M1-03 y M1-04:

BACKEND:
1. Crea módulo backend/src/modules/auth/ con routes, controller, service, validators
2. Endpoints:
   - POST /api/v1/auth/register (valida token, crea Company + User Admin + Stripe Customer mock)
   - POST /api/v1/auth/login (retorna JWT 24h + refresh 7d)
   - POST /api/v1/auth/refresh
   - POST /api/v1/auth/forgot-password (genera token, envía email mock por ahora)
   - POST /api/v1/auth/reset-password
3. Crea middleware/auth.ts: extractUser, enforceCompany, authorize (roles guard)
4. Rate limiting: 5 intentos → bloqueo 15min

FRONTEND:
5. Crea página /login con form (email + senha), validación Zod, mensajes de error PT-BR
6. Crea página /registro con form (nome empresa, CNPJ, token), validación
7. Crea lib/api.ts (axios client con interceptors para JWT)
8. Crea lib/auth.ts (token storage, refresh logic)
9. Crea layout protegido que redirige a /login si no hay JWT

Todos textos en PT-BR según los copys de la sección G3 del PRD.

Verifica:
1. POST /register con token válido → crea Company + User → 201
2. POST /login → retorna JWT → 200
3. GET /api/v1/users/me con JWT → retorna user data → 200
4. GET /api/v1/users/me sin JWT → 401
5. Frontend: login → redirect a dashboard (página vacía OK)
```

**STOP**: Los 5 checkpoints deben pasar.

---

### Sesión 4 — Users + RBAC

Prompt para Claude Code:
```
Lee CLAUDE.md.
Lee docs/PRD.md secciones C3 (Usuários & Roles) y la tabla de permisos RBAC.

Implementa ticket M1-07: Users — CRUD + Convite + Gerenciamento.

BACKEND:
1. Módulo backend/src/modules/users/
2. Endpoints: GET /users, POST /users/invite, PATCH /users/:id,
   POST /users/:id/resend-invite, POST /users/:id/force-logout
3. Lógica de convite: crea user con status pending_invite, genera token, "envía" email (log por ahora)
4. Verificar quota de usuarios antes de invitar
5. Force logout: incrementa session_version del user (JWT anterior se invalida)
6. Admin no puede auto-desactivarse si es el último Admin

FRONTEND:
7. Página /equipe con tabla de usuarios (nombre, email, role, status, último login)
8. Modal "Convidar Usuário" (email + role)
9. Modal "Editar Usuário" (nome, role, status)
10. Tooltips con descripción de roles
11. Badge de status: ativo (verde), inativo (rojo), convite pendente (amarillo)

Todos textos PT-BR.

Verifica:
1. Admin invita → user creado con pending_invite
2. Operador intenta invitar → 403
3. Viewer intenta editar → 403
4. Quota excedida → error con mensaje claro
5. Force logout → JWT anterior rechazado
```

---

### Sesión 5 — Contacts + Custom Fields + Tags

Prompt para Claude Code:
```
Lee CLAUDE.md.
Lee docs/PRD.md secciones C4 (Contatos), C5 (Upload CSV), y modelo de datos de Contact.

Implementa tickets M1-08, M1-09, M1-10.

BACKEND:
1. Módulo contacts/ — CRUD con paginación server-side (50/page)
   Filtros: search, status, tags, custom fields, date range
2. Módulo custom-fields/ — CRUD de campos custom por empresa
3. Módulo tags/ — CRUD compartido (usado en contacts y campaigns)
4. Tabla contact_tags (many-to-many)
5. ContactFieldValue para valores de campos custom

FRONTEND:
6. Página /contatos con TanStack Table:
   Columnas: Nome, Telefone, Email, Organização, Status, Tags, Último contato, Ações
7. Filtros: busca, status, tags, data
8. Modal de edição com 4 tabs:
   - Info Geral (nome, telefone, email, org, status)
   - Campos Custom (renderiza por tipo: text→input, number→number, boolean→switch, date→datepicker)
   - Tags (multi-select com autocomplete)
   - Histórico (placeholder — será implementado después)
9. Botão "Adicionar Contato"
10. Badge DNC vermelho quando status = dnc
11. Só Admin pode mudar status de DNC para active

Verifica:
1. CRUD contato funciona end-to-end
2. Custom field boolean renderiza como switch
3. Tags associáveis e filtráveis
4. Paginação server-side funcionando
5. User de Company A não vê contatos de Company B
```

---

### Sesión 6 — CSV Upload + Export

Prompt para Claude Code:
```
Lee CLAUDE.md.
Lee docs/PRD.md seção C5 (Upload CSV) completa.

Implementa tickets M1-11 e M1-12.

BACKEND:
1. POST /api/v1/contacts/upload — recebe CSV, retorna preview
2. POST /api/v1/contacts/upload/confirm — processa upload
3. Job pg-boss para processar uploads > 1000 linhas em background
4. Detecção de duplicatas por primary_phone + company_id
5. GET /api/v1/contacts/export — gera CSV ou Excel

FRONTEND:
6. Wizard de upload CSV com 4 steps:
   Step 1: Upload do arquivo
   Step 2: Mapeamento de colunas (auto-detect + manual)
           Opção "Criar novo campo custom" para colunas não mapeadas
           Opção "Ignorar coluna"
   Step 3: Preview (10 primeiros registros) + resumo de duplicatas
           Opção: "Atualizar existentes" ou "Ignorar duplicatas"
   Step 4: Confirmação + processamento
7. Indicador de progresso para uploads grandes
8. Notificação ao completar
9. Botão "Exportar Contatos" (CSV/Excel) que respeita filtros ativos

Verifica:
1. Upload CSV com 100 linhas → preview correto
2. Mapeamento auto-detect funciona para full_name, email, phone
3. Duplicatas detectadas corretamente
4. Upload 1000 linhas → job background completa
5. Export gera arquivo correto
```

---

## Fase 2: Templates + Campaigns + Retell

### Sesión 7 — Templates

```
Lee CLAUDE.md.
Lee docs/PRD.md seção C6 (Templates & Versionamento) e a estrutura de Steps.

Implementa tickets M2-01 e M2-02.
[... backend templates module + seed de 5 templates con steps completos ...]
```

### Sesión 8 — Phone Lines

```
Lee CLAUDE.md.
Lee docs/PRD.md seção C7 (Linhas Telefônicas).

Implementa ticket M2-03.
[... phone lines module, Retell API integration para compra/verificação ...]
```

### Sesión 9 — Campaigns CRUD

```
Lee CLAUDE.md.
Lee docs/PRD.md seção C8 (Campanhas) — fluxos de criação e validação.

Implementa tickets M2-04 e M2-05.
[... wizard 7 steps, lista com filtros, draft mode ...]
```

### Sesión 10 — Campaign Execution Engine (CRÍTICA)

```
Lee CLAUDE.md.
Lee docs/PRD.md seções C9 (Motor de Chamadas) e C8 (Campanhas) completas.
Presta atenção especial a: mapeamento de intents, retry policy, reconciliation job.

Implementa ticket M2-06.
[... scheduler, Retell API calls, webhook handler, outcome mapping, auto-DNC ...]
```

### Sesión 11 — Campaign Detail + Actions

```
Lee CLAUDE.md.
Lee docs/PRD.md seção C8 (detalhe de campanha).

Implementa tickets M2-07, M2-08, M2-09.
[... campaign detail page, duplicate, rerun failed, export ...]
```

---

## Fase 3: Dashboard + Billing + Polish

### Sesión 12 — Dashboard

```
Implementa ticket M3-01.
[... KPIs, funnel, charts, filters ...]
```

### Sesión 13 — Stripe + Billing

```
Implementa tickets M3-02 e M3-03.
[... Stripe setup, subscription, usage tracking, billing UI ...]
```

### Sesión 14 — Alerts + Audit + Help + Polish

```
Implementa tickets M3-04, M3-05, M3-06, M3-07, M3-08.
[... billing alerts, audit logs, help center, contact history, email service ...]
```

---

## Patrón de prompt para cada sesión

Usa siempre esta estructura:

```
1. Lee CLAUDE.md
2. Lee [sección específica del PRD]
3. Implementa [ticket(s) específico(s)]
4. [Lista detallada de lo que debe hacer — backend y frontend]
5. [Lista de verificaciones que debe pasar]
```

## Qué hacer cuando Claude Code se equivoca

1. **Inventa un endpoint o campo que no existe**: Dile "revisa docs/PRD.md sección X, ese campo no existe"
2. **Se salta company_id**: Dile "REGLA INVIOLABLE: toda query filtra por company_id. Corrige."
3. **Usa inglés en la UI**: Dile "toda UI en PT-BR. Corrige los textos."
4. **Hace queries pesadas en la UI**: Dile "usa backend aggregation, no calcules en frontend"
5. **Se confunde con el contexto**: Inicia nueva sesión, repite el patrón de prompt

## Qué hacer cuando un ticket se vuelve demasiado grande

Si Claude Code empieza a perder coherencia en un ticket L (grande):

1. Divide en 2 sub-sesiones:
   - Sub-A: Solo backend (endpoints + service + validators)
   - Sub-B: Solo frontend (página + componentes + hooks)
2. Valida backend con curl/Postman antes de empezar frontend

---

## Resumen de sesiones estimadas

| Sesión | Ticket(s) | Duración estimada |
|--------|-----------|-------------------|
| 1 | M1-01 Setup | 30 min |
| 2 | M1-02 Schema + Seed | 45 min |
| 3 | M1-03 + M1-04 Auth | 1-2 horas |
| 4 | M1-07 Users + RBAC | 1-2 horas |
| 5 | M1-08 + M1-09 + M1-10 Contacts | 2-3 horas |
| 6 | M1-11 + M1-12 CSV + Export | 1-2 horas |
| 7 | M2-01 + M2-02 Templates | 1-2 horas |
| 8 | M2-03 Phone Lines | 1 hora |
| 9 | M2-04 + M2-05 Campaigns CRUD | 2-3 horas |
| 10 | M2-06 Execution Engine | 3-4 horas |
| 11 | M2-07 + M2-08 + M2-09 Campaign Detail | 2-3 horas |
| 12 | M3-01 Dashboard | 2-3 horas |
| 13 | M3-02 + M3-03 Stripe + Billing UI | 3-4 horas |
| 14 | M3-04 a M3-08 Polish | 2-3 horas |
| **Total** | **20 tickets** | **~25-35 horas** |
