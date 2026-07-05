import os
from dotenv import load_dotenv

load_dotenv()


def get_database_url():
    database_url = os.getenv('DATABASE_URL')
    if database_url:
        return database_url

    db_user = os.getenv('DB_USER', 'postgres')
    db_password = os.getenv('DB_PASSWORD')
    db_host = os.getenv('DB_HOST')
    db_port = os.getenv('DB_PORT', '5432')
    db_name = os.getenv('DB_NAME', 'postgres')

    if not db_password or not db_host:
        raise RuntimeError(
            'Database credentials are not configured. '
            'Set DATABASE_URL, or DB_HOST and DB_PASSWORD, in backend/.env'
        )

    from urllib.parse import quote_plus
    encoded_password = quote_plus(db_password)
    return (
        f"postgresql://{db_user}:{encoded_password}"
        f"@{db_host}:{db_port}/{db_name}"
    )


class Config:
    SECRET_KEY = os.getenv(
        'SECRET_KEY', 'sk-mobiles-secret-key-2024')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.getenv(
        'JWT_SECRET_KEY', 'sk-mobiles-jwt-secret-2024')
    JWT_ACCESS_TOKEN_EXPIRES = 86400
    SUPABASE_URL = os.getenv('SUPABASE_URL', '')
    SUPABASE_SECRET_KEY = os.getenv(
        'SUPABASE_SECRET_KEY', '')
    SUPABASE_BUCKET = 'sk-mobiles-images'
    API_KEY = os.getenv(
        'API_KEY', 'sk-mobiles-api-key-2024-hafreed')


class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = get_database_url()


class ProductionConfig(Config):
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = get_database_url()


config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}