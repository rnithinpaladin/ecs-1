from flask import Flask, Response
import os
import uuid

app = Flask(__name__)

DATA_DIR = "/mnt/data"
os.makedirs(DATA_DIR, exist_ok=True)

@app.route('/')
def show_secret_and_create_file():
    # 1. Read secret
    secret_value = os.getenv('DB_PASSWORD', 'No secret found')

    # 2. Count existing files
    existing_files = sorted([f for f in os.listdir(DATA_DIR) if f.startswith("page-")])

    # 3. Create a new file
    new_id = str(uuid.uuid4())[:8]
    file_name = f"page-{len(existing_files)+1}-{new_id}.html"
    file_path = os.path.join(DATA_DIR, file_name)

    with open(file_path, "w") as f:
        f.write(f"<html><body><h1>This is page {file_name}</h1></body></html>")

    # 4. Generate file list HTML
    file_list_html = "<ul>" + "".join(f"<li>{f}</li>" for f in sorted(os.listdir(DATA_DIR))) + "</ul>"

    # 5. Return response
    return Response(
        f"<h2>Secret Value: {secret_value}</h2>"
        f"<h3>Created: {file_name}</h3>"
        f"<h3>All Pages:</h3>{file_list_html}",
        mimetype="text/html"
    )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
