# Documento de Requisitos do Sistema (PRD): Orquestração de Urologia Oncológica Robótica

Este documento define as especificações técnicas e funcionais para a implementação de um sistema de agendamento cirúrgico de alta complexidade, focado em Urologia Oncológica Robótica, operando sob conformidade com a LGPD, HIPAA e Resolução CFM Nº 2.454.

## 1. Atores e Permissões (RBAC - Role-Based Access Control)
A governança de acesso é sustentada por um modelo RBAC integrado a políticas de Row Level Security (RLS) no banco de dados (ex: Supabase), garantindo que as regras de negócio sejam aplicadas diretamente na camada de persistência.

| Ator | Função e Permissões Principais | Escopo de Acesso (RLS) |
| :--- | :--- | :--- |
| **Cirurgião** | Responsável técnico; cria/edita solicitações, anexa justificativas clínicas, define equipe e OPME. | Visualização total apenas de seus próprios pacientes e status de seus agendamentos. |
| **Secretária Clínica** | Gestão administrativa; pré-cadastro de pacientes, preenchimento de dados cadastrais e monitoramento de autorizações. | Visualização restrita à agenda e pacientes dos cirurgiões aos quais está vinculada. |
| **Setor de OPME** | Logística e validação de materiais especiais; cotação, verificação de estoque e registro de rastreabilidade (lote/série). | Dados técnicos de materiais e orçamentos; sem acesso a laudos sensíveis não relacionados ao material. |
| **Auditoria Médica (Convênio)** | Avaliação técnica da pertinência; aprova/nega guias, solicita informações complementares (diligência). | Acesso aos dados clínicos, CID-10, TUSS e justificativas pertinentes ao pedido em análise. |
| **Enfermagem/Gestão do CC** | Alocação de recursos físicos; monta mapa cirúrgico, reserva sala/robô e confirma checklists de segurança. | Visão global da agenda hospitalar e disponibilidade de equipamentos; acesso a necessidades de UTI e hemoderivados. |
| **Faturamento Hospitalar** | Processamento de contas; gera arquivos XML TISS, valida cobranças e concilia pagamentos. | Guia autorizada, materiais consumidos e prontuário administrativo. |
| **TI / Administrador** | Gestão de infraestrutura; gerencia usuários, parametriza listas (TUSS/CID) e consulta logs de auditoria. | Metadados técnicos; acesso ao mínimo necessário de dados clínicos. |

## 2. Estrutura de Dados (Payload do Pedido de Cirurgia)
O objeto central de dados deve respeitar o Padrão TISS para garantir interoperabilidade e evitar glosas. Cada registro na tabela `pedidos_cirurgia` deve conter:

- **Identificação do Paciente:** `paciente_id` (UUID), CNS (Cartão Nacional de Saúde), CPF, Nome Completo, e número de prontuário.
- **Dados do Convênio:** Operadora, plano, número da carteirinha, tipo de guia (TISS/AIH) e número da autorização/senha.
- **Dados Clínicos e Justificativa:** CID-10 (principal e secundários), indicação clínica detalhada, resumo clínico e laudos de exames (armazenados em buckets privados).
- **Procedimentos (Terminologia TUSS):** Código TUSS principal (ex: Prostatectomia Radical Robótica) e coadjuvantes (ex: Linfadenectomia), lateralidade e técnica cirúrgica.
- **Risco e Logística:** Classificação ASA, tempo estimado de sala, necessidade de vaga em UTI, reserva de hemoderivados e necessidade de congelação.
- **OPME Robótica Específica:** Relação de pinças (ex: ProGrasp, Maryland Bipolar, Monopolar Curved Scissors).
- **Rastreabilidade:** Código TUSS das pinças, drapes, grampeadores e controle de "vidas" remanescentes das pinças (uso limitado a 10 ou 18 usos).
- **Equipe Técnica:** CRM do Cirurgião principal (com verificação de certificação robótica), auxiliares, anestesista e indicação de proctor, se necessário.

## 3. Máquina de Estados (Status do Agendamento)
A transição de status é linear, auditável e gera registros em `audit_logs`.

1. `1_RASCUNHO`: Início do preenchimento; visível apenas ao Cirurgião e Secretária.
2. `2_AGUARDANDO_OPME`: Pedido enviado para cotação, reserva de materiais e validação de "vidas" de pinças.
3. `3_EM_AUDITORIA`: Envio eletrônico da Mensagem TISS de Solicitação para a operadora.
4. `4_PENDENCIA_TECNICA`: Auditoria solicita exames ou informações complementares (diligência).
5. `5_AUTORIZADO`: Emissão da guia autorizada e senha pelo convênio (pode ser total ou parcial).
6. `6_AGUARDANDO_MAPA`: Pedido autorizado aguardando alocação de sala e plataforma robótica pela coordenação do CC.
7. `7_AGENDADO_CC`: Data, hora e sala confirmadas no mapa cirúrgico; robô bloqueado.
8. `8_EM_EXECUCAO`: Procedimento em andamento no centro cirúrgico.
9. `9_REALIZADO`: Concluído; registro de consumo real e migração para fase de faturamento.
10. `10_CANCELADO`: Exige preenchimento obrigatório de `motivo_cancelamento` para fins de KPI e gestão de qualidade.

## 4. Gatilhos de Integração (Webhooks Telegram)
Mudanças de estado disparam Database Webhooks (via Supabase Edge Functions) para grupos específicos no Telegram. **Regra Crítica de Segurança:** Nenhuma mensagem conterá PII (nome, CPF) ou diagnóstico; apenas o ID do pedido e status.

- **Trigger 1 (Status 1 → 2):** Alvo: Grupo "Setor OPME". Mensagem: *"Nova solicitação de OPME Robótica. Pedido ID: [ID]. Procedimento: [TUSS]."*
- **Trigger 2 (Status 2 → 3):** Alvo: Grupo "Faturamento/Auditoria". Mensagem: *"Pedido ID: [ID] com OPME finalizada. Aguardando submissão TISS."*
- **Trigger 3 (Status 5 → 6):** Alvo: Grupo "Enfermagem CC". Mensagem: *"Pedido ID: [ID] AUTORIZADO. Necessita alocação de sala e robô."*
- **Trigger 4 (Status 6 → 7):** Alvo: Chat Direto (Cirurgião/Secretária). Mensagem: *"Cirurgia ID: [ID] confirmada. Data: [DATA], Sala: [SALA], Horário: [HORA]."*

## 5. Regras de Negócio e Fluxos Clínicos Adicionais

- **Conformidade TISS/TUSS:** O sistema deve estar integrado às tabelas de domínio da ANS e garantir que a versão vigente do padrão seja utilizada para evitar glosas administrativas.
- **Gestão de Pinças Robóticas:** O sistema deve validar a disponibilidade de pinças com "vidas" suficientes antes de permitir a mudança para o estado `AGENDADO_CC`. Deve-se diferenciar materiais "clicados" (que consomem vida ao conectar) de materiais de uso único (drapes).
- **Pré-Auditoria Automática:** Antes da submissão, o motor de regras deve confrontar o pedido com os contratos das operadoras (ex: Rol de Procedimentos ANS) para alertar sobre códigos não cobertos.
- **Monitora TISS:** O sistema deve gerar relatórios de completude de dados para mitigar o risco de avaliação negativa pela ANS e identificar padrões de glosa por falta de justificativa clínica.
- **Certificação e Proctoring:** Para cirurgiões em fase de curva de aprendizado (primeiros 20-50 procedimentos), o sistema deve exigir a indicação de um proctor certificado para validar o agendamento.
- **Registro de Consumo em Tempo Real:** A enfermagem deve registrar o consumo real (lote/série) durante o ato operatório para evitar discrepâncias entre o autorizado e o faturado.
- **Interoperabilidade:** O sistema deve permitir a captura de logs do console robótico para comprovar o tempo de uso da tecnologia junto às operadoras.

## 6. INTEGRAÇÕES DE ECOSSISTEMA E INTEROPERABILIDADE (CLOUD-FIRST)
O sistema deve atuar como um orquestrador central, comunicando-se com ferramentas externas de forma segura (Privacy by Design) via Supabase Edge Functions e Database Webhooks.

### 6.1. Google Calendar (Mapa Cirúrgico)
- **Gatilho:** Mudança de status para `6_AGENDADO_CC`.
- **Ação:** Criar evento no calendário da equipe cirúrgica.
- **Regra de Segurança (Zero-PHI):** O payload do evento deve conter APENAS as iniciais do paciente, hospital, sala, horário e equipamento (ex: "Robô Da Vinci"). É expressamente proibido enviar nome completo, CPF ou diagnóstico (CID) para o calendário.
- **Atualizações:** O sistema deve prever lógicas de `update` ou `delete` no evento caso a cirurgia seja reagendada ou o status mude para `8_CANCELADO`.

### 6.2. Metabase (Business Intelligence e KPIs)
- **Conexão:** O Metabase deve ser conectado ao PostgreSQL do Supabase utilizando um usuário com privilégios estritos de `READ-ONLY`.
- **Anonimização de Dados:** A arquitetura deve prever a criação de `Materialized Views` ou `Views` no Supabase que mascarem ou excluam colunas de identificação direta (nomes, CPFs) antes da leitura pelo Metabase.
- **Métricas-Alvo:** Dashboards focados em tempo de isquemia, taxa de conversão de autorizações, consumo de "vidas" de pinças robóticas e volume cirúrgico mensal por operadora.

### 6.3. Google Sheets (Faturamento e Auditoria)
- **Gatilho:** Mudança de status para `9_REALIZADO` ou via CRON Job de fechamento.
- **Ação:** Exportar dados da cirurgia para uma planilha de conciliação financeira.
- **Payload Administrativo:** Exportar apenas códigos TUSS, quantidade de materiais consumidos, lotes/séries de OPME e identificador da operadora. O nome do paciente deve ser substituído por um ID interno do sistema.

### 6.4. Google Docs e Google Drive (Documentação Clínica)
- **Gatilho:** Ação manual do usuário no frontend (ex: "Gerar Termo de Consentimento").
- **Ação:** A Edge Function deve ler um template no Google Docs, substituir tags (ex: `{{NOME_PACIENTE}}`, `{{PROCEDIMENTO}}`), exportar como PDF e salvar em uma pasta restrita no Google Drive.
- **Sincronização:** O link ou ID do PDF gerado deve ser salvo na tabela `pedidos_cirurgia` do Supabase para permitir o download seguro diretamente pela interface do SKIP, respeitando as regras de RLS do usuário autenticado.
