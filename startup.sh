#!/bin/bash
set -euxo pipefail

AWS_REGION="us-west-2"
DB_SECRET_ID="lab/rds/mysql"   # your Secrets Manager secret name/ARN

# Update + install nginx + python
dnf -y update || true
dnf -y install nginx python3 python3-pip

systemctl enable --now nginx

# Python deps for Flask + MySQL + Secrets Manager

# Old Version
# pip3 install --upgrade pip
# pip3 install flask pymysql boto3

python3 -m pip install --upgrade pip || true
python3 -m pip install flask pymysql boto3


# -------------------------
# Flask Notes App (EC2 -> RDS)
# -------------------------
mkdir -p /opt/notesapp

cat >/opt/notesapp/app.py <<'PY'
import os, json
from flask import Flask, request
import boto3
import pymysql

REGION    = os.environ.get("AWS_REGION", "us-west-2")
SECRET_ID = os.environ.get("DB_SECRET_ID", "lab/rds/mysql")

def get_secret():
    sm = boto3.client("secretsmanager", region_name=REGION)
    resp = sm.get_secret_value(SecretId=SECRET_ID)
    return json.loads(resp["SecretString"])

def conn():
    s = get_secret()
    host = s["host"]
    user = s["username"]
    pwd  = s["password"]
    port = int(s.get("port", 3306))
    return pymysql.connect(host=host, user=user, password=pwd, port=port, connect_timeout=5)

app = Flask(__name__)

@app.get("/")
def home():
    return "Operation Escape Matrix!!!!!!!!!!!\n"

@app.get("/init")
def init():
    c = conn()
    try:
        with c.cursor() as cur:
            cur.execute("CREATE DATABASE IF NOT EXISTS notes;")
            cur.execute("USE notes;")
            cur.execute("""
              CREATE TABLE IF NOT EXISTS notes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                note TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
              );
            """)
        c.commit()
        return "OK: initialized\n"
    finally:
        c.close()

@app.get("/add")
def add():
    note = request.args.get("note", "")
    if not note:
        return "Missing ?note=\n", 400
    c = conn()
    try:
        with c.cursor() as cur:
            cur.execute("USE notes;")
            cur.execute("INSERT INTO notes (note) VALUES (%s)", (note,))
        c.commit()
        return "OK: inserted\n"
    finally:
        c.close()

@app.get("/list")
def list_notes():
    c = conn()
    try:
        with c.cursor() as cur:
            cur.execute("USE notes;")
            cur.execute("SELECT id, note, created_at FROM notes ORDER BY id DESC LIMIT 50;")
            rows = cur.fetchall()
        return "\n".join([f"{r[0]} | {r[2]} | {r[1]}" for r in rows]) + "\n"
    finally:
        c.close()

PY

# Systemd service for Flask app (runs on localhost:5000)
cat >/etc/systemd/system/notesapp.service <<SERVICE
[Unit]
Description=Flask Notes App
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/opt/notesapp
Environment=AWS_REGION=${AWS_REGION}
Environment=DB_SECRET_ID=${DB_SECRET_ID}
ExecStart=/usr/bin/python3 -m flask --app /opt/notesapp/app.py run --host 127.0.0.1 --port 5000
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now notesapp

# Nginx: proxy to Flask (so port 80 works)
cat >/etc/nginx/conf.d/notesapp.conf <<'NGINX'
server {
  listen 80;
  server_name _;

  location = /init  { proxy_pass http://127.0.0.1:5000/init;  }
  location = /add   { proxy_pass http://127.0.0.1:5000/add;   }
  location = /list  { proxy_pass http://127.0.0.1:5000/list;  }
  location = /      { proxy_pass http://127.0.0.1:5000/;      }

  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto $scheme;
}
NGINX

systemctl restart nginx
echo "setup completed"
