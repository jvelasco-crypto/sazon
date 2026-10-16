from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.resena import Resena


class ResenaDuplicadaError(Exception):
    pass


def _a_dict(r: Resena, usuario_actual_id: int) -> dict:
    return {
        "id": r.id,
        "receta_id": r.receta_id,
        "receta_nombre": r.receta_nombre,
        "calificacion": r.calificacion,
        "comentario": r.comentario,
        "creada": r.creada,
        "autor": r.autor.email,
        "es_mia": r.usuario_id == usuario_actual_id,
    }


def crear(db: Session, usuario_id: int, receta_id: str, receta_nombre: str, calificacion: int, comentario: str) -> dict:
    resena = Resena(
        usuario_id=usuario_id,
        receta_id=receta_id,
        receta_nombre=receta_nombre,
        calificacion=calificacion,
        comentario=comentario,
    )
    db.add(resena)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise ResenaDuplicadaError("Ya escribiste una reseña para esta receta; puedes editarla")
    db.refresh(resena)
    return _a_dict(resena, usuario_id)


def de_receta(db: Session, receta_id: str, usuario_actual_id: int) -> list[dict]:
    """Todas las reseñas de una receta, de cualquier autor (funcionalidad colaborativa)."""
    filas = db.scalars(select(Resena).where(Resena.receta_id == receta_id).order_by(Resena.creada.desc(), Resena.id.desc())).all()
    return [_a_dict(r, usuario_actual_id) for r in filas]


def del_usuario(db: Session, usuario_id: int) -> list[dict]:
    filas = db.scalars(select(Resena).where(Resena.usuario_id == usuario_id).order_by(Resena.creada.desc(), Resena.id.desc())).all()
    return [_a_dict(r, usuario_id) for r in filas]


def obtener(db: Session, resena_id: int) -> Resena | None:
    return db.get(Resena, resena_id)


def actualizar(db: Session, resena: Resena, cambios: dict, usuario_actual_id: int) -> dict:
    for campo, valor in cambios.items():
        setattr(resena, campo, valor)
    db.commit()
    db.refresh(resena)
    return _a_dict(resena, usuario_actual_id)


def eliminar(db: Session, resena: Resena) -> None:
    db.delete(resena)
    db.commit()


def resumen(db: Session, receta_id: str) -> dict:
    cantidad, promedio = db.execute(
        select(func.count(Resena.id), func.avg(Resena.calificacion)).where(Resena.receta_id == receta_id)
    ).one()
    return {"receta_id": receta_id, "cantidad": int(cantidad), "promedio": None if promedio is None else round(float(promedio), 1)}
