from datetime import datetime

from sqlalchemy import ForeignKey, Integer, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
from app.models.usuario import Usuario


class Resena(Base):
    """Reseña de una receta de TheMealDB. Cada persona escribe como máximo una por receta,
    y todas las reseñas de una receta son visibles para cualquier usuario autenticado."""

    __tablename__ = "resenas"
    __table_args__ = (UniqueConstraint("usuario_id", "receta_id", name="uq_resenas_usuario_receta"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    receta_id: Mapped[str] = mapped_column(String(20), index=True)
    receta_nombre: Mapped[str] = mapped_column(String(200))
    calificacion: Mapped[int] = mapped_column(Integer)
    comentario: Mapped[str] = mapped_column(String(500))
    creada: Mapped[datetime] = mapped_column(server_default=func.now())
    usuario_id: Mapped[int] = mapped_column(ForeignKey("usuarios.id", ondelete="CASCADE"), index=True)

    autor: Mapped[Usuario] = relationship(lazy="joined")
