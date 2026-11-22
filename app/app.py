import os, time, psycopg2
from flask import Flask, request, jsonify, render_template_string, redirect, url_for

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST", "db")
DB_NAME = os.environ.get("POSTGRES_DB", "appdb")
DB_USER = os.environ.get("POSTGRES_USER", "appuser")
DB_PASS = os.environ.get("POSTGRES_PASSWORD", "")

def get_db_connection():
    retries = 5
    while retries > 0:
        try:
            return psycopg2.connect(host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS)
        except psycopg2.OperationalError:
            retries -= 1
            time.sleep(2)
    raise Exception("Не вдалося підключитися до PostgreSQL")

def init_db():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('CREATE TABLE IF NOT EXISTS notes (id SERIAL PRIMARY KEY, content TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);')
    conn.commit()
    cur.close()
    conn.close()

try:
    init_db()
except Exception as e:
    print(f"Помилка БД: {e}")

HTML = '''
<!DOCTYPE html><html><head><title>DevOps App</title></head>
<body>
    <h2>🚀 DevOps Infrastructure Project</h2>
    <form method="POST" action="/add">
        <input type="text" name="content" required>
        <button type="submit">Додати запис</button>
    </form>
    <h3>Нотатки у БД:</h3>
    <ul>
    {% for note in notes %}
        <li><strong>#{{ note[0] }}</strong>: {{ note[1] }} ({{ note[2] }})</li>
    {% endfor %}
    </ul>
</body></html>
'''

@app.route('/')
def index():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT id, content, created_at FROM notes ORDER BY id DESC;')
    notes = cur.fetchall()
    cur.close()
    conn.close()
    return render_template_string(HTML, notes=notes)

@app.route('/add', methods=['POST'])
def add():
    content = request.form.get('content')
    if content:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('INSERT INTO notes (content) VALUES (%s);', (content,))
        conn.commit()
        cur.close()
        conn.close()
    return redirect(url_for('index'))

@app.route('/health')
def health():
    try:
        conn = get_db_connection()
        conn.close()
        return jsonify(status="OK"), 200
    except Exception as e:
        return jsonify(status="ERROR", message=str(e)), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
