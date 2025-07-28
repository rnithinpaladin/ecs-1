from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def provide_secret():
    # Reads the secret from environment variable (injected via ECS task definition)
    secret_value = os.getenv('DB_PASSWORD', 'No secret found')
    return secret_value

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080)
