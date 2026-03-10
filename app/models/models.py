from sqlalchemy import Column, Integer, String, DateTime, Float, Boolean, ForeignKey, Enum, Text
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
import enum

Base = declarative_base()

class StatusCirurgia(str, enum.Enum):
    SOLICITADA = "solicitada"
    DISPONIBILIDADE_OK = "disponibilidade_ok"
    ORCAMENTO_GERADO = "orcamento_gerado"
    TASKS_DISPARADAS = "tasks_disparadas"
    VALIDADA = "validada"
    CONFIRMADA = "confirmada"
    PUBLICADA = "publicada"
    CANCELADA = "cancelada"

class StatusLeito(str, enum.Enum):
    DISPONIVEL = "disponivel"
    OCUPADO = "ocupado"
    MANUTENCAO = "manutencao"
    RESERVADO = "reservado"

class StatusSala(str, enum.Enum):
    DISPONIVEL = "disponivel"
    OCUPADA = "ocupada"
    MANUTENCAO = "manutencao"
    RESERVADA = "reservada"

class TipoTask(str, enum.Enum):
    ANESTESIA = "anestesia"
    ENFERMAGEM = "enfermagem"
    CME = "cme"
    RECEPCAO = "recepcao"
    FATURAMENTO = "faturamento"
    ROBOTICA = "robotica"

class Paciente(Base):
    __tablename__ = "pacientes"
    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(200), nullable=False)
    cpf = Column(String(14), unique=True, index=True)
    data_nascimento = Column(DateTime)
    telefone = Column(String(20))
    email = Column(String(100))
    convenio_id = Column(Integer, ForeignKey("convenios.id"))
    numero_carteirinha = Column(String(50))
    criado_em = Column(DateTime, default=datetime.utcnow)
    convenio = relationship("Convenio", back_populates="pacientes")
    cirurgias = relationship("Cirurgia", back_populates="paciente")

class Cirurgiao(Base):
    __tablename__ = "cirurgioes"
    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(200), nullable=False)
    crm = Column(String(20), unique=True, index=True)
    especialidade = Column(String(100))
    telefone = Column(String(20))
    email = Column(String(100))
    telegram_chat_id = Column(String(50))
    ativo = Column(Boolean, default=True)
    criado_em = Column(DateTime, default=datetime.utcnow)
    cirurgias = relationship("Cirurgia", back_populates="cirurgiao")

class SalaRobotica(Base):
    __tablename__ = "salas_roboticas"
    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(100), nullable=False)
    sistema_robotico = Column(String(100))
    status = Column(Enum(StatusSala), default=StatusSala.DISPONIVEL)
    observacoes = Column(Text)
    ativo = Column(Boolean, default=True)
    cirurgias = relationship("Cirurgia", back_populates="sala")

class Leito(Base):
    __tablename__ = "leitos"
    id = Column(Integer, primary_key=True, index=True)
    numero = Column(String(20), nullable=False)
    andar = Column(String(20))
    tipo = Column(String(50))
    status = Column(Enum(StatusLeito), default=StatusLeito.DISPONIVEL)
    ativo = Column(Boolean, default=True)
    cirurgias = relationship("Cirurgia", back_populates="leito")

class Convenio(Base):
    __tablename__ = "convenios"
    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(200), nullable=False)
    codigo_ans = Column(String(20))
    tipo = Column(String(50))
    ativo = Column(Boolean, default=True)
    pacientes = relationship("Paciente", back_populates="convenio")
    pacotes = relationship("PacoteOrcamento", back_populates="convenio")
    cirurgias = relationship("Cirurgia", back_populates="convenio")

class PacoteOrcamento(Base):
    __tablename__ = "pacotes_orcamento"
    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(200), nullable=False)
    procedimento_codigo = Column(String(50))
    procedimento_descricao = Column(String(300))
    convenio_id = Column(Integer, ForeignKey("convenios.id"))
    valor_total = Column(Float)
    inclui_robotica = Column(Boolean, default=True)
    inclui_anestesia = Column(Boolean, default=True)
    inclui_diaria = Column(Boolean, default=True)
    tempo_previsto_minutos = Column(Integer)
    ativo = Column(Boolean, default=True)
    criado_em = Column(DateTime, default=datetime.utcnow)
    convenio = relationship("Convenio", back_populates="pacotes")

class Cirurgia(Base):
    __tablename__ = "cirurgias"
    id = Column(Integer, primary_key=True, index=True)
    paciente_id = Column(Integer, ForeignKey("pacientes.id"), nullable=False)
    cirurgiao_id = Column(Integer, ForeignKey("cirurgioes.id"), nullable=False)
    procedimento_descricao = Column(String(300), nullable=False)
    procedimento_codigo = Column(String(50))
    sala_id = Column(Integer, ForeignKey("salas_roboticas.id"))
    leito_id = Column(Integer, ForeignKey("leitos.id"))
    convenio_id = Column(Integer, ForeignKey("convenios.id"))
    data_hora_inicio = Column(DateTime, nullable=False)
    tempo_previsto_minutos = Column(Integer, default=120)
    status = Column(Enum(StatusCirurgia), default=StatusCirurgia.SOLICITADA)
    pacote_orcamento_id = Column(Integer, ForeignKey("pacotes_orcamento.id"))
    valor_orcamento = Column(Float)
    orcamento_aprovado = Column(Boolean, default=False)
    validado_por = Column(String(200))
    validado_em = Column(DateTime)
    observacoes_validacao = Column(Text)
    criado_em = Column(DateTime, default=datetime.utcnow)
    atualizado_em = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    criado_por = Column(String(100))
    paciente = relationship("Paciente", back_populates="cirurgias")
    cirurgiao = relationship("Cirurgiao", back_populates="cirurgias")
    sala = relationship("SalaRobotica", back_populates="cirurgias")
    leito = relationship("Leito", back_populates="cirurgias")
    convenio = relationship("Convenio", back_populates="cirurgias")
    tasks = relationship("Task", back_populates="cirurgia")

class Task(Base):
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True, index=True)
    cirurgia_id = Column(Integer, ForeignKey("cirurgias.id"), nullable=False)
    tipo = Column(Enum(TipoTask), nullable=False)
    descricao = Column(Text)
    responsavel_nome = Column(String(200))
    responsavel_telegram_id = Column(String(50))
    enviada_em = Column(DateTime)
    confirmada_em = Column(DateTime)
    confirmada = Column(Boolean, default=False)
    prazo = Column(DateTime)
    cirurgia = relationship("Cirurgia", back_populates="tasks")
