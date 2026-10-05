import os, sys, logging
import psycopg
from flask import Flask, request, jsonify

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("backend")

REQUIRED = ["DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD"]
missing = [v for v in REQUIRED if not os.environ.get(v)]
if missing:
    log.error("Missing required environment variables: %s", ", ".join(missing))
    sys.exit(1)

DSN = (
    f"host={os.environ['DB_HOST']} port={os.environ.get('DB_PORT', '5432')} "
    f"dbname={os.environ['DB_NAME']} user={os.environ['DB_USER']} "
    f"password={os.environ['DB_PASSWORD']} connect_timeout=3"
)

app = Flask(__name__)


def query(sql, params=None, fetch=False):
    with psycopg.connect(DSN) as conn:
        conn.execute("CREATE TABLE IF NOT EXISTS items (id SERIAL PRIMARY KEY, name TEXT NOT NULL)")
        cur = conn.execute(sql, params)
        return cur.fetchall() if fetch else None


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready():
    try:
        query("SELECT 1")
        return {"status": "ready"}
    except Exception as e:
        log.error("DB not ready: %s", e)
        return {"status": "db unavailable"}, 503


@app.get("/items")
def list_items():
    rows = query("SELECT id, name FROM items ORDER BY id", fetch=True)
    return jsonify([{"id": r[0], "name": r[1]} for r in rows])


@app.post("/items")
def add_item():
    name = (request.get_json(silent=True) or {}).get("name")
    if not name:
        return {"error": "name is required"}, 400
    query("INSERT INTO items (name) VALUES (%s)", (name,))
    return {"status": "created"}, 201