# MANUAL DE FLUXO – SISTEMA DE MARCAÇÃO DE CIRURGIA ROBÓTICA  
(Hospital brasileiro de médio/grande porte)

## 1. Atores e Permissões (RBAC)

### 1.1 Atores

- Cirurgião solicitante  
- Cirurgião auxiliar / equipe cirúrgica  
- Secretária do consultório / Central de Marcação  
- Médico assistente  
- Setor de Autorização de Convênios / Faturamento  
- Auditoria médica do convênio (operadora)  
- Setor de OPME / Suprimentos cirúrgicos  
- Enfermagem do Centro Cirúrgico (CC)  
- Coordenação do Centro Cirúrgico  
- Anestesiologia / SCA  
- CME / Esterilização  
- Almoxarifado / Farmácia cirúrgica  
- Coordenação de Internação / Hotelaria  
- Núcleo de Segurança do Paciente / Qualidade  
- TI / Administrador do Sistema  

### 1.2 Perfis e permissões (visão funcional)

#### Cirurgião

- Pode:  
  - Criar e editar pedidos de cirurgia até submissão.  
  - Indicar procedimentos (TUSS/SUS), técnica robótica, tempo estimado, posição, necessidade de UTI, materiais/OPME.  
  - Anexar laudos, exames, parecer de risco cirúrgico.  
- Vê:  
  - Todos os pedidos em que é solicitante.  
  - Status (rascunho → autorizado → agendado → realizado/cancelado).  
  - Pareceres de auditoria, itens autorizados/glosados, datas de agendamento e histórico básico.  

#### Secretária do consultório

- Pode:  
  - Pré‑cadastrar paciente, convênio, guia.  
  - Lançar pedido em nome do cirurgião.  
  - Atualizar dados administrativos (contato, número de autorização do plano).  
- Vê:  
  - Pedidos dos médicos que representa.  
  - Pendências de documentos e retornos do convênio.  

#### Setor de Autorização / Faturamento

- Pode:  
  - Conferir elegibilidade, preencher/enviar guias TISS/AIH.  
  - Registrar número de autorização, validade, tipo de cobertura.  
  - Marcar pedido como autorizado total, parcial ou negado e registrar motivo.  
- Vê:  
  - Dados clínicos mínimos necessários, CID, TUSS, OPME solicitadas.  
  - Histórico de interações com o convênio.  

#### Auditoria médica do convênio

- Pode:  
  - Acessar pedido, laudos, exames.  
  - Registrar parecer (aprovado, aprovado com ajustes, negado).  
  - Ajustar quantidade/códigos de OPME, sugerir substituições.  
- Vê:  
  - Dados clínicos pertinentes, CID, TUSS, justificativas técnicas, protocolos.  

#### Setor de OPME / Suprimentos

- Pode:  
  - Avaliar lista de OPME (padronização, registro ANVISA, estoque).  
  - Cadastrar cotação, selecionar fornecedor, registrar reserva/compra.  
  - Vincular lote/série/validade ao agendamento.  
- Vê:  
  - Descrição técnica dos itens, códigos internos e TUSS, indicação/justificativa.  
  - Data da cirurgia, convênio, regras contratuais.  

#### Enfermagem / Coordenação do CC

- Pode:  
  - Montar mapa cirúrgico; alocar sala, horário, equipe.  
  - Verificar liberação de OPME e robô.  
  - Confirmar checklists de segurança; reagendar ou cancelar conforme protocolo.  
- Vê:  
  - Autorizações, status do pedido, tempo previsto de sala.  
  - Equipamentos especiais, reserva de UTI, sangue, posição cirúrgica.  

#### Anestesiologia

- Pode:  
  - Registrar avaliação pré‑anestésica e risco anestésico.  
  - Definir tipo de anestesia, necessidades específicas.  
  - Liberar ou contraindicar o procedimento.  
- Vê:  
  - Quadro clínico, exames, comorbidades, medicação de uso contínuo.  
  - Data/hora da cirurgia.  

#### Almoxarifado / CME / Farmácia

- Pode:  
  - Registrar recebimento e conferência de OPME e instrumentais.  
  - Dar baixa em estoque e vincular consumo ao paciente.  
- Vê:  
  - Cirurgias agendadas com materiais previstos.  
  - Reservas, lotes, validade e rastreabilidade.  

#### Coordenação de Internação / Hotelaria

- Pode:  
  - Reservar leito/UTI/isolamento.  
  - Ajustar data de internação conforme agenda cirúrgica.  
- Vê:  
  - Data/hora do procedimento, previsão de permanência.  
  - Tipo de acomodação e convênio.  

#### Núcleo de Segurança do Paciente / Qualidade

- Pode:  
  - Cadastrar e acompanhar incidentes, não conformidades, infecção de sítio cirúrgico.  
- Vê:  
  - Indicadores de cancelamento, tempo de espera, uso de OPME.  

#### TI / Administrador do sistema

- Pode:  
  - Gerir usuários, papéis, permissões e RLS.  
  - Parametrizar listas (CID, TUSS, catálogo de OPME).  
  - Consultar logs de auditoria técnica.  
- Vê:  
  - Metadados técnicos e configurações; o mínimo necessário de dado clínico.  

---

## 2. Dados Transitados (Payload do Pedido de Cirurgia)

### 2.1 Identificação do paciente

- Nome completo, CPF/Cartão SUS, data de nascimento, sexo.  
- Contato (telefone, e‑mail), endereço.  
- Número de prontuário, médico assistente, unidade de internação prevista.  

### 2.2 Convênio e guias

- Operadora, plano, número da carteirinha, validade.  
- Tipo de atendimento (eletivo, urgência, SUS, particular).  
- Tipo de guia (TISS/AIH), número e data de solicitação.  
- Número de autorização, validade, carências, coparticipação, limites de OPME.  

### 2.3 Dados clínicos do procedimento

- CID‑10 principal e secundários.  
- Indicação cirúrgica, resumo clínico, falha de tratamento conservador.  
- Tipo de cirurgia (robótica, laparoscópica, aberta etc.).  
- Procedimento(s) com código TUSS/CBHPM ou SUS.  
- Especialidade cirúrgica, lateridade, região anatômica, porte e tempo estimado.  

### 2.4 Risco cirúrgico e anestésico

- Parecer de risco cirúrgico (data, classificação, recomendações).  
- Classificação ASA, tipo de anestesia prevista.  
- Necessidade de UTI pós‑operatória, reserva de sangue/hemoderivados.  

### 2.5 Dados específicos da cirurgia robótica

- Plataforma robótica, console, braços, torres, instrumentais dedicados.  
- Tipo de kit robótico (trocárteres, pinças, grampeadores, cabos).  
- Confirmação de equipe treinada em robótica.  

### 2.6 Materiais especiais / OPME

- Lista detalhada de OPME: descrição técnica, finalidade, códigos internos e TUSS, registro ANVISA, quantidades e tamanhos.  
- Justificativa clínica por item quando necessário.  
- Informação sobre padronização ou exceção.  

### 2.7 Logística e agendamento

- Datas alvo, restrições de agenda, prioridade clínica.  
- Tipo de sala (robótica), equipamentos complementares.  
- Necessidade de internação prévia, reserva de UTI, isolamento, dieta.  

### 2.8 Documentos anexos

- Exames de imagem e laboratoriais relevantes.  
- Termo de consentimento para cirurgia robótica.  
- Pareceres de comitês, quando aplicável.  

---

## 3. Máquina de Estados (Status do Agendamento)

### 3.1 Estados sugeridos

1. **1_RASCUNHO** – pedido iniciado, não submetido.  
2. **2_ENVIADO_PARA_ANALISE_INTERNA** – checagem interna básica.  
3. **3_EM_ANALISE_OPME** – avaliação de OPME (padronização, estoque, ANVISA).  
4. **4_EM_AUDITORIA_CONVENIO** – análise do convênio.  
5. **5_OPME_NEGOCIACAO** – contraproposta/repactuação de OPME.  
6. **6_AUTORIZADO_PARCIAL** – parte dos itens/procedimentos autorizados.  
7. **7_AUTORIZADO_TOTAL** – tudo autorizado, apto a agendar.  
8. **8_AGENDAMENTO_CC_PENDENTE** – aguardando alocação de sala/equipe/robô.  
9. **9_AGENDADO_CC** – data/hora/sala definidas, OPME reservada.  
10. **10_EM_EXECUCAO** – procedimento em andamento.  
11. **11_REALIZADO** – procedimento concluído e consumo registrado.  
12. **12_CANCELADO** – cancelado, com motivo classificado.  
13. **13_SUSPENSO_ADIADO** – adiado, mantendo caso ativo.  

### 3.2 Transições principais (exemplos)

- 1_RASCUNHO → 2_ENVIADO_PARA_ANALISE_INTERNA (cirurgião/secretária).  
- 2_ENVIADO_PARA_ANALISE_INTERNA → 3_EM_ANALISE_OPME (se houver OPME).  
- 3_EM_ANALISE_OPME → 4_EM_AUDITORIA_CONVENIO (após parecer OPME).  
- 4_EM_AUDITORIA_CONVENIO → 6_AUTORIZADO_PARCIAL ou 7_AUTORIZADO_TOTAL (retorno convênio).  
- 7_AUTORIZADO_TOTAL → 8_AGENDAMENTO_CC_PENDENTE → 9_AGENDADO_CC (coordenação CC).  
- 9_AGENDADO_CC → 11_REALIZADO (após fechamento de consumo).  
- Qualquer estado ≥2 → 12_CANCELADO ou 13_SUSPENSO_ADIADO (com motivo).  

---

## 4. Diretrizes normativas básicas para OPME

- Observar legislação sanitária (registro ANVISA, rastreabilidade, proibição de reprocesso indevido).  
- Registrar sempre: código, lote, série, validade, fabricante e vínculo ao paciente.  
- Garantir que AIH/TISS estejam corretas para evitar glosas (procedimentos e OPME compatíveis).  
- Manter trilhas de auditoria e relatórios que permitam confrontar OPME autorizada x utilizada x faturada.  

---

## 5. Matriz RBAC (para Supabase / RLS)

### 5.1 Perfis x Permissões (alto nível)

Entidades sugeridas:  
- `pedidos_cirurgia`  
- `itens_opme`  
- `agendamentos_cc`  
- `anexos`  
- `pacientes` (visão limitada)  
- `logs_status`  

```markdown
| Perfil                         | Entidade            | Pode_Ler                                | Pode_Criar          | Pode_Editar                              | Pode_Deletar | Escopo_RLS_Exemplo                                                                                               |
|-------------------------------|---------------------|-----------------------------------------|---------------------|------------------------------------------|-------------|------------------------------------------------------------------------------------------------------------------|
| Cirurgiao                     | pedidos_cirurgia    | Sim (onde solicitante)                  | Sim                 | Sim (até envio análise interna)          | Não          | `solicitante_id = auth.uid()`                                                                                   |
| Cirurgiao                     | itens_opme          | Sim (se do seu pedido)                  | Sim                 | Sim (até envio análise interna)          | Não          | `pedido.solicitante_id = auth.uid()`                                                                            |
| Cirurgiao                     | agendamentos_cc     | Sim (dos seus pedidos)                  | Não                 | Não                                       | Não          | `pedido.solicitante_id = auth.uid()`                                                                            |
| Cirurgiao                     | anexos              | Sim (se do seu pedido)                  | Sim                 | Sim (até envio análise interna)          | Não          | `pedido.solicitante_id = auth.uid()`                                                                            |
| Cirurgiao                     | pacientes           | Sim (pacientes dos seus pedidos)        | Não                 | Não                                       | Não          | `id IN (SELECT paciente_id FROM pedidos_cirurgia WHERE solicitante_id = auth.uid())`                            |
| Secretária                    | pedidos_cirurgia    | Sim (médicos vinculados)                | Sim                 | Sim (até envio análise interna)          | Não          | `solicitante_id IN (SELECT medico_id FROM medico_secretaria WHERE secretaria_id = auth.uid())`                  |
| Secretária                    | itens_opme          | Sim (médicos vinculados)                | Sim                 | Sim (até envio análise interna)          | Não          | Mesmo acima                                                                                                      |
| Autorizacao_Convenios        | pedidos_cirurgia    | Sim (todos da unidade)                  | Não                 | Sim (campos de autorização/status)       | Não          | `hospital_id = current_setting('app.hospital_id')`                                                              |
| Autorizacao_Convenios        | itens_opme          | Sim                                     | Não                 | Sim (marcar como autorizado/glosado)     | Não          | Mesmo acima                                                                                                      |
| Autorizacao_Convenios        | anexos              | Sim (clínicos mínimos)                  | Não                 | Não                                       | Não          | Filtrar tipo de anexo (TISS/AIH)                                                                               |
| Auditoria_Convenio (externo) | pedidos_cirurgia    | Sim (em portal/API)                     | Não                 | Sim (parecer auditoria)                  | Não          | `convenio_id = auth.convenio_id`                                                                                |
| Auditoria_Convenio (externo) | itens_opme          | Sim                                     | Não                 | Sim (ajustes quantidade/código)          | Não          | Mesmo acima                                                                                                      |
| Setor_OPME                    | pedidos_cirurgia    | Sim                                     | Não                 | Sim (campos de parecer_opme)             | Não          | `hospital_id = current_setting('app.hospital_id')`                                                              |
| Setor_OPME                    | itens_opme          | Sim                                     | Sim (itens internos) | Sim (status_opme, fornecedor, lote)     | Não          | Mesmo acima                                                                                                      |
| Enfermagem_CC                 | pedidos_cirurgia    | Sim                                     | Não                 | Não (clínico); Sim (campos operacionais) | Não          | `status IN ('7_AUTORIZADO_TOTAL','8_AGENDAMENTO_CC_PENDENTE','9_AGENDADO_CC')`                                  |
| Enfermagem_CC                 | agendamentos_cc     | Sim                                     | Sim                 | Sim (sala, horário, equipe)              | Não          | Mesmo acima                                                                                                      |
| Anestesiologia                | pedidos_cirurgia    | Sim                                     | Não                 | Sim (campos risco_anestesico)            | Não          | `status >= '2_ENVIADO_PARA_ANALISE_INTERNA'`                                                                     |
| Anestesiologia                | anexos              | Sim                                     | Sim (laudos pré‑anestésicos) | Sim                         | Não          | Mesmo acima                                                                                                      |
| Almoxarifado_CME_Farmacia    | itens_opme          | Sim                                     | Não                 | Sim (lote, série, consumo)               | Não          | `status_pedido IN ('9_AGENDADO_CC','11_REALIZADO')`                                                             |
| Almoxarifado_CME_Farmacia    | agendamentos_cc     | Sim                                     | Não                 | Não                                       | Não          | Mesmo acima                                                                                                      |
| Internacao_Hotelaria          | pedidos_cirurgia    | Sim (dados mínimos)                     | Não                 | Sim (campos de leito, previsão alta)     | Não          | `hospital_id = current_setting('app.hospital_id')`                                                              |
| NSP_Qualidade                 | pedidos_cirurgia    | Sim (dados desidentificados/limitados)  | Não                 | Não                                       | Não          | Acesso por views com mascaramento                                                                             |
| NSP_Qualidade                 | logs_status         | Sim (para indicadores)                  | Não                 | Não                                       | Não          | Mesmo acima                                                                                                      |
| TI_Admin                      | *metadados*         | Sim                                     | Sim (usuários, perfis) | Sim (config)                        | Não dados clínicos | RLS específico para admin, idealmente via views separadas                                            |
```

### 5.2 Notas práticas de implementação

- Criar tabela `roles` (cirurgiao, secretaria, opme, enfermagem_cc, etc.).  
- Tabela `user_roles` ligando `user_id` a `role_id`.  
- Em Supabase, políticas RLS por tabela, usando `auth.uid()` + sub‑queries em `user_roles`.  
- Views específicas para auditoria de convênio e NSP com mascaramento de campos sensíveis.  
