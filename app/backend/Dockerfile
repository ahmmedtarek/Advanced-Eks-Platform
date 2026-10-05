FROM python:3.12.7-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Create an unprivileged user before switching to it
RUN groupadd --system app && useradd --system --gid app --no-create-home app

# Dependencies first: this layer is cached until requirements.txt changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# App code last, since it changes most often
COPY --chown=app:app app.py .

USER app

EXPOSE 8000

CMD ["gunicorn", "-b", "0.0.0.0:8000", "app:app"]