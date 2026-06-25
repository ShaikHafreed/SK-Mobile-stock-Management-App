from flask import Flask
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

    # Init extensions
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    CORS(app)

    # Register blueprints
    from app.routes.auth import auth_bp
    from app.routes.products import products_bp
    from app.routes.categories import categories_bp
    from app.routes.temper_glass import temper_bp
    from app.routes.excel import excel_bp
    from app.routes.logs import logs_bp
    from app.routes.search import search_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(products_bp, url_prefix='/api/products')
    app.register_blueprint(categories_bp, url_prefix='/api/categories')
    app.register_blueprint(temper_bp, url_prefix='/api/boxes')
    app.register_blueprint(excel_bp, url_prefix='/api/excel')
    app.register_blueprint(logs_bp, url_prefix='/api/logs')
    app.register_blueprint(search_bp, url_prefix='/api/search')

    # Health check
    @app.route('/api/health')
    def health():
        return {'status': 'SK Mobiles API is running'}, 200

    return app