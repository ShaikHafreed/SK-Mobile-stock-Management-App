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
        if request.path == '/api/health':
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
            'status': 'SK Mobiles API is running',
            'version': '1.0.0'
        }, 200

    return app