import os
from pathlib import Path

import psycopg2
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / ".env")


def main() -> None:
    database_url = os.getenv("DATABASE_URL", "")
    if not database_url or "password@" in database_url or "xxxxx" in database_url:
        raise SystemExit(
            "DATABASE_URL no esta configurada. Copiala desde Supabase > Connect > Database."
        )

    schema_path = ROOT / "database" / "supabase_schema.sql"
    with schema_path.open(encoding="utf-8") as schema_file:
        schema_sql = schema_file.read()

    with psycopg2.connect(database_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute(schema_sql)

    print("SUPABASE_SCHEMA_APPLIED=OK")


if __name__ == "__main__":
    main()
