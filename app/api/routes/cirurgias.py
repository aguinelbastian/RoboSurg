from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.database.session import get_db
from app.models.models import Cirurgia, StatusCirurgia

router = APIRouter()

class ValidacaoInput(BaseModel):
    validado_por: str
    observacoes: Optional[str] = None

@router.get("/hoje", summary="Cirurgias do dia")
def cirurgias_hoje(db: Session = Depends(get_db)):
    hoje = datetime.utcnow().date()
    result = []
    for c in db.query(Cirurgia).filter(Cirurgia.status.in_([StatusCirurgia.CONFIRMADA, StatusCirurgia.PUBLICADA])).all():
        if c.data_hora_inicio.date() == hoje:
            result.append({
                "id": c.id,
                "paciente": c.paciente.nome if c.paciente else "N/A",
                "cirurgiao": c.cirurgiao.nome if c.cirurgiao else "N/A",
                "procedimento": c.procedimento_descricao,
                "sala": c.sala.nome if c.sala else "N/A",
                "leito": c.leito.numero if c.leito else "N/A",
                "convenio": c.convenio.nome if c.convenio else "N/A",
                "data_hora": c.data_hora_inicio.isoformat(),
                "tempo_previsto_min": c.tempo_previsto_minutos,
                "status": c.status
            })
    return result

@router.post("/{cirurgia_id}/validar", summary="Validar cirurgia")
def validar_cirurgia(cirurgia_id: int, dados: ValidacaoInput, db: Session = Depends(get_db)):
    c = db.query(Cirurgia).filter(Cirurgia.id == cirurgia_id).first()
    if not c: raise HTTPException(404, "Não encontrada")
    c.status = StatusCirurgia.VALIDADA
    c.validado_por = dados.validado_por
    c.validado_em = datetime.utcnow()
    c.observacoes_validacao = dados.observacoes
    db.commit()
    return {"mensagem": f"✅ Cirurgia #{cirurgia_id} validada por {dados.validado_por}"}

@router.post("/{cirurgia_id}/confirmar", summary="Confirmar cirurgia")
def confirmar_cirurgia(cirurgia_id: int, db: Session = Depends(get_db)):
    c = db.query(Cirurgia).filter(Cirurgia.id == cirurgia_id).first()
    if not c: raise HTTPException(404, "Não encontrada")
    if c.status != StatusCirurgia.VALIDADA: raise HTTPException(400, "Precisa ser validada primeiro")
    c.status = StatusCirurgia.CONFIRMADA
    db.commit()
    return {"mensagem": f"✅ Cirurgia #{cirurgia_id} confirmada!"}

@router.post("/{cirurgia_id}/publicar", summary="Publicar no painel")
def publicar_cirurgia(cirurgia_id: int, db: Session = Depends(get_db)):
    c = db.query(Cirurgia).filter(Cirurgia.id == cirurgia_id).first()
    if not c: raise HTTPException(404, "Não encontrada")
    if c.status != StatusCirurgia.CONFIRMADA: raise HTTPException(400, "Precisa estar confirmada primeiro")
    c.status = StatusCirurgia.PUBLICADA
    db.commit()
    return {"mensagem": f"📢 Cirurgia #{cirurgia_id} publicada!"}
