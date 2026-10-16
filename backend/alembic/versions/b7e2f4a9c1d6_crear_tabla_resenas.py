"""crear tabla resenas (Sazón)

Revision ID: b7e2f4a9c1d6
Revises: a3f5c8d1e2b4
Create Date: 2026-10-16 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'b7e2f4a9c1d6'
down_revision: Union[str, Sequence[str], None] = 'a3f5c8d1e2b4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "resenas",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("receta_id", sa.String(20), nullable=False),
        sa.Column("receta_nombre", sa.String(200), nullable=False),
        sa.Column("calificacion", sa.Integer(), nullable=False),
        sa.Column("comentario", sa.String(500), nullable=False),
        sa.Column("creada", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column("usuario_id", sa.Integer(), sa.ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False),
        sa.UniqueConstraint("usuario_id", "receta_id", name="uq_resenas_usuario_receta"),
    )
    op.create_index("ix_resenas_receta_id", "resenas", ["receta_id"])
    op.create_index("ix_resenas_usuario_id", "resenas", ["usuario_id"])


def downgrade() -> None:
    op.drop_index("ix_resenas_usuario_id", table_name="resenas")
    op.drop_index("ix_resenas_receta_id", table_name="resenas")
    op.drop_table("resenas")
