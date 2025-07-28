from flask import Flask, Response
import os
import uuid
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

app = Flask(__name__)
DATA_DIR = "/mnt/data"

# Create the data directory if it doesn't exist.
# In a real-world scenario with a mounted volume like EFS, this directory should already exist.
os.makedirs(DATA_DIR, exist_ok=True)

def requests_session_with_retries():
    """
    Creates a requests.Session object with a retry mechanism.
    This will retry on transient errors, making the app more resilient
    to temporary network issues or slow-starting backend services.
    """
    session = requests.Session()
    retry = Retry(
        total=5,  # Total number of retries
        backoff_factor=0.5,  # A delay factor between attempts: {0.5, 1, 2, 4, 8} seconds
        status_forcelist=[500, 502, 503, 504],  # A set of HTTP status codes to retry on
        allowed_methods=["HEAD", "GET", "OPTIONS"]
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)
    return session

@app.route('/')
def show_secrets_and_create_file():
    """
    Main route that displays information and interacts with the backend and filesystem.
    """
    secret_value = os.getenv('DB_PASSWORD', 'No secret found')
    backend_url = os.getenv('BACKEND_URL', 'Not set')
    api_output = ""

    # Make a resilient request to the backend API using the retry session
    if backend_url != 'Not set':
        try:
            session = requests_session_with_retries()
            # Increased timeout to give backend more time to respond on the first try
            backend_response = session.get(backend_url, timeout=10)
            # Raise an exception for bad status codes (4xx or 5xx)
            backend_response.raise_for_status()
            api_output = backend_response.text
        except requests.exceptions.RequestException as e:
            # This will catch connection errors, timeouts, and bad status codes after retries
            api_output = f"Error calling backend after multiple retries: {str(e)}"
    else:
        api_output = "BACKEND_URL environment variable is not set."

    # --- File Creation Logic (remains the same) ---
    try:
        # Create a new unique HTML file on each visit
        new_id = str(uuid.uuid4())[:8]
        # To prevent the file list from growing indefinitely, you might want to add a cleanup logic.
        # For this example, we keep it simple.
        existing_files = sorted([f for f in os.listdir(DATA_DIR) if f.startswith("page-")])
        file_name = f"page-{len(existing_files)+1}-{new_id}.html"
        file_path = os.path.join(DATA_DIR, file_name)

        with open(file_path, "w") as f:
            f.write(f"<html><body><h1>This is page {file_name}</h1></body></html>")

        # List all files in the directory for display
        all_files_in_dir = sorted(os.listdir(DATA_DIR))
        file_list_html = "<ul>" + "".join(f"<li>{f}</li>" for f in all_files_in_dir) + "</ul>"
        creation_message = f"<h3>Created: {file_name}</h3>"

    except OSError as e:
        # Gracefully handle potential file system errors (e.g., permissions)
        file_list_html = "<p style='color:red;'>Could not read or write to data directory.</p>"
        creation_message = f"<h3 style='color:red;'>Error creating file: {e}</h3>"


    # --- Render the final HTML response ---
    return Response(
        f"<h2>Secret Value: {secret_value}</h2>"
        f"<h2>Backend URL: {backend_url}</h2>"
        f"<h2>API Response:</h2><pre>{api_output}</pre>"
        f"{creation_message}"
        f"<h3>All Pages in {DATA_DIR}:</h3>{file_list_html}",
        mimetype="text/html"
    )

@app.route('/health')
def health_check():
    """
    Simple, reliable health check endpoint for ECS.
    This should not have any dependencies on backends or filesystems.
    """
    return "OK", 200

if __name__ == '__main__':
    # Use a production-grade WSGI server like Gunicorn or Waitress in your Dockerfile
    # For simple execution, Flask's development server is used here.
    app.run(host='0.0.0.0', port=80)