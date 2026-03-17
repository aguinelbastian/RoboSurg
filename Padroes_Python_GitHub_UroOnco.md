# PADRÕES DE CÓDIGO PYTHON E GITHUB PARA PROJETOS DE SAÚDE (URO-ONCOLOGIA)

Este documento estabelece as diretrizes arquiteturais e de sintaxe obrigatórias para todo código Python e fluxos do GitHub Actions gerados para este ecossistema. A prioridade é a segurança (compliance com LGPD/HIPAA), estabilidade e legibilidade.

## 1. DIRETRIZES GERAIS DE PYTHON (PEP 8 + STRICT TYPING)
- **Tipagem Estrita Obrigatória:** Toda função, método e classe deve conter Type Hints (anotações de tipo) para parâmetros e retornos.
- **Tratamento de Exceções:** Uso obrigatório de blocos `try/except`. Erros devem ser logados sem expor dados sensíveis (PHI/PII).
- **Variáveis de Ambiente:** Credenciais, chaves de API e URLs nunca devem ser "hardcoded". Uso obrigatório de `os.environ.get()`.
- **Docstrings:** Toda função deve ter uma docstring clara explicando o propósito, os argumentos e o retorno.

## 2. BOILERPLATE PADRÃO: INTEGRAÇÃO PYTHON + SUPABASE
Sempre que um script Python precisar interagir com o Supabase, este é o padrão arquitetural obrigatório:
```python
import os
import logging
from typing import Dict, Any, Optional
from supabase import create_client, Client

# Configuração de logging segura (sem expor dados médicos)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def init_supabase_client() -> Client:
    """
    Inicializa o cliente do Supabase utilizando variáveis de ambiente.
    Garante que a execução falhe imediatamente se as credenciais estiverem ausentes.
    """
    url: str = os.environ.get("SUPABASE_URL")
    key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") # Usar service_role apenas em backend seguro
    
    if not url or not key:
        logger.error("Falha na inicialização: Credenciais do Supabase ausentes no ambiente.")
        raise ValueError("SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY são obrigatórios.")
        
    return create_client(url, key)

def fetch_patient_data(patient_id: str) -> Optional[Dict[str, Any]]:
    """
    Busca dados de um paciente específico com tratamento de erros rigoroso.
    """
    supabase = init_supabase_client()
    
    try:
        # A query deve sempre respeitar as políticas de RLS configuradas no banco
        response = supabase.table("pacientes").select("*").eq("id", patient_id).execute()
        
        if not response.data:
            logger.warning(f"Nenhum dado encontrado para o paciente com ID fornecido.")
            return None
            
        return response.data[0]
        
    except Exception as e:
        # Loga o erro técnico, mas não expõe o ID do paciente ou dados da query no log de erro
        logger.error("Erro na transação com o banco de dados de pacientes.")
        raise
```
## 3. PADRÃO GITHUB: ESTRUTURA DE REPOSITÓRIO
Todo repositório deve seguir esta estrutura de pastas para separação de responsabilidades:
```
├── .github/
│   └── workflows/
│       └── ci_cd_pipeline.yml
├── src/
│   ├── api/          # Endpoints ou Edge Functions
│   ├── core/         # Lógica de negócio e modelos de dados
│   └── utils/        # Funções auxiliares e conexões de banco
├── tests/            # Testes unitários (pytest)
├── .gitignore
├── requirements.txt
└── README.md
```
## 4. PADRÃO GITHUB ACTIONS: CI/CD PIPELINE
Todo repositório deve conter um workflow de CI/CD para garantir que código quebrado não chegue à produção.
O arquivo .github/workflows/ci_cd_pipeline.yml padrão é:
```
name: UroOnco Python CI/CD

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v3
      
    - name: Set up Python 3.11
      uses: actions/setup-python@v4
      with:
        python-version: "3.11"
        
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install ruff pytest
        if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
        
    - name: Lint with Ruff (Verificação de sintaxe e PEP 8)
      run: |
        ruff check .
        
    - name: Run Tests (Validação de lógica de negócio)
      env:
        SUPABASE_URL: ${{ secrets.TEST_SUPABASE_URL }}
        SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.TEST_SUPABASE_KEY }}
      run: |
        pytest tests/
```
## 5. REGRAS DE OURO (INVIOLÁVEIS)
- Zero Hardcoding: Nenhuma senha, token, chave de API ou URL de banco de dados deve existir no código-fonte.
- Logs Sanitizados: É expressamente proibido logar variáveis que contenham PHI (Protected Health Information) como nomes, CPFs ou diagnósticos.
- Princípio do Menor Privilégio: Scripts de automação devem usar chaves de API restritas ao escopo da tarefa, evitando o uso indiscriminado da service_role_key a menos que estritamente necessário para operações de admin.

