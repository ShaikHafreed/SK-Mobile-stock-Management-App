from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from config import config

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()


def create_app(config_name='default'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    CORS(app, resources={
        r"/api/*": {
            "origins": "*",
            "allow_headers": [
                "Content-Type",
                "Authorization",
                "X-API-Key",
                "ngrok-skip-browser-warning",
                "User-Agent"
            ],
            "methods": [
                "GET", "POST", "PUT",
                "DELETE", "PATCH", "OPTIONS"
            ]
        }
    })

    # ── API KEY MIDDLEWARE ─────────────────────────────────
    @app.before_request
    def check_api_key():
        if request.method == 'OPTIONS':
            return None
        if request.path in ('/api/health', '/privacy'):
            return None

        api_key = request.headers.get('X-API-Key')
        if not api_key or \
                api_key != app.config.get('API_KEY', ''):
            return jsonify({
                'error': 'Invalid or missing API key'
            }), 401

    # ── RESPONSE HEADERS ──────────────────────────────────
    @app.after_request
    def add_headers(response):
        response.headers[
            'ngrok-skip-browser-warning'] = 'true'
        response.headers[
            'Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Headers'] = (
            'Content-Type, Authorization, X-API-Key, '
            'ngrok-skip-browser-warning, User-Agent'
        )
        response.headers['Access-Control-Allow-Methods'] = (
            'GET, POST, PUT, DELETE, PATCH, OPTIONS'
        )
        return response

    # ── BLUEPRINTS ────────────────────────────────────────
    from app.routes.auth import auth_bp
    from app.routes.products import products_bp
    from app.routes.categories import categories_bp
    from app.routes.temper_glass import temper_bp
    from app.routes.excel import excel_bp
    from app.routes.logs import logs_bp
    from app.routes.search import search_bp

    app.register_blueprint(auth_bp,
                           url_prefix='/api/auth')
    app.register_blueprint(products_bp,
                           url_prefix='/api/products')
    app.register_blueprint(categories_bp,
                           url_prefix='/api/categories')
    app.register_blueprint(temper_bp,
                           url_prefix='/api/boxes')
    app.register_blueprint(excel_bp,
                           url_prefix='/api/excel')
    app.register_blueprint(logs_bp,
                           url_prefix='/api/logs')
    app.register_blueprint(search_bp,
                           url_prefix='/api/search')

    @app.route('/api/health')
    def health():
        return {
            'status': 'SR Mobiles API is running',
            'version': '1.0.0'
        }, 200

    @app.route('/privacy')
    def privacy_policy():
        from flask import render_template_string
        return render_template_string(PRIVACY_POLICY_HTML)

    return app


PRIVACY_POLICY_HTML = """
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Privacy Policy — SR Mobiles</title>
<style>
  body { font-family: -apple-system, Segoe UI, Roboto, Arial, sans-serif;
         max-width: 760px; margin: 40px auto; padding: 0 20px; color: #1a1a2e;
         line-height: 1.6; }
  h1 { color: #1565C0; }
  h2 { color: #1565C0; margin-top: 32px; }
  .updated { color: #666; font-size: 0.9em; }
</style>
</head>
<body>
<h1>Privacy Policy — SR Mobiles</h1>
<p class="updated">Last updated: 2026-07-09</p>

<p>SR Mobiles ("the app") is an internal stock management tool used by SR
Mobiles retail staff to manage inventory, billing, and related business
operations. This policy explains what information the app collects and
how it is used.</p>

<h2>Information we collect</h2>
<ul>
  <li><strong>Account information</strong>: username, password (stored as a
  secure hash, never in plain text), full name, and profile photo.</li>
  <li><strong>Authentication data</strong>: if you sign in with Google or
  phone number, we receive the identifiers Google/Firebase provide to
  authenticate you (email address or phone number, account ID).</li>
  <li><strong>Business data</strong>: product inventory, stock quantities,
  billing records, and product photos you upload. This data belongs to the
  shop's operations, not to individual end customers.</li>
  <li><strong>Device/usage data</strong>: basic app usage analytics via
  Firebase Analytics (e.g. crash reports, feature usage), used only to
  improve app reliability.</li>
</ul>

<h2>How we use this information</h2>
<p>Solely to operate the app's core functionality: authenticating staff,
storing and displaying inventory/billing data, generating reports, and
diagnosing technical issues. We do not sell or share this data with third
parties for advertising or marketing purposes.</p>

<h2>Data storage</h2>
<p>Data is stored using Supabase (PostgreSQL database and file storage) and
Firebase (authentication). Access to the underlying database is restricted
via Row-Level Security and access-key authentication.</p>

<h2>Data retention</h2>
<p>Data is retained for as long as the account or business record is
active. Deleted products/records are soft-deleted (marked inactive) for
audit purposes but are not shown in normal use.</p>

<h2>Your rights</h2>
<p>Since this app is used internally by SR Mobiles staff, requests to
access, correct, or delete personal data should be directed to the shop
owner/administrator directly.</p>

<h2>Contact</h2>
<p>For questions about this policy, contact: shaikhafreeddth@gmail.com</p>
</body>
</html>
"""