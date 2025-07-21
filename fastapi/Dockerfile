# ベースイメージとしてPython 3.11を指定
FROM python:3.11-slim

# 作業ディレクトリ作成
WORKDIR /app

# 依存関係を追加（requirements.txtがある前提）
COPY requirements.txt .

# 必要なPythonパッケージをインストール
RUN pip install --no-cache-dir -r requirements.txt

# アプリケーションコードをコピー
COPY . .

# Uvicornを使ってFastAPIアプリを起動
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]