from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./robosurg.db"
    SECRET_KEY: str = "robosurg-secret-key-mude-em-producao"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 480
    TELEGRAM_BOT_TOKEN: str = ""
    TELEGRAM_ENFERMEIRO_CHEFE_ID: str = ""
    HOSPITAL_NOME: str = "Hospital"

    class Config:
        env_file = ".env"

settings = Settings()
