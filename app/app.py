import os
from flask import Flask
from flask import render_template
from redis import StrictRedis
from datetime import datetime

if os.path.exists("/run/secrets/db_password"):
    with open("/run/secrets/db_password", "r") as secret:
        db_password = secret.readline().strip()

print (db_password)

app = Flask(__name__)
redis = StrictRedis(host='backend', port=6379, password=db_password)

@app.route('/')
def home():
    redis.lpush('times', datetime.now().strftime('%Y-%m-%dT%H:%M:%S%z'))
    return render_template('index.html', title='Home',
                           times=redis.lrange('times', 0, -1))


if __name__ == '__main__':
    app.run(host='0.0.0.0')
