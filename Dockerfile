# ベースイメージとしてPython 3.11を指定
FROM python:3.11-slim

# 作業ディレクトリ作成
WORKDIR /app

# 依存関係を追加（requirements.txtがある前提）
COPY requirements.txt .

# 必要なPythonパッケージをインストール
RUN pip install --no-cache-dir -r requirements.txt

# デバッグ用ツールを追加
RUN apt-get update && apt-get install -y \
    vim \
    curl \
    procps \
    net-tools \
    less \
    jq \
 && rm -rf /var/lib/apt/lists/*

# アプリケーションコードをコピー
COPY fastapi/app /app/app

# Uvicornを使ってFastAPIアプリを起動
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]