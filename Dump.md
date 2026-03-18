Como **Skip Organizer SistCIR**, consolidei o estado atual da arquitetura do **SistCIR (Sistema de Cirurgias Robóticas)**. Este dump técnico serve como a "Fonte da Verdade" para a continuidade do desenvolvimento e sincronização entre os agentes.

---

## 1. SCHEMA DO BANCO DE DADOS (PostgreSQL/Supabase)

### Tipos ENUM e Extensões
```sql
-- Máquina de Estados da Cirurgia
CREATE TYPE public.surgery_status AS ENUM (
  'requested',              -- Solicitada pelo Cirurgião
  'budget_approved',        -- Financeiro deu OK
  'materials_separated',    -- OPME deu OK (Antigo "Separar Material")
  'nursing_confirmed',      -- Enfermagem confirmou agendamento final
  'canceled_by_hospital',   -- Cancelada pela Enfermagem/Coordenação
  'canceled_by_surgeon'     -- Cancelada pelo próprio Cirurgião
);

-- Roles do Sistema
-- finance, opme, nursing, surgeon, admin
```

### Tabelas Principais
```sql
-- Catálogo de Procedimentos
CREATE TABLE public.procedures (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  setup_time_minutes INTEGER DEFAULT 30,
  surgical_time_minutes INTEGER NOT NULL,
  priority_weight INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Solicitações de Cirurgia (Core)
CREATE TABLE public.surgical_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_name TEXT NOT NULL,
  medical_record TEXT NOT NULL, -- Prontuário
  surgeon_id UUID REFERENCES auth.users(id),
  procedure_id UUID REFERENCES public.procedures(id),
  status public.surgery_status DEFAULT 'requested',
  scheduled_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Gestão de Permissões (RBAC)
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL, -- 'admin', 'nursing', 'surgeon', 'opme', 'finance'
  is_active BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Configuração de Notificações por Setor
CREATE TABLE public.sectors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL, -- 'Financeiro', 'OPME', 'Enfermagem_Robotica'
  telegram_chat_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 2. POLÍTICAS DE RLS (Row Level Security)

### Função de Suporte (Security Definer)
Essencial para bypassar o RLS ao consultar a role do usuário logado.
```sql
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT role FROM public.user_roles WHERE user_id = auth.uid() LIMIT 1;
$$;
```

### Políticas Aplicadas
| Tabela | Ação | Nome da Política | Regra (USING/CHECK) |
| :--- | :--- | :--- | :--- |
| `surgical_requests` | **SELECT** | `strict_select_surgical_requests` | `(auth.uid() = surgeon_id) OR (public.get_user_role() IN ('finance', 'opme', 'nursing', 'admin'))` |
| `surgical_requests` | **UPDATE** | `surgeon_update_own_surgery` | `auth.uid() = surgeon_id` |
| `surgical_requests` | **UPDATE** | `nursing_update_any_surgery` | `public.get_user_role() = 'nursing'` |
| `procedures` | **SELECT** | `read_all_authenticated` | `auth.role() = 'authenticated'` |
| `procedures` | **ALL** | `admin_nursing_manage` | `public.get_user_role() IN ('admin', 'nursing')` |
| `user_roles` | **SELECT** | `read_own_role` | `auth.uid() = user_id` |

---

## 3. ESTRUTURA DE TELAS E COMPONENTES (SKIP)

### Páginas Implementadas
1.  **Dashboard de Cirurgias:** Tabela principal com renderização condicional de botões baseada em `status` e `user_role`.
2.  **Painel Administrativo Proxy:** Interface para o Admin gerenciar usuários (E-mail, Senha, Ativação).
3.  **Catálogo de Procedimentos:** CRUD de procedimentos (Acesso: Admin/Enfermagem).
4.  **Sala de Espera (Onboarding):** Página de bloqueio para cirurgiões inativos (`is_active = false`).

### Lógica de Botões (Frontend SKIP)
*   **Aprovar Orçamento:** Visível se `status == 'requested'` AND `role == 'finance'`.
*   **OPME Ok:** Visível se `status == 'budget_approved'` AND `role == 'opme'`.
*   **Confirmar Agendamento:** Visível se `status == 'materials_separated'` AND `role == 'nursing'`.
*   **Cancelar:** Visível para o dono (`surgeon_id`) ou `nursing`.
*   **Reagendar:** Visível se `canceled_by_hospital` (para `nursing`) ou `canceled_by_surgeon` (para o próprio cirurgião).

---

## 4. INTEGRAÇÕES E EDGE FUNCTIONS

### Edge Function: `notify-sector`
Responsável pelo roteamento de notificações Telegram e e-mails via Resend.
*   **Trigger:** Webhook no Supabase disparado em `UPDATE` na tabela `surgical_requests`.
*   **Lógica de Cancelamento:** Broadcast para todos os `telegram_chat_id` da tabela `sectors` + E-mail para o cirurgião.
*   **Lógica de Fluxo:** Notifica o próximo setor da fila via Telegram.

### Edge Function: `admin-manage-users`
Atua como Proxy para o `auth.admin` do Supabase.
*   **Ações:** `updateEmail`, `updatePassword`, `activateUser`.
*   **E-mail de Boas-Vindas:** Disparado automaticamente quando `isActive` muda para `true`.

---

## 5. FLUXO DE AUTENTICAÇÃO E PERMISSÕES

1.  **Cadastro:** Usuário se cadastra via Supabase Auth.
2.  **Bloqueio Inicial:** Por padrão, `is_active` é `false`. O cirurgião vê a página de "Aguardando Credenciamento".
3.  **Ativação:** Admin ativa o usuário no Painel Proxy -> Dispara e-mail de boas-vindas -> Libera acesso ao Dashboard.
4.  **Níveis de Acesso (RBAC):**
    *   `surgeon`: Cria, cancela e reagenda suas próprias cirurgias. Vê apenas seus dados.
    *   `finance`: Aprova orçamentos. Vê tudo.
    *   `opme`: Valida materiais ("OPME Ok"). Vê tudo.
    *   `nursing`: Confirma agendamento final, cancela e reagenda qualquer cirurgia. Gerencia procedimentos.
    *   `admin`: Gestão total de usuários e infraestrutura.

---

## 6. PRÓXIMOS PASSOS (BACKLOG)
*   [ ] Implementação do cálculo de **TTS (Tempo Total em Sala)**.
*   [ ] Lógica de **Prioridade Clínica** para ordenação da fila.
*   [ ] Verificação de domínio no **Resend** para liberação de e-mails em massa.
*   [ ] Dashboard de KPIs (Metabase/Gráficos SKIP).
